# cleware-ampel

Steuert eine **Cleware USB-Ampel** als Statusanzeige für [Claude Code](https://claude.com/claude-code):

| Ampel | Bedeutung |
|-------|-----------|
| 🔴 Rot | Claude arbeitet |
| 🟡 Gelb | Claude wartet auf deine Antwort (echte Rückfrage / Berechtigung) |
| 🟢 Grün | Claude hat einen Zwischenschritt erreicht oder ist fertig (danach 5-Min-Timer bis „aus“) |
| ⚫ Aus | nichts läuft / Timer abgelaufen |

Umgesetzt über Claude-Code-Hooks, die einen **Dispatcher** (`claude-signal`)
aufrufen. Dieser führt – wie `/etc/cron.daily` – alle Skripte im passenden
Signal-Verzeichnis aus. Die Ampel ist nur eines dieser Skripte; weitere Aktionen
(z. B. ein Ring-Ton) lassen sich einfach dazulegen.

> **Hardware & Software:** Beschreibung der Ampel und Download der
> Cleware-Software unter <https://www.cleware-shop.de/>.

## Aufbau

```
bin/
  claude-signal       Dispatcher: führt /etc/claude-ampel/<signal>.d/* aus
                      (-> /usr/local/bin/claude-signal)
claude-ampel/         Inhalt für /etc/claude-ampel/ (Signal-Verzeichnisse)
  lib.sh              gemeinsame Helfer (ampel, Timer, Ring)  – wird gesourct
  ring.sh             spielt den Ring-Ton einmalig
  start.d/            Signal "start" (rot):  10-ampel.sh, 20-ring.sh (Ring stoppen)
  ask.d/              Signal "ask"  (gelb): 10-ampel.sh, 20-ring.sh (Ring starten)
  stop.d/             Signal "stop" (grün): 10-ampel.sh, 20-ring.sh (Ring starten)
  off.d/              Signal "off"  (aus):  10-ampel.sh, 20-ring.sh (Ring stoppen)
cleware/              Cleware-Hersteller-Tools (C/C++-Quellen, Makefile, Binaries)
  USBswitchCmd        Programm zum Schalten der Ampel/Switches (GPLv3)
  ...                 weitere Beispiel-Tools der Cleware GmbH
cleware-install.sh    Installer (Tools + Dispatcher + Signal-Verzeichnisse + Hooks)
```

## Voraussetzungen

- Linux mit angeschlossener Cleware-Ampel (USB Traffic Light)
- `sudo`-Rechte für die Installation
- Zum Bauen aus dem Quellcode: `make`, `gcc`/`g++` (optional – sonst werden die
  mitgelieferten Binaries verwendet)

## Installation

Repo klonen und Installer als root ausführen:

```bash
git clone git@github.com:gameplanXXL/cleware-ampel-.git
cd cleware-ampel-
sudo bash cleware-install.sh
```

Der Installer:

1. baut `USBswitchCmd` aus dem Quellcode (falls `make` vorhanden), sonst nutzt er
   das mitgelieferte Binary,
2. kopiert die Cleware-Tools nach `/usr/src/cleware/` und setzt `USBswitchCmd`
   auf **setuid root** (`chmod 4755`), damit der USB-Zugriff ohne `sudo` klappt,
3. installiert den Dispatcher nach `/usr/local/bin/claude-signal` und die
   Signal-Verzeichnisse nach `/etc/claude-ampel/` (und entfernt dabei verwaiste
   Alt-Skripte `claude_on_*.sh`/`claude_off.sh` aus `/usr/local/bin/`),
4. trägt die Hooks in die `~/.claude/settings.json` des aufrufenden Users ein
   (per `jq`-Merge; vorhandene Einstellungen und fremde Hooks bleiben erhalten,
   alte `claude_on_*.sh`-Einträge werden auf `claude-signal` migriert).

> Hinweis: Es muss **kein Tar-Archiv** mehr entpackt werden – der Installer
> arbeitet direkt mit dem ausgecheckten Git-Repo.

### Smoke-Test

```bash
/usr/local/bin/claude-signal start   # Ampel rot
/usr/local/bin/claude-signal ask     # Ampel gelb + Ring-Ton (einmalig)
/usr/local/bin/claude-signal stop    # Ampel grün, 5-Min-Timer + Ring-Ton
/usr/local/bin/claude-signal off     # Ampel ganz aus, Timer + Ring-Ton stoppen
```

## Anbindung an Claude Code

Die Hooks rufen den Dispatcher `claude-signal <signal>` auf. Der Installer trägt
diese Zuordnung automatisch in die `~/.claude/settings.json` ein:

| Hook-Ereignis | Dispatcher-Aufruf | Signal / Ampel |
|---------------|-------------------|----------------|
| `UserPromptSubmit` | `claude-signal start` | rot |
| `PreToolUse` (Matcher `AskUserQuestion`) | `claude-signal ask` | gelb |
| `PostToolUse` (Matcher `AskUserQuestion`) | `claude-signal start` | rot |
| `Notification` (Matcher `permission_prompt`) | `claude-signal ask` | gelb |
| `Stop` | `claude-signal stop` | grün |

Zusätzlich gibt es `claude-signal off` (Ampel ganz aus, Timer + Ring-Ton stoppen).
Es ist **keinem Hook zugeordnet**, sondern ein manueller Befehl zum sofortigen
Ausschalten – im Normalbetrieb erledigt das ohnehin der 5-Min-Timer nach `stop`.

**Gelb gezielt:** Es wird bewusst **nicht** der allgemeine `Notification`-Hook
verwendet, weil dieser auch im Leerlauf (~60 s nach Turn-Ende) feuert und die
Ampel dann fälschlich gelb färbte. Gelb erscheint nur, wenn Claude tatsächlich
blockiert ist und auf eine Antwort wartet – also beim Frage-Tool
`AskUserQuestion` oder einer Berechtigungsanfrage. Eine frei in Prosa gestellte
Frage lässt sich über Hooks nicht zuverlässig erkennen; ein solcher Turn endet
mit `Stop` und zeigt daher **grün**.

`stop.d/10-ampel.sh` startet einen Hintergrund-Timer (Standard: 300 s), der die
Ampel danach ausschaltet. Ein erneutes `start`/`ask`/`off` bricht einen noch
laufenden Off-Timer ab. Die Timer-PID liegt in `/tmp/claude_off_timer_$USER.pid`.

## Eigene Aktionen hinzufügen

Wie bei `/etc/cron.daily`: ein **ausführbares** Skript in das passende
Verzeichnis legen, fertig.

```bash
sudo tee /etc/claude-ampel/stop.d/30-desktop-notify.sh >/dev/null <<'EOF'
#!/bin/bash
notify-send "Claude" "Schritt erledigt."
EOF
sudo chmod +x /etc/claude-ampel/stop.d/30-desktop-notify.sh
```

Die Skripte laufen in alphabetischer Reihenfolge (daher die Präfixe `10-`,
`20-`, …). Helfer aus `lib.sh` (`ampel`, `job_spawn`, `job_cancel`, …) stehen nach
`. "$(dirname "$0")/../lib.sh"` bereit; der Signalname liegt in `$CLAUDE_SIGNAL`.
Lang laufende Aktionen müssen sich selbst in den Hintergrund schicken, damit der
Hook nicht blockiert.

## Ring-Ton

Bei `ask` (Rückfrage) und `stop` (fertig) spielt `ring.sh` einen Ton
**einmalig** – als akustische Erinnerung, falls die Ampel gerade
nicht im Blick ist. Kein dauerhaftes Klingeln: nach dem Ton ist Ruhe. Beim
nächsten `start` wird ein noch laufender Ton abgebrochen. Steuerbar über
Umgebungsvariablen (z. B. in der `settings.json` unter `env` oder global):

| Variable | Default | Bedeutung |
|----------|---------|-----------|
| `CLAUDE_RING_COUNT` | `1` | Anzahl der Töne |
| `CLAUDE_RING_INTERVAL` | `0` | Sekunden zwischen den Tönen (0 ⇒ direkt hintereinander) |
| `CLAUDE_RING_SOUND` | (System-Sound) | Pfad zu einer eigenen Sounddatei |

Der Player wird automatisch gewählt (`paplay`, `pw-play`, `ffplay`, `play`,
`aplay`). Findet sich kein Player oder Sound, ertönt ersatzweise die
Terminal-Glocke.

## `USBswitchCmd` direkt nutzen

```bash
USBswitchCmd R     # Rot
USBswitchCmd Y     # Gelb
USBswitchCmd G     # Grün
USBswitchCmd 0     # Aus
USBswitchCmd -l    # angeschlossene Cleware-Geräte auflisten
USBswitchCmd -h    # Hilfe
```

## Cleware-Tools neu bauen

```bash
cd cleware
make            # alle Tools
make USBswitchCmd   # nur das Ampel-Tool
```

## Cleware-Tools & Binaries

Die Tools im Verzeichnis `cleware/` stammen von der **Cleware GmbH**
(<https://www.cleware-shop.de/>). Die vorgebauten Binaries (`USBswitchCmd` etc.)
sind **bewusst mit eingecheckt** und dienen als Fallback auf Systemen ohne
Build-Werkzeuge (`make`/`gcc`). Daher gibt es hierfür keine `.gitignore`.

## Lizenz

Die Cleware-Tools im Verzeichnis `cleware/` stammen von der **Cleware GmbH** und
stehen unter der **GNU GPL v3** (siehe `cleware/gpl-3.0.txt`).
