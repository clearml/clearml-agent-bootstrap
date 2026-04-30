# Override ALPINE_BASE_IMAGE to use a different base (e.g. `alpine`) when DHI is unavailable.
ARG ALPINE_BASE_IMAGE=dhi.io/alpine-base
ARG DHI_ALPINE_VERSION=3.23
FROM ${ALPINE_BASE_IMAGE}:${DHI_ALPINE_VERSION}

# Set working directory to nonroot user home
WORKDIR /home/nonroot/

# Set bootstrap directory path
ENV CLEARML_BOOTSTRAP_DIR=/home/nonroot/.clearml.bootstrap

# Copy bootstrap scripts and config from local bootstrap folder
COPY ../bootstrap/ bootstrap/

# Copy bootstrap data to $CLEARML_BOOTSTRAP_DIR at runtime
CMD ["/bin/sh", "-c", "mkdir -p \"$CLEARML_BOOTSTRAP_DIR\" && cp -R bootstrap/* \"$CLEARML_BOOTSTRAP_DIR\" && echo \"Bootstrap data copied to $CLEARML_BOOTSTRAP_DIR\""]
