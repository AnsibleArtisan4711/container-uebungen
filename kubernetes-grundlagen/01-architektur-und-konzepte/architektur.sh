#!/usr/bin/env bash
# Modul 1: Architektur und Konzepte. Echt: Docker (gemeinsamer Netz-Namespace = Grundidee eines Pods), kubernetes-validate. Modell: Cluster (k8ssim.py).
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Bausteine (Fachwissen, nicht gegen die Dokumentation geprüft)"
cat <<'T'
Control Plane: kube-apiserver (einzige Schnittstelle), etcd (Zustandsspeicher), kube-scheduler (wählt den Knoten), kube-controller-manager (gleicht Soll und Ist ab).
Knoten: kubelet (startet Pods), Container-Runtime (z. B. containerd), kube-proxy (Dienste im Netz).
Grundidee: Man beschreibt den Soll-Zustand (Manifest); Controller stellen ihn her und halten ihn.
T
step "2. Ein Modell-Cluster mit drei Knoten"
k init
k get nodes
k get ns
step "3. Echt: Ein Pod teilt sich das Netz. Zwei Container, ein Netz-Namespace (mit Docker nachgestellt)"
if docker info >/dev/null 2>&1; then
  base_image
  docker run -d --name pod-pause --label p26=1 $B sleep 60 >/dev/null
  docker run -d --name pod-web --label p26=1 --network container:pod-pause $B sh -c 'echo "Antwort des Web-Containers" > /index.html; httpd -f -p 8080 -h /' >/dev/null; sleep 1
  docker run --rm --label p26=1 --network container:pod-pause $B wget -qO- http://127.0.0.1:8080/
  echo "Netzmodus von pod-web: $(docker inspect -f '{{.HostConfig.NetworkMode}}' pod-web | sed 's/container:[0-9a-f]*/container:<ID von pod-pause>/') (benutzt das Netz von pod-pause)"
else
  echo "Docker nicht erreichbar: Schritt übersprungen"
fi
step "4. Echt: Ein einfaches Pod-Manifest gegen das Schema prüfen"
cat > pod.yaml <<'Y'
apiVersion: v1
kind: Pod
metadata:
  name: hallo
  labels: { app: hallo }
spec:
  containers:
  - name: web
    image: nginx:1.27
    ports: [{ containerPort: 80 }]
Y
val pod.yaml
sed 's/containers:/container:/' pod.yaml > pod-fehler.yaml
val pod-fehler.yaml
step "5. Deklarativ: dieselbe Datei zweimal anwenden (Modell)"
k apply -f pod.yaml
echo "Hinweis: Das Modell kennt Pods nur als Teil von Deployments; ein einzelner Pod wird hier nur geprüft, nicht gestartet."
