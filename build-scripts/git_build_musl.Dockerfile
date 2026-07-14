ARG ALPINE_VERSION=3.22.1
ARG GO_VERSION=1.26
FROM alpine:${ALPINE_VERSION} AS builder

# Install build dependencies
RUN apk add --no-cache \
  bash gcc musl-dev make openssl-dev \
  perl tar wget gettext autoconf asciidoc xmlto \
  zlib-static zstd-static expat-static perl wget openssl-libs-static musl-dev git \
  build-base linux-headers gnupg zstd-dev libgcc musl-dev libc6-compat cmake


RUN git clone https://github.com/google/brotli.git && cd brotli && mkdir out && cd out && cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_SHARED_LIBS=OFF .. && cmake --build . --config Release -j$(nproc) && cmake --install . --prefix=/usr


# # PCRE2
ARG PCRE_VERSION=10.45
RUN wget https://github.com/PCRE2Project/pcre2/releases/download/pcre2-${PCRE_VERSION}/pcre2-${PCRE_VERSION}.tar.bz2 && tar -xjf pcre2-${PCRE_VERSION}.tar.bz2
#RUN find /usr -name 'libpcre2*' && rm /usr/lib/libpcre2-*.so* && find /usr -name 'libpcre2*'
RUN cd pcre2-${PCRE_VERSION} && cmake -DPCRE2_BUILD_PCRE2_8=ON -DBUILD_SHARED_LIBS=OFF -DCMAKE_INSTALL_PREFIX=/usr . && make -j$(nproc) && make install

# # Set CURL version to build
ARG CURL_VERSION=8.11.0

RUN wget https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz.asc
# convert mykey.asc to a .pgp file to use in verification
# this has a non-zero exit code if it fails, which will halt the script
# RUN gpg --no-default-keyring --yes -o ./curl.gpg --dearmor mykey.asc && gpg --no-default-keyring --keyring ./curl.gpg --verify curl-${CURL_VERSION}.tar.gz.asc

RUN rm -rf "curl-${CURL_VERSION}/" && tar xzf curl-${CURL_VERSION}.tar.gz

RUN apk add build-base clang openssl-dev nghttp2-dev nghttp2-static libssh2-dev libssh2-static perl && (apk add openssl-libs-static zlib-static || true)

RUN rm -f /usr/lib/pkgconfig/libpcre2-8.pc /usr/lib/pkgconfig/libpcre2-posix.pc
RUN find / -name 'libpcre2*'

RUN cd curl-${CURL_VERSION}/ && export CC=clang && LDFLAGS="-static -static-libgcc -static-libstdc++ -Wl,-Bstatic -L/usr/lib -ldl" PKG_CONFIG="pkg-config --static" ./configure --disable-shared --enable-static --disable-ldap --enable-ipv6 --enable-unix-sockets --with-ssl --with-libssh2 --with-brotli --with-zstd --disable-docs --disable-manual --without-libpsl && LDFLAGS="-static -static-libgcc -static-libstdc++ -all-static -Wl,-Bstatic" make -j$(nproc) V=1 && strip src/curl


RUN cd curl-${CURL_VERSION}/ && ls -lah src/curl && file src/curl && ldd src/curl
RUN cd curl-${CURL_VERSION}/ && ./src/curl -V
RUN cd curl-${CURL_VERSION}/ && make install


RUN apk add libpsl-static cmake

RUN cd / && git clone https://github.com/c-ares/c-ares.git && cd c-ares && cmake -DCMAKE_BUILD_TYPE=Release -DCARES_SHARED=OFF -DCARES_STATIC=ON . && make -j$(nproc) && make install


# Set GIT version to build
ARG GIT_VERSION=2.50.1

# Download and extract Git source
RUN wget https://mirrors.edge.kernel.org/pub/software/scm/git/git-${GIT_VERSION}.tar.gz && \
    tar -xzf git-${GIT_VERSION}.tar.gz


RUN apk add --no-cache expat-static expat-dev


WORKDIR /git-${GIT_VERSION}

RUN mkdir -p /tmp/libpcre2_so && (mv /usr/lib/libpcre2-*so* /tmp/libpcre2_so/ || echo "no /usr/lib/libpcre2-*.so*")
RUN rm -f /usr/lib/pkgconfig/libpcre2-8.pc /usr/lib/pkgconfig/libpcre2-posix.pc

