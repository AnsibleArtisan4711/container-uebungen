#!/usr/bin/env bash
# Modul 5: Namespaces und Ingress. Echt: Schema-Prüfung (auch einer veralteten API-Version). Modell: Namespaces, Regeln für Host und Pfad.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
mk() {  # mk NAME REPLICAS
cat <<Y
apiVersion: apps/v1
kind: Deployment
metadata: { name: $1 }
spec:
  replicas: $2
  selector: { matchLabels: { app: $1 } }
  template:
    metadata: { labels: { app: $1 } }
    spec:
      containers: [{ name: $1, image: "nginx:1.26" }]
---
apiVersion: v1
kind: Service
metadata: { name: $1 }
spec:
  selector: { app: $1 }
  ports: [{ port: 80 }]
Y
}
step "1. Namespaces trennen Namen: derselbe Name in zwei Bereichen"
cat > ns.yaml <<'Y'
apiVersion: v1
kind: Namespace
metadata: { name: dev }
---
apiVersion: v1
kind: Namespace
metadata: { name: prod }
Y
val ns.yaml; k init >/dev/null; k apply -f ns.yaml
mk web 1 > web-dev.yaml; mk web 3 > web-prod.yaml
k apply -f web-dev.yaml -n dev
k apply -f web-prod.yaml -n prod
k get deploy -n dev
k get deploy -n prod
k apply -f web-dev.yaml -n gibtsnicht
step "2. Ingress: Regeln für Host und Pfad"
mk api 2 > api-prod.yaml; k apply -f api-prod.yaml -n prod >/dev/null
cat > ingress.yaml <<'Y'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata: { name: shop }
spec:
  ingressClassName: nginx
  rules:
  - host: shop.example.com
    http:
      paths:
      - { path: /, pathType: Prefix, backend: { service: { name: web, port: { number: 80 } } } }
      - { path: /api, pathType: Prefix, backend: { service: { name: api, port: { number: 80 } } } }
      - { path: /status, pathType: Exact, backend: { service: { name: web, port: { number: 80 } } } }
Y
val ingress.yaml
k apply -f ingress.yaml -n prod
step "3. Anfragen auflösen (Modell: längster passender Pfad gewinnt)"
for r in "shop.example.com /" "shop.example.com /api/benutzer" "shop.example.com /status" "shop.example.com /status/x" "anders.example.com /"; do
  set -- $r; echo "\$ k8ssim route $1 $2"; python3 "$HERE/k8ssim.py" route $1 $2; done
step "4. Dienst fehlt"
python3 "$HERE/k8ssim.py" delete svc/api -n prod >/dev/null
k route shop.example.com /api
step "5. Veraltete API-Version eines Ingress: Das Schema 1.31 kennt sie nicht mehr (echt geprüft)"
cat > alt.yaml <<'Y'
apiVersion: extensions/v1beta1
kind: Ingress
metadata: { name: alt }
spec:
  rules:
  - host: alt.example.com
    http:
      paths:
      - { path: /, backend: { serviceName: web, servicePort: 80 } }
Y
val alt.yaml; echo "Rückgabewert: $? (0 = Prüfung ohne Fehler, aber die Datei wurde nicht gegen ein Schema geprüft)"
echo "Nicht ausgeführt: ein echter Ingress-Controller (z. B. nginx), TLS-Zertifikate und die Namensauflösung der Hosts."
