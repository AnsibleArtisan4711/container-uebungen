#!/usr/bin/env bash
# Modul 2: Dockerfile und Images bauen. Echt: docker build (BuildKit), history, inspect, Cache, mehrstufiger Bau, .dockerignore.
. "$(dirname "$0")/../lab.sh"
lab_up; mkdir -p "$W/app" && cd "$W/app"
echo "Version 1" > version.txt; echo "geheim" > secret.txt; printf 'secret.txt\n' > .dockerignore
cat > Dockerfile <<'D'
FROM p25/busybox:lab
ARG STAND=1
ENV APP_NAME=demo STAND=$STAND
WORKDIR /app
COPY . /app
RUN echo "gebaut mit Stand $STAND" > /app/build.txt
USER 1000
EXPOSE 8080
ENTRYPOINT ["cat"]
CMD ["/app/version.txt"]
D
step "1. Dockerfile bauen und starten"
docker build -q -t p25/app:1 . >/dev/null && echo "Bau erfolgreich"
docker run --rm --label p25=1 p25/app:1
step "2. ENTRYPOINT bleibt, CMD wird ersetzt"
docker run --rm --label p25=1 p25/app:1 /app/build.txt
step "3. .dockerignore: secret.txt liegt nicht im Image"
docker run --rm --label p25=1 --entrypoint ls p25/app:1 /app
step "4. Schichten (history) und Anzahl der Dateisystemschichten"
docker history --no-trunc --format '{{.CreatedBy}}' p25/app:1 | sed -E 's/ # buildkit//; s/\|1 STAND=1 //' | grep -v '^$' | awk '{print NR": "$0}'
docker image inspect -f 'Schichten: {{len .RootFS.Layers}}' p25/app:1
step "5. Cache: unveränderter Bau, dann Datei geändert (Zustand je Schritt)"
cachestatus() { docker build --progress=plain "$@" . 2>&1 | awk '/^#[0-9]+ \[[0-9]+\/[0-9]+\] /{ id=$1; $1=""; if ($0 ~ /FROM/) next; st[id]=$0; ord[++n]=id } /^#[0-9]+ CACHED/{ c[$1]=1 } END{ for(i=1;i<=n;i++){ id=ord[i]; printf "%s:%s\n", st[id], (c[id]?" aus dem Cache":" neu gebaut") } }' | sed -E 's/^ //' | sort; }
echo "unverändert:"; cachestatus -t p25/app:1
echo "Version 2" > version.txt
echo "nach Änderung von version.txt:"; cachestatus -t p25/app:2
docker run --rm --label p25=1 p25/app:2
step "6. ARG: Wert beim Bauen setzen, ENV: Wert im Image"
docker build -q -t p25/app:3 --build-arg STAND=7 . >/dev/null
docker run --rm --label p25=1 --entrypoint sh p25/app:3 -c 'echo "STAND=$STAND APP_NAME=$APP_NAME"; cat /app/build.txt; id -u'
step "7. Mehrstufiger Bau: Werkzeuge bleiben in der Bauphase"
cat > Dockerfile.multi <<'D'
FROM p25/busybox:lab AS bau
RUN mkdir /out && echo "fertiges Ergebnis" > /out/ergebnis.txt && echo "Bauwerkzeug" > /bauwerkzeug.txt
FROM p25/busybox:lab
COPY --from=bau /out/ergebnis.txt /ergebnis.txt
CMD ["cat", "/ergebnis.txt"]
D
docker build -q -f Dockerfile.multi -t p25/multi:1 . >/dev/null
docker run --rm --label p25=1 p25/multi:1
docker run --rm --label p25=1 --entrypoint ls p25/multi:1 /bauwerkzeug.txt 2>&1 | sed 's/^ls: //'
