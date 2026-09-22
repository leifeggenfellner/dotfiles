#!/usr/bin/env python3
import argparse
import asyncio
import copy
import json
import os
import re
import socket
import sys

RECONCILE_RETRY_DELAY = 0.75
MAX_RECONCILE_RETRIES = 2

import tempfile
import time
from pathlib import Path

OUTPUT_NAME = re.compile(r"^[A-Za-z0-9_.:-]+$")
WINDOW_ADDRESS = re.compile(r"^0x[0-9A-Fa-f]+$")


def validate_output_name(name):
    if not isinstance(name, str) or not OUTPUT_NAME.fullmatch(name):
        raise RuntimeError(f"invalid Hyprland output name: {name!r}")
    return name


def validate_window_address(address):
    if not isinstance(address, str) or not WINDOW_ADDRESS.fullmatch(address):
        raise RuntimeError(f"invalid Hyprland window address: {address!r}")
    return address


def workspace_selector(workspace):
    value = str(workspace)
    if not value.isdigit() or int(value) < 1:
        raise RuntimeError(f"invalid Hyprland workspace: {workspace!r}")
    return value


def workspace_move_command(workspace, output):
    workspace = workspace_selector(workspace)
    output = validate_output_name(output)
    return [
        "hyprctl",
        "dispatch",
        f'hl.dsp.workspace.move({{workspace = "{workspace}", monitor = "{output}"}})',
    ]


def window_move_command(workspace, address):
    workspace = workspace_selector(workspace)
    address = validate_window_address(address)
    return [
        "hyprctl",
        "dispatch",
        f'hl.dsp.window.move({{workspace = "{workspace}", follow = false, window = "address:{address}"}})',
    ]


def focus_command(kind, value):
    if kind == "monitor":
        value = validate_output_name(value)
    elif kind == "workspace":
        value = workspace_selector(value)
    else:
        raise RuntimeError(f"invalid Hyprland focus kind: {kind!r}")
    return ["hyprctl", "dispatch", f'hl.dsp.focus({{{kind} = "{value}"}})']


