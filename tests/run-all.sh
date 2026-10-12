#!/bin/sh
# Runs every host-side test program. Requires python3, ruby and clang++
# with ASan/UBSan (Xcode or Command Line Tools on macOS).
set -eu
cd "$(dirname "$0")/.."

run() {
	echo "::group::$*"
	"$@"
	echo "::endgroup::"
}

run python3 tests/association/peer-test.py
run python3 tests/association/bss-context-test.py
run python3 tests/lifecycle/test-queue.py
run python3 tests/lifecycle/test-detach.py
run python3 tests/lifecycle/test-basics.py
run sh tests/scan/run.sh
run python3 tests/rx-input/test-input.py
run python3 tests/tx-free/test-free.py
run python3 tests/tx-free/test-unwind.py
run python3 tests/tx-free/test-node.py
run python3 tests/tx-output/test-output-config.py

echo "All host tests passed."
