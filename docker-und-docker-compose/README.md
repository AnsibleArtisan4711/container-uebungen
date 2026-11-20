# Docker und Docker Compose (P25)

Übungsreihe zu Docker und Docker Compose: Container und Images, Dockerfile, Registries, Volumes und Netzwerke, Compose, Ressourcengrenzen und Sicherheit, Lizenz von Docker Desktop und Alternativen, Aufräumen, Sicherung. 8 Module, 100 Unterrichtseinheiten zu 45 Minuten, davon 1 Modul mit Priorität 2 (Vertiefung). Die Skripte wurden mit Docker Engine unter Linux ausgeführt. Die Aufgabentexte und Kontrollfragen stammen aus dem Lehrplan P25 (Reihe „Lehrplan-Prompts“, Datei `P25-docker-und-docker-compose.md`) und sind unverändert; Hinweise, Musterlösungen und Ergänzungen sind Teil der Ausarbeitung und gekennzeichnet.

> **Prüfstand, ehrlich:** **Im Cloud-Container echt ausgeführt:** Docker Engine 29.9.2, Compose 5.7.0, lokale Registry 2.8.2 und Podman 4.9.3. **Docker Hub war nicht erreichbar**, daher ein selbst gebautes Basis-Image aus `busybox-static`. **Nicht ausgeführt:** Docker Desktop, Rootless-Docker, Image-Scanner, Docker Hub, Hyper-V. **Lizenzstand von Docker Desktop (20.11.2026):** nur aus der Zusammenfassung einer Seite von docs.docker.com gelesen, Wortlaut nicht gelesen. Die Ausgaben stehen in den Ordnern `beispiele/`. Offene Punkte: [`befehle-nicht-bestaetigt.md`](befehle-nicht-bestaetigt.md); Anmerkungen zum Lehrplan: [`lehrplan-korrekturen.md`](lehrplan-korrekturen.md).

## Umgebung

Eine Ubuntu-Server-VM `dock01` mit Docker Engine unter **Hyper-V** (Lehrplan) am privaten Switch `Lab-Docker` (`10.70.0.0/24`). Das Labor wurde **nicht** aufgebaut. Die Skripte brauchen die VM nicht, aber einen laufenden Docker-Daemon, und arbeiten unter `/tmp/p25`.

## Module

| Nr. | Modul | Zeit | Prüfstand |
|---|---|---|---|
| 01 | [Container und Images](01-container-und-images/) | 9 h | Skript im Container ausgeführt (Docker Engine 29.9.2). |
| 02 | [Dockerfile und Images bauen](02-dockerfile/) | 10,5 h | Skript im Container ausgeführt (Docker Engine 29.9.2, BuildKit). |
| 03 | [Registries](03-registries/) | 7,5 h | Skript im Container ausgeführt (lokale Registry 2.8.2). |
| 04 | [Volumes und Netzwerke](04-volumes-und-netzwerke/) | 10,5 h | Skript im Container ausgeführt (Docker Engine 29.9.2). |
| 05 | [Docker Compose](05-docker-compose/) | 10,5 h | Skript im Container ausgeführt (Compose 5.7.0). |
| 06 | [Ressourcengrenzen, Logging und Sicherheit](06-grenzen-und-sicherheit/) | 10,5 h | Skript im Container ausgeführt (Docker Engine 29.9.2). |
| 07 | [Docker Desktop, Lizenz und Alternativen](07-desktop-lizenz-und-alternativen/) (Priorität 2) | 6 h | Skript im Container ausgeführt; Lizenzstand nur aus einer Seitenzusammenfassung (20.11.2026). |
| 08 | [Betrieb, Aufräumen, Sicherung und Abschlussprojekt](08-betrieb-und-abschluss/) | 10,5 h | Skripte im Container ausgeführt (Docker Engine 29.9.2, Compose 5.7.0). |

Summe 75 Stunden.

## Aufbau eines Moduls

Ordner `NN-kurzname/` mit `README.md`, der Übung `NN.1-….md` (Lernziele, Voraussetzungen, Grundbegriffe, Aufgaben, Hinweise, Kontrollfragen, einklappbare Musterlösung, Erweiterungen, Quellen), den Skripten und Beispieldaten des Moduls und einem Ordner `beispiele/` mit den echten Ausgaben der Läufe. Die Skripte der Module liegen im jeweiligen Modulordner und binden `../lab.sh` ein. Benötigt: Docker Engine mit Compose-Plugin, `busybox-static`, `curl`; für Modul 7 zusätzlich `podman`. Die Skripte entfernen am Ende alle Ressourcen mit dem Label `p25`.

## Hinweise

- Alle Namen sind erfunden.
- Die Skripte arbeiten unter `/tmp/p25` und räumen Ressourcen mit dem Label `p25` auf.
- Die Skripte starten den Docker-Daemon nicht selbst.

## Lizenz

- Skripte: MIT, siehe [`LICENSE`](LICENSE)
- Texte: CC BY 4.0, siehe [`LICENSE-DOCS.md`](LICENSE-DOCS.md)

*Lizenz: Text CC BY 4.0, Skripte MIT, siehe `LICENSE-DOCS.md` und `LICENSE` im Kursordner. Alle Personen, Firmen, Zahlen und Termine sind frei erfunden. Windows und Windows Server sind Marken der Microsoft Corporation; dieses Dokument steht in keiner Verbindung zu Microsoft.*
