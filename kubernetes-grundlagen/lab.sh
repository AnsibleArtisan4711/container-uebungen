#!/usr/bin/env bash
# Gemeinsame Hilfen der Übungsreihe (P26). ECHT ausgeführt: nur die Prüfung der Manifeste (kubernetes-validate 1.37.0, Schema 1.31), Docker (Modul 1 und 8,
# Pod-Gedanke mit gemeinsamem Netz-Namespace) sowie base64 und Systemabfragen. Der Cluster ist ein MODELL (k8ssim.py): KEIN Kubernetes, KEIN kubectl,
# KEIN k3s/kind/minikube/kubeadm (im Cloud-Container nicht erreichbar). Dateien unter /tmp/p26.
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; W=/tmp/p26; export K8S_STATE=$W/state.json; B=p26/busybox:lab
step() { echo; echo "## $*"; }
k() { echo "\$ k8ssim $*"; python3 "$HERE/k8ssim.py" "$@" 2>&1; return ${PIPESTATUS[0]}; }
val() { echo "\$ kubernetes-validate -k 1.31 --strict $*"; kubernetes-validate -k 1.31 --strict "$@" 2>&1 | sed -E 's/^INFO /OK: /; s/ against version 1.31//'; return ${PIPESTATUS[0]}; }
lab_down() { docker ps -aq --filter label=p26 2>/dev/null | xargs -r docker rm -f >/dev/null 2>&1; docker rmi -f $B >/dev/null 2>&1; rm -rf "$W"; }
lab_up() { lab_down; mkdir -p "$W"; }
base_image() {   # Basis-Image aus busybox-static (nur für Docker-Schritte)
  local r=$W/rootfs; mkdir -p $r/bin; cp /usr/bin/busybox $r/bin/busybox
  for a in $($r/bin/busybox --list); do [ "$a" = busybox ] || ln -sf busybox $r/bin/$a; done
  tar -C $r -c . | docker import - $B >/dev/null
}
trap 'lab_down >/dev/null 2>&1' EXIT
