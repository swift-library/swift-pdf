# SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
# Copyright (c) 2026 Xudong Xu

import importlib.util
import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch


root = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("ios_runner", root / "Scripts/run-ios-tests.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class IOSRunnerTests(unittest.TestCase):
    def setUp(self):
        output = root / ".build/ios-runner-tests"
        output.mkdir(parents=True, exist_ok=True)
        temporary = tempfile.TemporaryDirectory(dir=output)
        self.addCleanup(temporary.cleanup)
        self.directory = Path(temporary.name)
        self.log = self.directory / "tests.log"
        self.bundle = self.directory / "tests.xcresult"

    def test_child_failure_and_both_output_streams_are_preserved(self):
        result = module.execute(
            [sys.executable, "-c",
             "import sys; print('output'); print('diagnostic', file=sys.stderr); sys.exit(7)"],
            self.log, self.bundle,
        )
        self.assertEqual(result, 7)
        self.assertIn("output", self.log.read_text())
        self.assertIn("diagnostic", self.log.read_text())

    def test_sample_paths_preserve_source_frames_without_home_identities(self):
        foreign_home = Path("/").joinpath("Users", "compiler-builder")
        linux_home = Path("/").joinpath("home", "compiler-builder")
        source = "\n".join([
            f"frame ({foreign_home}/Sources/Executor.cpp:42)",
            f"frame ({linux_home}/Sources/Task.cpp:12)",
            str(Path.cwd() / "Tests/Test.swift"),
            str(Path.home() / "Library/Test.log"),
            "/private/test-temporary/session.log",
            "/usr/lib/libSystem.B.dylib",
        ])
        with patch.dict(os.environ, {"TMPDIR": "/private/test-temporary/"}):
            result = module.normalize_sample(source)
        self.assertEqual(result.splitlines(), [
            "frame (<home>/Sources/Executor.cpp:42)",
            "frame (<home>/Sources/Task.cpp:12)",
            "<package>/Tests/Test.swift",
            "<home>/Library/Test.log",
            "<temporary>/session.log",
            "/usr/lib/libSystem.B.dylib",
        ])

    def stalled_command(self):
        return [sys.executable, "-c",
                "import os,time; print(os.getpid(), flush=True); time.sleep(30)"]

    def assert_child_stopped(self):
        pid = int(self.log.read_text().splitlines()[0])
        with self.assertRaises(ProcessLookupError):
            os.kill(pid, 0)

    def test_timeout_captures_diagnostics_and_stops_the_owned_process(self):
        captures = []
        result = module.execute(
            self.stalled_command(), self.log, self.bundle, timeout=2,
            capture=lambda bundle, directory: captures.append((bundle, directory)),
        )
        self.assertEqual(result, 124)
        self.assertEqual(captures, [(self.bundle, self.directory)])
        self.assert_child_stopped()

    def test_failed_diagnostic_capture_still_stops_the_process(self):
        def unavailable(bundle, directory):
            raise OSError("sample unavailable")

        result = module.execute(
            self.stalled_command(), self.log, self.bundle, timeout=2, capture=unavailable,
        )
        self.assertEqual(result, 124)
        self.assertIn("sample unavailable", self.log.read_text())
        self.assert_child_stopped()

    def test_interrupted_diagnostics_still_stop_the_process(self):
        def interrupted(bundle, directory):
            raise KeyboardInterrupt

        with self.assertRaises(KeyboardInterrupt):
            module.execute(
                self.stalled_command(), self.log, self.bundle, timeout=2, capture=interrupted,
            )
        self.assert_child_stopped()


if __name__ == "__main__":
    unittest.main()
