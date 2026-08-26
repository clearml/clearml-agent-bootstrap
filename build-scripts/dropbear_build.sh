#!/bin/bash
set -euo pipefail

DROPBEAR_VER="${DROPBEAR_VER:-DROPBEAR_2025.88}"
OPENSSH_SFTP_VER="${OPENSSH_SFTP_VER:-V_10_0_P2}"
ALPINE_VERSION="${ALPINE_VERSION:-3.22.1}"

DROPBEAR_OUT_DIR="${1:-../bootstrap/dropbear}"

PIDS=()
FAILURES=0

# AMD x86_64
(
rm -rf $DROPBEAR_OUT_DIR/x64 && mkdir -p $DROPBEAR_OUT_DIR/x64

# dropbear binary x64
curl -L "https://github.com/clearml/dropbear/releases/download/$DROPBEAR_VER/dropbearmulti_amd64" -o $DROPBEAR_OUT_DIR/x64/dropbearmulti
chmod +x $DROPBEAR_OUT_DIR/x64/dropbearmulti

# sftp build - x86_64
docker buildx build ${DOCKER_BUILDX_BUILDER:+--builder "$DOCKER_BUILDX_BUILDER"} -f sftp_build_musl.Dockerfile --build-arg ALPINE_VERSION=$ALPINE_VERSION --build-arg OPENSSH_SFTP_VER=$OPENSSH_SFTP_VER --platform linux/amd64 --progress=plain --output type=tar,dest=sftpbin_musl_x64.tar .
tar -xf sftpbin_musl_x64.tar -C $DROPBEAR_OUT_DIR/x64
) &
PIDS+=($!)

# ARM AARCH64
(
rm -rf $DROPBEAR_OUT_DIR/a64 && mkdir -p $DROPBEAR_OUT_DIR/a64

# dropbear binary arm64
curl -L "https://github.com/clearml/dropbear/releases/download/$DROPBEAR_VER/dropbearmulti_arm64" -o $DROPBEAR_OUT_DIR/a64/dropbearmulti
chmod +x $DROPBEAR_OUT_DIR/a64/dropbearmulti

# sftp build - arm64
docker buildx build ${DOCKER_BUILDX_BUILDER:+--builder "$DOCKER_BUILDX_BUILDER"} -f sftp_build_musl.Dockerfile --build-arg ALPINE_VERSION=$ALPINE_VERSION --build-arg OPENSSH_SFTP_VER=$OPENSSH_SFTP_VER --platform linux/arm64/v8 --progress=plain --output type=tar,dest=sftpbin_musl_a64.tar .
tar -xf sftpbin_musl_a64.tar -C $DROPBEAR_OUT_DIR/a64
) &
PIDS+=($!)

echo "[dropbear_build] Waiting for x64 and a64 builds to complete..."
for pid in "${PIDS[@]}"; do
    if ! wait "$pid"; then
        FAILURES=$((FAILURES + 1))
    fi
done

if [[ $FAILURES -gt 0 ]]; then
    echo "[dropbear_build] ERROR: $FAILURES build(s) failed"
    exit 1
fi
