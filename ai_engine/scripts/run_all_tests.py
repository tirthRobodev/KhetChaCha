"""Master test execution script for KhetChacha Agriculture AI Engine."""

from __future__ import annotations

import sys
import time
from pathlib import Path
import pytest

# Add project root to sys.path
sys.path.insert(0, str(Path(__file__).resolve().parent.parent.parent))


def main():
    print("=" * 70)
    print("[TEST SUITE] KhetChacha Agriculture AI Engine - Complete Test Runner")
    print("=" * 70)

    test_dir = Path(__file__).resolve().parent.parent / "tests"
    print(f"Target Test Directory: {test_dir}\n")

    start_time = time.time()
    exit_code = pytest.main([
        str(test_dir),
        "-v",
        "--tb=short",
        "-rA",
    ])
    duration = time.time() - start_time

    print("\n" + "=" * 70)
    if exit_code == 0:
        print(f"[PASSED] All KhetChacha AI Engine test suites passed in {duration:.2f}s!")
    else:
        print(f"[FAILED] Test suite finished with exit code {exit_code} in {duration:.2f}s.")
    print("=" * 70)

    sys.exit(exit_code)


if __name__ == "__main__":
    main()
