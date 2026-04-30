ARG ALPINE_VERSION=3.22.1
FROM alpine:${ALPINE_VERSION} AS builder

# Install build dependencies
RUN apk add --no-cache \
    bash gcc musl-dev make openssl-dev \
    perl tar wget gettext autoconf asciidoc xmlto \
    zlib-static zstd-static expat-static perl wget openssl-libs-static musl-dev git \
    build-base linux-headers gnupg zstd-dev libgcc musl-dev libc6-compat cmake patchelf ca-certificates curl

ARG USE_CCACHE=false
RUN if [ "$USE_CCACHE" = "true" ]; then apk add --no-cache ccache; fi


# ---------------------------------------------------------
# Install Python via uv (same as Alpine version)
# ---------------------------------------------------------
ENV PIP_BREAK_SYSTEM_PACKAGES=1
ENV PATH=/root/.local/bin:$PATH
ENV UV_INSTALL_DIR="/root/.local/bin"
WORKDIR /root
ARG PYTHON_VERSION=3.12
RUN mkdir -p $UV_INSTALL_DIR && curl -LsSf https://astral.sh/uv/install.sh | sh && \
    uv python install $PYTHON_VERSION && uv python pin $PYTHON_VERSION && uv run python3 -m pip install --break-system-packages virtualenv

# ---------------------------------------------------------
# Install Nuitka
# ---------------------------------------------------------
ARG NUITKA_VERSION=2.8.9
RUN uv run python3 -m virtualenv ./venv-nuitka && . ./venv-nuitka/bin/activate && pip install --upgrade pip setuptools && pip install "nuitka==$NUITKA_VERSION"

RUN apk add --no-cache python3-dev


# code
ARG BUILD_VER=""
COPY . /clearml-agent
WORKDIR /clearml-agent
RUN uv run python3 -m virtualenv "./venv-build" && . "./venv-build/bin/activate" && pip install --upgrade pip setuptools

RUN . "./venv-build/bin/activate" && \
    ARCH=$(uname -m) ; \
    if [[ "$ARCH" == aarch64* ]] || [[ "$ARCH" == arm* ]]; then \
    echo "Overriding CFLAGS and LDSHARED to fix psutil on arm64" ; \
    export CFLAGS="-fno-strict-overflow -fno-strict-aliasing -DNDEBUG -g -O3 -Wall -O3 -fPIC" ; \
    export LDSHARED="gcc -pthread -shared -Wl,--exclude-libs,ALL -LModules/_hacl -fno-strict-overflow -fno-strict-aliasing -DNDEBUG -g -O3 -Wall -O3 -fPIC" ; \
    fi ; \
    if [ -n "$BUILD_VER" ] || [ -z "$(ls -A /clearml-agent)" ]; then \
    if [ -n "$BUILD_VER" ]; then \
    export BUILD_VER=" == $BUILD_VER"; \
    fi; \
    echo "INSTALLING CLEARML_AGENT VERSION: $BUILD_VER"; \
    pip install "clearml-agent$BUILD_VER"; \
    else \
    echo "INSTALLING CLEARML_AGENT FROM SOURCE"; \
    python3 setup.py bdist_wheel; \
    pip install ./dist/*.whl; \
    fi


# TODO: evaluate re-enabling LTO for release builds (smaller/faster binary, slower compile)
RUN . /root/venv-nuitka/bin/activate && nuitka --python-flag=isolated,-m --report=report.xml  --disable-plugin=anti-bloat  --company-name=ClearML --product-name=clearml-agent \
    --output-filename=clearml_agent.bin \
    --jobs="$(nproc)" --lto=no \
    --onefile --standalone --follow-imports --include-package=clearml_agent --include-package=psutil --include-package=virtualenv \
    --include-package=idna --include-package=certifi --include-package=filelock --include-package=platformdirs --include-package=distlib \
    --include-package=urllib3  --include-package=setuptools  --include-package-data=clearml_agent  --include-package-data=certifi  \
    /clearml-agent/venv-build/lib/python3.*/site-packages/clearml_agent

# Test
RUN ./clearml_agent.bin --help


# export stage
FROM scratch AS export-stage
COPY --from=builder /clearml-agent/clearml_agent.bin clearml_agent.bin
