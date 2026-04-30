#!/bin/bash
set -euo pipefail

NUITKA_VERSION="${NUITKA_VERSION:-2.8.9}"
ALPINE_VERSION="${ALPINE_VERSION:-3.22.1}"
PYTHON_VERSION="${PYTHON_VERSION:-3.12}"
FEDORA_VERSION="${FEDORA_VERSION:-26}"
PATCHELF_VERSION="${PATCHELF_VERSION:-0.18.0}"

BIN_OUT_DIR="${1:-../bootstrap/bin}"

# debugging - build from source or from package
# If BUILD_FROM_SOURCE is not provided, it will build from the latest wheel, unless BUILD_VER is specificed, then it will use BUILD_VER wheel
BUILD_VER="${BUILD_VER:-}"
BUILD_FROM_SOURCE="${BUILD_FROM_SOURCE:-./tmpsrc}"

if [[ ! -d "$BUILD_FROM_SOURCE" ]]; then
    # echo "Temp directory: $BUILD_FROM_SOURCE"
    mkdir -p "$BUILD_FROM_SOURCE"
    REMOVE_TMP_DIR=1
fi

PIDS=()
FAILURES=0

# AMD x86_64 - musl
(
docker buildx build ${DOCKER_BUILDX_BUILDER:+--builder "$DOCKER_BUILDX_BUILDER"} -f wheel_compile_build_musl.Dockerfile --build-arg ALPINE_VERSION=$ALPINE_VERSION --build-arg PYTHON_VERSION=$PYTHON_VERSION --build-arg BUILD_VER="$BUILD_VER" --build-arg NUITKA_VERSION=$NUITKA_VERSION --platform linux/amd64 --progress=plain --output type=tar,dest=agent_musl_x64.tar $BUILD_FROM_SOURCE
rm -rf $BIN_OUT_DIR/x64/musl && mkdir -p $BIN_OUT_DIR/x64/musl && tar -xf agent_musl_x64.tar -C $BIN_OUT_DIR/x64/musl/
) &
PIDS+=($!)

# AMD x86_64 - glib
(
docker buildx build ${DOCKER_BUILDX_BUILDER:+--builder "$DOCKER_BUILDX_BUILDER"} -f wheel_compile_build_fed.Dockerfile --build-arg FEDORA_VERSION=$FEDORA_VERSION --build-arg PATCHELF_VERSION=$PATCHELF_VERSION --build-arg PYTHON_VERSION=$PYTHON_VERSION --build-arg BUILD_VER="$BUILD_VER" --build-arg NUITKA_VERSION=$NUITKA_VERSION --platform linux/amd64 --progress=plain --output type=tar,dest=agent_fed_x64.tar $BUILD_FROM_SOURCE
rm -rf $BIN_OUT_DIR/x64/glib && mkdir -p $BIN_OUT_DIR/x64/glib && tar -xf agent_fed_x64.tar -C $BIN_OUT_DIR/x64/glib
) &
PIDS+=($!)

# ARM AARCH64 - musl
(
docker buildx build ${DOCKER_BUILDX_BUILDER:+--builder "$DOCKER_BUILDX_BUILDER"} -f wheel_compile_build_musl.Dockerfile --build-arg ALPINE_VERSION=$ALPINE_VERSION --build-arg PYTHON_VERSION=$PYTHON_VERSION --build-arg BUILD_VER="$BUILD_VER" --build-arg NUITKA_VERSION=$NUITKA_VERSION --platform linux/arm64/v8 --progress=plain --output type=tar,dest=agent_musl_a64.tar $BUILD_FROM_SOURCE
rm -rf $BIN_OUT_DIR/a64/musl && mkdir -p $BIN_OUT_DIR/a64/musl && tar -xf agent_musl_a64.tar -C $BIN_OUT_DIR/a64/musl
) &
PIDS+=($!)

# ARM AARCH64 - glib
(
docker buildx build ${DOCKER_BUILDX_BUILDER:+--builder "$DOCKER_BUILDX_BUILDER"} -f wheel_compile_build_fed.Dockerfile --build-arg FEDORA_VERSION=$FEDORA_VERSION --build-arg PATCHELF_VERSION=$PATCHELF_VERSION --build-arg PYTHON_VERSION=$PYTHON_VERSION --build-arg BUILD_VER="$BUILD_VER" --build-arg NUITKA_VERSION=$NUITKA_VERSION --platform linux/arm64/v8 --progress=plain --output type=tar,dest=agent_fed_a64.tar $BUILD_FROM_SOURCE
rm -rf $BIN_OUT_DIR/a64/glib && mkdir -p $BIN_OUT_DIR/a64/glib && tar -xf agent_fed_a64.tar -C $BIN_OUT_DIR/a64/glib
) &
PIDS+=($!)

echo "[wheel_compile] Waiting for all 4 builds to complete..."
for pid in "${PIDS[@]}"; do
    if ! wait "$pid"; then
        FAILURES=$((FAILURES + 1))
    fi
done

if [[ $FAILURES -gt 0 ]]; then
    echo "[wheel_compile] ERROR: $FAILURES build(s) failed"
    exit 1
fi

if [[ ! -z "${REMOVE_TMP_DIR:-}" ]]; then
    echo "delete temp directory: $BUILD_FROM_SOURCE"
    rm -rf "$BUILD_FROM_SOURCE"
fi
