import asyncio
import copy
import importlib.util
import json
import os
import tempfile
import unittest
from unittest import mock

spec = importlib.util.spec_from_file_location(
    "monitor_control", os.environ["MONITOR_CONTROL_SOURCE"]
)
monitor_control = importlib.util.module_from_spec(spec)
spec.loader.exec_module(monitor_control)


def output(monitor, position, workspaces, transform=0, primary=False):
    return {
        "monitor": monitor,
        "position": position,
        "resolution": None,
        "scale": None,
        "transform": transform,
        "workspaces": workspaces,
        "primary": primary,
    }


def monitor_command(name, mode, position, scale=1.0, transform=0):
    return [
        "hyprctl",
        "keyword",
        "monitor",
        f"{name},{mode},{position},{scale},transform,{transform}",
    ]


CONFIG = {
    "monitors": {
        "laptop": {
            "desc": "LG Display",
            "name": "eDP-1",
            "serial": "",
            "resolution": "1920x1200@60",
            "scale": "1",
        },
        "work": {
            "desc": "HP Inc. HP 527pu",
            "name": "",
            "serial": "1H361409R2",
            "resolution": "2560x1440@60",
            "scale": "1",
        },
        "workRight": {
            "desc": "HP Inc. HP 527pu",
            "name": "",
            "serial": "1H361409TR",
            "resolution": "2560x1440@60",
            "scale": "1",
        },
        "familyHome": {
            "desc": "Samsung C34J79x",
            "name": "",
            "serial": "HTRM900265",
            "resolution": "3440x1440@60",
            "scale": "1",
        },
    },
    "profiles": {
        "home_office": {
            "autoDetect": False,
            "outputs": [
                output("workRight", "0x0", [2, 4, 5], transform=1),
                output("work", "1440x0", [1, 3], primary=True),
                output("laptop", "4000x0", [6, 7]),
            ],
        },
        "work": {
            "autoDetect": False,
            "outputs": [
                output("laptop", "0x0", [2, 4, 6]),
                output("work", "1920x0", [1, 5], primary=True),
                output("workRight", "4480x0", [3, 7]),
            ],
        },
        "family_home": {
            "autoDetect": True,
            "outputs": [
                output("laptop", "0x0", [3, 4, 5, 6]),
                output("familyHome", "1920x0", [1, 2], primary=True),
            ],
        },
        "laptop_only": {
            "autoDetect": True,
            "outputs": [
                output("laptop", "0x0", list(range(1, 11)), primary=True),
            ],
        },
    },
    "fallbackProfile": "laptop_only",
    "appRoutes": {
        "terminal": {"class": "^(Alacritty|alacritty|foot)$", "workspace": 2},
        "slack": {"class": "^(Slack)$", "workspace": 4},
        "discord": {"class": "^(discord)$", "workspace": 4},
        "spotify": {"class": "^(spotify)$", "workspace": 5},
    },
}


def monitor(
    name,
    serial="",
    width=2560,
    height=1440,
    x=99,
    y=99,
    transform=0,
    description="",
    refresh_rate=60.0,
):
    return {
        "name": name,
        "serial": serial,
        "description": description,
        "width": width,
        "height": height,
        "refreshRate": refresh_rate,
        "x": x,
        "y": y,
        "scale": 1.0,
        "transform": transform,
        "disabled": False,
    }


LAPTOP = monitor("eDP-1", width=1920, height=1200, description="LG Display")
LAPTOP_AT_ORIGIN = {**LAPTOP, "x": 0, "y": 0}
HP_LEFT = monitor("DP-9", "1H361409TR", description="HP Inc. HP 527pu")
HP_CENTER = monitor("DP-6", "1H361409R2", description="HP Inc. HP 527pu")
SAMSUNG = monitor("DP-3", "HTRM900265", width=3440, description="Samsung C34J79x")


