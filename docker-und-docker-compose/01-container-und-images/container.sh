#!/usr/bin/env bash
# Modul 1: Container und Images. Echt: Docker Engine (run, create, start, exec, logs, inspect), Namespaces und cgroups auf dem Host.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Versionen (Client und Server)"
docker version --format 'Client {{.Client.Version}}, Server {{.Server.Version}}'
step "2. Ein Container ist ein isolierter Prozess: eigener Rechnername, eigene Prozessliste"
docker run --rm --label p25=1 $B sh -c 'echo "Befehl: hallo aus dem Container"; echo "PID der Shell: $$"'
HOSTH=$(hostname); INH=$(docker run --rm --label p25=1 $B hostname)
[ "$HOSTH" != "$INH" ] && echo "Rechnername im Container ist ein anderer als auf dem Host: ja"
step "3. Lebenslauf: create, start, ps, stop, rm (Zustand je Schritt)"
docker create --name web1 --label p25=1 $B sh -c 'echo hallo-log; sleep 300' >/dev/null
docker ps -a --filter name=web1 --format '{{.Names}}: {{.State}}'
docker start web1 >/dev/null; sleep 1
docker ps -a --filter name=web1 --format '{{.Names}}: {{.State}}'
step "4. Ausgabe lesen (logs) und Befehl im laufenden Container ausführen (exec)"
docker logs web1
docker exec web1 sh -c 'ls / | tr "\n" " "; echo'
step "5. Der Container im Host: eigene Namespaces, eigene cgroup"
PID=$(docker inspect -f '{{.State.Pid}}' web1)
for ns in pid net mnt uts; do
  [ "$(readlink /proc/$PID/ns/$ns)" != "$(readlink /proc/self/ns/$ns)" ] && echo "Namespace $ns: eigener"
done
echo "cgroup-Pfad enthält 'docker': $(grep -c docker /proc/$PID/cgroup | sed 's/^0$/nein/; s/^[1-9][0-9]*$/ja/')"
step "6. Anhalten, Zustand, Exit-Code, Entfernen"
docker stop -t 1 web1 >/dev/null
docker inspect -f '{{.State.Status}}, Exit-Code {{.State.ExitCode}}' web1
docker run --name fehler --label p25=1 $B sh -c 'exit 3'; docker inspect -f 'fehler: {{.State.Status}}, Exit-Code {{.State.ExitCode}}' fehler
docker rm web1 fehler
docker ps -a --filter label=p25 --format '{{.Names}}' | wc -l | sed 's/^/Container mit Label p25 übrig: /'
step "7. Image und Container sind verschieden"
docker image ls p25/busybox --format 'Image {{.Repository}}:{{.Tag}}'
echo "Ein Image ist die schreibgeschützte Vorlage; jeder Container bekommt darüber eine beschreibbare Schicht (Fachwissen)."
