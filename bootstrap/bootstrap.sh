#!/usr/bin/env bash

CMD_ARGS="$@"

# global environment variables for SSL (do not set if they do not exist
if [ -n "$SSL_CERT_FILE" ]; then
  export SSL_CERT_FILE="${SSL_CERT_FILE}"
fi
if [ -n "$SSL_CLIENT_CERT" ]; then
  export SSL_CLIENT_CERT="${SSL_CLIENT_CERT}"
fi
if [ -n "$ALL_PROXY" ]; then
  export ALL_PROXY="${ALL_PROXY}"
fi

# Store original UV
_UV_CONFIG_FILE="${UV_CONFIG_FILE}"
_UV_UNMANAGED_INSTALL="${UV_UNMANAGED_INSTALL}"
_UV_INSTALL_DIR="${UV_INSTALL_DIR}"
_UV_NO_BUILD_PACKAGE="${UV_NO_BUILD_PACKAGE}"
_UV_BREAK_SYSTEM_PACKAGES="${UV_BREAK_SYSTEM_PACKAGES}"
_UV_PYTHON_INSTALL_BIN="${UV_PYTHON_INSTALL_BIN}"
_CLEARML_APT_INSTALL="${CLEARML_APT_INSTALL}"

# bootstrap configs
  export CLEARML_BOOTSTRAP_DIR="${CLEARML_BOOTSTRAP_DIR:-/.clearml.bootstrap}"

# print bom.yaml
  if [ -f "$CLEARML_BOOTSTRAP_DIR/bom.yaml" ]; then
    echo "Bootstrap BOM versions"
    cat "$CLEARML_BOOTSTRAP_DIR/bom.yaml"
  fi
  export CLEARML_BOOTSTRAP_RO_UV="${CLEARML_BOOTSTRAP_RO_UV:-$CLEARML_BOOTSTRAP_DIR/uv}"
  export CLEARML_BOOTSTRAP_RO_GIT="${CLEARML_BOOTSTRAP_RO_GIT:-$CLEARML_BOOTSTRAP_DIR/git}"
  export CLEARML_BOOTSTRAP_RO_SSHD="${CLEARML_BOOTSTRAP_RO_SSHD:-$CLEARML_BOOTSTRAP_DIR/dropbear}"
  export CLEARML_BOOTSTRAP_CACHE_DIR="${CLEARML_BOOTSTRAP_CACHE_DIR:-/tmp/.clearml.bootstrap.cache}"
  # example: CLEARML_PYTHON_VER="3.12"
  export CLEARML_PYTHON_VER="${CLEARML_PYTHON_VER:-3.12}"
  # example: CLEARML_UPDATE_UV="1"
  export CLEARML_UPDATE_UV="${CLEARML_UPDATE_UV:-}"
  # example CLEARML_PIP_VER="\"pip<21 ; python_version < '3.11'\" \"pip<26 ; python_version >= '3.10'\""
  export CLEARML_PIP_VER="${CLEARML_PIP_VER:--U \"pip<21 ; python_version < '3.11'\" \"pip<26 ; python_version >= '3.10'\"}"
  export CLEARML_AGENT_VERSION="${CLEARML_AGENT_VERSION:-clearml_agent}"

# cache folders
  export UV_PYTHON_CACHE_DIR="$CLEARML_BOOTSTRAP_CACHE_DIR/uv_python/"
  export UV_CACHE_DIR="$CLEARML_BOOTSTRAP_CACHE_DIR/uv/"

# reset UV to controlled environment
  export UV_UNMANAGED_INSTALL="/tmp/.clearml.inst"
  export UV_INSTALL_DIR="$UV_UNMANAGED_INSTALL/uv"
  export UV_PYTHON_INSTALL_DIR="$UV_UNMANAGED_INSTALL/python"

# networking TLS certification bypass option
  # export UV_NATIVE_TLS="${UV_NATIVE_TLS:-1}"
  # export UV_INSECURE_HOST="${UV_INSECURE_HOST}"
  # export GIT_SSL_NO_VERIFY="${GIT_SSL_NO_VERIFY}"

