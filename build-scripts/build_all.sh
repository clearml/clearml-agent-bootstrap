#!/bin/bash
set -euo pipefail

FAILURES=0

# UV binaries x64/arm64
python3 update_uv_binaries.py ../bootstrap/uv

# Runs the following three compilation steps in parallel.
# NOTE: at peak, this spawns up to 8 concurrent docker builds (4 wheel + 2 git + 2 dropbear).

# clearml-agent binaries
BUILD_VER="${BUILD_VER:-}" BUILD_FROM_SOURCE="${BUILD_FROM_SOURCE:-}" ./wheel_compile_build.sh &
PID_WHEEL=$!

# git build x64/arm64
./git_build.sh ../bootstrap/git &
PID_GIT=$!

# dropbear and sftp build x64/arm64
./dropbear_build.sh ../bootstrap/dropbear &
PID_DROPBEAR=$!

echo "[build_all] Waiting for wheel_compile, git_build, and dropbear_build..."

for pid in $PID_WHEEL $PID_GIT $PID_DROPBEAR; do
    if ! wait "$pid"; then
        FAILURES=$((FAILURES + 1))
    fi
done

if [[ $FAILURES -gt 0 ]]; then
    echo "[build_all] ERROR: $FAILURES step(s) failed"
    exit 1
fi

echo "[build_all] All builds completed successfully"
