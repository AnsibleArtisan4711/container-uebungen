#!/usr/bin/env bash
# Modul 8 (Teil 2): Einordnung gegenüber Docker Compose. Echt: docker compose config, Schema-Prüfung. Gleiche Anwendung, zwei Beschreibungen.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
cat > compose.yaml <<'Y'
name: shop
services:
  web:
    image: nginx:1.26
    ports: ["8080:80"]
    environment: { MODUS: produktion }
    deploy: { replicas: 3 }
Y
cat > shop.yaml <<'Y'
apiVersion: apps/v1
kind: Deployment
metadata: { name: web }
spec:
  replicas: 3
  selector: { matchLabels: { app: web } }
  template:
    metadata: { labels: { app: web } }
    spec:
      containers:
      - name: web
        image: nginx:1.26
        ports: [{ containerPort: 80 }]
        env: [{ name: MODUS, value: produktion }]
---
apiVersion: v1
kind: Service
metadata: { name: web }
spec:
  type: NodePort
  selector: { app: web }
  ports: [{ port: 80, nodePort: 30080 }]
Y
step "1. Dieselbe Anwendung: Compose-Datei (echt geprüft) und Kubernetes-Manifest (echt geprüft)"
if docker compose version >/dev/null 2>&1; then docker compose -f compose.yaml config --services; docker compose -f compose.yaml config -q && echo "Compose-Datei gültig"; else echo "docker compose nicht vorhanden: Schritt übersprungen"; fi
val shop.yaml
wc -l compose.yaml shop.yaml | sed '$d' | awk '{print $2 ": " $1 " Zeilen"}'
step "2. Gegenüberstellung (Fachwissen, nicht gegen die Dokumentation geprüft)"
cat <<'T'
Compose                      Kubernetes
Dienst (service)             Deployment + Service
ports: "8080:80"             Service (NodePort/ClusterIP) und Ingress
environment                  env, ConfigMap, Secret
volumes                      Volume, PersistentVolumeClaim
replicas (deploy)            replicas im Deployment, selbstheilend und knotenübergreifend
ein Rechner                  mehrere Knoten, Planung durch den Scheduler
Entscheidung: Ein Rechner und wenig Dienste: Compose genügt. Mehrere Knoten, Selbstheilung, Updates ohne Ausfall: Kubernetes.
T
step "3. Selbstheilung: nur Kubernetes (Modell) gleicht Soll und Ist ständig ab"
k init >/dev/null; k apply -f shop.yaml
P=$(python3 "$HERE/k8ssim.py" get pods | awk 'NR==2{print $1}'); python3 "$HERE/k8ssim.py" delete pod/$P >/dev/null
k get deploy
