# 🛡️ uledwin/nettools — Wolfi Nettools (Zero-CVE Container Utility)

[![Build, Scan & Publish Nettools](https://github.com/uledwin/nettools/actions/workflows/publish.yml/badge.svg)](https://github.com/uledwin/nettools/actions/workflows/publish.yml)
[![Docker Pulls](https://img.shields.io/docker/pulls/uledwin/nettools?logo=docker&label=Docker%20Hub)](https://hub.docker.com/r/uledwin/nettools)
[![Docker Image Size](https://img.shields.io/docker/image-size/uledwin/nettools/latest?logo=docker&label=Image%20Size)](https://hub.docker.com/r/uledwin/nettools)
[![GHCR](https://img.shields.io/badge/GHCR-ghcr.io%2Fuledwin%2Fnettools-blue?logo=github)](https://github.com/uledwin/nettools/pkgs/container/nettools)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

Imagen ligera (~60 MB), multi-arquitectura (`linux/amd64`, `linux/arm64`) para diagnóstico de redes, pruebas de conexión a bases de datos, debugging en Kubernetes e inspección de registros OCI, construida sobre **[Chainguard Wolfi](https://github.com/chainguard-dev/wolfi-os)** bajo una política estricta de **0 CVEs** validada por **Trivy** y **Docker Scout**.

---

## ✨ Características de Seguridad y Cadena de Suministro

- **Zero-CVE Policy (`0C 0H 0M 0L`):** Escaneo obligatorio como *Quality Gate* en cada Pull Request y antes de cada publicación mediante **Aqua Trivy** (`ignore-unfixed: false`) y **Docker Scout CLI**.
- **Multi-Stage Patched Go Binaries:** `crane` y `sqlcmd` (`go-sqlcmd`) se compilan desde código fuente en una etapa aislada (`--platform=$BUILDPLATFORM`) con dependencias actualizadas (`go get -u`) y limpieza de `.go.buildinfo` mediante `objcopy` para eliminar falsos positivos `+incompatible`.
- **Supply Chain Attestations (SLSA & SBOM):** Cada imagen publicada incluye su inventario de paquetes (**SBOM**) y atestación de procedencia criptográfica (**SLSA Provenance**) generados automáticamente con Docker Buildx.
- **Actualizaciones Automáticas Semanales:** Reconstrucción programada todos los lunes (`03:00 UTC`) para incorporar los últimos parches de seguridad de los repositorios de Wolfi (`apk upgrade`).

---

## 🧰 Herramientas Incluidas

| Categoría | Paquetes / Binarios | Propósito |
| :--- | :--- | :--- |
| **DNS & Nombres** | `bind-tools` (`dig`, `nslookup`, `host`) | Resolución y depuración de registros DNS |
| **Conectividad & Rutas** | `iputils` (`ping`, `tracepath`), `iproute2` (`ip`, `ss`), `mtr` | Análisis de enrutamiento, latencia, interfaces y sockets |
| **Captura & Tráfico** | `tcpdump`, `iperf3`, `netcat-openbsd` (`nc`), `socat` | Captura de paquetes, pruebas de ancho de banda y túneles TCP/UDP |
| **HTTP, TLS & Cripto** | `curl`, `openssl`, `openssh-client` (`ssh`, `scp`) | Pruebas de endpoints REST/gRPC, inspección de certificados X.509 y acceso remoto |
| **Bases de Datos** | `mariadb-client` (`mariadb`, `mysql`), `sqlcmd` | Pruebas de conectividad, autenticación y consultas en MySQL, MariaDB y SQL Server |
| **Contenedores & JSON** | `crane`, `jq`, `bash` | Inspección y copia de manifiestos en registros OCI y procesamiento JSON |

---

## 🚀 Uso Rápido

### 1. Ejecutar contenedor interactivo en Docker

Desde **Docker Hub**:
```bash
docker run --rm -it uledwin/nettools:latest
```

Desde **GitHub Container Registry (GHCR)**:
```bash
docker run --rm -it ghcr.io/uledwin/nettools:latest
```

### 2. Uso en Kubernetes (Pod efímero de diagnóstico)

Lanzar un pod temporal de debugging dentro de un namespace:
```bash
kubectl run nettools-debug --rm -i --tty --image=uledwin/nettools:latest -- /bin/bash
```

Adjuntar como **Ephemeral Debug Container** a un pod existente (ej. un contenedor *distroless* sin shell):
```bash
kubectl debug -it <nombre-del-pod> --image=uledwin/nettools:latest --target=<nombre-del-contenedor>
```

### 3. Pruebas de conexión a Bases de Datos

* **MySQL / MariaDB:**
  ```bash
  # Conexión interactiva (solicita contraseña de forma segura)
  mariadb -h <host-db> -P 3306 -u <usuario> -p -e "SELECT VERSION() AS db_version, NOW() AS server_time;"

  # Si el servidor interno usa certificados TLS autofirmados (evita ERROR 2026):
  mariadb --skip-ssl -h <host-db> -P 3306 -u <usuario> -p -e "SHOW DATABASES;"

  # También disponible mediante el alias clásico (si pasas la contraseña por parámetro, escríbela pegada a -p):
  mysql -h <host-db> -P 3306 -u <usuario> -p -e "SELECT VERSION() AS db_version, NOW() AS server_time;"
  ```

* **Microsoft SQL Server / Azure SQL:**
  ```bash
  sqlcmd -S <host-db>,1433 -U <usuario> -P '<password>' -C -Q "SELECT @@VERSION AS sqlserver_version;"
  ```
  *(El flag `-C` confía en el certificado TLS del servidor sin requerir validación de CA raíz).*

---

## 🛠️ Guía de Desarrollo y Validación Local (Pre-PR Checklist)

Antes de abrir un Pull Request hacia `main`, todos los cambios deben cumplir con el checklist de seguridad y calidad configurado en [`.github/pull_request_template.md`](.github/pull_request_template.md). Ejecuta los siguientes pasos en tu entorno local:

### Paso 1: Construir la imagen localmente y verificar binarios
Verifica que el `Dockerfile` multi-etapa compile sin errores y comprueba que los binarios principales respondan correctamente:
```bash
docker build -t ult-nettools:v1 .
docker run --rm ult-nettools:v1 crane version
docker run --rm ult-nettools:v1 mariadb --version
docker run --rm ult-nettools:v1 sqlcmd --version
```

### Paso 2: Escaneo local con Aqua Trivy (Zero-CVE Gate)
Valida que tanto los paquetes del sistema operativo (`wolfi`) como los binarios compilados reporten **0 vulnerabilidades** (incluyendo aquellas sin parche):
```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $HOME/.cache/trivy:/root/.cache/ \
  aquasec/trivy:latest image \
  --scanners vuln \
  --severity CRITICAL,HIGH,MEDIUM \
  --exit-code 1 \
  ult-nettools:v1
```

### Paso 3: Escaneo local con Docker Scout CLI (Scout Gate)
Si no tienes el plugin de Docker Scout instalado localmente, instálalo e inicia sesión en Docker Hub:
```bash
curl -sSfL https://raw.githubusercontent.com/docker/scout-cli/main/install.sh | sh -s --
docker login -u <tu-usuario-dockerhub>
```

Ejecuta el análisis sobre la imagen local y verifica que el marcador sea **`0C 0H 0M 0L`** (`No vulnerable packages detected`):
```bash
docker scout cves local://ult-nettools:v1 --only-severity critical,high,medium --exit-code
```

### Paso 4: Validar compatibilidad Multi-Arquitectura (Opcional)
Para comprobar que la compilación cruzada (`linux/amd64` y `linux/arm64`) funciona sin enviar la imagen al registro:
```bash
docker buildx build --platform linux/amd64,linux/arm64 .
```

---

## 🔄 Arquitectura del Pipeline CI/CD

El flujo de trabajo en [`.github/workflows/publish.yml`](.github/workflows/publish.yml) opera en dos fases según el evento:

1. **En Pull Requests (`pull_request -> main`):**
   - Construye la imagen de prueba (`uledwin/nettools:scan-test`) utilizando la caché de GitHub Actions.
   - Ejecuta **Trivy** y **Docker Scout CLI** con `--exit-code`. Si se detecta cualquier vulnerabilidad `CRITICAL`, `HIGH` o `MEDIUM`, el check falla y bloquea el merge a `main`.
   - Omite los pasos de publicación a registros externos.
2. **En Merge a `main`, Ejecución Semanal (`cron`) o Manual (`workflow_dispatch`):**
   - Ejecuta la validación completa de seguridad.
   - Genera etiquetas dinámicas (`latest`, `sha-<commit>`, `YYYYMMDD`) y metadatos estándar OCI.
   - Compila para `linux/amd64` y `linux/arm64` adjuntando **SBOM** y **SLSA Provenance**, publicando simultáneamente en **Docker Hub** y **GHCR**.

---

## 📄 Licencia

Distribuido bajo la licencia **MIT**. Consulta el archivo [`LICENSE`](LICENSE) para más detalles.