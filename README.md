# ClearML Agent Bootstrap

NOTE: Bootstrap is supported when using ClearML Agent version `3.0.0` and up

---

The `clearml-agent-bootstrap` package provides a pre-compiled and self-contained initialization system executed within any container launched by the `ClearML Agent`. It ships precompiled binaries for **Python**, **Git**, **ClearML Agent**, and essential utilities, eliminating the need for containers to have these tools pre-installed and ensuring a reliable and efficient setup.

When a ClearML Agent launches a containerised task, the bootstrap script runs first. It detects the container's architecture and distribution, sets up a working Python environment, ensures Git is available, and then hands off to the ClearML Agent to execute the actual task.

### Why Use Bootstrap

- **Faster cold starts** — precompiled binaries avoid slow package-manager installs at task launch time.
- **Broader container compatibility** — tasks can run in minimal or stripped-down images (Alpine, slim, distroless-adjacent) that lack requirements such as Python or Git.
- **Consistent environments** — every task gets the same known-good toolchain regardless of the base image.
- **Offline support** — all critical binaries are bundled, so no internet access is needed for the initial setup.

### Core Components

  - **ClearML Agent**: Pre-compiled agent binary (available variants for each architecture).
  - **Python**: Managed by the `uv` package manager for streamlined environment setup.
  - **Git**: A statically precompiled binary to guarantee version control functionality.

### Supported Platforms

  - **Architectures**: `x86_64` (Intel/AMD 64-bit) and `aarch64` (ARM64).
  - **Linux Distributions**: Ubuntu, Debian, CentOS, RHEL, Fedora, Rocky Linux, and Alpine — or any distribution that provides `apt-get`, `dnf`, `yum`, or `apk`.

For any issues, please submit a detailed bug report that includes a clear description, suggested solutions, and recommendations.

-----

## Bootstrap Process Overview

The bootstrap script ensures that all necessary dependencies — `git`, `python`, and `pip` — are available and correctly configured before the `clearml-agent` command is executed. It runs through the following steps:

1.  **Environment Variable Setup**: The script configures critical environment variables, including those for SSL/TLS certificates and proxies, to ensure network connectivity. It also handles specific variables for the `uv` package manager.

2.  **Git Installation**: The script checks for an existing `git` installation. If none is found, it attempts to install it using common package managers (`apt`, `dnf`, `yum`, `apk`). If this fails, it defaults to a pre-compiled, static `git` binary included in the package.

3.  **Python and Pip Installation**: The script searches for a compatible `python3` installation (version 3.6 or newer) that includes `pip`.

      - If a suitable installation is found, it is used to install `clearml-agent`.
      - If no suitable environment exists, it uses the `uv` package manager to bootstrap a new, self-contained Python environment before installing `clearml-agent`.

4.  **`clearml-agent` Execution**: Once all dependencies are in place, the script executes the `clearml-agent` using the configured Python interpreter and passes through any command-line arguments.

-----

## Installation

### Running tasks in docker mode on a machine/VM

NOTE: Bootstrap on a standalone machine/VM requires ClearML Agent version `3.0.0` and up

The simplest way to install the bootstrap package on a machine is using the `clearml-agent` CLI with the `clearml-agent install-bootstrap` command.

First, make sure you install ClearML Agent (version 3.0.0 and up):

```bash
pip install clearml-agent
```

Than, use the agent to install the bootstrap support:

```bash
clearml-agent install-bootstrap
```

This last command downloads the latest available `clearml-agent-bootstrap` distribution and installs it. Later, when using the ClearML Agent daemon in docker mode, the agent will automatically unpack the bootstrap binaries, mount them into task containers and make sure the bootstrap script will run on container startup.

**This command does not require a ClearML server connection** and can be executed before `clearml-agent init`.

#### Command line options

| Flag | Description |
|---|---|
| `--check` | Preview a dry-run of the command without making changes. |
| `--force` | Force reinstall even if the same version is already installed. |
| `--version TAG` | Install a specific release version (e.g., `v1.0.0+24`). |
| `--from-file PATH` | Install from a local `.whl` file instead of downloading from the official GitHub Releases. |

#### Examples

