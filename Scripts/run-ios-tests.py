#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0 WITH Swift-exception
# Copyright (c) 2026 Xudong Xu

"""Run simulator tests with a bounded lifetime and stalled-host diagnostics."""

import argparse
import os
from pathlib import Path
import re
import signal
import subprocess
import sys


def normalize_sample(text):
    roots = [(str(Path.cwd()), "<package>"), (str(Path.home()), "<home>")]
    for name in ("TMPDIR", "RUNNER_TEMP"):
        if os.environ.get(name):
            roots.append((os.environ[name].rstrip("/"), "<temporary>"))
    for source, replacement in sorted(roots, key=lambda pair: len(pair[0]), reverse=True):
        if len(source) > 1:
            text = text.replace(source, replacement)
    # Symbolicated frames can contain the toolchain builder's home directory.
    return re.sub(r"/(?:Users|home)/[^/\s]+/", "<home>/", text)


def capture_stall(bundle, directory):
    sessions = list(bundle.rglob("Session-*.log"))
    if not sessions:
        raise RuntimeError("The result bundle has no test-host session log")
    session = max(sessions, key=lambda path: path.stat().st_mtime_ns)
    matches = re.findall(r"\bxctest\[(\d+):", session.read_text(errors="replace"))
    if not matches:
        raise RuntimeError("The session log has no test-host process identifier")
    pid = int(matches[-1])
    command = subprocess.run(
        ["ps", "-p", str(pid), "-o", "comm="], capture_output=True, text=True, check=True
    ).stdout.strip()
    if pid <= 1 or Path(command).name != "xctest":
        raise RuntimeError("The recorded test host is no longer available")
    # Sample only the test host identified by this run's fresh result bundle.
    diagnostics = directory / "ios-stall-diagnostics.log"
    sample = directory / "ios-stall-sample.log"
    try:
        with diagnostics.open("w") as output:
            subprocess.run(
                ["sample", str(pid), "5", "-file", str(sample)],
                stdout=output, stderr=subprocess.STDOUT, timeout=20, check=True,
            )
    finally:
        for path in (sample, diagnostics):
            if path.is_file():
                path.write_text(normalize_sample(path.read_text()))


def terminate(process):
    if process.poll() is not None:
        return
    os.killpg(process.pid, signal.SIGTERM)
    try:
        process.wait(timeout=10)
    except subprocess.TimeoutExpired:
        os.killpg(process.pid, signal.SIGKILL)
        process.wait()


def execute(command, log, bundle, timeout=600, capture=capture_stall):
    with log.open("w") as output:
        process = subprocess.Popen(
            command, stdin=subprocess.DEVNULL, stdout=output,
            stderr=subprocess.STDOUT, start_new_session=True,
        )
        try:
            try:
                return process.wait(timeout=timeout)
            except subprocess.TimeoutExpired:
                output.write(f"\nSimulator tests exceeded {timeout} seconds.\n")
                output.flush()
                try:
                    capture(bundle, log.parent)
                except Exception as error:
                    output.write("Could not capture the stalled test host: " + str(error) + "\n")
                return 124
        finally:
            terminate(process)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("destination")
    parser.add_argument("result_bundle", type=Path)
    args = parser.parse_args()
    os.chdir(Path(__file__).resolve().parent.parent)
    signal.signal(signal.SIGTERM, lambda signum, frame: sys.exit(128 + signum))
    result = execute(
        ["xcodebuild", "test", "-scheme", "swift-pdf", "-destination", args.destination,
         "-derivedDataPath", ".build/xcode/ios", "-resultBundlePath", str(args.result_bundle)],
        Path(".build/release-validation/ios-tests.log"), args.result_bundle,
    )
    return result if result >= 0 else 128 - result


if __name__ == "__main__":
    sys.exit(main())
