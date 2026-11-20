#!/usr/bin/env bash
# Modul 7: Lokale Umgebung (kubeadm, k3s, kind, minikube). NICHT ausgeführt: keines der Werkzeuge. Echt: Abfragen dieses Rechners.
. "$(dirname "$0")/../lab.sh"
lab_up
step "1. Welche Werkzeuge sind auf diesem Rechner vorhanden?"
for p in kubectl kubeadm kubelet k3s kind minikube helm crictl containerd docker; do
  command -v $p >/dev/null 2>&1 && echo "$p: vorhanden" || echo "$p: nicht vorhanden"
done
step "2. Voraussetzungen prüfen (echt abgefragt, Ergebnis gilt nur für diesen Rechner)"
[ "$(nproc)" -ge 2 ] && echo "mindestens 2 CPU-Kerne: ja" || echo "mindestens 2 CPU-Kerne: nein"
[ "$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)" -ge 2000 ] && echo "mindestens 2 GiB Arbeitsspeicher: ja" || echo "mindestens 2 GiB Arbeitsspeicher: nein"
[ -z "$(swapon --show --noheadings 2>/dev/null)" ] && echo "Swap ausgeschaltet: ja" || echo "Swap ausgeschaltet: nein"
echo "cgroup-Dateisystem: $(stat -fc %T /sys/fs/cgroup 2>/dev/null)"
echo "IPv4-Weiterleitung (net.ipv4.ip_forward): $(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null)"
(lsmod 2>/dev/null | grep -q '^br_netfilter' && echo "Kernelmodul br_netfilter: geladen") || echo "Kernelmodul br_netfilter: nicht geladen oder nicht abfragbar"
step "3. Vergleich der Möglichkeiten (Fachwissen, nicht ausgeführt, Versionen nicht geprüft)"
cat <<'T'
kubeadm: baut einen Cluster aus mehreren Rechnern (Control Plane und Knoten); nah an der Produktion; Aufwand hoch.
k3s:     schlanke Distribution aus einer Datei; ein oder mehrere Knoten; für Labor, Edge und kleine Cluster.
kind:    Cluster in Docker-Containern; schnell zu erzeugen und zu löschen; für Tests und CI.
minikube: Ein-Knoten-Cluster auf dem Arbeitsplatz (VM oder Container); für Einsteiger.
T
step "4. Laborplan (Hyper-V, Lehrplan): 2 bis 3 Linux-VMs"
cat <<'T'
cp1 (Control Plane), w1 und w2 (Arbeitsknoten) am privaten Switch; je 2 CPU und mindestens 2 GiB RAM (Annahme); Swap aus; gleiche Container-Runtime auf allen.
Die Schritte zum Aufbau wurden NICHT ausgeführt und sind nicht gegen die Dokumentation geprüft; sie gehören in die Prüfliste des Kurses.
T
