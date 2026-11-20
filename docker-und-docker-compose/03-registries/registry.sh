#!/usr/bin/env bash
# Modul 3: Registries. Echt: lokale Registry (docker-registry 2.8.2) auf 127.0.0.1:5000, tag, push, pull, Katalog, Tags, Digest.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
mkdir -p registry data
cat > config.yml <<'C'
version: 0.1
storage:
  filesystem:
    rootdirectory: /tmp/p25/data
http:
  addr: 127.0.0.1:5000
log:
  level: error
C
docker-registry serve config.yml >/dev/null 2>&1 & echo $! > "$W/registry.pid"
for i in $(seq 1 20); do curl -s http://127.0.0.1:5000/v2/ >/dev/null && break; sleep 0.5; done
step "1. Die Registry antwortet (Registry-API v2)"
curl -s -o /dev/null -w 'GET /v2/ -> HTTP %{http_code}\n' http://127.0.0.1:5000/v2/
curl -s http://127.0.0.1:5000/v2/_catalog; echo
step "2. Namen: Registry/Pfad:Tag, taggen und hochladen (push)"
docker tag $B localhost:5000/p25/basis:1.0
docker tag $B localhost:5000/p25/basis:latest
docker push localhost:5000/p25/basis:1.0 2>&1 | grep -E 'digest:' | sed -E 's/sha256:[0-9a-f]{64}/sha256:<Prüfsumme>/; s/size: [0-9]+/size: <Größe>/'
docker push localhost:5000/p25/basis:latest >/dev/null 2>&1
step "3. Katalog und Tags abfragen"
curl -s http://127.0.0.1:5000/v2/_catalog; echo
curl -s http://127.0.0.1:5000/v2/p25/basis/tags/list; echo
step "4. Lokal löschen und wieder holen (pull)"
docker rmi localhost:5000/p25/basis:1.0 localhost:5000/p25/basis:latest >/dev/null
docker image ls 'localhost:5000/p25/*' --format '{{.Repository}}:{{.Tag}}' | wc -l | sed 's/^/Lokale Images mit diesem Namen: /'
docker pull -q localhost:5000/p25/basis:1.0 | mask
docker run --rm --label p25=1 localhost:5000/p25/basis:1.0 echo "Container aus dem geholten Image"
step "5. Digest: unveränderlicher Verweis (statt des beweglichen Tags)"
docker images --digests localhost:5000/p25/basis --format '{{.Repository}}:{{.Tag}} @ {{.Digest}}' | grep ':1.0 ' | mask
step "6. Nicht vorhandenes Image"
docker pull localhost:5000/p25/gibtsnicht:1 2>&1 | sed -E 's/^Error response from daemon: //' | head -2
cat <<'T'
Nicht geprüft: Docker Hub und andere Internet-Registries (im Container nicht erreichbar), Anmeldung mit docker login, TLS und Benutzerverwaltung
der Registry. Eine Registry ohne TLS und Anmeldung ist nur für localhost und das Übungslabor geeignet (Fachwissen).
T
