#!/bin/bash

DROPBEAR_VER="${DROPBEAR_VER:-DROPBEAR_2025.88}"
OPENSSH_SFTP_VER="${OPENSSH_SFTP_VER:-V_10_0_P2}"

DROPBEAR_OUT_DIR="${1:-../bootstrap/dropbear}"

# AMD x86_64
rm -rf $DROPBEAR_OUT_DIR/x64 && mkdir -p $DROPBEAR_OUT_DIR/x64

# dropbear binary x64
curl -L "https://github.com/clearml/dropbear/releases/download/$DROPBEAR_VER/dropbearmulti_amd64" -o $DROPBEAR_OUT_DIR/x64/dropbearmulti
chmod +x $DROPBEAR_OUT_DIR/x64/dropbearmulti

# sftp build - x86_64
docker build -f sftp_build_musl.Dockerfile --build-arg OPENSSH_SFTP_VER=$OPENSSH_SFTP_VER --platform linux/amd64 --progress=plain --output type=tar,dest=sftpbin_musl.tar .
tar -xf sftpbin_musl.tar -C $DROPBEAR_OUT_DIR/x64


# ARM AARCH64
rm -rf $DROPBEAR_OUT_DIR/a64 && mkdir -p $DROPBEAR_OUT_DIR/a64

# dropbear binary arm64
curl -L "https://github.com/clearml/dropbear/releases/download/$DROPBEAR_VER/dropbearmulti_arm64" -o $DROPBEAR_OUT_DIR/a64/dropbearmulti
chmod +x $DROPBEAR_OUT_DIR/a64/dropbearmulti

# sftp build - arm64
docker build -f sftp_build_musl.Dockerfile --build-arg OPENSSH_SFTP_VER=$OPENSSH_SFTP_VER --platform linux/arm64/v8 --progress=plain --output type=tar,dest=sftpbin_musl.tar .
tar -xf sftpbin_musl.tar -C $DROPBEAR_OUT_DIR/a64