# UV installer (should point to the file server"
  # export UV_INSTALLER_GHE_BASE_URL="${UV_INSTALLER_GHE_BASE_URL}"
  # export UV_INSTALLER_GITHUB_BASE_URL="${UV_INSTALLER_GITHUB_BASE_URL}"

  # pointer to all the python compiled binaries e.g. https://github.com/astral-sh/python-build-standalone/releases/download
  # example to assets to be put under our file server: https://github.com/astral-sh/python-build-standalone/releases/tag/20250612
  # export UV_PYTHON_INSTALL_MIRROR="${UV_PYTHON_INSTALL_MIRROR}"

  # control the list of links from the from a served JSON file, should be stored on the file server as well
  # example file: https://github.com/astral-sh/uv/blob/main/crates/uv-python/download-metadata.json
  # export UV_PYTHON_DOWNLOADS_JSON_URL="${UV_PYTHON_DOWNLOADS_JSON_URL}"

# override local repositories
  # export UV_DEFAULT_INDEX="${UV_DEFAULT_INDEX}"
  # export UV_INDEX="${UV_INDEX}"
  # export UV_PYPY_INSTALL_MIRROR="${UV_PYPY_INSTALL_MIRROR}"

# customization, allow user to have custom bootstrap command to be executed before bootstrap execution but after initial environment variable setup
  # CLEARML_BOOTSTRAP_CUSTOM_CMD is evaluated as a single line command using `eval` (in the context of the bootstrap script)
  # CLEARML_BOOTSTRAP_CUSTOM_CMD_BASE64 is evaluated by decoding base64 and piping into eval

# customization, allow user to have custom shell command to be executed just before the agent is starting but after else is configured
  # CLEARML_PRE_CUSTOM_CMD is evaluated as a single line command using `eval` (in the context of the bootstrap script)
  # CLEARML_PRE_CUSTOM_CMD_BASE64 is evaluated by decoding base64 and piping into eval

# Secure bootup process, pass execution script to be executed after bootstrap is completed and before any user code is executed
  # example: CLEARML_SECURE_PRE_CLEANUP_CMD="\$LOCAL_PYTHON /mounted/cleanup_script.py"


# building from source might fail so we disable it
export UV_NO_BUILD_PACKAGE="${UV_NO_BUILD_PACKAGE:-1}"
export UV_BREAK_SYSTEM_PACKAGES=1
export PIP_BREAK_SYSTEM_PACKAGES=1
export UV_PYTHON_INSTALL_BIN=0

# determine if we are using SH or Bash compatible for execution
_SHELL="${SHELL:-/bin/bash}"
if [ -z "$SHELL" ] && [ "$(echo {A,B})" != "A B" ]; then
  _SHELL="/bin/sh"
fi
echo SHELL="$_SHELL"

# check networking ca-certification files
if [ -z "$SSL_CERT_FILE" ]; then
  if [ -n "$CURL_CA_BUNDLE" ]; then
      export SSL_CERT_FILE="$CURL_CA_BUNDLE"
  elif [ -n "$REQUESTS_CA_BUNDLE" ]; then
      export SSL_CERT_FILE="$REQUESTS_CA_BUNDLE"
  else
    if [ -f /etc/ssl/certs/ca-certificates.crt ]; then
        export SSL_CERT_FILE="/etc/ssl/certs/ca-certificates.crt"
    elif [ -f /etc/pki/tls/certs/ca-bundle.crt ]; then
        export SSL_CERT_FILE="/etc/pki/tls/certs/ca-bundle.crt"
    elif [ -f /etc/ssl/cert.pem ]; then
        export SSL_CERT_FILE="/etc/ssl/cert.pem"
    fi
  fi
fi

# networking ca-certification files env var
  if [ -z "$GIT_SSL_CAINFO" ]; then
    if [ -n "$SSL_CERT_FILE" ]; then
        export GIT_SSL_CAINFO="$SSL_CERT_FILE"
    elif [ -n "$CURL_CA_BUNDLE" ]; then
        export GIT_SSL_CAINFO="$CURL_CA_BUNDLE"
    fi
  fi
  if [ -z "$REQUESTS_CA_BUNDLE" ]; then
    if [ -n "$SSL_CERT_FILE" ]; then
        export REQUESTS_CA_BUNDLE="$SSL_CERT_FILE"
    elif [ -n "$CURL_CA_BUNDLE" ]; then
        export REQUESTS_CA_BUNDLE="$CURL_CA_BUNDLE"
    fi
  fi