class MonitorControlTests(unittest.TestCase):
    def test_exact_serial_disambiguates_duplicate_descriptions(self):
        found, unknown = monitor_control.inventory(CONFIG, [LAPTOP, HP_LEFT, HP_CENTER])
        self.assertEqual(found["work"]["name"], "DP-6")
        self.assertEqual(found["workRight"]["name"], "DP-9")
        self.assertEqual(unknown, [])

    def test_duplicate_exact_identity_is_rejected(self):
        duplicate = copy.deepcopy(HP_CENTER)
        duplicate["name"] = "DP-7"
        with self.assertRaisesRegex(RuntimeError, "duplicate monitor identity"):
            monitor_control.inventory(CONFIG, [LAPTOP, HP_CENTER, duplicate])

    def test_hp_topology_is_ambiguous_without_explicit_selection(self):
        plan = monitor_control.build_plan(
            CONFIG, [LAPTOP, HP_LEFT, HP_CENTER], {"mode": "auto"}
        )
        self.assertEqual(plan["activeProfile"], "ambiguous")
        self.assertEqual(plan["commands"], [])

    def test_explicit_profiles_generate_distinct_geometry(self):
        home = monitor_control.build_plan(
            CONFIG,
            [LAPTOP, HP_LEFT, HP_CENTER],
            {"mode": "explicit", "profile": "home_office"},
        )
        work = monitor_control.build_plan(
            CONFIG,
            [LAPTOP, HP_LEFT, HP_CENTER],
            {"mode": "explicit", "profile": "work"},
        )
        self.assertIn(
            monitor_command("DP-9", "2560x1440@60", "0x0", transform=1),
            home["commands"],
        )
        self.assertIn(
            monitor_command("DP-6", "2560x1440@60", "1440x0"), home["commands"]
        )
        self.assertIn(
            monitor_command("eDP-1", "1920x1200@60", "4000x0"), home["commands"]
        )
        self.assertIn(
            monitor_command("DP-6", "2560x1440@60", "1920x0"), work["commands"]
        )
        self.assertIn(
            monitor_command("DP-9", "2560x1440@60", "4480x0"), work["commands"]
        )

    def test_every_laptop_profile_uses_native_mode_scale_and_transform(self):
        cases = [
            ("home_office", [LAPTOP, HP_LEFT, HP_CENTER], "4000x0"),
            ("work", [LAPTOP, HP_LEFT, HP_CENTER], "0x0"),
            ("family_home", [LAPTOP, SAMSUNG], "0x0"),
            ("laptop_only", [LAPTOP], "0x0"),
        ]
        for profile, monitors, position in cases:
            with self.subTest(profile=profile):
                plan = monitor_control.build_plan(
                    CONFIG,
                    monitors,
                    {"mode": "explicit", "profile": profile},
                )
                laptop = next(
                    output for output in plan["outputs"] if output["name"] == "eDP-1"
                )
                self.assertEqual(laptop["mode"], "1920x1200@60")
                self.assertEqual(laptop["scale"], "1")
                self.assertEqual(laptop["transform"], 0)
                self.assertIn(
                    monitor_command("eDP-1", "1920x1200@60", position),
                    plan["commands"],
                )

    def test_laptop_fallback_assigns_all_workspaces(self):
        plan = monitor_control.build_plan(CONFIG, [LAPTOP], {"mode": "auto"})
        self.assertEqual(plan["activeProfile"], "laptop_only")
        self.assertIn(
            monitor_command("eDP-1", "1920x1200@60", "0x0"),
            plan["commands"],
        )
        rules = [
            command
            for command in plan["commands"]
            if command[1:3] == ["keyword", "workspace"]
        ]
        self.assertEqual(len(rules), 10)
        self.assertEqual(
            rules[0],
            ["hyprctl", "keyword", "workspace", "1,monitor:eDP-1,default:true"],
        )

    def test_wrong_refresh_rate_requires_monitor_update(self):
        laptop = monitor(
            "eDP-1",
            width=1920,
            height=1200,
            x=0,
            y=0,
            description="LG Display",
            refresh_rate=120.0,
        )
        plan = monitor_control.build_plan(CONFIG, [laptop], {"mode": "auto"})
        self.assertIn(
            monitor_command("eDP-1", "1920x1200@60", "0x0"),
            plan["commands"],
        )

    def test_auto_profile_requires_all_declared_outputs(self):
        plan = monitor_control.build_plan(CONFIG, [SAMSUNG], {"mode": "auto"})
        self.assertEqual(plan["activeProfile"], "ambiguous")
        self.assertEqual(plan["commands"], [])

    def test_family_profile_is_uniquely_auto_detected(self):
        plan = monitor_control.build_plan(CONFIG, [LAPTOP, SAMSUNG], {"mode": "auto"})
        self.assertEqual(plan["activeProfile"], "family_home")

    def test_partial_explicit_profile_keeps_selection_and_covers_workspaces(self):
        plan = monitor_control.build_plan(
            CONFIG, [LAPTOP, HP_CENTER], {"mode": "explicit", "profile": "work"}
        )
        self.assertEqual(plan["selectedProfile"], "work")
        self.assertEqual(plan["activeProfile"], "work:partial")
        self.assertIn(
            monitor_command("eDP-1", "1920x1200@60", "0x0"),
            plan["commands"],
        )
        assigned = {
            workspace
            for output_spec in plan["outputs"]
            for workspace in output_spec["workspaces"]
        }
        self.assertEqual(assigned, set(range(1, 11)))

    def test_workspace_and_app_route_commands_are_native_argv(self):
        plan = monitor_control.build_plan(
            CONFIG, [LAPTOP], {"mode": "auto"}, include_routes=True
        )
        self.assertIn(
            ["hyprctl", "keyword", "workspace", "5,monitor:eDP-1,default:false"],
            plan["commands"],
        )
        self.assertIn(
            [
                "hyprctl",
                "keyword",
                "windowrule",
                "workspace 4 silent,match:class ^(Slack)$",
            ],
            plan["commands"],
        )
        self.assertIn(
            monitor_command("eDP-1", "1920x1200@60", "0x0"),
            plan["commands"],
        )
        self.assertTrue(all(command[1] == "keyword" for command in plan["commands"]))

    def test_native_plan_disables_unselected_monitor(self):
        plan = monitor_control.build_plan(
            CONFIG,
            [LAPTOP, HP_LEFT, HP_CENTER, SAMSUNG],
            {"mode": "explicit", "profile": "work"},
            include_routes=True,
        )
        self.assertIn(
            ["hyprctl", "keyword", "monitor", "DP-3,disable"],
            plan["commands"],
        )

    def test_disabled_connected_monitor_can_be_enabled_by_next_profile(self):
        laptop_plan = monitor_control.build_plan(
            CONFIG,
            [LAPTOP, HP_LEFT, HP_CENTER],
            {"mode": "explicit", "profile": "laptop_only"},
        )
        self.assertIn(
            ["hyprctl", "keyword", "monitor", "DP-6,disable"],
            laptop_plan["commands"],
        )

        disabled_center = {
            "name": "DP-6",
            "serial": "1H361409R2",
            "description": "HP Inc. HP 527pu",
            "disabled": True,
            "width": None,
            "height": None,
            "refreshRate": None,
            "x": None,
            "y": None,
            "scale": None,
            "transform": None,
        }
        work_plan = monitor_control.build_plan(
            CONFIG,
            [LAPTOP, HP_LEFT, disabled_center],
            {"mode": "explicit", "profile": "work"},
        )
        self.assertEqual(work_plan["activeProfile"], "work")
        self.assertIn(
            monitor_command("DP-6", "2560x1440@60", "1920x0"),
            work_plan["commands"],
        )

    def test_converged_plan_accepts_intentionally_disabled_external_output(self):
        disabled_center = {**HP_CENTER, "disabled": True}
        plan = monitor_control.build_plan(
            CONFIG,
            [LAPTOP_AT_ORIGIN, disabled_center],
            {"mode": "explicit", "profile": "laptop_only"},
        )
        monitor_control.verify_plan_converged(
            CONFIG, plan, [LAPTOP_AT_ORIGIN, disabled_center]
        )

    def test_native_plan_rejects_untrusted_output_names(self):
        unsafe = copy.deepcopy(HP_CENTER)
        unsafe["name"] = "DP-6,$(touch /tmp/monitor-control-injection)"
        with self.assertRaisesRegex(RuntimeError, "invalid Hyprland output name"):
            monitor_control.build_plan(
                CONFIG,
                [LAPTOP, HP_LEFT, unsafe],
                {"mode": "explicit", "profile": "work"},
            )

    def test_event_parser_is_exact(self):
        self.assertTrue(monitor_control.is_monitor_event("monitoradded>>DP-4"))
        self.assertTrue(monitor_control.is_monitor_event("monitorremoved>>DP-4"))
        self.assertTrue(monitor_control.is_monitor_event("monitoraddedv2>>1,DP-4,desc"))
        self.assertFalse(monitor_control.is_monitor_event("workspace>>2"))
        self.assertFalse(monitor_control.is_monitor_event("monitoraddedlater>>DP-4"))


