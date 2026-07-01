ARG APP_PLATFORM=linux/amd64

FROM --platform=${APP_PLATFORM} debian:trixie-slim AS builder

ARG C3_VERSION=0.8.1
ARG C3_SHA256=d2fd7cbf746d1e4e3cd6d5a3ff02298d6978fec810056cc056fa1732ae8fd0d2

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        ca-certificates \
        curl \
        tar \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://github.com/c3lang/c3c/releases/download/v${C3_VERSION}/c3-linux.tar.gz" -o /tmp/c3-linux.tar.gz \
    && echo "${C3_SHA256}  /tmp/c3-linux.tar.gz" | sha256sum -c - \
    && mkdir -p /opt/c3 /tmp/c3 \
    && tar -xzf /tmp/c3-linux.tar.gz -C /tmp/c3 \
    && cp -a /tmp/c3/*/. /opt/c3/ \
    && ln -s /opt/c3/c3c /usr/local/bin/c3c \
    && rm -rf /tmp/c3 /tmp/c3-linux.tar.gz

WORKDIR /src

COPY project.json ./
COPY csource ./csource
COPY lib ./lib
COPY src ./src
COPY test ./test

RUN c3c -O2 -g0 build todoc3

FROM --platform=${APP_PLATFORM} debian:trixie-slim AS runtime

RUN useradd --create-home --home-dir /data --shell /usr/sbin/nologin todoc3

COPY --from=builder /src/build/todoc3 /usr/local/bin/todoc3

WORKDIR /data
USER todoc3

ENTRYPOINT ["/usr/local/bin/todoc3"]
