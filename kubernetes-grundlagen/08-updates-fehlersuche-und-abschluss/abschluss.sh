#!/usr/bin/env bash
# Abschlussprojekt (Modul 8): Shop im Namespace "shop" mit ConfigMap, Secret, Deployment, Service, Ingress und Rechten; Update mit Fehler und Rollback; Abnahme.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
cat > shop.yaml <<'Y'
apiVersion: v1
kind: Namespace
metadata: { name: shop }
Y
cat > app.yaml <<'Y'
apiVersion: v1
kind: ConfigMap
metadata: { name: shop-konfig }
data: { MODUS: produktion }
---
apiVersion: v1
kind: Secret
metadata: { name: shop-geheimnis }
type: Opaque
data: { DB_PASSWORT: Z2VoZWltMTIz }
---
apiVersion: apps/v1
kind: Deployment
metadata: { name: shop }
spec:
  replicas: 3
  selector: { matchLabels: { app: shop } }
  template:
    metadata: { labels: { app: shop } }
    spec:
      containers:
      - name: shop
        image: nginx:1.26
        resources: { requests: { cpu: 250m, memory: 64Mi } }
        env:
        - { name: MODUS, valueFrom: { configMapKeyRef: { name: shop-konfig, key: MODUS } } }
        - { name: DB_PASSWORT, valueFrom: { secretKeyRef: { name: shop-geheimnis, key: DB_PASSWORT } } }
---
apiVersion: v1
kind: Service
metadata: { name: shop }
spec:
  selector: { app: shop }
  ports: [{ port: 80, targetPort: 8080 }]
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata: { name: shop }
spec:
  ingressClassName: nginx
  rules:
  - host: shop.example.com
    http:
      paths:
      - { path: /, pathType: Prefix, backend: { service: { name: shop, port: { number: 80 } } } }
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata: { name: betrieb }
rules:
- { apiGroups: [""], resources: [pods], verbs: [get, list] }
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata: { name: betrieb-bindung }
subjects: [{ kind: User, name: carla, apiGroup: rbac.authorization.k8s.io }]
roleRef: { kind: Role, name: betrieb, apiGroup: rbac.authorization.k8s.io }
Y
step "1. Manifeste prüfen (echt) und anwenden (Modell)"
val shop.yaml app.yaml
k init >/dev/null; k apply -f shop.yaml; k apply -f app.yaml -n shop
step "2. Zustand"
k get deploy -n shop; k get endpoints -n shop | sed -E 's/10\.244\.[0-9]+\.[0-9]+/<IP>/g'
python3 "$HERE/k8ssim.py" route shop.example.com / 
step "3. Update mit Fehler, Fehlersuche und Rollback"
k set-image deploy/shop shop=nginx:doesnotexist -n shop >/dev/null
k rollout status deploy/shop -n shop
k curl shop -n shop | sed -E 's/shop-[0-9a-f]+-[0-9a-f]+/shop-<Hash>-<Id>/'
k rollout undo deploy/shop -n shop >/dev/null
k rollout status deploy/shop -n shop
step "4. Abnahme"
k get deploy -n shop
k get cm -n shop; k get secret -n shop
echo "\$ k8ssim can-i get pods --as carla -n shop"; python3 "$HERE/k8ssim.py" can-i get pods --as carla -n shop
echo "\$ k8ssim can-i delete pods --as carla -n shop"; python3 "$HERE/k8ssim.py" can-i delete pods --as carla -n shop || true
