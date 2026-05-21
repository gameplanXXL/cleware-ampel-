# cleware-ampel

Steuert eine **Cleware USB-Ampel** als Statusanzeige für [Claude Code](https://claude.com/claude-code):

| Ampel | Bedeutung |
|-------|-----------|
| 🔴 Rot | Claude arbeitet |
| 🟡 Gelb | Claude wartet auf eine Eingabe |
| 🟢 Grün | Claude ist fertig (danach 5-Min-Timer bis „aus“) |
| ⚫ Aus | nichts läuft / Timer abgelaufen |

Umgesetzt über Claude-Code-Hooks, die kleine Shell-Skripte aufrufen, welche
wiederum das Cleware-Tool `USBswitchCmd` ansteuern.

> **Hardware & Software:** Beschreibung der Ampel und Download der
> Cleware-Software unter <https://www.cleware-shop.de/>.

## Aufbau

```
bin/                  Hook-Skripte für Claude Code
  claude_on_start.sh  -> Ampel rot   (Arbeit beginnt, Off-Timer wird gestoppt)
  claude_on_ask.sh    -> Ampel gelb  (wartet auf Eingabe, Off-Timer wird gestoppt)
  claude_on_stop.sh   -> Ampel grün  (fertig, startet 5-Min-Off-Timer)
  claude_off.sh       -> Ampel aus
cleware/              Cleware-Hersteller-Tools (C/C++-Quellen, Makefile, Binaries)
  USBswitchCmd        Programm zum Schalten der Ampel/Switches (GPLv3)
  ...                 weitere Beispiel-Tools der Cleware GmbH
cleware-install.sh    Installer (Tools + Hook-Skripte systemweit installieren)
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
3. installiert die Hook-Skripte nach `/usr/local/bin/`.

> Hinweis: Es muss **kein Tar-Archiv** mehr entpackt werden – der Installer
> arbeitet direkt mit dem ausgecheckten Git-Repo.

### Smoke-Test

```bash
/usr/local/bin/claude_on_start.sh   # Ampel rot
/usr/local/bin/claude_on_ask.sh     # Ampel gelb
/usr/local/bin/claude_on_stop.sh    # Ampel grün, 5-Min-Timer läuft
/usr/local/bin/claude_off.sh        # Ampel aus
```

## Anbindung an Claude Code

Die Skripte sind als Claude-Code-Hooks gedacht. Beispielhafte Zuordnung in der
Claude-Code-Konfiguration (`~/.claude/settings.json`):

| Hook-Ereignis        | Skript                              | Ampel |
|----------------------|-------------------------------------|-------|
| `SessionStart` / `UserPromptSubmit` | `/usr/local/bin/claude_on_start.sh` | rot |
| `Notification` (wartet auf Eingabe) | `/usr/local/bin/claude_on_ask.sh`   | gelb |
| `Stop`               | `/usr/local/bin/claude_on_stop.sh`  | grün |

`claude_on_stop.sh` startet einen Hintergrund-Timer (Standard: 300 s), der die
Ampel danach via `claude_off.sh` ausschaltet. Ein erneuter Start (`rot`/`gelb`)
bricht einen noch laufenden Off-Timer ab. Der Timer-PID wird in
`/tmp/claude_off_timer_$USER.pid` abgelegt.

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
