# Anmerkungen zum Lehrplan P25

Beim Ausarbeiten und Testen aufgefallene Punkte. Der Lehrplan selbst wurde zusammen mit der Übungsreihe erstellt und danach **nicht** verändert.

| Nr. | Modul | Befund | Vorschlag |
|---|---|---|---|
| 1 | alle | **Basis-Image:** Docker Hub war im Cloud-Container nicht erreichbar. Alle Übungen benutzen ein selbst gebautes Image `p25/busybox:lab` aus `busybox-static` (mit `docker import`). Meldungen zu offiziellen Images (z. B. `nginx`, `alpine`) wurden nicht beobachtet. | Im Labor mit Internet die Übungen mit offiziellen Images wiederholen. |
| 2 | alle | **Daemon:** Im Cloud-Container gibt es kein systemd; `dockerd` wurde von Hand gestartet. Die Skripte starten den Daemon nicht selbst und brauchen einen laufenden Daemon. | Im Labor den Dienst mit systemd verwenden. |
| 3 | 02 | **Meldungen des Baus:** Die Ausgabe von BuildKit ist im Skript auf eine einheitliche Form gebracht (Cache-Status je Schritt), nicht roh abgedruckt. | Rohe Ausgabe im Labor ansehen. |
| 4 | 03 | **Registry:** Ohne TLS und Anmeldung; nur für `localhost` und das Übungslabor geeignet. | TLS und Benutzerverwaltung im Labor prüfen. |
| 5 | 06 | **Grenzen:** Ergebnisse zu Speicher- und Prozessgrenzen hängen von Kernel und cgroup-Version ab; Rootless-Docker, Scanner, AppArmor und SELinux wurden nicht ausgeführt. | Im Labor prüfen. |
| 6 | 07 | **Lizenzstand von Docker Desktop (20.11.2026):** Gelesen wurde nur die Zusammenfassung einer Seite von docs.docker.com (dort Aktualisierung 28.09.2026), nicht der Wortlaut. Die Lizenz von Docker Engine unter Linux wurde nicht geprüft. Keine Rechtsberatung. | Originalseite lesen; die Angabe mit Datum belegen. |
| 7 | 07 | **Priorität:** Modul 7 ist Priorität 2; der Lizenzstand (Schritt 5) ist laut Lehrplanhinweis aber Pflichtinhalt und sollte auch bei Wegfall des Moduls gelesen werden. | Schritt 5 separat behandeln. |
