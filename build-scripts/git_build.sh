#!/bin/bash
set -euo pipefail

replace_duplicates_with_symlink() {
    local basefile="$1"
    local targetdir="$2"
    local basefile_link="$3"

    # Resolve absolute path of base file
    local baseabs
    baseabs="$(readlink -f "$basefile")"

    if [[ ! -f "$baseabs" ]]; then
        echo "Base file not found: $baseabs"
        return 1
    fi

    if [[ ! -d "$targetdir" ]]; then
        echo "Target directory not found: $targetdir"
        return 1
    fi

    local basehash
    basehash=$(sha256sum "$baseabs" | awk '{print $1}')

    for file in "$targetdir"/*; do
        # Skip if not a regular file
        [[ -f "$file" ]] || continue

        # Resolve absolute path of current file
        local fileabs
        fileabs="$(readlink -f "$file")"

        # Skip if same file (by absolute path)
        [[ "$fileabs" == "$baseabs" ]] && continue

        # Compare SHA256 hashes
        local filehash
        filehash=$(sha256sum "$fileabs" | awk '{print $1}')

        if [[ "$filehash" == "$basehash" ]]; then
            echo "Replacing '$fileabs' with symlink to base file"
            rm "$fileabs"
            ln -s "$basefile_link" "$fileabs"
        fi
    done
}

## docker build -f git_build.Dockerfile --platform linux/amd64,linux/arm64 --progress=plain --output type=tar,dest=gitbin.tar .

GIT_VERSION="${GIT_VERSION:-2.55.0}"
PCRE_VERSION="${PCRE_VERSION:-10.45}"
CURL_VERSION="${CURL_VERSION:-8.11.0}"
GIT_LFS_VERSION="${GIT_LFS_VERSION:-3.7.1}"
ALPINE_VERSION="${ALPINE_VERSION:-3.22.1}"

GIT_OUT_DIR="${1:-../bootstrap/git}"

# Test by running: GIT_EXEC_PATH=$(pwd)/libexec/git-core GIT_TEMPLATE_DIR=$(pwd)/share/git-core/templates ./git clone https://...

PIDS=()
FAILURES=0

# AMD x86_64
(
docker buildx build ${DOCKER_BUILDX_BUILDER:+--builder "$DOCKER_BUILDX_BUILDER"} --no-cache -f git_build_musl.Dockerfile --build-arg ALPINE_VERSION=$ALPINE_VERSION --build-arg GIT_VERSION=$GIT_VERSION --build-arg GIT_LFS_VERSION=$GIT_LFS_VERSION --build-arg PCRE_VERSION=$PCRE_VERSION --build-arg CURL_VERSION=$CURL_VERSION --platform linux/amd64 --progress=plain --output type=tar,dest=gitbin_musl_x64.tar .
rm -rf $GIT_OUT_DIR/x64 && mkdir -p $GIT_OUT_DIR/x64 && tar -xf gitbin_musl_x64.tar -C $GIT_OUT_DIR/x64

replace_duplicates_with_symlink "$GIT_OUT_DIR/x64/bin/git" "$GIT_OUT_DIR/x64/libexec/git-core" "../../bin/git"
replace_duplicates_with_symlink "$GIT_OUT_DIR/x64/libexec/git-core/git-remote-https" "$GIT_OUT_DIR/x64/libexec/git-core" "git-remote-https"
) &
PIDS+=($!)

# ARM AARCH64
(
docker buildx build ${DOCKER_BUILDX_BUILDER:+--builder "$DOCKER_BUILDX_BUILDER"} --no-cache -f git_build_musl.Dockerfile --build-arg ALPINE_VERSION=$ALPINE_VERSION --build-arg GIT_VERSION=$GIT_VERSION --build-arg GIT_LFS_VERSION=$GIT_LFS_VERSION --build-arg PCRE_VERSION=$PCRE_VERSION --build-arg CURL_VERSION=$CURL_VERSION --platform linux/arm64/v8 --progress=plain --output type=tar,dest=gitbin_musl_a64.tar .
rm -rf $GIT_OUT_DIR/a64 && mkdir -p $GIT_OUT_DIR/a64 && tar -xf gitbin_musl_a64.tar -C $GIT_OUT_DIR/a64

replace_duplicates_with_symlink "$GIT_OUT_DIR/a64/bin/git" "$GIT_OUT_DIR/a64/libexec/git-core" "../../bin/git"
replace_duplicates_with_symlink "$GIT_OUT_DIR/a64/libexec/git-core/git-remote-https" "$GIT_OUT_DIR/a64/libexec/git-core" "git-remote-https"
) &
PIDS+=($!)

echo "[git_build] Waiting for x64 and a64 builds to complete..."
for pid in "${PIDS[@]}"; do
    if ! wait "$pid"; then
        FAILURES=$((FAILURES + 1))
    fi
done

if [[ $FAILURES -gt 0 ]]; then
    echo "[git_build] ERROR: $FAILURES build(s) failed"
    exit 1
fi
