#!/usr/bin/env bash
# Modul 7: Docker Desktop, Lizenz und Alternativen. Echt: Docker Engine (docker context, docker info), Podman 4.9.3 mit einem aus Docker geladenen Image.
# Lizenzstand von Docker Desktop: nur nach der Seite docs.docker.com (Abruf 20.11.2026, Zusammenfassung), Wortlaut nicht gelesen.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Docker Engine unter Linux: Daemon, Kontext, Betriebssystem"
docker context ls --format '{{.Name}}: {{.DockerEndpoint}}'
docker info --format 'Server: {{.ServerVersion}}, Betriebssystem: {{.OperatingSystem}}'
step "2. Was auf diesem Rechner installiert ist (Docker Desktop ist es nicht)"
for p in docker docker-compose dockerd podman buildah skopeo dockerd-rootless-setuptool.sh; do
  command -v $p >/dev/null 2>&1 && echo "$p: vorhanden" || echo "$p: nicht vorhanden"
done
docker compose version --short | sed 's/^/Compose-Plugin: /'
step "3. Dasselbe Image mit Podman starten (Image per save/load aus Docker übernommen)"
docker save $B | podman load -q 2>&1 | sed 's/^/geladen: /'
podman run --rm docker.io/$B echo "hallo von Podman"
podman --version
step "4. Gleiche Befehle, gleiche Compose-Datei?"
mkdir -p stack && cat > stack/compose.yaml <<'Y'
name: p25alt
services:
  a:
    image: p25/busybox:lab
    command: sleep 5
Y
docker compose -f stack/compose.yaml config --services
podman compose version >/dev/null 2>&1 && echo "podman compose: Befehl vorhanden (der Provider dahinter wurde nicht geprüft)" || echo "podman compose: nicht vorhanden (Ersatz: podman-compose oder Quadlet, nicht geprüft)"
step "5. Lizenzstand Docker Desktop (Quelle: docs.docker.com, Abruf 20.11.2026; die Seite nennt als Aktualisierung 28.09.2026)"
cat <<'T'
Kostenlos: kleine Unternehmen (weniger als 250 Beschäftigte und weniger als 10 Mio. USD Jahresumsatz), persönlicher Gebrauch, Ausbildung,
nichtkommerzielle Open-Source-Projekte. Berufliche Nutzung in größeren Organisationen und in Behörden: kostenpflichtiges Abonnement (Pro, Team, Business).
Das ist die Zusammenfassung einer Seite des Herstellers; der Wortlaut der Bedingungen wurde nicht gelesen. Vor dem Einsatz die Originalseite lesen.
Docker Engine unter Linux (docker-ce) ist nicht Docker Desktop; deren Lizenz wurde nicht geprüft.
Nicht geprüft: Docker Desktop selbst (nur Windows und macOS, hier nicht installiert), Rootless-Docker, Rancher Desktop, Colima.
T
