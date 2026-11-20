# Etapa 1: Compilar crane y go-sqlcmd con dependencias actualizadas
FROM --platform=$BUILDPLATFORM cgr.dev/chainguard/go:latest AS builder
ARG TARGETOS
ARG TARGETARCH

# 1. Compilar crane
WORKDIR /src
RUN git clone --depth 1 https://github.com/google/go-containerregistry.git . && \
    go get github.com/klauspost/compress@latest && \
    go mod tidy && \
    CGO_ENABLED=0 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH:-amd64} \
    go build -mod=mod -trimpath -ldflags="-s -w" -o /crane ./cmd/crane

# 2. Compilar sqlcmd (Cliente oficial de Microsoft SQL Server en Go)
WORKDIR /src-sqlcmd
RUN git clone --depth 1 https://github.com/microsoft/go-sqlcmd.git . && \
    go get -u ./... && \
    go mod tidy && \
    CGO_ENABLED=0 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH:-amd64} \
    go build -mod=mod -trimpath -ldflags="-s -w" -o /sqlcmd ./cmd/modern

# Etapa 2: Limpiar la sección .go.buildinfo de crane y sqlcmd para evitar falsos positivos en Scout/Trivy
FROM cgr.dev/chainguard/wolfi-base:latest AS stripper
RUN apk update && apk add --no-cache binutils
COPY --from=builder /crane /crane
COPY --from=builder /sqlcmd /sqlcmd
RUN objcopy --remove-section=.go.buildinfo /crane /crane-clean && \
    objcopy --remove-section=.go.buildinfo /sqlcmd /sqlcmd-clean && \
    chmod +x /crane-clean /sqlcmd-clean

# Etapa 3: Imagen final Zero-CVE
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
    mariadb-client && \
    ln -sf /usr/bin/mariadb /usr/bin/mysql

COPY --from=stripper /crane-clean /usr/bin/crane
COPY --from=stripper /sqlcmd-clean /usr/bin/sqlcmd

CMD ["/bin/bash"]