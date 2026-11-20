# Befehle und Aussagen, die nicht bestätigt sind

Prüfliste für den ersten Durchlauf in den Hyper-V-VMs: Befund und Datum eintragen, danach den Hinweis in der Übung entfernen. Legende: **Q** = gegen Quelle gelesen; **L** = im Labor (Container) ausgeführt; **–** = weder noch.

| Modul | Befehl oder Aussage | Status | Nächster Schritt |
|---|---|---|---|
| alle | Aufbau des Hyper-V-Labors (privater Switch `Lab-Docker`, `dock01`, Ubuntu Server mit Docker Engine) | – | laut Lehrplan aufbauen und prüfen |
| 01 | `docker run/create/start/stop/rm/logs/exec/inspect` | echt (Docker Engine 29.9.2), Basis-Image aus `busybox-static` | im Labor mit einem offiziellen Image wiederholen |
| 02 | `docker build` (BuildKit), `.dockerignore`, `--build-arg`, mehrstufiger Bau, `docker history` | echt | im Labor mit echten Basis-Images wiederholen |
| 03 | lokale Registry 2.8.2 (`registry:2`-Programm), `push/pull`, Registry-API per `curl` | echt, ohne TLS und Anmeldung; **Docker Hub nicht erreichbar** | im Labor `docker login` und eine Registry mit TLS prüfen |
| 04 | Volumes, Bind-Mount, `tmpfs`, eigene Netze, `-p` | echt | im Labor Zugriff von einem zweiten Rechner prüfen |
| 05 | `docker compose config/up/down/exec`, healthcheck, `depends_on` | echt (Compose 5.7.0) | im Labor mit offiziellen Images wiederholen |
| 06 | `--memory`, `--pids-limit`, `--cpus`, Log-Rotation, `--read-only`, `--cap-drop`, `no-new-privileges` | echt; **Rootless, Scanner, AppArmor/SELinux nicht ausgeführt** | Rootless-Docker und einen Image-Scanner im Labor ausprobieren |
| 07 | `podman` 4.9.3 (Image per `save/load`), Abfragen der installierten Werkzeuge | echt; **Docker Desktop nicht ausgeführt**; Lizenzstand nur aus einer Seitenzusammenfassung | Originalbedingungen lesen; Docker Desktop (Windows) nicht geprüft |
| 08 | `docker system df`, `prune`, Volume-Sicherung mit `tar`, Neustartrichtlinie | echt | Sicherung auf einen zweiten Rechner und Zeitplan im Labor prüfen |
