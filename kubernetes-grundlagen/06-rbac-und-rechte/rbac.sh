#!/usr/bin/env bash
# Modul 6: Rechte mit RBAC. Echt: Schema-Prüfung. Modell: einfache Auswertung (Verb, Ressource, Namespace); Standard ist Verbot.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
cat > rbac.yaml <<'Y'
apiVersion: v1
kind: ServiceAccount
metadata: { name: app, namespace: dev }
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata: { name: pod-leser, namespace: dev }
rules:
- apiGroups: [""]
  resources: [pods, pods/log]
  verbs: [get, list, watch]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata: { name: alice-liest, namespace: dev }
subjects:
- { kind: User, name: alice, apiGroup: rbac.authorization.k8s.io }
roleRef: { kind: Role, name: pod-leser, apiGroup: rbac.authorization.k8s.io }
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata: { name: knoten-leser }
rules:
- apiGroups: [""]
  resources: [nodes]
  verbs: [get, list]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata: { name: bob-knoten }
subjects:
- { kind: User, name: bob, apiGroup: rbac.authorization.k8s.io }
roleRef: { kind: ClusterRole, name: knoten-leser, apiGroup: rbac.authorization.k8s.io }
Y
step "1. Rollen und Bindungen prüfen (echt) und anwenden (Modell)"
val rbac.yaml
k init >/dev/null
printf 'apiVersion: v1\nkind: Namespace\nmetadata: { name: dev }\n---\napiVersion: v1\nkind: Namespace\nmetadata: { name: prod }\n' > ns.yaml; k apply -f ns.yaml >/dev/null
k apply -f rbac.yaml
step "2. Wer darf was? (Modell). Ohne Regel gilt: nein"
chk() { echo "\$ k8ssim can-i $*"; python3 "$HERE/k8ssim.py" can-i "$@"; true; }
chk get pods --as alice -n dev
chk list pods --as alice -n dev
chk delete pods --as alice -n dev
chk get secrets --as alice -n dev
chk get pods --as alice -n prod
chk get pods --as bob -n dev
chk get nodes --as bob
chk get nodes --as alice
step "3. Was das Schema findet und was nicht (echt geprüft)"
sed 's/kind: Role, name: pod-leser/kind: Rol, name: pod-leser/' rbac.yaml > fehler.yaml
val fehler.yaml | tail -1
echo "Der Tippfehler im Typ (Rol statt Role) fällt dem Schema NICHT auf; erst die Bindung im Betrieb würde ins Leere laufen."
sed 's/verbs: \[get, list, watch\]/verbs: get/' rbac.yaml > fehler2.yaml
val fehler2.yaml | grep ERROR
echo "Nicht ausgeführt: echte Authentifizierung (Zertifikate, Token), Aggregierte Rollen, ServiceAccount-Token, Admission-Regeln."