# if we have secure bootup process, do not run anything before secure cleanup is executed
if [ -n "$CLEARML_SECURE_PRE_CLEANUP_CMD" ]; then
  CLEARML_APT_INSTALL=""
  LOCAL_PYTHON=""
fi

# set the package cmd line based on the distro
if command -v apt-get >/dev/null 2>&1; then
  echo "Binary::apt::APT::Keep-Downloaded-Packages \"true\";" > /etc/apt/apt.conf.d/docker-clean
  export DEBIAN_FRONTEND=noninteractive
  if [ "$(id -u)" -eq 0 ]; then
    PKG_INSTALL_CMD="(\$APT_UPDATE_CALLED || apt-get update -y) && apt-get install -y"
  else
    PKG_INSTALL_CMD="(\$APT_UPDATE_CALLED || sudo apt-get update -y) && sudo apt-get install -y"
  fi
elif command -v dnf >/dev/null 2>&1; then
  if [ "$(id -u)" -eq 0 ]; then
    PKG_INSTALL_CMD="dnf install -y"
  else
    PKG_INSTALL_CMD="sudo dnf install -y"
  fi
elif command -v yum >/dev/null 2>&1; then
  if [ "$(id -u)" -eq 0 ]; then
    PKG_INSTALL_CMD="yum install -y"
  else
    PKG_INSTALL_CMD="sudo yum install -y"
  fi
elif command -v apk >/dev/null 2>&1; then
  if [ "$(id -u)" -eq 0 ]; then
    PKG_INSTALL_CMD="apk update && apk add"
  else
    PKG_INSTALL_CMD="(\$APT_UPDATE_CALLED || sudo apk update) && sudo apk add"
  fi
else
    PKG_INSTALL_CMD=
fi


# run custom script here unless secure bootup
if [ -z "$CLEARML_SECURE_PRE_CLEANUP_CMD" ]; then
  # custom bash boot script
  if [ -n "$CLEARML_BOOTSTRAP_CUSTOM_CMD" ]; then
    eval "$CLEARML_BOOTSTRAP_CUSTOM_CMD"
  fi
  # custom bash boot script (base64 format)
  if [ -n "$CLEARML_BOOTSTRAP_CUSTOM_CMD_BASE64" ]; then
    eval "$(echo "$CLEARML_BOOTSTRAP_CUSTOM_CMD_BASE64" | base64 -d)"
  fi
fi

CLEARML_SKIP_CA_CERT_INST="${CLEARML_SKIP_CA_CERT_INST:-0}"
if [ -n "${CLEARML_SKIP_CA_CERT_INST}" ] && [ "${CLEARML_SKIP_CA_CERT_INST}" -gt 0 ]; then 
  echo "INFO: CLEARML_SKIP_CA_CERT_INST=$CLEARML_SKIP_CA_CERT_INST skipping ca-certificates install"
else
  if [ -n "$CLEARML_APT_INSTALL" ]; then
    CLEARML_APT_INSTALL="$CLEARML_APT_INSTALL ca-certificates"
  else
    CLEARML_APT_INSTALL="ca-certificates"
  fi
fi

# any missing system package install now
APT_UPDATE_CALLED=false
if [ -n "$CLEARML_APT_INSTALL" ]; then
  eval "$PKG_INSTALL_CMD $CLEARML_APT_INSTALL"
  APT_UPDATE_CALLED=true
fi

# checking for GIT executable, install if needed
if ! command -v git >/dev/null 2>&1; then
    # check if we need to skip the git install
    CLEARML_SKIP_GIT_INST="${CLEARML_SKIP_GIT_INST:-0}"
    if [ -n "${CLEARML_SKIP_GIT_INST}" ] && [ "${CLEARML_SKIP_GIT_INST}" -gt 0 ]; then
      echo "INFO: CLEARML_SKIP_GIT_INST=$CLEARML_SKIP_GIT_INST skipping git install and using static git executable"
    else
      # try to install if we are root
      (eval "$PKG_INSTALL_CMD git") || echo "WARNING: failed installing git"
    fi
