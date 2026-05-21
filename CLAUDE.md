# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Was ist das?

Ein kleines Linux-Projekt, das eine **Cleware USB-Ampel** als Statusanzeige für
Claude Code selbst nutzt: rot = arbeitet, gelb = wartet auf Eingabe, grün =
fertig (mit 5-Min-Abschalt-Timer), aus = nichts läuft.

## Struktur

- `bin/` – die eigentlich gepflegten Hook-Skripte (`claude_on_start.sh`,
  `claude_on_ask.sh`, `claude_on_stop.sh`, `claude_off.sh`).
- `cleware/` – **Fremdcode der Cleware GmbH** (GPLv3): C/C++-Quellen, `Makefile`
  und vorgebaute Binaries. Hier in der Regel **nichts ändern** – nur das Binary
  `USBswitchCmd` wird benötigt.
- `cleware-install.sh` – Installer, der aus dem Git-Checkout heraus installiert.

## Wie es zusammenhängt

Hook-Skript → ruft `/usr/src/cleware/USBswitchCmd <R|Y|G|0>` auf → schaltet die
Ampel. `USBswitchCmd` braucht USB-Zugriff und wird daher bei der Installation
**setuid root** (`chmod 4755`) gesetzt.

`claude_on_stop.sh` startet einen Hintergrund-Off-Timer (Default 300 s) via
`setsid`; die PID liegt in `/tmp/claude_off_timer_$USER.pid`. `claude_on_start.sh`
und `claude_on_ask.sh` brechen einen laufenden Timer ab.

## Konventionen

- Skripte sind Bash, Kommentare und Ausgaben auf **Deutsch** – Stil beibehalten.
- Die Skripte verweisen fest auf `/usr/src/cleware/USBswitchCmd`. Wird dieser
  Pfad geändert, muss er in **allen** `bin/`-Skripten und im Installer konsistent
  bleiben.
- Installer-Logik liegt komplett in `cleware-install.sh`; er muss als root laufen
  und arbeitet relativ zu `SCRIPT_DIR` (kein Tar-Archiv mehr).

## Prüfen / Testen

- Syntaxcheck: `bash -n cleware-install.sh` bzw. `bash -n bin/*.sh`.
- Funktionstest braucht echte Hardware (angeschlossene Cleware-Ampel) – siehe
  Smoke-Test in der `README.md`.
- Cleware-Tools bauen: `make -C cleware USBswitchCmd`.

## Beim Ändern beachten

- Pfade und Berechtigungen (`setuid`) im Installer nicht versehentlich entfernen.
- Den Default-Timer (300 s) nur bewusst ändern (`DELAY_SECONDS` in
  `claude_on_stop.sh`).
- Keine destruktiven Aktionen gegen `/usr/src/cleware/` oder `/usr/local/bin/`
  ohne Rückfrage.