RUN make configure && \
    ./configure --help && \
    (./configure --disable-shared --prefix=/usr \
                --with-curl \
                --with-expat \
                --with-openssl \
                --with-zlib --with-libpcre2=/pcre2-10.45 NO_GETTEXT=1 EXTLIBS="-static libz.a" LDFLAGS="-static -static-libstdc++ -static-libgcc -Wl,-Bstatic" LIBS="-Wl,-Bstatic -lbrotlidec -lbrotlicommon -lbrotlienc -lnghttp2 -lssh2 -lssl -lcrypto -ldl -lz -pthread -lzstd -lz" \
                NO_TCLTK=Yes || cat config.log) && cat Makefile



RUN rm "/usr/lib/libpcre2-*" || echo "no /usr/lib/libpcre2-*"
RUN find / -name '*pcre2*.a'

# NO_RUST=1: git 2.55 builds a Rust libgitcore.a via cargo by default; disable it
# (uses the C fallbacks) so we don't need a Rust toolchain in this static musl build.
RUN cat Makefile && make EXTLIBS="-static /usr/lib/libz.a /usr/lib/libpcre2-8.a /usr/lib/libpcre2-posix.a" NO_GETTEXT=1 NO_RUST=1 USE_LIBPCRE=0 USE_LIBPCRE2=0 V=1 -j$(nproc) git
RUN make install EXTLIBS="-static /usr/lib/libz.a /usr/lib/libpcre2-8.a /usr/lib/libpcre2-posix.a" NO_GETTEXT=1 NO_RUST=1 USE_LIBPCRE=0 USE_LIBPCRE2=0 V=1 -j$(nproc) DESTDIR=/tmp/git-install
RUN find /tmp/git-install -type f \( -perm -100 -o -perm -010 -o -perm -001 \)  -exec strip "$@" {} \;

RUN cp /tmp/libpcre2_so/* /usr/lib/

# TESTING
# RUN apk del git
# # Test: GIT_TEMPLATE_DIR=/tmp/git-install/usr/share/git-core/templates GIT_EXEC_PATH=/tmp/git-install/usr/libexec/git-core ./git clone https://...
# RUN cd /tmp/ && export GIT_EXEC_PATH=/tmp/git-install/usr/libexec/git-core && export GIT_TEMPLATE_DIR=/tmp/git-install/usr/share/git-core/templates && ls -laR && /tmp/git-install/usr/bin/git clone  https://github.com/google/brotli.git && ls -la ./brotli

# Build git-lfs from source instead of using the prebuilt release binary:
# upstream 3.7.0 binaries ship a vulnerable Go stdlib plus outdated
# golang.org/x/crypto and golang.org/x/net modules. Compiling with a current
# toolchain and bumped modules clears the known CVEs until a fixed upstream
# release exists.
FROM golang:${GO_VERSION}-alpine AS lfs-builder

RUN apk add --no-cache git

ARG GIT_LFS_VERSION=3.7.1
RUN git clone --depth 1 --branch v${GIT_LFS_VERSION} https://github.com/git-lfs/git-lfs.git /git-lfs

WORKDIR /git-lfs

ARG X_CRYPTO_VERSION=0.53.0
ARG X_NET_VERSION=0.56.0
RUN go get golang.org/x/crypto@v${X_CRYPTO_VERSION} golang.org/x/net@v${X_NET_VERSION} && go mod tidy

RUN CGO_ENABLED=0 go build -trimpath -ldflags "-s -w -X github.com/git-lfs/git-lfs/v3/config.GitCommit=$(git rev-parse HEAD)" -o /usr/local/bin/git-lfs .
RUN /usr/local/bin/git-lfs version

# export stage
FROM scratch AS export-stage
COPY --from=builder /tmp/git-install/usr/bin/git /bin/git
COPY --from=lfs-builder /usr/local/bin/git-lfs /bin/git-lfs
COPY --from=builder /tmp/git-install/usr/libexec/git-core /libexec/git-core
COPY --from=builder /tmp/git-install/usr/share/git-core/ /share/git-core
