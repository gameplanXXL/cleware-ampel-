#!/bin/bash
# Installer: Cleware-USB-Ampel + Claude-Hook-Scripts.
#
# Installiert direkt aus dem ausgecheckten Git-Repo – es muss kein
# Tar-Archiv mehr entpackt werden.
# Aufruf:  sudo bash cleware-install.sh

set -euo pipefail

if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    echo "Bitte als root oder mit sudo ausführen." >&2
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Plausibilitätscheck: liegen die erwarteten Quellen neben dem Skript?
if [ ! -d "$SCRIPT_DIR/cleware" ] || [ ! -d "$SCRIPT_DIR/bin" ] \
   || [ ! -d "$SCRIPT_DIR/claude-ampel" ]; then
    echo "Fehler: 'cleware/', 'bin/' oder 'claude-ampel/' nicht neben dem Skript gefunden." >&2
    echo "       Das Skript muss aus dem ausgecheckten Repo heraus laufen." >&2
    exit 1
fi

echo "==> Cleware-Installer"

# 0. USBswitchCmd nach Möglichkeit frisch aus dem Quellcode bauen, damit das
#    setuid-Binary zum Zielsystem passt. Schlägt das fehl bzw. fehlt make,
#    wird das im Repo mitgelieferte Binary verwendet.
if command -v make >/dev/null 2>&1; then
    echo "    Baue USBswitchCmd aus dem Quellcode ..."
    if ! make -C "$SCRIPT_DIR/cleware" USBswitchCmd; then
        echo "    Warnung: Build fehlgeschlagen – nutze vorgebautes Binary." >&2
    fi
else
    echo "    'make' nicht gefunden – nutze vorgebautes Binary."
fi

if [ ! -x "$SCRIPT_DIR/cleware/USBswitchCmd" ]; then
    echo "Fehler: $SCRIPT_DIR/cleware/USBswitchCmd nicht vorhanden." >&2
    exit 1
fi

# 1. Cleware-Werkzeuge nach /usr/src/cleware/
echo "    Installiere Cleware-Tools nach /usr/src/cleware/ ..."
mkdir -p /usr/src/cleware
cp -a "$SCRIPT_DIR/cleware/." /usr/src/cleware/
chown root:root /usr/src/cleware/USBswitchCmd
chmod 4755 /usr/src/cleware/USBswitchCmd   # setuid root für USB-Zugriff

# 2. Signal-Dispatcher nach /usr/local/bin/
echo "    Installiere Dispatcher nach /usr/local/bin/claude-signal ..."
install -m 0755 "$SCRIPT_DIR/bin/claude-signal" /usr/local/bin/claude-signal

# 2b. Signal-Verzeichnisse (start.d/ask.d/stop.d/off.d + lib.sh, ring.sh) nach
#     /etc/claude-ampel/. Eigene Aktionen lassen sich dort einfach als
#     ausführbares Skript ablegen (analog zu /etc/cron.daily). Bereits vorhandene
#     Fremd-Skripte in den Verzeichnissen bleiben erhalten – cp überschreibt nur
#     die mitgelieferten Dateien und löscht nichts.
echo "    Installiere Signal-Verzeichnisse nach /etc/claude-ampel/ ..."
mkdir -p /etc/claude-ampel
cp -a "$SCRIPT_DIR/claude-ampel/." /etc/claude-ampel/
chown -R root:root /etc/claude-ampel
find /etc/claude-ampel -type f -name '*.sh' -exec chmod 0755 {} +
chmod 0644 /etc/claude-ampel/lib.sh   # wird nur gesourct, nicht ausgeführt

# 2c. Verwaiste Hook-Skripte frueherer Installationen aus /usr/local/bin/
#     entfernen. Es werden ausschliesslich unsere bekannten Altdateien geloescht.
echo "    Entferne verwaiste Alt-Skripte aus /usr/local/bin/ ..."
for old in claude_on_start.sh claude_on_ask.sh claude_on_stop.sh claude_off.sh; do
    if [ -e "/usr/local/bin/$old" ]; then
        rm -f "/usr/local/bin/$old" && echo "      entfernt: /usr/local/bin/$old"
    fi
done

# 3. Claude-Code-Hooks in der settings.json des aufrufenden Users einrichten.
#    Bei sudo ist das der echte Aufrufer (SUDO_USER), nicht root – sonst landet
#    die Konfig im falschen Home und gehoert anschliessend root.
TARGET_USER="${SUDO_USER:-$(id -un)}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6 || true)"