fi

# check if we need to use the static build
CLEARML_FORCE_STATIC_GIT_BIN="${CLEARML_FORCE_STATIC_GIT_BIN:-0}"
if ( [ -n "$CLEARML_FORCE_STATIC_GIT_BIN" ] && [ "$CLEARML_FORCE_STATIC_GIT_BIN" -gt 0 ] ) || ! command -v git >/dev/null 2>&1; then
  if [ -n "${CLEARML_FORCE_STATIC_GIT_BIN}" ] && [ "${CLEARML_FORCE_STATIC_GIT_BIN}" -gt 0 ]; then
    echo "INFO: CLEARML_FORCE_STATIC_GIT_BIN=$CLEARML_FORCE_STATIC_GIT_BIN using static git executable"
  elif ! ( [ -n "${CLEARML_SKIP_GIT_INST}" ] && [ "${CLEARML_SKIP_GIT_INST}" -gt 0 ] ); then
    echo "INFO: no git found/installed reverting to static git executable"
  fi

  # try x64 (x86-64) and a64 (aarch64) versions
  if "$CLEARML_BOOTSTRAP_RO_GIT/x64/bin/git" --version >/dev/null 2>&1; then
    export GIT_EXEC_PATH="$CLEARML_BOOTSTRAP_RO_GIT/x64/libexec/git-core"
    export GIT_TEMPLATE_DIR="$CLEARML_BOOTSTRAP_RO_GIT/x64/share/git-core/templates"
    GIT_PATH="$CLEARML_BOOTSTRAP_RO_GIT/x64/bin"
  elif "$CLEARML_BOOTSTRAP_RO_GIT/a64/bin/git" --version >/dev/null 2>&1; then
    export GIT_EXEC_PATH="$CLEARML_BOOTSTRAP_RO_GIT/a64/libexec/git-core"
    export GIT_TEMPLATE_DIR="$CLEARML_BOOTSTRAP_RO_GIT/a64/share/git-core/templates"
    GIT_PATH="$CLEARML_BOOTSTRAP_RO_GIT/a64/bin"
  else
    echo "WARNING: no git found! static git failed!"
  fi

  if [ -n "$GIT_PATH" ]; then
    if command -v git >/dev/null 2>&1; then
      export PATH="$GIT_PATH:$PATH"
    else
      export PATH="$PATH:$GIT_PATH"
    fi
  fi
fi

# test git
echo "INFO: testing git command"
git --version

# check if we already have python and pip installed
LOCAL_PYTHON="${LOCAL_PYTHON}"

# Check if python3 is installed
if [ -z "$LOCAL_PYTHON" ]; then
  i=30
  while [ "$i" -ge 5 ]; do    
    if command -v python3.$i >/dev/null 2>&1 ; then
      echo "INFO: Python 3.$i is installed"
      LOCAL_PYTHON="$(command -v python3.$i)"

      # Now check for pip3 or pip
      if $LOCAL_PYTHON -m pip --version >/dev/null 2>&1 ; then
        echo "INFO: Python 3.$i and pip are installed"
        break
      else
        echo "INFO: pip is MISSING from pre-installed python3.$i"
        LOCAL_PYTHON=""
      fi
    fi
    i=$((i - 1))
  done
  # if for some reason we failed and we still have python3, try just python3
  if [ -z "$LOCAL_PYTHON" ]; then
    if command -v python3 >/dev/null 2>&1 ; then
      echo "INFO: Python3 is installed"
      LOCAL_PYTHON="$(command -v python3)"

      # Now check for pip3 or pip
      if $LOCAL_PYTHON -m pip >/dev/null 2>&1 ; then
        echo "INFO: Python3 and pip are installed"
      else
        echo "INFO: pip is MISSING from pre-installed python"
        LOCAL_PYTHON=""
      fi
    fi
  fi
fi


# remove PEP 668 - system packages should always be optional inside container
rm -f /usr/lib/python3.*/EXTERNALLY-MANAGED


