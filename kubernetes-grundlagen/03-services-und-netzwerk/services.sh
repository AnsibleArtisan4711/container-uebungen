#!/usr/bin/env bash
# Modul 3: Services und Netzwerk. Echt: Schema-Prüfung. Modell: Auswahl der Pods über Labels (Endpunkte), Verteilung der Anfragen, Dienst ohne Endpunkte.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
cat > app.yaml <<'Y'
apiVersion: apps/v1
kind: Deployment
metadata: { name: web }
spec:
  replicas: 3
  selector: { matchLabels: { app: web } }
  template:
    metadata: { labels: { app: web, stufe: prod } }
    spec:
      containers:
      - name: web
        image: nginx:1.26
---
apiVersion: v1
kind: Service
metadata: { name: web }
spec:
  selector: { app: web }
  ports: [{ port: 80, targetPort: 8080 }]
Y
step "1. Deployment und Service anwenden; der Dienst wählt Pods über Labels"
val app.yaml
k init >/dev/null
k apply -f app.yaml
k get svc
k get endpoints
step "2. Anfragen an den Dienst werden reihum auf die Pods verteilt"
for i in 1 2 3 4; do python3 "$HERE/k8ssim.py" curl web | sed -E 's/web-[0-9a-f]+-/web-<Hash>-/'; done
step "3. Ein Pod fällt aus: der Endpunkt verschwindet, ein neuer kommt hinzu"
python3 "$HERE/k8ssim.py" scale deploy/web --replicas=1 >/dev/null
k get endpoints | sed -E 's/10\.244\.[0-9]+\.[0-9]+/<IP>/g'
step "4. Fehler: Selector passt zu keinem Pod (Tippfehler im Label)"
cat > falsch.yaml <<'Y'
apiVersion: v1
kind: Service
metadata: { name: falsch }
spec:
  selector: { app: wep }
  ports: [{ port: 80, targetPort: 8080 }]
Y
val falsch.yaml
k apply -f falsch.yaml
k get endpoints
k curl falsch
echo "Der Dienst existiert und ist gültig, hat aber keine Endpunkte: Die Prüfung des Schemas findet diesen Fehler nicht."
step "5. Dienst, der nicht existiert"
k curl gibtsnicht
step "6. Dienst-Typen im Schema (nur Prüfung): ClusterIP ohne Adresse (Headless) und NodePort"
cat > typen.yaml <<'Y'
apiVersion: v1
kind: Service
metadata: { name: headless }
spec:
  clusterIP: None
  selector: { app: web }
  ports: [{ port: 80 }]
---
apiVersion: v1
kind: Service
metadata: { name: extern }
spec:
  type: NodePort
  selector: { app: web }
  ports: [{ port: 80, nodePort: 30080 }]
Y
val typen.yaml
