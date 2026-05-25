# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Was ist das?

Ein kleines Linux-Projekt, das eine **Cleware USB-Ampel** als Statusanzeige für
Claude Code selbst nutzt: rot = arbeitet, gelb = echte Rückfrage (Claude ist
blockiert und wartet auf eine Antwort), grün = Zwischenschritt erreicht oder
fertig (mit 5-Min-Abschalt-Timer), aus = nichts läuft.

## Struktur

- `bin/claude-signal` – **Dispatcher**. Bekommt ein Signal (`start|ask|stop|off`) und
  führt alle ausführbaren Skripte im passenden Verzeichnis aus (analog zu
  `/etc/cron.daily`). Wird nach `/usr/local/bin/claude-signal` installiert. Liest das
  von Claude Code per stdin gelieferte **Hook-JSON** einmal zentral ein, exportiert
  daraus `CLAUDE_HOOK_EVENT`, `CLAUDE_AGENT_ID`, `CLAUDE_AGENT_TYPE` und das rohe
  `CLAUDE_HOOK_JSON` für die Drop-ins und schreibt ein **Diagnose-Log** (siehe unten).
- `claude-ampel/` – Inhalt für `/etc/claude-ampel/`: die vier Signal-Verzeichnisse
  `start.d/`, `ask.d/`, `stop.d/`, `off.d/` mit den mitgelieferten Drop-in-Skripten,
  dazu die geteilte `lib.sh` und der Ton-Player `ring.sh`. **Hier liegt die Logik.**
- `cleware/` – **Fremdcode der Cleware GmbH** (GPLv3): C/C++-Quellen, `Makefile`
  und vorgebaute Binaries. Hier in der Regel **nichts ändern** – nur das Binary
  `USBswitchCmd` wird benötigt.
- `cleware-install.sh` – Installer, der aus dem Git-Checkout heraus installiert.

## Wie es zusammenhängt

Der Kerngedanke: Statt fest verdrahteter Aktionen gibt es **vier Signal-Verzeichnisse**
unter `/etc/claude-ampel/`, in die man – wie bei `/etc/cron.daily` – beliebige
ausführbare Skripte ablegen kann. Die Ampel selbst ist nur noch eines dieser
Drop-ins, der Ring-Ton ein weiteres.

Hook-Event → `claude-signal <signal>` → führt `/etc/claude-ampel/<signal>.d/*`
(alphabetisch, daher Präfixe `10-`, `20-`) aus. Die Zuordnung schreibt der
Installer in die `~/.claude/settings.json` des aufrufenden Users:

- `UserPromptSubmit` → `claude-signal start` (rot)
- `PreToolUse` mit Matcher `AskUserQuestion` → `claude-signal ask` (gelb)
- `PostToolUse` mit Matcher `AskUserQuestion` → `claude-signal start` (rot)
- `Notification` mit Matcher `permission_prompt` → `claude-signal ask` (gelb)
- `Stop` → `claude-signal stop` (grün)

Das vierte Signal `off` (Ampel ganz aus) ist **keinem Hook zugeordnet** – es ist ein
manueller Befehl zum sofortigen Ausschalten (`claude-signal off`), z. B. zum Aufräumen
oder um es selbst an einen Hook zu hängen. Im Normalbetrieb schaltet ohnehin der
5-Min-Off-Timer nach `stop` aus.

Mitgelieferte Drop-ins je Verzeichnis:

- `start.d/` → `10-ampel.sh` (rot + Off-Timer stoppen), `20-ring.sh` (Ring stoppen)
- `ask.d/`   → `10-ampel.sh` (gelb + Off-Timer stoppen), `20-ring.sh` (Ring starten)
- `stop.d/`  → `10-ampel.sh` (grün + Off-Timer armen), `20-ring.sh` (Ring starten)
- `off.d/`   → `10-ampel.sh` (aus + Off-Timer stoppen), `20-ring.sh` (Ring stoppen)

Die Drop-ins sourcen `../lib.sh` und nutzen deren Helfer: `ampel <R|Y|G|O>` schaltet
die Ampel über `/usr/src/cleware/USBswitchCmd` (USB-Zugriff → bei Installation
**setuid root**, `chmod 4755`), `ampel_off` schaltet sie komplett aus (über den
Aus-Befehl `O`, der rot/grün/gelb in **einem** Aufruf abschaltet – kein Zwischen-Rot;
Achtung: die Ziffer `0` schaltet nur den roten Kanal),
`off_timer_arm`/`off_timer_cancel` verwalten den Abschalt-Timer,
`ring_start`/`ring_cancel` den Ring-Ton.

`PostToolUse`/`AskUserQuestion` feuert, wenn die Frage **beantwortet** ist und
Claude weiterarbeitet – so wechselt die Ampel von gelb zurück auf rot (und der
Ring stoppt), statt bis zum nächsten `Stop` (grün) gelb zu bleiben.

Gelb wird **bewusst** nur über das Frage-Tool `AskUserQuestion` bzw. eine
Berechtigungsanfrage ausgelöst – nicht über den allgemeinen `Notification`-Hook,
weil dieser auch im Leerlauf feuert und die Ampel sonst grundlos gelb färbt.
Prosa-Fragen sind über Hooks nicht erkennbar; ein solcher Turn endet mit `Stop`
(grün).

`stop.d/10-ampel.sh` startet einen Hintergrund-Off-Timer (Default 300 s, via
`lib.sh` `off_timer_arm`) mit `setsid`; die PID (PGID) liegt in
`/tmp/claude_off_timer_$USER.pid`. `start.d/`/`ask.d/`/`off.d/` brechen ihn ab.