CLEARML_BOOTSTRAP_UV_EXEC=""
if [ -n "$LOCAL_PYTHON" ]; then

  # check python version
  PYTHON_VERSION_CHECK="$($LOCAL_PYTHON --version)"
  set -- $PYTHON_VERSION_CHECK
  for last; do :; done
  PYTHON_VERSION_CHECK="$last"

  IFS='.' read -r w1 w2 w3 << EOF
$PYTHON_VERSION_CHECK
EOF

  # check that we have at least python 3.6
  if [ "$w1" -ge 3 ] && [ "$w2" -ge 6 ]; then
    echo "INFO: Python version found $w1.$w2 is valid, validating pip version"

    if [ -n "$CLEARML_PIP_VER" ]; then
      echo "$LOCAL_PYTHON" -m pip install ${CLEARML_PIP_VER}
      eval "$LOCAL_PYTHON" -m pip install ${CLEARML_PIP_VER}
    fi

    # we have python and pip so we need to use it
    if $LOCAL_PYTHON -m pip install "$CLEARML_AGENT_VERSION" ; then
      echo "INFO: clearml-agent successfully installed"
    else
      echo ""
      echo "WARNING: Failed installing using preinstalled python, using bootstrap UV"
      echo ""
      LOCAL_PYTHON=
    fi
  else
    if [ -z "$PYTHON_VERSION_CHECK" ]; then
      echo "INFO: No installed python found, bootstrapping with UV"
    else
      echo "INFO: Installed python version is too old $PYTHON_VERSION_CHECK < 3.6 , bootstrapping with UV"
    fi
    LOCAL_PYTHON=
  fi
fi

# if we do not install environment using bootstrap UV
echo "INFO: selecting UV binary"

