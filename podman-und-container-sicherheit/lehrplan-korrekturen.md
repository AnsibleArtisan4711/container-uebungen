# Anmerkungen zum Lehrplan P53

Beim Ausarbeiten und Testen aufgefallene Punkte. Der Lehrplan selbst wurde zusammen mit der Übungsreihe erstellt und danach **nicht** verändert.

| Nr. | Modul | Befund | Vorschlag |
|---|---|---|---|
| 1 | alle | **Ausführung:** Alle Skripte liefen im Cloud-Container (Ubuntu 24.04, Kernel 6.18.44, cgroup v1, kein systemd) mit Podman 4.9.3, Buildah 1.33.7 und Skopeo 1.13.3, mit einem aus `busybox` gebauten Image. Das Verhalten mit Registry-Images, anderen Versionen und cgroup v2 wurde nicht getestet. | Übungen auf `pod01` nachvollziehen; Ausgaben vergleichen. |
| 2 | alle | **Nicht ausführbar im Container:** Registries, Signaturen, SELinux/AppArmor, Schwachstellenscanner, systemd-Dienste, Podman Compose und Rootless-Netzwerk. Diese Teile sind Textdateien aus Fachwissen und **nicht bestätigt**. | Auf `pod01` ausführen und Ergebnis eintragen. |
| 3 | alle | **Quellen:** Die Dokumentation von Podman, Buildah, Skopeo und Quadlet wurde nicht gelesen. | Quellen lesen und eintragen. |
| 4 | 01 | **Exitcode 137:** `podman stop -t 1` beendete den Container nach SIGKILL; die Ursache (Prozess 1 ist `sh`) ist eine Beobachtung dieses Laufs. | Mit anderen Programmen als Prozess 1 vergleichen. |
| 5 | 02 | **Rootless-Netzwerk:** `slirp4netns` scheiterte im Container an `/dev/net/tun`; die Rootless-Übungen laufen deshalb mit `--network=none`. | Auf `pod01` mit Netzwerk prüfen. |
| 6 | 04 | **Buildah-Warnungen:** `buildah run` meldete Warnungen zu Capabilities (ambient); sie wurden aus der Ausgabe entfernt. | Ursache auf `pod01` prüfen. |
| 7 | 06 | **Priorität:** Modul 6 ist Priorität 2; kein anderes Modul setzt es voraus. Compose wurde nicht ausgeführt. | Bei Zeitmangel entfallen lassen. |
| 8 | 08 | **OOM:** Der Container endete mit Exitcode 137, Podman zeigte aber `OOMKilled=false`; die Ursache wurde nicht untersucht. | Auf `pod01` (cgroup v2) prüfen. |