class MonitorControlAsyncTests(unittest.IsolatedAsyncioTestCase):
    async def test_failed_scheduled_reconcile_retries_until_geometry_converges(self):
        scheduled = []

        class Timer:
            def cancel(self):
                pass

        def schedule_later(delay, callback):
            scheduled.append((delay, callback))
            return Timer()

        daemon = monitor_control.MonitorDaemon(CONFIG, schedule_later=schedule_later)
        stale_laptop = copy.deepcopy(LAPTOP)
        stale_laptop["disabled"] = True
        hypr_json = mock.AsyncMock(
            side_effect=[
                [stale_laptop],
                [stale_laptop],
                [stale_laptop],
                [LAPTOP_AT_ORIGIN],
                [{"id": 1}],
                [],
            ]
        )

        with tempfile.TemporaryDirectory() as directory, mock.patch.dict(
            os.environ,
            {"XDG_RUNTIME_DIR": directory, "XDG_STATE_HOME": directory},
        ), mock.patch.object(
            monitor_control, "hypr_json", new=hypr_json
        ), mock.patch.object(
            monitor_control, "run_command", new=mock.AsyncMock(return_value="")
        ):
            daemon.schedule_reconcile(0)
            _, start_initial = scheduled.pop(0)
            start_initial()
            await daemon.reconcile_task

            self.assertIn("did not converge for eDP-1", daemon.status["lastError"])
            self.assertEqual(scheduled[0][0], monitor_control.RECONCILE_RETRY_DELAY)

            _, start_retry = scheduled.pop(0)
            start_retry()
            await daemon.reconcile_task

        self.assertEqual(daemon.status["activeProfile"], "laptop_only")
        self.assertIsNone(daemon.status["lastError"])
        self.assertEqual(daemon.reconcile_retries, 0)

    async def test_run_command_passes_dangerous_text_as_one_argv_element(self):
        process = mock.Mock(returncode=0)
        process.communicate = mock.AsyncMock(return_value=(b"", b""))
        dangerous = "match:class $(touch /tmp/bad); echo bad, workspace 2 silent"
        argv = monitor_control.window_rule_command(dangerous, "2")
        with mock.patch(
            "asyncio.create_subprocess_exec",
            new=mock.AsyncMock(return_value=process),
        ) as create_process:
            await monitor_control.run_command(argv)
        create_process.assert_awaited_once_with(
            *argv,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )

    async def test_route_install_failure_does_not_abort_reconcile(self):
        daemon = monitor_control.MonitorDaemon(CONFIG)
        commands = []

        async def run_command(argv, check=True):
            commands.append(argv)
            if len(argv) > 2 and argv[1:3] == ["keyword", "windowrule"]:
                raise RuntimeError("unsupported rule grammar")
            return ""

        hypr_json = mock.AsyncMock(
            side_effect=[[LAPTOP], [LAPTOP_AT_ORIGIN], [{"id": 1}], []]
        )
        with tempfile.TemporaryDirectory() as directory, mock.patch.dict(
            os.environ,
            {"XDG_RUNTIME_DIR": directory, "XDG_STATE_HOME": directory},
        ), mock.patch.object(
            monitor_control,
            "hypr_json",
            new=hypr_json,
        ), mock.patch.object(
            monitor_control, "run_command", side_effect=run_command
        ):
            self.assertTrue(await daemon.reconcile())

        self.assertEqual(hypr_json.await_args_list[0], mock.call("monitors", "all"))
        self.assertIn(
            [
                "hyprctl",
                "dispatch",
                'hl.dsp.workspace.move({workspace = "1", monitor = "eDP-1"})',
            ],
            commands,
        )
        self.assertIn(["wallpaper-restore"], commands)
        self.assertTrue(daemon.routes_applied)
        self.assertIsNone(daemon.status["lastError"])
        self.assertTrue(daemon.status["warnings"])

    async def test_stale_post_apply_snapshot_fails_reconciliation(self):
        daemon = monitor_control.MonitorDaemon(CONFIG)
        stale_laptop = copy.deepcopy(LAPTOP)
        stale_laptop["disabled"] = True
        stale_laptop["scale"] = 1.5
        commands = []

        async def run_command(argv, check=True):
            commands.append(argv)
            return ""

        hypr_json = mock.AsyncMock(side_effect=[[stale_laptop], [stale_laptop]])
        with tempfile.TemporaryDirectory() as directory, mock.patch.dict(
            os.environ,
            {"XDG_RUNTIME_DIR": directory, "XDG_STATE_HOME": directory},
        ), mock.patch.object(
            monitor_control, "hypr_json", new=hypr_json
        ), mock.patch.object(
            monitor_control, "run_command", side_effect=run_command
        ):
            self.assertFalse(await daemon.reconcile())

        self.assertIn(monitor_command("eDP-1", "1920x1200@60", "0x0"), commands)
        self.assertEqual(
            hypr_json.await_args_list,
            [mock.call("monitors", "all"), mock.call("monitors", "all")],
        )
        self.assertIsNone(daemon.status["activeProfile"])
        self.assertIn("did not converge for eDP-1", daemon.status["lastError"])
        self.assertIn("observed disabled", daemon.status["lastError"])
        self.assertFalse(daemon.routes_applied)

    async def test_failed_dispatchers_do_not_block_keyword_geometry_or_status(self):
        daemon = monitor_control.MonitorDaemon(CONFIG)
        laptop = copy.deepcopy(LAPTOP)
        laptop["scale"] = 1.5
        commands = []

        async def run_command(argv, check=True):
            commands.append(argv)
            if len(argv) > 1 and argv[1] == "dispatch":
                raise RuntimeError("dispatcher rejected")
            return ""

        hypr_json = mock.AsyncMock(
            side_effect=[
                [laptop],
                [LAPTOP_AT_ORIGIN],
                [{"id": 1}],
                [
                    {
                        "class": "Slack",
                        "address": "0x1234",
                        "workspace": {"id": 1},
                    }
                ],
            ]
        )
        with tempfile.TemporaryDirectory() as directory, mock.patch.dict(
            os.environ,
            {"XDG_RUNTIME_DIR": directory, "XDG_STATE_HOME": directory},
        ), mock.patch.object(
            monitor_control, "hypr_json", new=hypr_json
        ), mock.patch.object(
            monitor_control, "run_command", side_effect=run_command
        ):
            self.assertTrue(await daemon.reconcile())

        keyword_geometry = monitor_command("eDP-1", "1920x1200@60", "0x0")
        self.assertIn(keyword_geometry, commands)
        self.assertLess(
            commands.index(keyword_geometry),
            next(
                index
                for index, command in enumerate(commands)
                if command[1] == "dispatch"
            ),
        )
        self.assertEqual(daemon.status["activeProfile"], "laptop_only")
        self.assertIsNone(daemon.status["lastError"])
        self.assertGreaterEqual(len(daemon.status["warnings"]), 4)

    async def test_debounce_does_not_cancel_active_reconcile(self):
        daemon = monitor_control.MonitorDaemon(CONFIG)
        started = asyncio.Event()
        release = asyncio.Event()
        calls = 0

        async def reconcile():
            nonlocal calls
            calls += 1
            if calls == 1:
                started.set()
                await release.wait()
            return True

        daemon.reconcile = reconcile
        daemon.schedule_reconcile(0)
        await started.wait()
        first_task = daemon.reconcile_task
        daemon.schedule_reconcile(0)
        await asyncio.sleep(0)
        self.assertFalse(first_task.cancelled())
        release.set()
        await first_task
        await asyncio.sleep(0)
        await daemon.reconcile_task
        self.assertEqual(calls, 2)

    async def test_control_selection_and_reconcile_are_serial(self):
        daemon = monitor_control.MonitorDaemon(CONFIG)
        first_started = asyncio.Event()
        release_first = asyncio.Event()
        reconciled = []

        async def reconcile():
            reconciled.append(copy.deepcopy(daemon.selection))
            if len(reconciled) == 1:
                first_started.set()
                await release_first.wait()
            return True

        async def request(value):
            reader = asyncio.StreamReader()
            reader.feed_data((json.dumps(value) + "\n").encode())
            reader.feed_eof()
            writer = mock.AsyncMock()
            writer.write = mock.Mock()
            writer.close = mock.Mock()
            await daemon.handle_control(reader, writer)

        daemon.reconcile = reconcile
        with tempfile.TemporaryDirectory() as directory, mock.patch.dict(
            os.environ, {"XDG_STATE_HOME": directory}
        ):
            first = asyncio.create_task(
                request({"command": "select", "profile": "work"})
            )
            await first_started.wait()
            second = asyncio.create_task(request({"command": "auto"}))
            await asyncio.sleep(0)
            self.assertEqual(reconciled, [{"mode": "explicit", "profile": "work"}])
            release_first.set()
            await asyncio.gather(first, second)

        self.assertEqual(
            reconciled,
            [
                {"mode": "explicit", "profile": "work"},
                {"mode": "auto"},
            ],
        )


if __name__ == "__main__":
    unittest.main()