# find the correct UV version
for uv_dir in "$CLEARML_BOOTSTRAP_RO_UV"/*; do
  if [ -x "$uv_dir/uv" ]; then
      echo "INFO: trying: $uv_dir/uv"
      if "$uv_dir/uv" --version > /dev/null 2>&1 ; then
          CLEARML_BOOTSTRAP_UV_DIR="$uv_dir"
          CLEARML_UV_DIR_TMP="${CLEARML_UV_DIR_TMP:-/tmp/.bootstrap.uv}"
          if mkdir -p "$CLEARML_UV_DIR_TMP"; then
            cp "$uv_dir/uv" "$CLEARML_UV_DIR_TMP/uv"
          else
            CLEARML_UV_DIR_TMP="$CLEARML_BOOTSTRAP_UV_DIR"
          fi
          CLEARML_BOOTSTRAP_UV_EXEC="$CLEARML_UV_DIR_TMP/uv"
          if [ -f "$CLEARML_BOOTSTRAP_RO_UV/download-metadata.json" ]; then
            echo "Found custom UV python download repo"
            export UV_PYTHON_DOWNLOADS_JSON_URL="$CLEARML_BOOTSTRAP_RO_UV/download-metadata.json"
          fi
          echo "INFO: Found working UV : $CLEARML_BOOTSTRAP_UV_EXEC"
          export PATH="$CLEARML_UV_DIR_TMP:$PATH"
          echo "INFO: PATH=$PATH"
          break
      fi
  fi
done

if [ -z "$LOCAL_PYTHON" ]; then
  echo "INFO: bootstrapping with UV"

  # Leave if we failed to find the UV executable
  if [ -z "$CLEARML_BOOTSTRAP_UV_EXEC" ]; then
    echo "ERROR: COULD NOT FIND WORKING UV executable for the environment, LEAVING!"
	exit 1
  fi

  # update UV if we need to
  if [ -n "$CLEARML_UPDATE_UV" ] && [ "$CLEARML_UPDATE_UV" -gt 0 ] ; then

    CLEARML_BOOTSTRAP_UV_DIR="$UV_INSTALL_DIR"
    mkdir -p "$CLEARML_BOOTSTRAP_UV_DIR"
    cp -f "$CLEARML_BOOTSTRAP_UV_EXEC" "$CLEARML_BOOTSTRAP_UV_DIR/"
    CLEARML_BOOTSTRAP_UV_EXEC="$CLEARML_BOOTSTRAP_UV_DIR/uv"

    # get the UV version
    UV_VERSION_OUT=$("$CLEARML_BOOTSTRAP_UV_EXEC" --version)
    set -- $UV_VERSION_OUT
    UV_VERSION="${!#}"

    echo "{\"binaries\":[\"uv\"],\"binary_aliases\":{},\"cdylibs\":[],\"cstaticlibs\":[],\"install_layout\":\"flat\",\"install_prefix\":\"$CLEARML_BOOTSTRAP_UV_DIR\",\"modify_path\":true,\"provider\":{\"source\":\"cargo-dist\",\"version\":\"0.28.7-prerelease.1\"},\"source\":{\"app_name\":\"uv\",\"name\":\"uv\",\"owner\":\"astral-sh\",\"release_type\":\"github\"},\"version\":\"$UV_VERSION\"}" > "$CLEARML_BOOTSTRAP_UV_DIR/uv-receipt.json"

    CUR_DIR=$(pwd) ; cd "$CLEARML_BOOTSTRAP_UV_DIR" ; AXOUPDATER_CONFIG_WORKING_DIR="$CLEARML_BOOTSTRAP_UV_DIR" "$CLEARML_BOOTSTRAP_UV_EXEC" self update ; cd "$CUR_DIR"
  fi

  # install a new PYTHON with pip
  "$CLEARML_BOOTSTRAP_UV_EXEC" python install "$CLEARML_PYTHON_VER"
  LOCAL_PYTHON=$("$CLEARML_BOOTSTRAP_UV_EXEC" python find --managed-python)
  "$CLEARML_BOOTSTRAP_UV_EXEC" pip install --python "$LOCAL_PYTHON" pip setuptools "$CLEARML_AGENT_VERSION"

  # debug print
  echo "INFO: New python environment install in: LOCAL_PYTHON=$LOCAL_PYTHON"

  # update path
  export PATH="$CLEARML_BOOTSTRAP_UV_DIR:$PATH"
fi

# set git to use static mapped git if it is not already installed or installation fails
echo "DEBUG: CLEARML_BOOTSTRAP_UV_EXEC=$CLEARML_BOOTSTRAP_UV_EXEC"
export CLEARML_BOOTSTRAP_UV_EXEC=$CLEARML_BOOTSTRAP_UV_EXEC

# set python to the new installed environment and use the agent's package manager
export LOCAL_PYTHON="$LOCAL_PYTHON"


if [ -z "$CLEARML_DROPBEAR_EXEC" ]; then
  # try x64 (x86-64) and a64 (aarch64) versions
  if "$CLEARML_BOOTSTRAP_RO_SSHD/x64/dropbearmulti" dropbear -V >/dev/null 2>&1; then
    CLEARML_DROPBEAR_DIR="$CLEARML_BOOTSTRAP_RO_SSHD/x64"
  elif "$CLEARML_BOOTSTRAP_RO_SSHD/a64/dropbearmulti" dropbear -V >/dev/null 2>&1; then
    CLEARML_DROPBEAR_DIR="$CLEARML_BOOTSTRAP_RO_SSHD/a64"
  else
    echo "WARNING: static sshd (dropbear) failed to found!"
  fi

  # copy into temp folder because the SSH server should not be executed from the mapped RO folder
  if [ -n "$CLEARML_DROPBEAR_DIR" ]; then
    CLEARML_DROPBEAR_EXEC_TMP="${CLEARML_DROPBEAR_EXEC_TMP:-/tmp/.dropbear}"
    mkdir -p "$CLEARML_DROPBEAR_EXEC_TMP"
    cp "$CLEARML_DROPBEAR_DIR"/* "$CLEARML_DROPBEAR_EXEC_TMP/"
    export CLEARML_DROPBEAR_EXEC="$CLEARML_DROPBEAR_EXEC_TMP/dropbearmulti"
    export SFTPSERVER_PATH="$CLEARML_DROPBEAR_EXEC_TMP/sftp-server"
  fi
fi

#################################################################################


# restore original UV
unset CLEARML_BOOTSTRAP_DIR
unset CLEARML_BOOTSTRAP_RO_UV
unset CLEARML_BOOTSTRAP_RO_GIT
unset CLEARML_BOOTSTRAP_RO_SSHD
unset CLEARML_AGENT_VERSION
unset CLEARML_BOOTSTRAP_CACHE_DIR
if [ -z "$_UV_CONFIG_FILE" ]; then
  unset UV_CONFIG_FILE
  unset _UV_CONFIG_FILE
else
  export UV_CONFIG_FILE="${_UV_CONFIG_FILE}"
  unset _UV_CONFIG_FILE
fi
if [ -z "$_UV_UNMANAGED_INSTALL" ]; then
  unset UV_UNMANAGED_INSTALL
  unset _UV_UNMANAGED_INSTALL
else
  export UV_UNMANAGED_INSTALL="${_UV_UNMANAGED_INSTALL}"
  unset _UV_UNMANAGED_INSTALL
fi
if [ -z "$_UV_INSTALL_DIR" ]; then
  unset UV_INSTALL_DIR
  unset _UV_INSTALL_DIR
else
  export UV_INSTALL_DIR="${_UV_INSTALL_DIR}"
  unset _UV_INSTALL_DIR
fi
if [ -z "$_UV_NO_BUILD_PACKAGE" ]; then
  unset UV_NO_BUILD_PACKAGE
  unset _UV_NO_BUILD_PACKAGE
else
  export UV_NO_BUILD_PACKAGE="${_UV_NO_BUILD_PACKAGE}"
  unset _UV_NO_BUILD_PACKAGE
fi
if [ -z "$_UV_BREAK_SYSTEM_PACKAGES" ]; then
  unset UV_BREAK_SYSTEM_PACKAGES
  unset _UV_BREAK_SYSTEM_PACKAGES
else
  export UV_BREAK_SYSTEM_PACKAGES="${_UV_BREAK_SYSTEM_PACKAGES}"
  unset _UV_BREAK_SYSTEM_PACKAGES
fi
if [ -z "$_UV_PYTHON_INSTALL_BIN" ]; then
  unset UV_PYTHON_INSTALL_BIN
  unset _UV_PYTHON_INSTALL_BIN
else
  export UV_PYTHON_INSTALL_BIN="${_UV_PYTHON_INSTALL_BIN}"
  unset _UV_PYTHON_INSTALL_BIN
fi

# run the secure bootup script here after we completed the bootstrap process
if [ -n "$CLEARML_SECURE_PRE_CLEANUP_CMD" ]; then
  eval "$CLEARML_SECURE_PRE_CLEANUP_CMD"

  # NOW, we can run custom script, only AFTER secure bootup script was executed
  if [ -n "$CLEARML_BOOTSTRAP_CUSTOM_CMD" ]; then
    eval "$CLEARML_BOOTSTRAP_CUSTOM_CMD"
  fi
  # custom bash boot script (base64 format)
  if [ -n "$CLEARML_BOOTSTRAP_CUSTOM_CMD_BASE64" ]; then
    eval "$(echo "$CLEARML_BOOTSTRAP_CUSTOM_CMD_BASE64" | base64 -d)"
  fi
  
  # Now check if we were supposed to also install something (same order as before, fist pre cmd then install package)
  if [ -n "$_CLEARML_APT_INSTALL" ]; then
    eval "$PKG_INSTALL_CMD $_CLEARML_APT_INSTALL"
  fi
fi

# custom user script
if [ -n "$CLEARML_PRE_CUSTOM_CMD" ]; then
  eval "$CLEARML_PRE_CUSTOM_CMD"
fi
# custom bash boot script (base64 format)
if [ -n "$CLEARML_PRE_CUSTOM_CMD_BASE64" ]; then
  eval "$(echo "$CLEARML_PRE_CUSTOM_CMD_BASE64" | base64 -d)"
fi

# final env cleanup
unset CLEARML_SECURE_PRE_CLEANUP_CMD
unset CLEARML_BOOTSTRAP_CUSTOM_CMD
unset CLEARML_BOOTSTRAP_CUSTOM_CMD_BASE64
unset CLEARML_PRE_CUSTOM_CMD
unset CLEARML_PRE_CUSTOM_CMD_BASE64
unset CLEARML_APT_INSTALL

# run the agent
echo "$LOCAL_PYTHON" -u -m clearml_agent "$CMD_ARGS"
exec $LOCAL_PYTHON -u -m clearml_agent $CMD_ARGS
