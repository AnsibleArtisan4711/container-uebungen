# Befehle und Aussagen, die nicht bestätigt sind

Prüfliste für den ersten Durchlauf in den Hyper-V-VMs: Befund und Datum eintragen, danach den Hinweis in der Übung entfernen. Legende: **Q** = gegen Quelle gelesen; **L** = im Labor (Container) ausgeführt; **–** = weder noch.

| Modul | Befehl oder Aussage | Status | Nächster Schritt |
|---|---|---|---|
| alle | Aufbau des Hyper-V-Labors (privater Switch `Lab-K8s`, `cp1`, `w1`, optional `w2`, Linux) | – | laut Lehrplan aufbauen und prüfen |
| 01 | `kubernetes-validate`; Docker-Nachstellung eines Pods (`--network container:`); `k8ssim.py init/get/apply` | Schemaprüfung und Docker echt; Cluster **Modell** | Bausteine im echten Cluster mit `kubectl get nodes` und `kube-system` ansehen |
| 02 | `kubernetes-validate`; `k8ssim.py apply/get/scale/delete/node fail` | Schemaprüfung echt; Planung und Selbstheilung **Modell** | im Labor mit `kubectl` und einem echten Knotenausfall prüfen |
| 03 | `kubernetes-validate`; `k8ssim.py get svc/endpoints/curl` | Schemaprüfung echt; Verteilung und Endpunkte **Modell** | im Labor mit `kubectl get endpoints` und `curl` prüfen |
| 04 | `base64`, `kubernetes-validate`; `k8ssim.py env` | `base64` und Schema echt; Auflösung **Modell** | im Labor Secrets und ConfigMaps in einem echten Pod prüfen |
| 05 | `kubernetes-validate`; `k8ssim.py route` | Schema echt; Ingress-Auflösung **Modell**; kein Ingress-Controller | Ingress-Controller im Labor installieren (nicht geprüft) |
| 06 | `kubernetes-validate`; `k8ssim.py can-i` | Schema echt; RBAC **Modell** | im Labor mit `kubectl auth can-i` prüfen |
| 07 | Abfragen des Rechners (Werkzeuge, CPU, RAM, Swap, cgroup, ip_forward, br_netfilter) | Abfragen echt; **kubeadm, k3s, kind, minikube nicht ausgeführt** | Cluster im Labor aufbauen und die Schritte gegen die Dokumentation prüfen |
| 08 | `k8ssim.py set-image/rollout`, `docker compose config`, `kubernetes-validate` | Compose und Schema echt; Rollout **Modell** | Abschlussprojekt im Labor mit echtem Cluster wiederholen |
