# Container – Übungsreihen

Praxisübungen zu Containern: Docker und Docker Compose, Kubernetes-Grundlagen sowie Podman (Rootless-Betrieb, Pods, Images, Quadlet, Sicherheit und Ressourcenlimits). Jede Reihe liegt in einem eigenen Ordner mit Modulen, Material und Skripten.

## Reihen

| Ordner | Thema | Stand |
|---|---|---|
| [`docker-und-docker-compose/`](docker-und-docker-compose/) | Docker und Docker Compose (P25): 8 Module, 100 Unterrichtseinheiten | Entwurf, Skripte mit Docker Engine 29.9.2, Compose 5.7.0, lokaler Registry und Podman im Cloud-Container ausgeführt (Basis-Image aus `busybox-static`, Docker Hub nicht erreichbar); Docker Desktop, Rootless-Docker, Image-Scanner und Hyper-V nicht ausgeführt; Lizenzstand von Docker Desktop nur aus einer Seitenzusammenfassung (20.11.2026) |
| [`kubernetes-grundlagen/`](kubernetes-grundlagen/) | Kubernetes-Grundlagen (P26): 8 Module, 100 Unterrichtseinheiten | Entwurf, Manifeste mit `kubernetes-validate` (Schema 1.31) geprüft; **Kubernetes nicht ausgeführt**, der Cluster ist ein Lernmodell in Python; Hyper-V nicht |
| [`podman-und-container-sicherheit/`](podman-und-container-sicherheit/) | Podman und Container-Sicherheit (P53): 8 Module, 100 Unterrichtseinheiten | Entwurf, Skripte mit Podman 4.9.3, Buildah und Skopeo im Cloud-Container ausgeführt; Registries, Signaturen, systemd-Dienste und Compose nicht ausgeführt, Hyper-V nicht |

## Lizenz

- Skripte: MIT, siehe [`LICENSE`](LICENSE)
- Texte: CC BY 4.0, siehe [`LICENSE-DOCS.md`](LICENSE-DOCS.md)

Podman, Buildah, Skopeo und Red Hat sind Marken bzw. Projekte von Red Hat, Inc.; Docker ist eine Marke von Docker, Inc.; Kubernetes ist eine Marke der Linux Foundation; Ubuntu ist eine Marke von Canonical Ltd. Dieses Repository steht in keiner Verbindung zu den Markeninhabern. Der Teststatus jeder Reihe steht in deren README.