def lua_literal(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return repr(value)
    if isinstance(value, str):
        escaped = []
        for character in value:
            if character == "\\":
                escaped.append("\\\\")
            elif character == '"':
                escaped.append('\\"')
            elif character == "\n":
                escaped.append("\\n")
            elif character == "\r":
                escaped.append("\\r")
            elif character == "\t":
                escaped.append("\\t")
            elif ord(character) < 32:
                escaped.append(f"\\{ord(character):03d}")
            else:
                escaped.append(character)
        return f'"{"".join(escaped)}"'
    raise RuntimeError(f"unsupported Lua literal: {value!r}")


def lua_table(fields):
    return (
        "{ "
        + ", ".join(f"{key} = {lua_literal(value)}" for key, value in fields.items())
        + " }"
    )


def eval_command(expression):
    # This compositor's dynamic configuration API is exposed through hl.* Lua.
    return ["hyprctl", "eval", expression]


def monitor_command(name, mode, position, scale=1.0, transform=0):
    name = validate_output_name(name)
    fields = {
        "output": name,
        "mode": mode,
        "position": position,
        "scale": float(scale),
        "transform": int(transform),
    }
    return "monitor", eval_command(f"hl.monitor({lua_table(fields)})")


def disabled_monitor_command(name):
    name = validate_output_name(name)
    return "monitor", eval_command(
        f"hl.monitor({lua_table({'output': name, 'disabled': True})})"
    )


def workspace_rule_command(workspace, output, default):
    workspace = workspace_selector(workspace)
    output = validate_output_name(output)
    fields = {"workspace": workspace, "monitor": output, "default": bool(default)}
    return "workspace_rule", eval_command(f"hl.workspace_rule({lua_table(fields)})")


def window_rule_command(window_class, workspace):
    workspace = workspace_selector(workspace)
    match = lua_table({"class": window_class})
    return "window_rule", eval_command(
        f'hl.window_rule({{ match = {match}, workspace = {lua_literal(f"{workspace} silent")} }})'
    )


def state_root():
    return (
        Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state"))
        / "monitor-control"
    )


def runtime_root():
    runtime = os.environ.get("XDG_RUNTIME_DIR")
    if not runtime:
        raise RuntimeError("XDG_RUNTIME_DIR is not set")
    return Path(runtime) / "monitor-control"


def atomic_json(path, value):
    path.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        os.fchmod(descriptor, 0o600)
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            json.dump(value, handle, sort_keys=True)
            handle.write("\n")
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    except BaseException:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
        raise


def read_json(path, default=None):
    try:
        with path.open(encoding="utf-8") as handle:
            return json.load(handle)
    except (FileNotFoundError, json.JSONDecodeError, OSError):
        return default


def monitor_key(config, monitor):
    matches = []
    for key, identity in config["monitors"].items():
        serial = identity.get("serial", "")
        connector = identity.get("name", "")
        if serial and monitor.get("serial") == serial:
            matches.append(key)
        elif not serial and connector and monitor.get("name") == connector:
            matches.append(key)
    if len(matches) > 1:
        raise RuntimeError(
            f"monitor {monitor.get('name', '?')} matches multiple identities: {matches}"
        )
    return matches[0] if matches else None


def inventory(config, monitors):
    found = {}
    unknown_external = []
    for monitor in monitors:
        key = monitor_key(config, monitor)
        if key:
            if key in found:
                raise RuntimeError(f"duplicate monitor identity for {key}")
            found[key] = monitor
        elif monitor.get("name") != "eDP-1":
            unknown_external.append(monitor.get("name", "unknown"))
    return found, unknown_external


def required_keys(profile):
    return {output["monitor"] for output in profile["outputs"]}


def external_serials(config, keys):
    return {
        config["monitors"][key]["serial"]
        for key in keys
        if config["monitors"][key].get("serial")
    }


def load_selection(config):
    selection = read_json(state_root() / "selection.json", {"mode": "auto"})
    if (
        selection.get("mode") == "explicit"
        and selection.get("profile") in config["profiles"]
    ):
        return selection
    return {"mode": "auto"}


def resolve_layout(config, monitors, selection):
    found, unknown = inventory(config, monitors)
    connected_external = {
        monitor.get("serial", "")
        for monitor in monitors
        if monitor.get("name") != "eDP-1" and monitor.get("serial")
    }

    if selection["mode"] == "explicit":
        name = selection["profile"]
        profile = config["profiles"][name]
        available = copy.deepcopy(
            [output for output in profile["outputs"] if output["monitor"] in found]
        )
        complete = required_keys(profile) <= set(found)
        if complete:
            return name, name, available, found, unknown
        laptop_key = next(
            (
                key
                for key, item in config["monitors"].items()
                if item.get("name") == "eDP-1"
            ),
            None,
        )
        covered = {
            workspace for output in available for workspace in output["workspaces"]
        }
        if laptop_key in found:
            laptop = next(
                (output for output in available if output["monitor"] == laptop_key),
                None,
            )
            if laptop is None:
                laptop = {
                    "monitor": laptop_key,
                    "position": "0x0",
                    "resolution": None,
                    "scale": None,
                    "transform": 0,
                    "workspaces": [],
                    "primary": True,
                }
                available.insert(0, laptop)
            laptop["workspaces"] = laptop["workspaces"] + [
                workspace for workspace in range(1, 11) if workspace not in covered
            ]
        return name, f"{name}:partial", available, found, unknown

    candidates = []
    for name, profile in config["profiles"].items():
        if (
            profile.get("autoDetect")
            and required_keys(profile) <= set(found)
            and external_serials(config, required_keys(profile)) == connected_external
        ):
            candidates.append(name)
    if len(candidates) == 1 and not unknown:
        name = candidates[0]
        return (
            None,
            name,
            copy.deepcopy(config["profiles"][name]["outputs"]),
            found,
            unknown,
        )
    if connected_external or unknown:
        return None, "ambiguous", [], found, unknown
    name = config["fallbackProfile"]
    profile = config["profiles"][name]
    if required_keys(profile) <= set(found):
        return None, name, copy.deepcopy(profile["outputs"]), found, unknown
    return None, "ambiguous", [], found, unknown


def is_monitor_event(line):
    return line.partition(">>")[0] in {
        "monitoradded",
        "monitoraddedv2",
        "monitorremoved",
    }


def desired_output(config, output, found):
    identity = config["monitors"][output["monitor"]]
    current = found[output["monitor"]]
    return {
        "name": validate_output_name(current["name"]),
        "mode": output.get("resolution") or identity["resolution"],
        "position": output["position"],
        "scale": output.get("scale") or identity["scale"],
        "transform": output.get("transform", 0),
        "workspaces": output["workspaces"],
        "primary": output.get("primary", False),
    }


def output_matches(current, desired, active_names):
    if current.get("name") not in active_names:
        return False
    mode_parts = desired["mode"].split("@", 1)
    mode = mode_parts[0]
    dimensions = mode.split("x", 1)
    if mode != "preferred" and len(dimensions) == 2:
        if (current.get("width"), current.get("height")) != tuple(map(int, dimensions)):
            return False
        if (
            len(mode_parts) == 2
            and abs(float(current.get("refreshRate", 0)) - float(mode_parts[1])) > 0.5
        ):
            return False
    position = tuple(map(int, desired["position"].split("x", 1)))
    return (
        (current.get("x"), current.get("y")) == position
        and float(current.get("scale", 1)) == float(desired["scale"])
        and int(current.get("transform", 0)) == desired["transform"]
    )


def output_state(current, active_names):
    if current is None:
        return "missing"
    if current.get("name") not in active_names:
        return "disabled"
    return (
        f"enabled at {current.get('width')}x{current.get('height')}"
        f"@{current.get('refreshRate')} position {current.get('x')}x{current.get('y')}"
        f" scale {current.get('scale')} transform {current.get('transform')}"
    )


def verify_plan_converged(config, plan, monitors, active_names):
    found, _ = inventory(config, monitors)
    desired_names = {output["name"] for output in plan["outputs"]}
    for desired in plan["outputs"]:
        current = next(
            (
                monitor
                for monitor in found.values()
                if monitor["name"] == desired["name"]
            ),
            None,
        )
        if not output_matches(current or {}, desired, active_names):
            raise RuntimeError(
                f"monitor reconciliation did not converge for {desired['name']}: "
                f"expected enabled {desired['mode']} at {desired['position']} "
                f"scale {desired['scale']} transform {desired['transform']}; "
                f"observed {output_state(current, active_names)}"
            )
    for key, current in found.items():
        if (
            config["monitors"][key].get("serial")
            and current["name"] not in desired_names
            and current["name"] in active_names
        ):
            raise RuntimeError(
                f"monitor reconciliation did not converge for {current['name']}: "
                f"expected disabled; observed {output_state(current, active_names)}"
            )


def build_plan(config, monitors, active_names, selection, include_routes=False):
    selected, active, outputs, found, unknown = resolve_layout(
        config, monitors, selection
    )
    commands = []
    desired = []
    if active != "ambiguous":
        desired = [desired_output(config, output, found) for output in outputs]
        desired_names = {output["name"] for output in desired}
        for output in desired:
            if not output_matches(
                found[
                    next(
                        key
                        for key, value in found.items()
                        if value["name"] == output["name"]
                    )
                ],
                output,
                active_names,
            ):
                commands.append(
                    monitor_command(
                        output["name"],
                        output["mode"],
                        output["position"],
                        float(output["scale"]),
                        output["transform"],
                    )
                )
        for key, current in found.items():
            if current["name"] not in desired_names and config["monitors"][key].get(
                "serial"
            ):
                commands.append(disabled_monitor_command(current["name"]))
        for output in desired:
            for index, workspace in enumerate(output["workspaces"]):
                commands.append(
                    workspace_rule_command(workspace, output["name"], index == 0)
                )
    if include_routes:
        for name, route in config["appRoutes"].items():
            commands.append(window_rule_command(route["class"], route["workspace"]))
    return {
        "selectedProfile": selected,
        "activeProfile": active,
        "outputs": desired,
        "found": found,
        "unknown": unknown,
        "commands": commands,
    }


async def run_command(argv, check=True):
    process = await asyncio.create_subprocess_exec(
        *argv,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
    )
    stdout, stderr = await process.communicate()
    if check and process.returncode:
        message = stderr.decode().strip() or stdout.decode().strip()
        raise RuntimeError(f"{' '.join(argv[:3])} failed: {message}")
    return stdout.decode()


async def hypr_json(*arguments):
    return json.loads(await run_command(["hyprctl", *arguments, "-j"]))


def record_warning(warnings, label, error):
    warning = f"{label}: {error}"
    warnings.append(warning)
    print(f"monitor-control: warning: {warning}", file=sys.stderr, flush=True)


async def run_best_effort(warnings, label, argv):
    try:
        await run_command(argv)
    except Exception as error:
        record_warning(warnings, label, error)


async def move_existing_windows(config, warnings):
    try:
        clients = await hypr_json("clients")
    except Exception as error:
        record_warning(warnings, "app routing query failed", error)
        return
    for client in clients:
        window_class = client.get("class", "")
        address = client.get("address", "")
        current_workspace = client.get("workspace", {}).get("id")
        for route in config["appRoutes"].values():
            if (
                address
                and re.search(route["class"], window_class)
                and current_workspace != route["workspace"]
            ):
                await run_best_effort(
                    warnings,
                    f"app routing to workspace {route['workspace']} failed",
                    window_move_command(route["workspace"], address),
                )
                break


class MonitorDaemon:
    def __init__(self, config, schedule_later=None):
        self.config = config
        self.selection = load_selection(config)
        self.schedule_later = schedule_later
        self.reconcile_timer = None
        self.reconcile_task = None
        self.reconcile_pending = False
        self.reconcile_retries = 0
        self.reconcile_lock = asyncio.Lock()
        self.control_lock = asyncio.Lock()
        self.routes_applied = False
        self.server = None
        self.status = {}

    def write_status(self, **values):
        self.status = {
            "schemaVersion": 1,
            "mode": self.selection["mode"],
            "selectedProfile": self.selection.get("profile"),
            "activeProfile": self.status.get("activeProfile"),
            "connected": self.status.get("connected", {}),
            "unknownOutputs": self.status.get("unknownOutputs", []),
            "availableProfiles": sorted(self.config["profiles"]),
            "lastError": None,
            "warnings": [],
            "updatedAt": int(time.time()),
        }
        self.status.update(values)
        atomic_json(runtime_root() / "status.json", self.status)

    def schedule_reconcile(self, delay=0.35, reset_retries=True):
        if reset_retries:
            self.reconcile_retries = 0
        if self.reconcile_timer:
            self.reconcile_timer.cancel()
        schedule_later = self.schedule_later or asyncio.get_running_loop().call_later
        self.reconcile_timer = schedule_later(delay, self.start_reconcile)

    def start_reconcile(self):
        self.reconcile_timer = None
        if self.reconcile_task and not self.reconcile_task.done():
            self.reconcile_pending = True
            return
        self.reconcile_task = asyncio.create_task(self.run_scheduled_reconcile())

    async def run_scheduled_reconcile(self):
        succeeded = await self.reconcile()
        if self.reconcile_pending:
            self.reconcile_pending = False
            self.schedule_reconcile(0, reset_retries=False)
        elif succeeded:
            self.reconcile_retries = 0
        elif self.reconcile_retries < MAX_RECONCILE_RETRIES:
            self.reconcile_retries += 1
            self.schedule_reconcile(RECONCILE_RETRY_DELAY, reset_retries=False)

    async def reconcile(self):
        async with self.reconcile_lock:
            try:
                warnings = []
                monitors = await hypr_json("monitors", "all")
                focused = next(
                    (monitor for monitor in monitors if monitor.get("focused")), None
                )
                # The active-only query is authoritative for enabled state.
                active_names = {
                    monitor["name"] for monitor in await hypr_json("monitors")
                }
                plan = build_plan(
                    self.config,
                    monitors,
                    active_names,
                    self.selection,
                    not self.routes_applied,
                )
                for kind, command in plan["commands"]:
                    if kind == "window_rule":
                        await run_best_effort(
                            warnings, "dynamic app route unavailable", command
                        )
                    else:
                        await run_command(command)
                if plan["activeProfile"] != "ambiguous":
                    verify_plan_converged(
                        self.config,
                        plan,
                        await hypr_json("monitors", "all"),
                        {monitor["name"] for monitor in await hypr_json("monitors")},
                    )
                self.routes_applied = True
                if plan["activeProfile"] != "ambiguous":
                    try:
                        workspaces = await hypr_json("workspaces")
                        existing = {
                            str(workspace.get("id", workspace.get("name", "")))
                            for workspace in workspaces
                        }
                        for output in plan["outputs"]:
                            for workspace in output["workspaces"]:
                                if str(workspace) in existing:
                                    await run_best_effort(
                                        warnings,
                                        f"workspace {workspace} migration to {output['name']} failed",
                                        workspace_move_command(
                                            workspace, output["name"]
                                        ),
                                    )
                    except Exception as error:
                        record_warning(
                            warnings, "workspace migration query failed", error
                        )
                await move_existing_windows(self.config, warnings)
                focus_output = None
                focus_workspace = None
                retained_names = {output["name"] for output in plan["outputs"]} | set(
                    plan["unknown"]
                )
                if focused and (
                    plan["activeProfile"] == "ambiguous"
                    or focused.get("name") in retained_names
                ):
                    focus_output = focused["name"]
                    focus_workspace = focused.get("activeWorkspace", {}).get("id")
                elif plan["outputs"]:
                    fallback = next(
                        (output for output in plan["outputs"] if output["primary"]),
                        plan["outputs"][0],
                    )
                    focus_output = fallback["name"]
                    focus_workspace = (
                        fallback["workspaces"][0] if fallback["workspaces"] else None
                    )
                if focus_output:
                    await run_best_effort(
                        warnings,
                        f"focus restoration to monitor {focus_output} failed",
                        focus_command("monitor", focus_output),
                    )
                if focus_workspace:
                    await run_best_effort(
                        warnings,
                        f"focus restoration to workspace {focus_workspace} failed",
                        focus_command("workspace", focus_workspace),
                    )
                if any(kind == "monitor" for kind, _ in plan["commands"]):
                    await run_command(["wallpaper-restore"], check=False)
                self.write_status(
                    activeProfile=plan["activeProfile"],
                    connected={
                        key: value["name"] for key, value in plan["found"].items()
                    },
                    unknownOutputs=plan["unknown"],
                    warnings=warnings,
                )
                return True
            except Exception as error:
                self.write_status(activeProfile=None, lastError=str(error))
                print(f"monitor-control: {error}", file=sys.stderr, flush=True)
                return False

    async def handle_control(self, reader, writer):
        try:
            request = json.loads((await reader.readline()).decode())
            command = request.get("command")
            async with self.control_lock:
                if (
                    command == "select"
                    and request.get("profile") in self.config["profiles"]
                ):
                    self.selection = {"mode": "explicit", "profile": request["profile"]}
                    atomic_json(state_root() / "selection.json", self.selection)
                    response = {"ok": await self.reconcile()}
                elif command == "auto":
                    self.selection = {"mode": "auto"}
                    atomic_json(state_root() / "selection.json", self.selection)
                    response = {"ok": await self.reconcile()}
                elif command == "reconcile":
                    response = {"ok": await self.reconcile()}
                else:
                    response = {"ok": False, "error": "invalid command or profile"}
        except Exception as error:
            response = {"ok": False, "error": str(error)}
        writer.write((json.dumps(response) + "\n").encode())
        await writer.drain()
        writer.close()
        await writer.wait_closed()

    async def watch_events(self):
        delay = 0.25
        while True:
            signature = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
            runtime = os.environ.get("XDG_RUNTIME_DIR")
            if not signature or not runtime:
                self.write_status(
                    lastError="Hyprland runtime environment is unavailable"
                )
                await asyncio.sleep(delay)
                delay = min(delay * 2, 5)
                continue
            event_socket = Path(runtime) / "hypr" / signature / ".socket2.sock"
            try:
                reader, writer = await asyncio.open_unix_connection(event_socket)
                delay = 0.25
                self.routes_applied = False
                self.schedule_reconcile(0)
                while line := await reader.readline():
                    if is_monitor_event(line.decode(errors="replace")):
                        self.schedule_reconcile()
                writer.close()
                await writer.wait_closed()
            except (ConnectionError, FileNotFoundError, OSError) as error:
                self.write_status(lastError=f"event socket unavailable: {error}")
            await asyncio.sleep(delay)
            delay = min(delay * 2, 5)

    async def run(self):
        root = runtime_root()
        root.mkdir(mode=0o700, parents=True, exist_ok=True)
        control_socket = root / "control.sock"
        control_socket.unlink(missing_ok=True)
        self.server = await asyncio.start_unix_server(
            self.handle_control, path=control_socket
        )
        os.chmod(control_socket, 0o600)
        self.write_status()
        self.schedule_reconcile(0)
        async with self.server:
            await self.watch_events()


def send_control(command, profile=None):
    request = {"command": command}
    if profile:
        request["profile"] = profile
    path = runtime_root() / "control.sock"
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as client:
        client.connect(str(path))
        client.sendall((json.dumps(request) + "\n").encode())
        response = b""
        while not response.endswith(b"\n"):
            chunk = client.recv(4096)
            if not chunk:
                break
            response += chunk
    result = json.loads(response)
    print(json.dumps(result, sort_keys=True))
    return 0 if result.get("ok") else 1


def parse_args():
    parser = argparse.ArgumentParser(prog="monitor-control")
    parser.add_argument("--config", required=True)
    subcommands = parser.add_subparsers(dest="command", required=True)
    subcommands.add_parser("daemon")
    subcommands.add_parser("status")
    select = subcommands.add_parser("select")
    select.add_argument("profile")
    subcommands.add_parser("auto")
    subcommands.add_parser("reconcile")
    return parser.parse_args()


def main():
    arguments = parse_args()
    with open(arguments.config, encoding="utf-8") as handle:
        config = json.load(handle)
    if arguments.command == "daemon":
        asyncio.run(MonitorDaemon(config).run())
        return 0
    if arguments.command == "status":
        status = read_json(runtime_root() / "status.json")
        if status is None:
            print(
                json.dumps(
                    {
                        "schemaVersion": 1,
                        "available": False,
                        "lastError": "daemon status unavailable",
                    }
                )
            )
            return 3
        status["available"] = True
        print(json.dumps(status, sort_keys=True))
        return 0
    if arguments.command == "select" and arguments.profile not in config["profiles"]:
        print(f"unknown profile: {arguments.profile}", file=sys.stderr)
        return 2
    return send_control(arguments.command, getattr(arguments, "profile", None))


if __name__ == "__main__":
    raise SystemExit(main())
