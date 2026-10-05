# SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
# Copyright (c) 2026 Xudong Xu

import importlib.machinery
import importlib.util
import json
from pathlib import Path
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


if __name__ == "__main__":
    unittest.main()
