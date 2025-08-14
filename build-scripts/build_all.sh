#!/bin/bash

# UV binaries x64/arm64
python3 update_uv_binaries.py ../bootstrap/uv

# git build x64/arm64
./git_build.sh ../bootstrap/git

# dropbear and sftp build x64/arm64
./dropbear_build.sh ../bootstrap/dropbear
