#!/usr/bin/env bash
# Modul 4: ConfigMaps, Secrets und Volumes. Echt: Schema-Prüfung, base64. Modell: Auflösung der Verweise in Umgebungsvariablen.
. "$(dirname "$0")/../lab.sh"
lab_up; cd "$W"
step "1. Secret-Werte sind nur base64-kodiert (echt)"
printf 'geheim123' | base64
printf 'Z2VoZWltMTIz' | base64 -d; echo
echo "base64 ist keine Verschlüsselung: Wer das Secret lesen darf, liest den Wert."
cat > konfig.yaml <<'Y'
apiVersion: v1
kind: ConfigMap
metadata: { name: app-konfig }
data:
  MODUS: produktion
  SEITENTITEL: Mein Shop
---
apiVersion: v1
kind: Secret
metadata: { name: app-geheimnis }
type: Opaque
data:
  DB_PASSWORT: Z2VoZWltMTIz
---
apiVersion: apps/v1
kind: Deployment
metadata: { name: shop }
spec:
  replicas: 1
  selector: { matchLabels: { app: shop } }
  template:
    metadata: { labels: { app: shop } }
    spec:
      containers:
      - name: shop
        image: nginx:1.26
        env:
        - name: MODUS
          valueFrom: { configMapKeyRef: { name: app-konfig, key: MODUS } }
        - name: DB_PASSWORT
          valueFrom: { secretKeyRef: { name: app-geheimnis, key: DB_PASSWORT } }
        - name: STUFE
          value: "test"
Y
step "2. Manifeste prüfen (echt) und anwenden (Modell)"
val konfig.yaml
k init >/dev/null
k apply -f konfig.yaml
k get cm
k get secret
step "3. Was sieht der Pod? (Modell: Umgebungsvariablen aus ConfigMap und Secret)"
python3 "$HERE/k8ssim.py" env $(python3 "$HERE/k8ssim.py" get pods | awk 'NR==2{print $1}')
step "4. Fehler: Verweis auf eine ConfigMap, die es nicht gibt"
sed 's/name: app-konfig, key: MODUS/name: fehlt, key: MODUS/' konfig.yaml > fehlt.yaml
val fehlt.yaml
echo "Das Schema prüft nur die Form; ob die ConfigMap existiert, zeigt erst der Betrieb:"
k apply -f fehlt.yaml | tail -1
python3 "$HERE/k8ssim.py" env $(python3 "$HERE/k8ssim.py" get pods | awk 'NR==2{print $1}') | sed -n '1p'
step "5. Volumes im Schema (nur Prüfung): emptyDir und PersistentVolumeClaim"
cat > volumes.yaml <<'Y'
apiVersion: v1
kind: PersistentVolumeClaim
metadata: { name: daten }
spec:
  accessModes: [ReadWriteOnce]
  resources: { requests: { storage: 1Gi } }
---
apiVersion: apps/v1
kind: Deployment
metadata: { name: db }
spec:
  replicas: 1
  selector: { matchLabels: { app: db } }
  template:
    metadata: { labels: { app: db } }
    spec:
      containers:
      - name: db
        image: postgres:16
        volumeMounts:
        - { name: daten, mountPath: /var/lib/postgresql/data }
        - { name: cache, mountPath: /cache }
      volumes:
      - { name: daten, persistentVolumeClaim: { claimName: daten } }
      - { name: cache, emptyDir: {} }
Y
val volumes.yaml
echo "Nicht geprüft: Speicherklassen (StorageClass), echte Volumes und die Wirkung von ReadWriteOnce im Betrieb (im Modell nicht abgebildet)."
