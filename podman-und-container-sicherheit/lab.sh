#!/usr/bin/env bash
# Gemeinsame Hilfen der Übungsreihe (P53). Nur im Testlabor als root ausführen.
# Es wird ein winziges Image localhost/bb:1 aus der statischen busybox gebaut (kein Zugriff auf eine Registry nötig).
W=/tmp/p53; IMG=localhost/bb:1; RL=rl1
step() { echo; echo "## $*"; }
cmd() { echo "\$ $*"; "$@" 2>&1; return $?; }
base_image() {
  mkdir -p $W/rootfs/bin; cp "$(command -v busybox)" $W/rootfs/bin/busybox
  for a in sh ls id cat sleep httpd wget touch echo ps mkdir hostname head tail grep hostname env true false dd nc date sync; do ln -sf busybox $W/rootfs/bin/$a; done
  tar -C $W/rootfs -cf - . | podman import --change 'CMD ["sh"]' - $IMG >/dev/null 2>&1
}
rl() { su $RL -s /bin/bash -c "cd /tmp; $*" 2>&1; }
lab_up() { lab_down >/dev/null 2>&1; mkdir -p $W; base_image; }
lab_down() {
  podman pod rm -af >/dev/null 2>&1; podman rm -af >/dev/null 2>&1
  podman volume rm -af >/dev/null 2>&1; podman network rm -f lab >/dev/null 2>&1
  podman rmi -af >/dev/null 2>&1
  if id $RL >/dev/null 2>&1; then rl "podman rm -af; podman rmi -af" >/dev/null 2>&1; pkill -KILL -u $RL 2>/dev/null; sleep 1; userdel -r $RL >/dev/null 2>&1; fi
  rm -rf $W
  return 0
}
