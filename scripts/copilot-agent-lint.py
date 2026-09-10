#!/usr/bin/env python3

import argparse
import pathlib
import re
import sys

import yaml


EXPECTED_AGENTS = {
    "dotfiles-orchestrator": {
        "tools": {"agent"},
        "agents": {
            "context-scout",
            "nix-home-manager-worker",
            "rice-quickshell-worker",
            "validation-runner",
            "evaluator",
        },
    },
    "nix-home-manager-worker": {
        "tools": {"read", "edit", "search", "execute", "agent"},
        "agents": {"context-scout"},
    },
    "rice-quickshell-worker": {
        "tools": {"read", "edit", "search", "execute", "agent"},
        "agents": {"context-scout"},
    },
    "context-scout": {
        "tools": {"read", "search"},
        "agents": set(),
    },
    "validation-runner": {
        "tools": {"read", "search", "execute"},
        "agents": set(),
    },
    "evaluator": {
        "tools": {"read", "search"},
        "agents": set(),
    },
}

SHARED_AGENTS = {"context-scout", "validation-runner", "evaluator"}


def parse_agent(path):
    text = path.read_text()
    match = re.match(r"\A---\n(.*?)\n---(?:\n|\Z)", text, re.DOTALL)
    if match is None:
        raise ValueError("missing YAML frontmatter")

    data = yaml.safe_load(match.group(1))
    if not isinstance(data, dict):
        raise ValueError("frontmatter must be a mapping")
    return data


def validate_agents(agent_paths):
    errors = []
    agents = {}

    for path in agent_paths:
        try:
            data = parse_agent(path)
        except (OSError, UnicodeError, yaml.YAMLError, ValueError) as error:
            errors.append(f"{path}: {error}")
            continue

        name = data.get("name")
        if not isinstance(name, str) or not name:
            errors.append(f"{path}: name must be a non-empty string")
            continue
        if name in agents:
            errors.append(f"{path}: duplicate agent name {name!r}")
            continue

        expected_filename = f"{name}.agent.md"
        if path.name != expected_filename:
            errors.append(f"{path}: filename must be {expected_filename!r}")
        for field in ("description", "argument-hint"):
            if not isinstance(data.get(field), str) or not data[field].strip():
                errors.append(f"{path}: {field} must be a non-empty string")

        agents[name] = (path, data)

    missing = sorted(set(EXPECTED_AGENTS) - set(agents))
    unexpected = sorted(set(agents) - set(EXPECTED_AGENTS))
    if missing:
        errors.append(f"missing agents: {', '.join(missing)}")
    if unexpected:
        errors.append(f"unexpected agents: {', '.join(unexpected)}")

    for name, (path, data) in agents.items():
        if name not in EXPECTED_AGENTS:
            continue
        for field in ("tools", "agents"):
            values = data.get(field)
            if not isinstance(values, list) or not all(isinstance(value, str) for value in values):
                errors.append(f"{path}: {field} must be a list of strings")
                continue
            actual = set(values)
            expected = EXPECTED_AGENTS[name][field]
            if actual != expected:
                errors.append(
                    f"{path}: {field} must be {sorted(expected)!r}, got {sorted(actual)!r}"
                )
            if field == "agents":
                unresolved = sorted(actual - set(agents))
                if unresolved:
                    errors.append(f"{path}: unresolved agents: {', '.join(unresolved)}")

    return agents, errors


def validate_installation(agents, install_file):
    errors = []
    install_text = install_file.read_text()
    for name in sorted(SHARED_AGENTS):
        if name not in agents:
            continue
        filename = f"{name}.agent.md"
        mapping = f'"Code/User/prompts/{filename}".source = ./vscode/prompts/{filename};'
        if mapping not in install_text:
            errors.append(f"{install_file}: missing source mapping for {filename}")
    return errors


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--workspace-dir", type=pathlib.Path, required=True)
    parser.add_argument("--shared-dir", type=pathlib.Path, required=True)
    parser.add_argument("--install-file", type=pathlib.Path, required=True)
    args = parser.parse_args()

    agent_paths = sorted(args.workspace_dir.glob("*.agent.md"))
    agent_paths += sorted(args.shared_dir.glob("*.agent.md"))
    agents, errors = validate_agents(agent_paths)
    errors.extend(validate_installation(agents, args.install_file))

    if errors:
        for error in errors:
            print(f"copilot-agent-lint: {error}", file=sys.stderr)
        return 1

    print(f"copilot-agent-lint: validated {len(agents)} agent sources")
    return 0


if __name__ == "__main__":
    sys.exit(main())
