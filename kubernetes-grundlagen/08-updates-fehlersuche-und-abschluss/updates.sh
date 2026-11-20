#!/usr/bin/env bash
# Modul 8 (Teil 1): Updates, Rollbacks und Fehlersuche. Echt: Schema-Prüfung. Modell: Rolling Update, Fehlstart (ImagePullBackOff), Rollback, Events.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
cat > web.yaml <<'Y'
apiVersion: apps/v1
kind: Deployment
metadata: { name: web }
spec:
  replicas: 4
  selector: { matchLabels: { app: web } }
  template:
    metadata: { labels: { app: web } }
    spec:
      containers: [{ name: web, image: "nginx:1.26" }]
Y
val web.yaml; k init >/dev/null; k apply -f web.yaml
step "1. Rolling Update auf ein vorhandenes Image (Schritte des Modells; maxSurge und maxUnavailable je 25 %)"
k set-image deploy/web web=nginx:1.27
k get rs
k get deploy
step "2. Update auf ein Image, das es nicht gibt: der Rollout bleibt stehen, die alten Pods laufen weiter"
k set-image deploy/web web=nginx:doesnotexist
k rollout status deploy/web
k get pods | sed -E 's/web-[0-9a-f]+-[0-9a-f]+/web-<Hash>-<Id>     /'
step "3. Fehlersuche: Ereignisse des fehlerhaften Pods lesen"
BAD=$(python3 "$HERE/k8ssim.py" get pods | awk '/ImagePullBackOff/ {print $1; exit}')
python3 "$HERE/k8ssim.py" describe $BAD | sed -E 's/web-[0-9a-f]+-[0-9a-f]+/web-<Hash>-<Id>/'
step "4. Rollback auf die vorige Version"
k rollout history deploy/web
k rollout undo deploy/web
k rollout status deploy/web
k rollout history deploy/web
step "5. Abgleich: Soll und Ist"
k get deploy
