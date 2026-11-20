# Befehle und Aussagen, die nicht bestätigt sind

Prüfliste für den ersten Durchlauf in den Hyper-V-VMs: Befund und Datum eintragen, danach den Hinweis in der Übung entfernen. Legende: **Q** = gegen Quelle gelesen; **L** = im Labor (Container) ausgeführt; **–** = weder noch.

| Modul | Befehl oder Aussage | Status | Nächster Schritt |
|---|---|---|---|
| alle | Aufbau des Hyper-V-Labors (privater Switch `Lab-Container`, `pod01`), Installation von `podman`, `buildah`, `skopeo`, `uidmap` | – | laut Lehrplan aufbauen und prüfen |
| 01 | `podman run [--rm|-d]`, `ps`, `exec`, `logs`, `stop`, `rm`, `inspect`, `images` | L (Container, Image aus busybox) | auf `pod01` mit Registry-Image wiederholen |
| 02 | `useradd`, `podman load`, `podman run --network=none`, `uid_map`, `podman info` | L (Rootless ohne Netzwerk); Rootless-Netzwerk: scheiterte (`/dev/net/tun`) | auf `pod01` mit Netzwerk prüfen |
| 03 | `podman pod create`, `podman volume create`, `-v :ro`, `podman network create` | L (als root); Rootless: nicht geprüft | auf `pod01` auch Rootless prüfen |
| 04 | `podman build`, `podman history`, `buildah from/run/commit`, `skopeo copy` (`dir:`, `oci:`), `skopeo inspect --config` | L (ohne Registry); `pull`/`push`/`login`: nicht ausgeführt | Registry-Befehle auf `pod01` ausführen |
| 05 | `/usr/libexec/podman/quadlet -dryrun` mit `QUADLET_UNIT_DIRS` | L (Probelauf); systemd: nicht ausgeführt | Dienste auf `pod01` mit `systemctl` starten |
| 06 | `podman generate kube`, `podman kube play`, `podman kube down`; `compose.yaml`, `beispiel_compose.txt` | Kube: L; Compose: nicht ausgeführt | `podman-compose` auf `pod01` installieren und testen |
| 07 | `--cap-drop`, `--read-only`, `--security-opt no-new-privileges|seccomp=unconfined`, `--user`, `policy.json` | L (Container); SELinux/AppArmor, Signaturen, Scans: nicht ausgeführt | Signaturprüfung und Scan auf `pod01` testen |
| 08 | `--memory`, `--pids-limit`, `--tmpfs`, `podman inspect` | L (cgroup v1) | auf `pod01` mit cgroup v2 wiederholen |