# Hook-Zuordnung (alle ueber den Dispatcher claude-signal <start|ask|stop>):
#   UserPromptSubmit                -> start  (rot:  Claude arbeitet)
#   PreToolUse/AskUserQuestion      -> ask    (gelb: echte Rueckfrage, blockiert)
#   PostToolUse/AskUserQuestion     -> start  (rot:  Frage beantwortet, weiter)
#   Notification/permission_prompt  -> ask    (gelb: Berechtigung noetig, blockiert)
#   Stop                            -> stop   (gruen: Zwischenschritt oder fertig)
# read -d '' liefert am EOF stets Exit != 0 -> mit || true abfangen (set -e).
read -r -d '' HOOKS_JSON <<'JSON' || true
{
  "UserPromptSubmit": [
    { "hooks": [ { "type": "command", "command": "/usr/local/bin/claude-signal start" } ] }
  ],
  "PreToolUse": [
    { "matcher": "AskUserQuestion", "hooks": [ { "type": "command", "command": "/usr/local/bin/claude-signal ask" } ] }
  ],
  "PostToolUse": [
    { "matcher": "AskUserQuestion", "hooks": [ { "type": "command", "command": "/usr/local/bin/claude-signal start" } ] }
  ],
  "Notification": [
    { "matcher": "permission_prompt", "hooks": [ { "type": "command", "command": "/usr/local/bin/claude-signal ask" } ] }
  ],
  "Stop": [
    { "hooks": [ { "type": "command", "command": "/usr/local/bin/claude-signal stop" } ] }
  ]
}
JSON

# Merge: aus den verwalteten Events frueher von uns gesetzte Eintraege entfernen
# (sowohl den neuen Dispatcher claude-signal als auch die alten claude_on_*.sh
# aus aelteren Installationen) und unsere anhaengen. So bleiben fremde Hooks auf
# denselben Events erhalten und Wiederholungslaeufe bleiben idempotent.
HOOKS_MERGE='
  .hooks = (.hooks // {})
  | reduce ($h | to_entries[]) as $e (.;
      .hooks[$e.key] = (
        ((.hooks[$e.key] // [])
          | map(select(
              ([ .hooks[]?.command // empty
                 | test("claude_on_(start|ask|stop)\\.sh|/claude-signal( |$)") ] | any) | not)))
        + $e.value))'

if [ -z "$TARGET_HOME" ] || [ ! -d "$TARGET_HOME" ]; then
    echo "    Warnung: Home von '$TARGET_USER' nicht ermittelbar – Hooks uebersprungen." >&2
elif ! command -v jq >/dev/null 2>&1; then
    echo "    Warnung: 'jq' fehlt – Hooks bitte manuell unter \"hooks\" in" >&2
    echo "             $TARGET_HOME/.claude/settings.json eintragen:" >&2
    printf '%s\n' "$HOOKS_JSON" >&2
else
    SETTINGS_DIR="$TARGET_HOME/.claude"
    SETTINGS="$SETTINGS_DIR/settings.json"
    echo "    Richte Claude-Code-Hooks in $SETTINGS ein ..."

    dir_created=0
    if [ ! -d "$SETTINGS_DIR" ]; then
        mkdir -p "$SETTINGS_DIR"
        dir_created=1
    fi

    # Leere/whitespace-Datei wie {} behandeln – jq macht aus leerer Eingabe
    # sonst klammheimlich eine 0-Byte-Datei (Exit 0, keine Ausgabe).
    if [ -s "$SETTINGS" ]; then
        existing="$(cat "$SETTINGS")"
    else
        existing='{}'
    fi
    [ -n "${existing//[[:space:]]/}" ] || existing='{}'

    if printf '%s' "$existing" | jq --argjson h "$HOOKS_JSON" "$HOOKS_MERGE" \
        > "$SETTINGS.tmp" && [ -s "$SETTINGS.tmp" ]; then
        mv "$SETTINGS.tmp" "$SETTINGS"
        # Nur die geschriebene Datei (und ggf. das frisch angelegte Verzeichnis)
        # dem User geben – kein rekursives chown ueber das ganze ~/.claude.
        chown "$TARGET_USER:" "$SETTINGS"
        if [ "$dir_created" -eq 1 ]; then chown "$TARGET_USER:" "$SETTINGS_DIR"; fi
    else
        rm -f "$SETTINGS.tmp"
        if [ "$dir_created" -eq 1 ]; then chown "$TARGET_USER:" "$SETTINGS_DIR"; fi
        echo "    Warnung: $SETTINGS ist kein gueltiges JSON – Hooks nicht eingerichtet." >&2
    fi
fi

echo ""
echo "Fertig."
echo "  Cleware-Binaries : /usr/src/cleware/"
echo "  Dispatcher       : /usr/local/bin/claude-signal"
echo "  Signal-Skripte   : /etc/claude-ampel/{start,ask,stop,off}.d/"
echo "                     (eigene Aktionen einfach als ausführbares Skript dort ablegen)"
echo "  Claude-Hooks     : ${SETTINGS:-(uebersprungen)}"
echo ""
echo "Smoke-Test:"
echo "  /usr/local/bin/claude-signal start   # Ampel rot"
echo "  /usr/local/bin/claude-signal ask     # Ampel gelb + Ring-Ton (einmalig)"
echo "  /usr/local/bin/claude-signal stop    # Ampel grün, 5-Min-Timer + Ring-Ton"
echo "  /usr/local/bin/claude-signal off     # Ampel ganz aus, Timer + Ring-Ton stoppen"