Der **Ring-Ton** (`ring.sh`) spielt einen Ton **einmalig**
als Hintergrundjob (PID in `/tmp/claude_ring_$USER.pid`). `ask`
und `stop` starten ihn, `start` bricht ihn ab. Einstellbar über Umgebungsvariablen
`CLAUDE_RING_COUNT` (1), `CLAUDE_RING_INTERVAL` (0 s), `CLAUDE_RING_SOUND` (Pfad
zur Sounddatei). Der
Player wird automatisch gesucht (paplay/pw-play/ffplay/play/aplay), sonst ertönt
die Terminal-Glocke.

## Git / Commits

- Nach Abschluss einer Aufgabe **alle Änderungen automatisch committen und
  pushen — ohne Rückfrage**. Nicht nachfragen, ob committet/gepusht werden soll,
  sondern es einfach tun (aussagekräftige Commit-Message, dann `git push`).

## Eigene Aktionen hinzufügen

Einfach ein ausführbares Skript in das passende Verzeichnis legen, z. B.
`/etc/claude-ampel/stop.d/30-desktop-notify.sh`. Es wird beim jeweiligen Signal
automatisch mit ausgeführt (alphabetische Reihenfolge → sinnvolle Zahlen-Präfixe
wählen). Helfer aus `lib.sh` (`ampel`, `job_spawn`, `job_cancel`, …) stehen nach
`. "$(dirname "$0")/../lib.sh"` zur Verfügung. Der Signalname liegt zusätzlich in
`$CLAUDE_SIGNAL`; zum Hook-Kontext stehen `$CLAUDE_HOOK_EVENT` (echtes Event, z. B.
`Stop` vs. `SubagentStop`), `$CLAUDE_AGENT_ID`, `$CLAUDE_AGENT_TYPE` und das rohe
`$CLAUDE_HOOK_JSON` bereit. Lang laufende Aktionen müssen sich selbst in den
Hintergrund schicken (siehe Off-Timer/Ring via `job_spawn`), damit der Hook nicht
blockiert.

## Diagnose-Log

Der Dispatcher protokolliert jeden Aufruf zeilenweise (Zeitpunkt, Signal, echtes
Hook-Event, Agent-Typ, rohes JSON) – damit lässt sich z. B. ein zu früh oder
grundlos klingelnder Ton dem auslösenden Event zuordnen (klingeln nur `ask` und
`stop`). Default-Pfad: `/tmp/claude-signal_<user>.log` (bei ~1 MB wird gekappt).

- Live mitlesen: `tail -f /tmp/claude-signal_$USER.log`
- Abschalten: Umgebungsvariable `CLAUDE_SIGNAL_LOG` leer (`""`) oder auf `off`
  setzen (z. B. unter `"env"` in der `settings.json`); eigener Pfad über denselben
  Namen.
- Pattern für „Ton zu früh": ein `signal=stop event=Stop`, dem **ohne**
  zwischenzeitliches `event=UserPromptSubmit` weitere Aktivität folgt → der
  Haupt-Agent hat weitergearbeitet (z. B. wegen eines Hintergrund-Agenten), der
  `stop`-Ton war also verfrüht.

## Konventionen

- Skripte sind Bash, Kommentare und Ausgaben auf **Deutsch** – Stil beibehalten.
- Der Pfad zu `USBswitchCmd` steht **zentral** in `claude-ampel/lib.sh`
  (`USBSWITCH_CMD`, Default `/usr/src/cleware/USBswitchCmd`). Nur dort pflegen –
  die Drop-ins nutzen die `ampel`-Funktion, hängen also nicht jeweils am Pfad.
- Installer-Logik liegt komplett in `cleware-install.sh`; er muss als root laufen
  und arbeitet relativ zu `SCRIPT_DIR` (kein Tar-Archiv mehr).

## Prüfen / Testen

- Syntaxcheck: `bash -n cleware-install.sh`, `bash -n bin/claude-signal`,
  `bash -n claude-ampel/*.sh claude-ampel/*/*.sh`.
- Dispatcher ohne Hardware testen: `CLAUDE_AMPEL_DIR` auf den Repo-Baum und
  `USBSWITCH_CMD` auf ein Stub-Skript setzen, dann `bin/claude-signal start|ask|stop`.
- Funktionstest mit Hardware (angeschlossene Cleware-Ampel) – siehe Smoke-Test in
  der `README.md`.
- Cleware-Tools bauen: `make -C cleware USBswitchCmd`.

## Beim Ändern beachten

- Pfade und Berechtigungen (`setuid`) im Installer nicht versehentlich entfernen.
- Den Default-Off-Timer (300 s) nur bewusst ändern (`CLAUDE_OFF_DELAY` in
  `lib.sh` `off_timer_arm`); Ring-Defaults entsprechend in `ring.sh`.
- Keine destruktiven Aktionen gegen `/usr/src/cleware/`, `/usr/local/bin/` oder
  `/etc/claude-ampel/` ohne Rückfrage. Der Installer überschreibt mit `cp` nur die
  mitgelieferten Dateien und löscht **keine** fremden Drop-ins. Einzige Ausnahme:
  er entfernt gezielt die **eigenen** verwaisten Alt-Skripte
  (`claude_on_*.sh`, `claude_off.sh`) aus `/usr/local/bin/` – diese Liste nur
  bewusst erweitern.
- Gelb-Trigger **nicht** wieder auf den allgemeinen `Notification`-Hook
  umstellen (feuert im Leerlauf → grundloses Gelb). Bei `AskUserQuestion`
  (PreToolUse) bzw. `permission_prompt` bleiben.
- Schreibt der Installer die Hooks, immer in das Home des **aufrufenden** Users
  (`SUDO_USER`) und danach `chown` auf diesen User – nicht als root anlegen.
