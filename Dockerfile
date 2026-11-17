FROM cgr.dev/chainguard/wolfi-base:latest

LABEL org.opencontainers.image.source="https://github.com/TU_USUARIO/TU_REPO"
LABEL org.opencontainers.image.description="Imagen de diagnóstico de red (nettools) basada en Wolfi con 0 CVEs"
LABEL org.opencontainers.image.licenses="MIT"

RUN apk update && apk upgrade --no-cache && \
    apk add --no-cache \
    bash curl bind-tools iputils iproute2 netcat-openbsd \
    mtr tcpdump iperf3 socat openssh-client openssl jq crane

CMD ["/bin/bash"]