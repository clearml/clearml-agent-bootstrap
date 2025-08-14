FROM alpine:3.22.1 AS builder

# Install build dependencies
RUN apk add --no-cache \
  bash gcc musl-dev make openssl-dev \
  perl tar wget gettext autoconf asciidoc xmlto \
  zlib-static zstd-static expat-static perl wget openssl-libs-static musl-dev git \
  build-base gnupg zstd-dev libgcc musl-dev libc6-compat cmake

RUN apk add --no-cache \
    musl-dev \
    zlib-dev \
    tar \
    bzip2 \
    bash openssl-dev automake autoconf
    
# now we builf sftp-server from openssh-portable
ARG OPENSSH_SFTP_VER=V_10_0_P2
WORKDIR /openssh-${OPENSSH_SFTP_VER}
RUN mkdir -p /tmp/sftp-install/ && git clone --branch "${OPENSSH_SFTP_VER}" https://github.com/openssh/openssh-portable && cd openssh-portable && autoreconf && ./configure --enable-static --with-ldflags-after="-static -static-libstdc++ -static-libgcc -Wl,-Bstatic" && make -j$(nproc) sftp-server && strip sftp-server && cp sftp-server /tmp/sftp-install/sftp-server

# export stage
FROM scratch AS export-stage
COPY --from=builder /tmp/sftp-install/sftp-server /sftp-server
