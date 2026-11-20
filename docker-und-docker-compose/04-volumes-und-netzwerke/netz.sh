#!/usr/bin/env bash
# Modul 4: Volumes und Netzwerke. Echt: benannte Volumes, Bind-Mount, tmpfs, benutzerdefiniertes Netz mit Namensauflösung, Port-Veröffentlichung.
. "$(dirname "$0")/../lab.sh"
lab_up; mkdir -p "$W/www" && cd "$W"
echo "Startseite" > www/index.html
step "1. Benanntes Volume: Daten überleben den Container"
docker volume create --label p25=1 daten >/dev/null
docker run --rm --label p25=1 -v daten:/d $B sh -c 'echo "gespeichert" > /d/notiz.txt'
docker run --rm --label p25=1 -v daten:/d $B cat /d/notiz.txt
docker volume ls --filter label=p25 --format 'Volume: {{.Name}} ({{.Driver}})'
step "2. Ohne Volume ist die beschreibbare Schicht weg"
docker run --name tmp1 --label p25=1 $B sh -c 'echo x > /nur-im-container'; docker rm tmp1 >/dev/null
docker run --rm --label p25=1 $B ls /nur-im-container 2>&1 | sed 's/^ls: //'
step "3. Bind-Mount (Ordner des Hosts) und tmpfs (Arbeitsspeicher)"
docker run --rm --label p25=1 -v "$W/www:/www:ro" $B cat /www/index.html
docker run --rm --label p25=1 -v "$W/www:/www:ro" $B sh -c 'echo x > /www/neu 2>&1' 2>&1 | sed 's/^sh: //'
docker run --rm --label p25=1 --tmpfs /scratch $B sh -c 'echo flüchtig > /scratch/a; cat /scratch/a; grep " /scratch " /proc/mounts | cut -d" " -f1,3'
step "4. Standard-Bridge: keine Namensauflösung, eigenes Netz: Name = Adresse"
docker network create --label p25=1 labnetz >/dev/null
docker run -d --name web --label p25=1 --network labnetz -v "$W/www:/www:ro" $B httpd -f -p 80 -h /www >/dev/null
docker run --rm --label p25=1 --network labnetz $B wget -qO- http://web/
docker run -d --name web0 --label p25=1 -v "$W/www:/www:ro" $B httpd -f -p 80 -h /www >/dev/null
docker run --rm --label p25=1 $B wget -T 2 -qO- http://web0/ 2>&1 | sed 's/^wget: //'
step "5. Port veröffentlichen (-p) und von außen abrufen"
docker run -d --name pub --label p25=1 -p 18025:80 -v "$W/www:/www:ro" $B httpd -f -p 80 -h /www >/dev/null; sleep 1
docker port pub
curl -s http://127.0.0.1:18025/
step "6. Netz ansehen und Container ohne Netz"
docker network inspect labnetz -f '{{.Driver}}, Container im Netz: {{len .Containers}}'
docker run --rm --label p25=1 --network none $B sh -c 'ls /sys/class/net | tr "\n" " "; echo'