```bash
# Check what's available without installing
clearml-agent install-bootstrap --check

# Install a specific version
clearml-agent install-bootstrap --version v1.0.0+24

# Install from a local wheel
clearml-agent install-bootstrap --from-file ./clearml_agent_bootstrap-1.0.0+24-py3-none-any.whl

# Force reinstall
clearml-agent install-bootstrap --force
```

### Running tasks on a Kubernetes cluster

Bootstrap mode is supported in the ClearML Enterprise Agent helm chart.

If enabled in Kubernetes, bootstrap is deployed with each task pod, injecting binaries into the main container using a pre-configured init container.

#### Helm Chart Configuration

Enable bootstrap in the ClearML Enterprise Agent Helm chart by setting `bootstrap.enabled: true` in your `clearml-agent-values.override.yaml`:

```yaml
bootstrap:
  enabled: true
```

More options are available and documented in the helm chart values for configuring the bootstrap mode.

#### Resources Server

When bootstrap is enabled, the Helm chart also deploys a lightweight HTTP server (`clearml/bootstrap-resources-server`). This server hosts pre-built binaries and packages (e.g. VSCode and plugins), so task pods can fetch them locally without necessarily reaching the internet. It is automatically configured and includes more configuration options in the helm chart values.

-----

## Build Process

### Requirements

The build process requires the following commands to be installed:

- `docker`
- `docker buildx`
- `python`
- `yq`
- `jq`
- `zip`
- `pip3 install build twine requests`

### Bill of Materials (BoM)

All component versions are centralized in a single [`bom.yaml`](bom.yaml) file at the repository root. This file is the **single source of truth** for every version used during the build — Git, Git LFS, cURL, PCRE, Dropbear, uv, CPython, base images, VSCode, and build toolchain versions are all defined there.

Some entries can be set to `"latest"` (e.g. `UV_VERSION`, `CPYTHON_STANDALONE_VERSION` and `VSCODE_VERSION`). After building, versions are always resolved by the `build-scripts/resolve_bom.sh` script, which writes a resolved copy of the BOM to `bootstrap/bom.yaml` to be included in the wheel and Docker images.

*Tip - Export all `bom.yaml` versions as environment variables*

Instead of passing each version inline, you can export every entry from `bom.yaml` into your current shell so the build scripts pick them up automatically:

```bash
export $(yq -r 'to_entries | map("\(.key)=\(.value)") | .[]' bom.yaml | xargs)
```

### Building from Source

To build the package from source, use the provided script:

*Step one - Updating UV and Dropbear binaries and compiling a statically linked `git` binary*

```bash
cd build-scripts
GIT_VERSION="2.50.1" GIT_LFS_VERSION="3.7.0" PCRE_VERSION="10.45" CURL_VERSION="8.11.0"  DROPBEAR_VER="DROPBEAR_2025.88" OPENSSH_SFTP_VER="V_10_0_P2" ./build_all.sh
cd ..
```

