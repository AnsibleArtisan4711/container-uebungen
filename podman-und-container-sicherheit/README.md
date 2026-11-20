# Podman und Container-Sicherheit (P53)

Übungsreihe zu Podman und Container-Sicherheit: erste Container, Rootless-Betrieb, Pods, Volumes und Netzwerke, Images bauen und prüfen (Containerfile, Buildah, Skopeo), systemd-Einbindung mit Quadlet, Kubernetes-YAML und Compose, Sicherheit sowie Ressourcenlimits und Fehlersuche. 8 Module, 100 Unterrichtseinheiten zu 45 Minuten, davon 1 Modul mit Priorität 2 (Vertiefung). Praxisübungen mit Podman im Container; Registries, systemd und Compose als Text. Die Aufgabentexte und Kontrollfragen stammen aus dem Lehrplan P53 (Reihe „Lehrplan-Prompts“, Datei `P53-podman-und-container-sicherheit.md`) und sind unverändert; Hinweise, Musterlösungen und Ergänzungen sind Teil der Ausarbeitung und gekennzeichnet.

> **Prüfstand, ehrlich:** **Im Cloud-Container ausgeführt, nicht in Hyper-V.** Die Skripte liefen mit Podman 4.9.3, Buildah 1.33.7 und Skopeo 1.13.3 (Ubuntu 24.04, Kernel 6.18.44) mit einem aus `busybox` gebauten Image; die Ausgaben stehen in den Ordnern `beispiele/`. Alle Daten sind erfunden. **Registries, Signaturen, SELinux/AppArmor, Schwachstellenscans, systemd-Dienste und Compose wurden nicht ausgeführt**: Diese Teile sind Textdateien aus Fachwissen und nicht bestätigt. Bestätigt wurde das Verhalten der Programme in diesem Lauf, **nicht** gegen die Dokumentation. Offene Punkte: [`befehle-nicht-bestaetigt.md`](befehle-nicht-bestaetigt.md); Anmerkungen zum Lehrplan: [`lehrplan-korrekturen.md`](lehrplan-korrekturen.md).

## Umgebung

Eine Linux-VM unter **Hyper-V** (Lehrplan): `pod01` (`10.53.0.2`, Debian/Ubuntu oder Fedora/RHEL-Derivat) am privaten Switch `Lab-Container` (`10.53.0.0/24`). Das Labor wurde **nicht** aufgebaut. Die Skripte arbeiten stattdessen mit Podman im Test-Container (Daten unter `/tmp/p53`) und brauchen `root`.

## Module

| Nr. | Modul | Zeit | Prüfstand |
|---|---|---|---|
| 01 | [Podman im Überblick: erste Container](01-podman-im-ueberblick/) | 9 h | Skript im Container ausgeführt. |
| 02 | [Rootless-Container](02-rootless-container/) | 9 h | Skript im Container ausgeführt; Rootless-Netzwerk dort nicht möglich. |
| 03 | [Pods, Volumes und Netzwerke](03-pods-volumes-und-netzwerke/) | 10,5 h | Skript im Container ausgeführt. |
| 04 | [Images bauen und prüfen: Containerfile, Buildah, Skopeo](04-images-bauen-und-pruefen/) | 10,5 h | Bauen, Buildah und Skopeo im Container ausgeführt; Registry nicht ausgeführt. |
| 05 | [systemd-Einbindung mit Quadlet](05-systemd-einbindung-mit-quadlet/) | 9 h | Probelauf des Generators ausgeführt; systemd nicht ausgeführt. |
| 06 | [Mehrere Container: Kubernetes-YAML und Compose](06-kubernetes-yaml-und-compose/) (Priorität 2) | 7,5 h | Kube ausgeführt; Compose nicht ausgeführt. |
| 07 | [Container-Sicherheit](07-container-sicherheit/) | 10,5 h | Capabilities, Härtung und seccomp im Container ausgeführt; SELinux/AppArmor/Signaturen/Scans nicht. |
| 08 | [Ressourcenlimits und Fehlersuche](08-ressourcenlimits-und-fehlersuche/) | 9 h | Skript im Container ausgeführt. |

Summe 75 Stunden.

## Aufbau eines Moduls

Ordner `NN-kurzname/` mit `README.md`, der Übung `NN.1-….md` (Lernziele, Voraussetzungen, Grundbegriffe, Aufgaben, Hinweise, Kontrollfragen, einklappbare Musterlösung, Erweiterungen, Quellen), den Skripten und Beispieldaten des Moduls und einem Ordner `beispiele/` mit den echten Ausgaben der Läufe. Die Skripte der Module liegen im jeweiligen Modulordner und binden `../lab.sh` ein.

## Hinweise

- Die Skripte starten und entfernen Container, Pods, Volumes, Netzwerke und Images und legen den Benutzer `rl1` an. **Nicht auf einem Rechner mit vorhandenen Container-Daten ausführen**: `lab_down` entfernt dort **alle** Container, Pods, Volumes, Netzwerke und Images (`podman rm -af`, `podman rmi -af`).
- Alle Namen, Adressen (`10.53.0.0/24`) und Daten sind erfunden.
- Die Textdateien `beispiel_compose.txt` und `compose.yaml` wurden nicht ausgeführt und nicht gegen die Dokumentation geprüft.

## Lizenz

- Skripte: MIT, siehe [`LICENSE`](LICENSE)
- Texte: CC BY 4.0, siehe [`LICENSE-DOCS.md`](LICENSE-DOCS.md)

*Lizenz: Text CC BY 4.0, Skripte MIT, siehe `LICENSE-DOCS.md` und `LICENSE` im Kursordner. Alle Personen, Firmen, Zahlen und Termine sind frei erfunden. Windows und Windows Server sind Marken der Microsoft Corporation; dieses Dokument steht in keiner Verbindung zu Microsoft.*
