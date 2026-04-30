ARG NGINX_VERSION=alpine
FROM nginx:${NGINX_VERSION}

# Install OpenSSL for optional self-signed certs
RUN apk add --no-cache openssl

# Build-time arguments
ARG CONTENT_DIR=/usr/share/nginx/html
ARG SERVER_NAME=localhost
ARG ENABLE_SSL=false
ARG VSCODE_DIR=vscode_build
ARG CPYTHON_DIR=cpython_build

# Runtime environment variables
ENV CONTENT_DIR=${CONTENT_DIR} \
    SERVER_NAME=${SERVER_NAME} \
    SERVER_HOST=${SERVER_HOST} \
    ENABLE_SSL=${ENABLE_SSL} \
    SSL_CERT_PATH=/etc/ssl/private/server.crt \
    SSL_KEY_PATH=/etc/ssl/private/server.key

# Copy static files
COPY $CPYTHON_DIR/ ${CONTENT_DIR}/$CPYTHON_DIR/
COPY $VSCODE_DIR/ ${CONTENT_DIR}/$VSCODE_DIR/


# Generate config and optional cert
RUN rm /etc/nginx/conf.d/default.conf && /bin/sh -c '\
  if [ "$ENABLE_SSL" = "self-signed" ]; then \
    mkdir -p /etc/ssl/private && \
    openssl req -x509 -nodes -days 365 \
      -subj "/CN=$SERVER_NAME" \
      -newkey rsa:2048 \
      -keyout $SSL_KEY_PATH \
      -out $SSL_CERT_PATH; \
  fi && \
  if [ "$ENABLE_SSL" = "self-signed" ] || [ "$ENABLE_SSL" = "true" ]; then \
    echo -e "server {\n\
    listen 80;\n\
    server_name \${SERVER_NAME};\n\
    return 301 https://\\\$host\\\$request_uri;\n\
}\n\
server {\n\
    listen 443 ssl;\n\
    server_name $SERVER_NAME;\n\
    ssl_certificate $SSL_CERT_PATH;\n\
    ssl_certificate_key $SSL_KEY_PATH;\n\
    root $CONTENT_DIR;\n\
    index index.html;\n\
    location / { try_files \\\$uri \\\$uri/ =404; }\n\
}" > /etc/nginx/conf.d/default.conf; \
  else \
    echo -e "server {\n\
    listen 80;\n\
    server_name \${SERVER_NAME};\n\
    root $CONTENT_DIR;\n\
    index index.html;\n\
    location / { try_files \$uri \$uri/ =404; }\n\
}" > /etc/nginx/conf.d/default.conf; \
  fi'

EXPOSE 80 443
CMD ["sh", "-c", "echo \"s|http://localhost:80/|$SERVER_HOST|g\" && sed -i \"s|http://localhost:80/|$SERVER_HOST|g\" $CONTENT_DIR/cpython_build/download-metadata.json && nginx -g \"daemon off;\""]