To optionally *compile the Agent executable* as well, pass the `BUILD_FROM_SOURCE` variable. Its value should point to the Agent repository code, e.g. `BUILD_FROM_SOURCE=../../clearml-agent` assumes this repository and the [Agent](https://github.com/clearml/clearml-agent) one were cloned under the same directory.

```bash
cd build-scripts
GIT_VERSION="2.50.1" GIT_LFS_VERSION="3.7.0" PCRE_VERSION="10.45" CURL_VERSION="8.11.0"  DROPBEAR_VER="DROPBEAR_2025.88" OPENSSH_SFTP_VER="V_10_0_P2" BUILD_FROM_SOURCE=../../clearml-agent ./build_all.sh
cd ..
```

*Step two - Build python wheel for distribution*
```bash
python3 -m build -w .
```

*Step three - Optional - Grab the `bootstrap` and package it into a container for Kubernetes bootstrap operators*
```bash
cp -R bootstrap target_folder/
```

*Optional - Overriding the Alpine base image*

The Kubernetes bootstrap Docker image (`k8s/Dockerfile`) defaults to a hardened `dhi.io/alpine-base` image, which requires access to the [Docker Hardened Images](https://www.docker.com/products/hardened-images/) registry. If that registry isn't available to you, override the base via the `ALPINE_BASE_IMAGE` build arg to use the public Alpine image instead:

```bash
docker buildx build \
  --build-arg ALPINE_BASE_IMAGE=alpine \
  --build-arg DHI_ALPINE_VERSION=3.23 \
  -f k8s/Dockerfile -t clearml/agent-bootstrap:dev .
```

#### Package offline/standalone python binaries and VSCode server

Download and package only the relevant python builds for easier distribution, as well as VSCode and default python vscode extensions

Server packaged vscode via Nginx http static serving, build a docker image with all binaries and serving engine in a single docker for easier distribution

1. build the docker image including downloading the latest binaries
`VSCODE_VERSION`: VSCode code-server version, (default: 4.112.0)
`SERVER_PORT`   : Internal (container) port number for the server (default: 80 for HTTP, 443 for HTTPS)
`SSL_CERT_PATH` : Path to existing SSL certificate file (optional)
`SSL_KEY_PATH`  : Path to existing SSL private key file (optional)
NOTE: If both `SSL_CERT_PATH` and `SSL_KEY_PATH` are set, HTTPS will be used automatically.
NOTE: Offline VSCode extensions are defined inside `vscode_build.sh` bash script

```bash
cd build-scripts
./package_offline_docker.sh
cd ..
```

2. Run the offline binary serving container image `offline_cpython_vscode_serving`

```bash
docker run -t -e SERVER_HOST="http://10.0.0.100:8080" -p 8080:80 -p 8443:443 offline_cpython_vscode_serving:latest
```

**Notice**: When running manually on Kubernetes, do not forget to pass `SERVER_HOST` pointing to the ingress of the pod.

3. Set the `clearml_agent` to use the packaged UV python binary server by setting the following in your `clearml.conf` or via the clearml vault:
```
agent.bootstrap.uv_python_meta_file: "http://localhost:8080/cpython_build/download-metadata.json"
```

**Notice**: When running on Kubernetes, `download-metadata.json` must be volume mapped into the container and NOT configured as http/s link, as UV does not support downloading the json file from http link. Example for read-only read-many Kubernetes configuration: `agent.bootstrap.uv_python_meta_file: "/bootstrap/download-metadata.json"`

4. Set the `clearml_agent` to use the packaged VSCode binary by setting the following in your `clearml.conf` or via the clearml vault:
```
environment.CLEARML_SESSION_VSCODE_SERVER_TGZ: "http://10.0.0.100:8080/vscode_build/code-server-4.112.0-linux-{platform_type}.tar.gz"
environment.CLEARML_SESSION_VSCODE_PY_EXT: "http://10.0.0.100:8080/vscode_build/vscode_extensions.zip"
```

**Notice**: Verify that environment variable `CLEARML_SESSION_VSCODE_SERVER_DEB` or value `environment.CLEARML_SESSION_VSCODE_SERVER_DEB` are removed before applying the new configuration.


#### [optional] Manual build Dropbear standalone ssh server from source code

This is a fork of dropbear, a user space SSH server, see source code here: https://github.com/clearml/dropbear.git
Notice: the forked `dropbear` server adds the ability to set SSH root password via environment variable `DROPBEAR_CLEARML_FIXED_PASSWORD=password`

1. Download and compile the code repository
```bash
git clone https://github.com/clearml/dropbear.git
cd dropbear
./build.sh
cd ..
```
2. Place the compiled build into `clearml_agent_bootstrap/data/` directory
```bash
mkdir -p ./bootstrap/dropbear/x64
cp ./dropbear/build/dropbearmulti ./bootstrap/dropbear/x64/
```

## Environment Configuration

The script's behavior can be customized by setting the following environment variables. If not explicitly set, variables are assigned a default value where applicable.

| Variable | Description | Default Value |
| :--- | :--- | :--- |
| **`CLEARML_BOOTSTRAP_CUSTOM_CMD`** | Allow user to have custom command to be executed before bootstrap execution but after initial environment variable setup | n/a |
| **`CLEARML_SKIP_CA_CERT_INST`** | If set to `1`, skip trying to install the ca-certificates package. Even if installation fails, the script continues. | `0` |
| **`CLEARML_APT_INSTALL`** | Allow user to install additional packages before setting up the environment | n/a |
| **`CLEARML_SKIP_GIT_INST`** | A flag to skip the automatic installation of `git`. Set to `1` to skip and use the prepackaged static git executable (includes LFS support). | `0` |
| **`CLEARML_FORCE_STATIC_GIT_BIN`** | If set to `1`, always use the prepackaged static git executable (includes LFS support). | `0` |
| **`SSL_CERT_FILE`** | Path to the file containing SSL certificates. Inferred from other variables or system paths if not set. | n/a |
| **`SSL_CLIENT_CERT`** | Path to the client-side SSL certificate file. | n/a |
| **`ALL_PROXY`** | A proxy URL to be used for all network traffic. | n/a |
| **`CURL_CA_BUNDLE`** | Path to the CA bundle file for cURL, used as a fallback for `SSL_CERT_FILE` and `GIT_SSL_CAINFO`. | n/a |
| **`REQUESTS_CA_BUNDLE`** | Path to the CA bundle file for the Python `requests` library, used as a fallback for `SSL_CERT_FILE`. | n/a |
| **`GIT_SSL_CAINFO`** | Path to the CA bundle file for Git, inferred from `SSL_CERT_FILE` or `CURL_CA_BUNDLE` if not explicitly set. | n/a |
| **`UV_NATIVE_TLS`** | A flag to enable native TLS support for `uv`. (e.g., `0` or `1`) | n/a |
| **`UV_INSECURE_HOST`** | A flag to allow insecure host connections for `uv`. (e.g., `0` or `1`) | n/a |
| **`GIT_SSL_NO_VERIFY`** | A flag to disable SSL verification for Git. (e.g., `0` or `1`) | n/a |
| **`UV_INSTALLER_GHE_BASE_URL`** | The URL from which to download `uv` using the standalone installer. e.g., `"https://github.com/astral-sh/uv/releases"` | `""` |
| **`UV_INSTALLER_GITHUB_BASE_URL`** | The URL from which to download `uv` using the standalone installer. e.g., `"https://github.com/astral-sh/uv/releases"` | `""` |
| **`UV_PYTHON_INSTALL_MIRROR`** | A URL to a mirror for installing Python binaries. e.g. `https://raw.githubusercontent.com/astral-sh/uv/refs/heads/main/crates/uv-python/download-metadata.json` | n/a |
| **`UV_PYTHON_DOWNLOADS_JSON_URL`** | A URL to a JSON file containing metadata for Python binary downloads. e.g., `"https://github.com/astral-sh/uv/blob/main/crates/uv-python/download-metadata.json"` | n/a |
| **`UV_DEFAULT_INDEX`** | Equivalent to the `--default-index` command-line argument. The URL `uv` will use as the default index when searching for packages. | n/a |
| **`UV_INDEX`** | Equivalent to the `--extra-index-url` command-line argument. A space-separated list of URLs `uv` will use as additional indexes. | n/a |
| **`CLEARML_BOOTSTRAP_DIR`** | The base directory for the bootstrap process, where `uv` and `git` binaries will be stored if downloaded. | `/tmp/.clearml.bootstrap` |
| **`CLEARML_BOOTSTRAP_RO_UV`** | The read-only directory where `uv` binaries are located. | `"$CLEARML_BOOTSTRAP_DIR/uv"` |
| **`CLEARML_BOOTSTRAP_RO_GIT`** | The read-only directory where `git` binaries are located. | `"$CLEARML_BOOTSTRAP_DIR/git"` |
| **`CLEARML_CACHE_DIR`** | The directory used for caching downloaded files and Python packages by `uv`. | `/tmp/.clearml.cache` |
| **`CLEARML_PYTHON_VER`** | The specific Python version to install if a new environment is bootstrapped. If empty, the latest supported version will be used. | `""` |
| **`CLEARML_UPDATE_UV`** | A flag to control whether the script should attempt to update the `uv` package manager. Set to `1` to enable. | `""` |
| **`CLEARML_PIP_VER`** | A string of version specifiers for `pip` to install, allowing control over the `pip` version based on the Python version. | `-U "pip<21 ; python_version < '3.11'" "pip<26 ; python_version >= '3.10'"` |
| **`UV_PYTHON_CACHE_DIR`** | The specific directory for caching Python binaries. | `"$CLEARML_CACHE_DIR/uv_python/"` |
| **`UV_CACHE_DIR`** | The specific directory for `uv`'s cache. | `"$CLEARML_CACHE_DIR/uv/"` |
| **`UV_PYTHON_INSTALL_DIR`** | The directory where the bootstrapped Python interpreter will be installed. | `"$UV_UNMANAGED_INSTALL/python"` |

-----
