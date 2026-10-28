#!/usr/bin/env python3
"""Render .github/dependabot.yml for a repository from templates/dependabot.

usage: render-dependabot.py <kind> <output> [runner-directory ...]

kinds:
  service           npm + github-actions + docker (microservices, api-gateway, ws-service)
  service-nodocker  npm + github-actions (nativapp)
  monorepo          npm over "/" and "/packages/*" + github-actions (npm-packages)
  runner            npm + docker over every sub-package + github-actions
  actions           github-actions only (proto-registry, deploy, docs)
"""
import sys
from pathlib import Path

TEMPLATES = Path(__file__).resolve().parent.parent / "templates" / "dependabot"
DOCKER = '  - package-ecosystem: "docker"'
ACTIONS = '  - package-ecosystem: "github-actions"'


# Expo SDK pins the native stack (react, react-native, reanimated, screens, maps, svg...): those packages only move
# through an SDK upgrade (expo install --fix), so version updates are limited to patches.
EXPO_PINNED = [
    "@react-native/*",
    "expo",
    "expo-*",
    "@expo/*",
]


# Pinned exactly by the Expo SDK: even patches fail the 'expo install --check' step (datetimepicker 8.4.7,
# keyboard-controller 1.18.6, worklets 0.5.2) and react-native 0.81.6 broke 24 tests under SDK 54 (0.81.5).
EXPO_EXACT = [
    "react",
    "react-dom",
    "react-test-renderer",
    "@types/react",
    "react-native",
    "react-native-*",
    "@react-native-community/*",
    "@react-navigation/native-stack",
    "typescript-eslint",
    "@typescript-eslint/*",
]

# Proven regressions in nativapp: bottom-tabs 7.21 (render is not a function) and typescript-eslint 8.72
# (no-unsafe-enum-assignment on enums mapped across packages).
NATIVAPP_HOLD_MINOR = ["@react-navigation/bottom-tabs"]

# jest-expo pins jest and the Babel toolchain of the SDK: majors move with it.
EXPO_MAJOR_ONLY = ["jest", "jest-expo", "@types/jest", "@testing-library/react-native", "@babel/core"]


# npm-packages publishes wrappers around these libraries whose 0.x or minor releases changed their API:
# @opentelemetry/sdk-node 0.300 (metricReader became metricReaders), bullmq 5.81 (BaseWorker call at 4 arguments),
# sharp 0.35 (failOnError removed from SharpOptions). Migrate them in a dedicated PR with changesets.
MONOREPO_HOLD = [
    "@opentelemetry/sdk-node",
    "@opentelemetry/exporter-*",
    "@opentelemetry/auto-instrumentations-node",
    "bullmq",
    "sharp",
]


def monorepo_ignore(text: str) -> str:
    major_only = '      - dependency-name: "bullmq"\n        update-types: ["version-update:semver-major"]\n'
    text = text.replace(major_only, "")
    lines = ["      # Wrapped by published @volontariapp/* packages: see MONOREPO_HOLD in render-dependabot.py."]
    for name in MONOREPO_HOLD:
        lines.append(f'      - dependency-name: "{name}"')
        lines.append('        update-types: ["version-update:semver-major", "version-update:semver-minor"]')
    return text.replace("    groups:", "\n".join(lines) + "\n    groups:", 1)


def expo_ignore() -> str:
    lines = ["      # Pinned by the Expo SDK: bump through an SDK upgrade, not through Dependabot."]
    for name in EXPO_PINNED:
        lines.append(f'      - dependency-name: "{name}"')
        lines.append('        update-types: ["version-update:semver-major", "version-update:semver-minor"]')
    for name in EXPO_EXACT:
        lines.append(f'      - dependency-name: "{name}"')
    for name in NATIVAPP_HOLD_MINOR:
        lines.append(f'      - dependency-name: "{name}"')
        lines.append('        update-types: ["version-update:semver-major", "version-update:semver-minor"]')
    for name in EXPO_MAJOR_ONLY:
        lines.append(f'      - dependency-name: "{name}"')
        lines.append('        update-types: ["version-update:semver-major"]')
    return "\n".join(lines) + "\n"


def render(kind: str, directories: list[str]) -> str:
    if kind == "runner":
        text = (TEMPLATES / "runner.yml").read_text()
        listing = "\n".join(f'      - "/{d}"' for d in directories)
        text = text.replace('      - "/worker-example"', listing)
    else:
        text = (TEMPLATES / "service.yml").read_text()
        if kind in ("service-nodocker", "monorepo"):
            text = text[: text.index(DOCKER)].rstrip() + "\n"
        if kind == "service-nodocker":
            text = text.replace("    groups:", expo_ignore().rstrip("\n").join(["", "\n"]) + "    groups:", 1)
        if kind == "monorepo":
            text = monorepo_ignore(text)
            text = text.replace(
                '    directory: "/"\n    open-pull-requests-limit: 3',
                '    directories:\n      - "/"\n      - "/packages/*"\n    open-pull-requests-limit: 3',
                1,
            )
        if kind == "actions":
            text = "version: 2\nupdates:\n" + text[text.index(ACTIONS) : text.index(DOCKER)].rstrip() + "\n"
    header = (
        "# Generated from Volontariapp/ci-tools templates/dependabot by sync-dependabot.yml: do not edit here.\n"
        "# Dependabot PRs carry docker-e2e and docker-and-e2e (the latter is required by the CI).\n"
    )
    if kind == "runner":
        header += "# `directories` lists every sub-package of the repository.\n"
    return header + text[text.index("version: 2") :]


if __name__ == "__main__":
    if len(sys.argv) < 3 or sys.argv[1] not in ("service", "service-nodocker", "monorepo", "runner", "actions"):
        sys.exit(__doc__)
    Path(sys.argv[2]).write_text(render(sys.argv[1], sys.argv[3:]))
