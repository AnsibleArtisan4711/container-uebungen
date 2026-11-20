# Kubernetes-Grundlagen (P26)

Übungsreihe zu Kubernetes-Grundlagen: Architektur, Pods und Deployments, Services, ConfigMaps und Secrets, Volumes, Namespaces und Ingress, Rechte mit RBAC, lokale Umgebung, Updates, Rollbacks und Fehlersuche, Einordnung gegenüber Docker Compose. 8 Module, 100 Unterrichtseinheiten zu 45 Minuten, davon 1 Modul mit Priorität 2 (Vertiefung). Kubernetes wird nicht ausgeführt; der Cluster ist ein Lernmodell in Python. Die Aufgabentexte und Kontrollfragen stammen aus dem Lehrplan P26 (Reihe „Lehrplan-Prompts“, Datei `P26-kubernetes-grundlagen.md`) und sind unverändert; Hinweise, Musterlösungen und Ergänzungen sind Teil der Ausarbeitung und gekennzeichnet.

> **Prüfstand, ehrlich:** **Im Cloud-Container ausgeführt, Kubernetes nicht.** Echt geprüft ist die Form der Manifeste (`kubernetes-validate` 1.37.0, Schema 1.31, streng); der Cluster ist ein Lernmodell in Python (`k8ssim.py`). Modul 1 stellt einen Pod mit Docker nach. Nicht ausgeführt: kubectl, kubeadm, k3s, kind, minikube, Ingress-Controller, Hyper-V. Die Kubernetes-Dokumentation wurde nicht gelesen. Die Ausgaben stehen in den Ordnern `beispiele/`. Offene Punkte: [`befehle-nicht-bestaetigt.md`](befehle-nicht-bestaetigt.md); Anmerkungen zum Lehrplan: [`lehrplan-korrekturen.md`](lehrplan-korrekturen.md).

## Umgebung

Zwei bis drei Linux-VMs `cp1`, `w1`, optional `w2` unter **Hyper-V** (Lehrplan) am privaten Switch `Lab-K8s` (`10.80.0.0/24`). Das Labor wurde **nicht** aufgebaut. Die Skripte brauchen die VMs nicht und arbeiten unter `/tmp/p26`.

## Module

| Nr. | Modul | Zeit | Prüfstand |
|---|---|---|---|
| 01 | [Architektur und Konzepte](01-architektur-und-konzepte/) | 9 h | Skript im Container ausgeführt; Schemaprüfung echt, Cluster als Modell. |
| 02 | [Pods, ReplicaSets und Deployments](02-pods-und-deployments/) | 10,5 h | Skript im Container ausgeführt; Schemaprüfung echt, Cluster als Modell. |
| 03 | [Services und Netzwerk](03-services-und-netzwerk/) | 9 h | Skript im Container ausgeführt; Schemaprüfung echt, Cluster als Modell. |
| 04 | [ConfigMaps, Secrets und Volumes](04-konfiguration-und-volumes/) | 9 h | Skript im Container ausgeführt; Schemaprüfung echt, Cluster als Modell. |
| 05 | [Namespaces und Ingress](05-ingress-und-namespaces/) | 9 h | Skript im Container ausgeführt; Schemaprüfung echt, Cluster als Modell. |
| 06 | [Rechte mit RBAC](06-rbac-und-rechte/) | 9 h | Skript im Container ausgeführt; Schemaprüfung echt, Cluster als Modell. |
| 07 | [Lokale Umgebung: kubeadm, k3s, kind, minikube](07-lokale-umgebung/) (Priorität 2) | 6 h | Skript im Container ausgeführt (nur Abfragen); keine Kubernetes-Werkzeuge ausgeführt. |
| 08 | [Updates, Rollbacks, Fehlersuche, Einordnung und Abschlussprojekt](08-updates-fehlersuche-und-abschluss/) | 13,5 h | Skripte im Container ausgeführt; Schemaprüfung echt, Cluster als Modell. |

Summe 75 Stunden.

## Aufbau eines Moduls

Ordner `NN-kurzname/` mit `README.md`, der Übung `NN.1-….md` (Lernziele, Voraussetzungen, Grundbegriffe, Aufgaben, Hinweise, Kontrollfragen, einklappbare Musterlösung, Erweiterungen, Quellen), den Skripten und Beispieldaten des Moduls und einem Ordner `beispiele/` mit den echten Ausgaben der Läufe. Die Skripte der Module liegen im jeweiligen Modulordner und binden `../lab.sh` ein; `k8ssim.py` (Modell) liegt im Kursordner. Benötigt: `python3` mit PyYAML und `kubernetes-validate` (`pip install kubernetes-validate`); für Modul 1 und 8 zusätzlich Docker und `busybox-static`.

## Hinweise

- Alle Namen und Adressen sind erfunden.
- Die Skripte arbeiten nur unter `/tmp/p26` und räumen am Ende auf.
- Die Ausgaben stammen vom Modell `k8ssim.py`, nicht von Kubernetes (`k8ssim` ersetzt `kubectl`).

## Lizenz

- Skripte: MIT, siehe [`LICENSE`](LICENSE)
- Texte: CC BY 4.0, siehe [`LICENSE-DOCS.md`](LICENSE-DOCS.md)

*Lizenz: Text CC BY 4.0, Skripte MIT, siehe `LICENSE-DOCS.md` und `LICENSE` im Kursordner. Alle Personen, Firmen, Zahlen und Termine sind frei erfunden. Windows und Windows Server sind Marken der Microsoft Corporation; dieses Dokument steht in keiner Verbindung zu Microsoft.*
