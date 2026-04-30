#!/bin/bash
set -euo pipefail

############################################
# Environment Variables
############################################
# SERVER_NAME    : Hostname or domain name of the server (default: localhost)
# SERVER_PORT    : Port number for the server (default: 8080 for HTTP, 443 for HTTPS)
# SSL_CERT_PATH  : Path to existing SSL certificate file (optional)
# SSL_KEY_PATH   : Path to existing SSL private key file (optional)
# DOCKER_OUTPUT          : Docker buildx output mode — valid values: "load" or "push" (default: load)
# IMAGE_TAG              : Docker image tag for the built image (default: offline_cpython_vscode_serving)
# DOCKER_BUILDX_BUILDER  : Name of the buildx builder to use (optional — omit to use the default builder)
# NGINX_VERSION          : Nginx base image tag (default: 1.29.7-alpine)
# NOTE: If both SSL_CERT_PATH and SSL_KEY_PATH are set, HTTPS will be used automatically.
############################################

DOCKER_OUTPUT="--${DOCKER_OUTPUT:-load}"
IMAGE_TAG="${IMAGE_TAG:-offline_cpython_vscode_serving}"
NGINX_VERSION="${NGINX_VERSION:-1.29.7-alpine}"

SERVER_NAME="${SERVER_NAME:-localhost}"
SERVER_PORT="${SERVER_PORT:-8080}"
SSL_CERT_PATH="${SSL_CERT_PATH:-}"
SSL_KEY_PATH="${SSL_KEY_PATH:-}"

# Detect protocol based on SSL vars
if [[ -n "$SSL_CERT_PATH" && -n "$SSL_KEY_PATH" ]]; then
    PROTOCOL="https"
    ENABLE_SSL=true
    SERVER_PORT="${SERVER_PORT:-8443}"
    SERVER_PORT_INT="443"
else
    SERVER_PORT_INT="80"
    PROTOCOL="http"
    ENABLE_SSL=false
fi

SERVER_HOST="${PROTOCOL}://${SERVER_NAME}:${SERVER_PORT}"

echo "======================================"
echo " Server Configuration"
echo "--------------------------------------"
echo " Hostname:     $SERVER_NAME"
echo " Port:         $SERVER_PORT"
echo " Protocol:     $PROTOCOL"
echo " SSL Enabled:  $ENABLE_SSL"
if [[ "$ENABLE_SSL" == true ]]; then
    echo " SSL Cert:     $SSL_CERT_PATH"
    echo " SSL Key:      $SSL_KEY_PATH"
fi
echo "======================================"

# Download UV binaries (x64/arm64)
python3 download_standalone_pythons_for_uv.py "$SERVER_HOST/cpython_build/releases"

# Download VSCode binaries
./vscode_build.sh

# Prepare Docker build args
DOCKER_BUILD_ARGS=(
    --build-arg NGINX_VERSION="$NGINX_VERSION"
    --build-arg SERVER_NAME="$SERVER_NAME"
    --build-arg ENABLE_SSL="$ENABLE_SSL"
)

# If SSL is enabled, prepare certs and mount them
DOCKER_RUN_MOUNTS=()
if [[ "$ENABLE_SSL" == true ]]; then
    mkdir -p ssl_certs
    cp "$SSL_CERT_PATH" ./ssl_certs/server.crt
    cp "$SSL_KEY_PATH" ./ssl_certs/server.key
    echo "Copied SSL certificates to ./ssl_certs"

    # Add mount for runtime
    DOCKER_RUN_MOUNTS=(-v "$(pwd)/ssl_certs:/etc/ssl/private:ro")
fi

# Build Docker image
docker buildx build "${DOCKER_BUILD_ARGS[@]}" \
    ${DOCKER_BUILDX_BUILDER:+--builder "$DOCKER_BUILDX_BUILDER"} \
    --platform linux/amd64,linux/arm64 \
    -t "$IMAGE_TAG" \
    "$DOCKER_OUTPUT" \
    -f offline_cpython_vscode_serving.Dockerfile .

# Example run command with mount if SSL is enabled
echo
echo "To run the container:"
if [[ "$ENABLE_SSL" == true ]]; then
    echo "docker run -e "SERVER_HOST=\"${PROTOCOL}://${SERVER_NAME}:${SERVER_PORT}\"" -p ${SERVER_PORT}:${SERVER_PORT_INT} \"${DOCKER_RUN_MOUNTS[@]}\" $IMAGE_TAG"
else
    echo "docker run -e "SERVER_HOST=\"${PROTOCOL}://${SERVER_NAME}:${SERVER_PORT}\"" -p ${SERVER_PORT}:${SERVER_PORT_INT} $IMAGE_TAG"
fi
