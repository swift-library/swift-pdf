# SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
# Copyright (c) 2026 Xudong Xu

import importlib.machinery
import importlib.util
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch


loader = importlib.machinery.SourceFileLoader(
    "platform_preparation", str(Path(__file__).resolve().parents[2] / "Scripts/prepare-ci-platforms")
)
spec = importlib.util.spec_from_loader(loader.name, loader)
module = importlib.util.module_from_spec(spec)
loader.exec_module(module)


class PlatformTests(unittest.TestCase):
    def setUp(self):
        self.runtime = {
            "identifier": "com.apple.CoreSimulator.SimRuntime.xrOS-26-0",
            "version": "26.0", "buildversion": "fixture-build", "isAvailable": True,
            "supportedDeviceTypes": [{
                "identifier": "com.apple.CoreSimulator.SimDeviceType.Apple-Vision-Pro",
                "productFamily": "Apple Vision", "name": "Vision device",
            }],
        }
        self.device = {
            "name": "Vision device", "udid": "vision-device", "isAvailable": True,
            "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.Apple-Vision-Pro",
        }
        self.runtimes = [self.runtime]
        self.devices = {self.runtime["identifier"]: [self.device]}
        self.created = []
        capture = patch.object(module, "capture", side_effect=self.capture)
        capture.start()
        self.addCleanup(capture.stop)

    def capture(self, *command):
        if command == ("xcode-select", "-p"):
            return "/Applications/SelectedXcode.app/Contents/Developer"
        if command[:2] == ("xcrun", "--sdk"):
            self.assertIn(command[2], ("xrsimulator", "iphonesimulator"))
            return "26.0"
        if command[:4] == ("xcrun", "simctl", "list", "runtimes"):
            return json.dumps({"runtimes": self.runtimes})
        if command[:4] == ("xcrun", "simctl", "list", "devices"):
            return json.dumps({"devices": self.devices})
        if command[:3] == ("xcrun", "simctl", "create"):
            self.created.append(command)
            return "created-device"
        self.fail("Unexpected command: " + repr(command))

    def test_vision_runtime_uses_xros_identity_and_concrete_destination(self):
        with patch.object(module.subprocess, "run") as download:
            result = module.prepare("visionOS")
        download.assert_not_called()
        self.assertEqual(result["sdk"], "xrsimulator")
        self.assertEqual(result["destination"], "platform=visionOS Simulator,id=vision-device")
        self.assertEqual(result["runtime"]["identifier"], self.runtime["identifier"])

    def test_missing_vision_runtime_downloads_the_visionos_platform(self):
        self.runtimes = []

        def install(command, **arguments):
            self.assertEqual(command[command.index("-downloadPlatform") + 1], "visionOS")
            self.assertEqual(command[command.index("-buildVersion") + 1], "26.0")
            self.assertTrue(arguments["check"])
            self.runtimes = [self.runtime]

        with patch.object(module.subprocess, "run", side_effect=install) as download:
            result = module.prepare("visionOS")
        download.assert_called_once()
        self.assertEqual(result["device"]["udid"], "vision-device")

    def test_runtime_must_match_platform_sdk_and_availability(self):
        for change in [
            {"identifier": "com.apple.CoreSimulator.SimRuntime.iOS-26-0"},
            {"version": "27.0"},
            {"isAvailable": False},
        ]:
            with self.subTest(change=change):
                self.runtimes = [dict(self.runtime, **change)]
                with patch.object(module.subprocess, "run") as download:
                    with self.assertRaises(RuntimeError):
                        module.prepare("visionOS", download=False)
                download.assert_not_called()

    def test_missing_device_is_created_for_the_matched_runtime(self):
        self.devices = {}
        result = module.prepare("visionOS", download=False)
        self.assertEqual(result["device"]["udid"], "created-device")
        self.assertEqual(self.created[0][-2:], (
            self.runtime["supportedDeviceTypes"][0]["identifier"], self.runtime["identifier"],
        ))

    def test_device_selection_ignores_unavailable_and_other_runtime_devices(self):
        self.devices[self.runtime["identifier"]].insert(0, dict(
            self.device, name="Unavailable device", udid="unavailable", isAvailable=False,
        ))
        self.devices["com.apple.CoreSimulator.SimRuntime.xrOS-27-0"] = [dict(
            self.device, name="Other runtime device", udid="other-runtime",
        )]
        result = module.prepare("visionOS", download=False)
        self.assertEqual(result["device"]["udid"], "vision-device")

    def test_default_device_is_preferred_to_a_custom_named_device(self):
        self.devices[self.runtime["identifier"]].insert(0, dict(
            self.device, name="A custom device", udid="custom-device",
        ))
        result = module.prepare("visionOS", download=False)
        self.assertEqual(result["device"]["udid"], "vision-device")

    def test_ios_prepares_an_iphone_on_the_matching_runtime(self):
        self.runtime.update({
            "identifier": "com.apple.CoreSimulator.SimRuntime.iOS-26-0",
            "supportedDeviceTypes": [{
                "identifier": "com.apple.CoreSimulator.SimDeviceType.iPhone",
                "productFamily": "iPhone",
            }],
        })
        self.device.update({"deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone"})
        self.devices = {self.runtime["identifier"]: [self.device]}
        result = module.prepare("iOS", download=False)
        self.assertEqual(result["sdk"], "iphonesimulator")
        self.assertEqual(result["destination"], "platform=iOS Simulator,id=vision-device")

    def test_boot_readiness_is_recorded_only_after_success(self):
        output = Path(__file__).resolve().parents[2] / ".build/platform-tests"
        output.mkdir(parents=True, exist_ok=True)
        with tempfile.TemporaryDirectory(dir=output) as directory:
            evidence = module.prepare("visionOS", download=False)

            def ready(command, **arguments):
                self.assertNotIn("boot", evidence)
                self.assertEqual(command, ["xcrun", "simctl", "bootstatus", "vision-device", "-b"])
                self.assertTrue(arguments["check"])
                self.assertEqual(arguments["timeout"], 300)
                arguments["stdout"].write("Finished booting\n")

            log = Path(directory) / "boot.log"
            with patch.object(module.subprocess, "run", side_effect=ready):
                module.wait_for_boot(evidence, log)
            self.assertEqual(evidence["boot"]["status"], "complete")
            self.assertIn("Finished booting", log.read_text())

    def test_failed_or_stalled_boot_cannot_produce_ready_evidence(self):
        output = Path(__file__).resolve().parents[2] / ".build/platform-tests"
        output.mkdir(parents=True, exist_ok=True)
        for error in [subprocess.CalledProcessError(1, ["simctl"]),
                      subprocess.TimeoutExpired(["simctl"], 300)]:
            with self.subTest(error=type(error).__name__), tempfile.TemporaryDirectory(dir=output) as directory:
                evidence = module.prepare("visionOS", download=False)
                with patch.dict(os.environ, {"GITHUB_ACTIONS": "", "RUNNER_ENVIRONMENT": ""}), \
                        patch.object(module.subprocess, "run", side_effect=error):
                    with self.assertRaises(type(error)):
                        module.wait_for_boot(evidence, Path(directory) / "boot.log")
                self.assertNotIn("boot", evidence)

    def test_hosted_recovery_preserves_device_and_toolchain_and_handles_absent_service(self):
        output = Path(__file__).resolve().parents[2] / ".build/platform-tests"
        output.mkdir(parents=True, exist_ok=True)
        environment = {
            "GITHUB_ACTIONS": "true", "RUNNER_ENVIRONMENT": "github-hosted",
            "DEVELOPER_DIR": "/Applications/SelectedXcode.app/Contents/Developer",
        }
        boot = ["xcrun", "simctl", "bootstatus", "vision-device", "-b"]
        for service_status in (0, 1):
            with self.subTest(service_status=service_status), tempfile.TemporaryDirectory(dir=output) as directory:
                evidence = module.prepare("visionOS", download=False)
                calls = []

                def run(command, **arguments):
                    calls.append(command)
                    self.assertNotIn("boot", evidence)
                    if len(calls) == 1:
                        raise subprocess.TimeoutExpired(command, 300)
                    status = service_status if command[0] == "pkill" else 0
                    return subprocess.CompletedProcess(command, status)

                with patch.dict(os.environ, environment), patch.object(module.subprocess, "run", side_effect=run):
                    module.wait_for_boot(evidence, Path(directory) / "boot.log")
                self.assertEqual(calls, [
                    boot,
                    ["xcrun", "simctl", "shutdown", "vision-device"],
                    ["sudo", "xcode-select", "-s", environment["DEVELOPER_DIR"]],
                    ["sudo", "xcodebuild", "-runFirstLaunch"],
                    ["pkill", "-TERM", "-x", "com.apple.CoreSimulator.CoreSimulatorService"],
                    ["xcrun", "simctl", "list", "devices", "--json"],
                    boot,
                ])
                self.assertEqual(evidence["boot"]["attempts"], 2)
                self.assertEqual(evidence["boot"]["status"], "complete")

    def test_service_recovery_never_runs_on_local_or_self_hosted_machines(self):
        output = Path(__file__).resolve().parents[2] / ".build/platform-tests"
        output.mkdir(parents=True, exist_ok=True)
        for actions, runner in [("", ""), ("true", "self-hosted"), ("true", ""), ("", "github-hosted")]:
            with self.subTest(actions=actions, runner=runner), tempfile.TemporaryDirectory(dir=output) as directory:
                evidence = module.prepare("visionOS", download=False)
                error = subprocess.TimeoutExpired(["simctl"], 300)
                with patch.dict(os.environ, {"GITHUB_ACTIONS": actions, "RUNNER_ENVIRONMENT": runner}), \
                        patch.object(module.subprocess, "run", side_effect=error) as run:
                    with self.assertRaises(subprocess.TimeoutExpired):
                        module.wait_for_boot(evidence, Path(directory) / "boot.log")
                self.assertEqual(run.call_count, 1)
                self.assertNotIn("boot", evidence)

    def test_recovery_failures_and_second_boot_failure_are_not_retried(self):
        output = Path(__file__).resolve().parents[2] / ".build/platform-tests"
        output.mkdir(parents=True, exist_ok=True)
        environment = {
            "GITHUB_ACTIONS": "true", "RUNNER_ENVIRONMENT": "github-hosted", "DEVELOPER_DIR": "",
        }
        for failing_call in (2, 4, 5, 7):
            with self.subTest(failing_call=failing_call), tempfile.TemporaryDirectory(dir=output) as directory:
                evidence = module.prepare("visionOS", download=False)
                calls = []

                def run(command, **arguments):
                    calls.append(command)
                    if len(calls) == 1:
                        raise subprocess.TimeoutExpired(command, 300)
                    status = 2 if len(calls) == failing_call else 0
                    result = subprocess.CompletedProcess(command, status)
                    if arguments.get("check"):
                        result.check_returncode()
                    return result

                with patch.dict(os.environ, environment), patch.object(module.subprocess, "run", side_effect=run):
                    with self.assertRaises(subprocess.CalledProcessError):
                        module.wait_for_boot(evidence, Path(directory) / "boot.log")
                self.assertEqual(len(calls), failing_call)
                self.assertNotIn("boot", evidence)


if __name__ == "__main__":
    unittest.main()
