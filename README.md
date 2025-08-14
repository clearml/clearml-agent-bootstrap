# `ClearML-Agent` Bootstrap Auxiliary Package

The `clearml-agent-bootstrap` package provides the essential initialization script executed within any container launched by the `ClearML Agent`. It includes precompiled utilities necessary to configure the container environment, ensuring a reliable and efficient setup.

### **Core Components**

  - **Python**: Managed by the `uv` package manager for streamlined environment setup.
  - **Git**: A statically precompiled binary to guarantee version control functionality.

### **Supported Platforms**

  - **Architectures**: `x86_64` (Intel/AMD 64-bit) and `aarch64` (ARM64).
  - **Linux Distributions**: Ubuntu, Debian, CentOS, RHEL, Fedora, and Rocky Linux.

For any issues, please submit a detailed bug report that includes a clear description, suggested solutions, and recommendations.

-----

## **Bootstrap Process Overview**

This bash script serves as a **bootstrap script** to prepare an environment for running a `clearml-agent` inside a container. Its primary function is to ensure that all necessary dependencies—`git`, `python`, and `pip`—are available and correctly configured before the `clearml-agent` command is executed.

The script executes the following steps:

1.  **Environment Variable Setup**: The script configures critical environment variables, including those for SSL/TLS certificates and proxies, to ensure network connectivity. It also handles specific variables for the `uv` package manager.

2.  **Git Installation**: The script checks for an existing `git` installation. If none is found, it attempts to install it using common package managers (`apt`, `dnf`, `yum`, `apk`). If this fails, it defaults to a pre-compiled, static `git` binary included in the package.

3.  **Python and Pip Installation**: The script searches for a compatible `python3` installation (version 3.6 or newer) that includes `pip`.

      - If a suitable installation is found, it is used to install `clearml-agent`.
      - If no suitable environment exists, it uses the `uv` package manager to bootstrap a new, self-contained Python environment before installing `clearml-agent`.

4.  **`clearml-agent` Execution**: Once all dependencies are in place, the script executes the `clearml-agent` using the configured Python interpreter and passes through any command-line arguments.

-----

## **Environment Configuration**

The script's behavior can be customized by setting the following environment variables. If not explicitly set, variables are assigned a default value where applicable.

| Variable | Description | Default Value |
| :--- | :--- | :--- |
| **`CLEARML_BOOTSTRAP_CUSTOM_CMD`** | allow user to have custom command to be executed before bootstrap execution but after initial environment variable setup | n/a |
| **`CLEARML_SKIP_CA_CERT_INST`** | If set to `1` skip trying to install ca-certificates package, notice even if installation fails script continues | 0 |
| **`CLEARML_APT_INSTALL`** | allow user to install additional packages before setting up the environment | n/a |
| **`CLEARML_SKIP_GIT_INST`** | A flag to skip the automatic installation of `git`. Set to `1` to skip and use the prepackaged static git executable (includes LFS support). | `0` |
| **`CLEARML_FORCE_STATIC_GIT_BIN`** | If set to `1` Always use the prepackaged static git executable (includes LFS support). | `0` |
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
| **`UV_INDEX`** | Equivalent to the `--extra-index-url` command-line argument. A space-separated list of URLs `uv` will use as additional indexes. | N/A |
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

## **Installation**

To install the package, execute the following command:

```bash
pip install clearml-agent-bootstrap
```

## **Build Process**

### **Configurations**

The static binary build uses the following component versions:

  - `GIT_VERSION="2.50.0"`
  - `GIT_LFS_VERSION="3.7.0"`
  - `PCRE_VERSION="10.45"`
  - `CURL_VERSION="8.11.0"`
  - `DROPBEAR_VER="DROPBEAR_2025.88"`
  - `OPENSSH_SFTP_VER="V_10_0_P2"`


The `uv` version is automatically synchronized with the latest version from its public Git repository.

### **Build**

To build the package from source, use the provided script:

*Step one - Updating UV binaries and compiling a staticaly linked `git` binary*

```bash
cd build-scripts
GIT_VERSION="2.50.0" GIT_LFS_VERSION="3.7.0" PCRE_VERSION="10.45" CURL_VERSION="8.11.0" ./build_all.sh
cd ..
```

*Step two - Build python wheel for distribution*
```bash
python3 -m build -w
```

*Step three - Optional - Grab the `bootstrap` and package it into a container for Kubernetes bootstrap operators*
```bash
cp -R bootstrap target_folder/
```

### **Package standalone python binaries**

Download and package only the relevant python builds for easier distribution*

1. download and prepare the meta-data.json
```bash
cd build-scripts
python3 download_standalone_pythons_for_uv.py "https://download.clear.ml/cpython_builds/releases/" "cpython_builds/releases/" "cpython_builds/download-metadata.json"
cd ..
```
2. Place the `cpython_builds/` directory on your http/s server

3. Set the `clearml_agent` to use the packaged UV python binary server by setting the following in your `clearml.conf` or via the clearml vault:
```
agent.bootstrap.uv_python_meta_file: "https://download.clear.ml/cpython_builds/cpython_builds/download-metadata.json"
```

### **Package standalone ssh user mode**

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

## **Installation**

After installing the packages, you can start the `clearml-agent` in daemon mode.

```bash
pip install clearml-agent-bootstrap "clearml-agent>=2.1"
```

### manually unpacking

```bash
python3 -c "from clearml_agent_bootstrap import install; install('target_folder')"
```


### **Testing**

The bootstrap script can be tested within various Docker environments. Below are examples for several supported distributions:

**Ubuntu**

```bash
docker run -it -v $(pwd)/bootstrap:/.clearml.bootstrap:ro -e CLEARML_BOOTSTRAP_DIR=/.clearml.bootstrap ubuntu:24.04 bash -c "\$CLEARML_BOOTSTRAP_DIR/bootstrap.sh --help"
```

**Rocky Linux**

```bash
docker run -it -v $(pwd)/bootstrap:/.clearml.bootstrap:ro -e CLEARML_BOOTSTRAP_DIR=/.clearml.bootstrap rockylinux/rockylinux:9.5 bash -c "\$CLEARML_BOOTSTRAP_DIR/bootstrap.sh --help"
```

**Fedora**

```bash
docker run -it -v $(pwd)/bootstrap:/.clearml.bootstrap:ro -e CLEARML_BOOTSTRAP_DIR=/.clearml.bootstrap fedora:42 bash -c "\$CLEARML_BOOTSTRAP_DIR/bootstrap.sh --help"
```

**Alpine**

```bash
docker run -it -v $(pwd)/bootstrap:/.clearml.bootstrap:ro -e CLEARML_BOOTSTRAP_DIR=/.clearml.bootstrap alpine:latest bash -c "\$CLEARML_BOOTSTRAP_DIR/bootstrap.sh --help"
```

-----
