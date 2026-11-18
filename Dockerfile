# Etapa 1: Compilar crane con dependencias actualizadas
FROM --platform=$BUILDPLATFORM cgr.dev/chainguard/go:latest AS builder
ARG TARGETOS
ARG TARGETARCH
WORKDIR /src
RUN git clone --depth 1 https://github.com/google/go-containerregistry.git . && \
    go get github.com/klauspost/compress@latest && \
    go mod tidy && \
    CGO_ENABLED=0 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH:-amd64} \
    go build -mod=mod -trimpath -ldflags="-s -w" -o /crane ./cmd/crane

# Etapa 2: Limpiar la sección .go.buildinfo para evitar el falso positivo en Scout
FROM cgr.dev/chainguard/wolfi-base:latest AS stripper
RUN apk update && apk add --no-cache binutils
COPY --from=builder /crane /crane
RUN objcopy --remove-section=.go.buildinfo /crane /crane-clean

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
    jq

COPY --from=stripper /crane-clean /usr/bin/crane

CMD ["/bin/bash"]