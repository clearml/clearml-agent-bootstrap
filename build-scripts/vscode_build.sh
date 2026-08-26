#!/bin/bash
set -euo pipefail

VSCODE_VERSION="${VSCODE_VERSION:-latest}"

# Get the latest VSCode version online if not pinned
if [ "$VSCODE_VERSION" = "latest" ]; then
    # Get the latest non-prerelease (rc) version and verify it is extracted correctly and follows versioning as x.y.z
    latest_version=$(curl -sSf https://api.github.com/repos/coder/code-server/releases | jq -r '.[] | select(.prerelease == false) | .tag_name' | sed 's/^v//' | head -n1)
    if [ $? -ne 0 ] || ! echo "$latest_version" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
        echo "ERROR: Invalid VSCode version found as latest. Version: '$latest_version'"
    fi
    VSCODE_VERSION="$latest_version"
fi

echo "Latest VSCode version: $VSCODE_VERSION"

EXTENSIONS=(
    "ms-python.python"
    "ms-toolsai.jupyter"
    "njpwerner.autodocstring"
    "ms-python.pylint"
    "ms-python.flake8"
    "ms-python.mypy-type-checker"
#   "ms-python.vscode-pylance"    
)

# Extensions that have platform-specific builds on Open VSX
BINARY_EXTENSIONS=(
    "charliermarsh.ruff"
    # Add more here if needed
)

PLATFORMS=(
    "linux-x64"
    "alpine-x64"
    "linux-arm64"
    "alpine-arm64"
)

VSCODE_OUT_DIR="${VSCODE_OUT_DIR:-vscode_build}"
VSCODE_EXT_ZIP_FILE="${VSCODE_EXT_ZIP_FILE:-vscode_extensions.zip}"

VSCODE_BIN_AMD64="https://github.com/coder/code-server/releases/download/v$VSCODE_VERSION/code-server-$VSCODE_VERSION-linux-amd64.tar.gz"
VSCODE_BIN_ARM64="https://github.com/coder/code-server/releases/download/v$VSCODE_VERSION/code-server-$VSCODE_VERSION-linux-arm64.tar.gz"

mkdir -p "$VSCODE_OUT_DIR"

download_vsix() {
    local EXT="$1"
    local PUBLISHER="${EXT%%.*}"
    local NAME="${EXT#*.}"

    VERSION=$(curl -s "https://open-vsx.org/api/$PUBLISHER/$NAME" | jq -r '.version')
    if [[ -z "$VERSION" || "$VERSION" == "null" ]]; then
        echo "[!] Could not get version for $EXT"
        return 1
    fi

    FILE="$VSCODE_OUT_DIR/${EXT//./_}-$VERSION.vsix"
    URL="https://open-vsx.org/api/$PUBLISHER/$NAME/$VERSION/file/$PUBLISHER.$NAME-$VERSION.vsix"

    echo "   - $EXT @ $VERSION"
    curl --compressed  -H 'Accept-Encoding: gzip, deflate, br, zstd' -H 'Upgrade-Insecure-Requests: 1' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' -sSL "$URL" -o "$FILE"
}

download_binary_vsix_flavors() {
    local EXT="$1"
    local PUBLISHER="${EXT%%.*}"
    local NAME="${EXT#*.}"

    for PLATFORM in "${PLATFORMS[@]}"; do
        # Per-platform binaries are versioned independently on Open VSX — the
        # generic /api/$PUBLISHER/$NAME endpoint returns whichever flavor was
        # published most recently, whose version may not exist for $PLATFORM.
        VERSION=$(curl -s "https://open-vsx.org/api/$PUBLISHER/$NAME/$PLATFORM/latest" | jq -r '.version')
        if [[ -z "$VERSION" || "$VERSION" == "null" ]]; then
            echo "[!] Could not get version for $EXT ($PLATFORM)"
            return 1
        fi

        FILE="$VSCODE_OUT_DIR/${EXT//./_}-$VERSION@$PLATFORM.vsix"
        URL="https://open-vsx.org/api/$PUBLISHER/$NAME/$PLATFORM/$VERSION/file/$PUBLISHER.$NAME-$VERSION@$PLATFORM.vsix"
        echo "   - $EXT @ $VERSION ($PLATFORM)"
        curl --compressed  -H 'Accept-Encoding: gzip, deflate, br, zstd' -H 'Upgrade-Insecure-Requests: 1' -H 'Pragma: no-cache' -H 'Cache-Control: no-cache' -sSL "$URL" -o "$FILE"
    done
}

DOWNLOAD_PIDS=()
FAILURES=0

echo "[*] Downloading binary extension flavors from Open VSX..."
for EXT in "${BINARY_EXTENSIONS[@]}"; do
    download_binary_vsix_flavors "$EXT" &
    DOWNLOAD_PIDS+=($!)
done

echo "[*] Downloading regular VSIX files..."
for EXT in "${EXTENSIONS[@]}"; do
    download_vsix "$EXT" &
    DOWNLOAD_PIDS+=($!)
done

echo "[*] Waiting for all extension downloads to complete..."
for pid in "${DOWNLOAD_PIDS[@]}"; do
    if ! wait "$pid"; then
        FAILURES=$((FAILURES + 1))
    fi
done

if [[ $FAILURES -gt 0 ]]; then
    echo "[vscode_build] ERROR: $FAILURES download(s) failed"
    exit 1
fi

echo "[*] Packaging into $VSCODE_EXT_ZIP_FILE..."
(
    cd "$VSCODE_OUT_DIR"
    zip -qr "$VSCODE_EXT_ZIP_FILE" ./*.vsix
    rm ./*.vsix
)

echo "[*] Downloading VS Code Server binaries..."
curl -sSL "$VSCODE_BIN_AMD64" -o "$VSCODE_OUT_DIR/code-server-${VSCODE_VERSION}-linux-amd64.tar.gz" &
PID_AMD64=$!
curl -sSL "$VSCODE_BIN_ARM64" -o "$VSCODE_OUT_DIR/code-server-${VSCODE_VERSION}-linux-arm64.tar.gz" &
PID_ARM64=$!

FAILURES=0
for pid in $PID_AMD64 $PID_ARM64; do
    if ! wait "$pid"; then
        FAILURES=$((FAILURES + 1))
    fi
done

if [[ $FAILURES -gt 0 ]]; then
    echo "[vscode_build] ERROR: $FAILURES VS Code Server download(s) failed"
    exit 1
fi

latest_amd64_vscode_file="$VSCODE_OUT_DIR/code-server-latest-linux-amd64.tar.gz"
latest_arm64_vscode_file="$VSCODE_OUT_DIR/code-server-latest-linux-arm64.tar.gz"

# Remove existing "latest" files if they exist in local build folders
if [ -f "$latest_amd64_vscode_file" ]; then
    rm -f "$latest_amd64_vscode_file"
fi

if [ -f "$latest_arm64_vscode_file" ]; then
    rm -f "$latest_arm64_vscode_file"
fi

# Copy the VS Code files with the version named "latest"
cp $VSCODE_OUT_DIR/code-server-${VSCODE_VERSION}-linux-amd64.tar.gz $latest_amd64_vscode_file
cp $VSCODE_OUT_DIR/code-server-${VSCODE_VERSION}-linux-arm64.tar.gz $latest_arm64_vscode_file

echo "[*] All extensions and binaries saved in $VSCODE_OUT_DIR"
