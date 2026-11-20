#!/usr/bin/env bash
# Modul 2: Pods, ReplicaSets und Deployments. Echt: Schema-Prüfung. Modell: Planung, Selbstheilung, Skalierung, Knotenausfall, Ressourcenanforderungen.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
cat > web.yaml <<'Y'
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
        resources: { requests: { cpu: 500m, memory: 128Mi } }
Y
step "1. Manifest prüfen (echt) und anwenden (Modell)"
val web.yaml
sed 's/replicas: 3/replicas: "drei"/' web.yaml > fehler.yaml
val fehler.yaml
k init >/dev/null
k apply -f web.yaml
step "2. Deployment -> ReplicaSet -> Pods, verteilt auf die Arbeitsknoten (Control-Plane-Knoten nehmen keine Pods an)"
k get deploy
k get rs
k get pods
step "3. Selbstheilung: Ein Pod wird gelöscht, der Controller erzeugt einen neuen"
P=$(python3 "$HERE/k8ssim.py" get pods | awk 'NR==2{print $1}')
echo "gelöscht wird der erste Pod der Liste"
python3 "$HERE/k8ssim.py" delete pod/$P | sed 's/"[^"]*"/"<Name>"/'
k get deploy
step "4. Skalieren: von 3 auf 5 und zurück auf 2"
k scale deploy/web --replicas=5
k get deploy
k scale deploy/web --replicas=2
k get pods
step "5. Knotenausfall: die Pods des Knotens werden auf dem anderen Knoten neu gestartet"
k scale deploy/web --replicas=3 >/dev/null
k node fail w1
k get pods
k node recover w1
step "6. Ressourcenanforderung (requests) zu groß: der Pod bleibt Pending"
cat > gross.yaml <<'Y'
apiVersion: apps/v1
kind: Deployment
metadata: { name: gross }
spec:
  replicas: 1
  selector: { matchLabels: { app: gross } }
  template:
    metadata: { labels: { app: gross } }
    spec:
      containers:
      - name: g
        image: nginx:1.26
        resources: { requests: { cpu: "3", memory: 128Mi } }
Y
k apply -f gross.yaml
k get pods -l app=gross
k describe $(python3 "$HERE/k8ssim.py" get pods -l app=gross | awk 'NR==2{print $1}') | sed -n '1,4p;/Events/,$p' | sed -E 's/gross-[0-9a-f]+-[0-9a-f]+/gross-<Hash>-<Id>/g'
