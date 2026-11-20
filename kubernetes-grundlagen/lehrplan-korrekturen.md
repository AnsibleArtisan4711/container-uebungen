# Anmerkungen zum Lehrplan P26

Beim Ausarbeiten und Testen aufgefallene Punkte. Der Lehrplan selbst wurde zusammen mit der Übungsreihe erstellt und danach **nicht** verändert.

| Nr. | Modul | Befund | Vorschlag |
|---|---|---|---|
| 1 | alle | **Ausführung:** Kubernetes wurde im Container nicht ausgeführt. Die Manifeste wurden mit `kubernetes-validate` 1.37.0 gegen das Schema 1.31 geprüft (echt); der Cluster ist ein Modell in Python (`k8ssim.py`). Das Modell vereinfacht Planung, Rolling Update, Dienste, Ingress und RBAC und wurde nicht gegen einen echten Cluster geprüft. | Übungen im Hyper-V-Labor mit einem echten Cluster nachvollziehen und das Modell prüfen. |
| 2 | alle | **Quellen:** Die Kubernetes-Dokumentation wurde nicht gelesen; Aussagen zu Architektur und Verhalten sind Fachwissen. Versionen von kubeadm, k3s, kind und minikube wurden nicht geprüft. | Dokumentation lesen und Angaben mit Datum belegen. |
| 3 | 03 | **Selektor-Fehler:** Das Schema findet einen falschen Selector nicht; erst der Betrieb zeigt „keine Endpunkte“. | Im Labor mit `kubectl get endpoints` prüfen. |
| 4 | 05 | **Veraltete API:** `kubernetes-validate` meldet für `extensions/v1beta1` nur eine Warnung (Rückgabewert 0), keinen Fehler. | Im Labor das Verhalten von `kubectl apply` prüfen. |
| 5 | 06 | **Tippfehler im roleRef:** Das Schema findet `kind: Rol` nicht; der Fehler zeigt sich erst im Betrieb. | Im Labor prüfen. |
| 6 | 07 | **Priorität:** Modul 7 ist Priorität 2; die Abfragen sind hostabhängig, und die Mindestwerte (2 CPU, 2 GiB RAM) sind Annahmen. | Bei Zeitmangel entfallen lassen; im Labor aber nötig. |
