#!/bin/bash

# Remove offline-package build folders
rm -rf cpython_build vscode_build

# Remove bootstrap build folders
rm -rf ../bootstrap/bin ../bootstrap/dropbear ../bootstrap/git ../bootstrap/uv

# Remove bootstrap agent wheel local builds
rm -rf agent_fed*.tar agent_musl*.tar gitbin_musl*.tar sftpbin_musl*.tar

# Remove the wheel build and output dist folder
rm -rf ../dist ../build ../clearml_agent_bootstrap.egg-info