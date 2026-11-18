FROM cgr.dev/chainguard/wolfi-base:latest

LABEL org.opencontainers.image.source="https://github.com/uledwin/nettools"
LABEL org.opencontainers.image.description="Lightweight zero-CVE network troubleshooting and container utility image based on Wolfi"
LABEL org.opencontainers.image.licenses="MIT"

RUN apk update && apk upgrade --no-cache && \
    apk add --no-cache \
    bash \
    curl \
    bind-tools \
    iputils \
    iproute2 \
    netcat-openbsd \
    mtr \
    tcpdump \
    iperf3 \
    socat \
    openssh-client \
    openssl \
    jq \
    crane

CMD ["/bin/bash"]