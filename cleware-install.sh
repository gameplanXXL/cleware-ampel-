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
if [ ! -d "$SCRIPT_DIR/cleware" ] || [ ! -d "$SCRIPT_DIR/bin" ]; then
    echo "Fehler: 'cleware/' oder 'bin/' nicht neben dem Skript gefunden." >&2
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

# 2. Claude-Hook-Scripts nach /usr/local/bin/
echo "    Installiere Claude-Scripts nach /usr/local/bin/ ..."
install -m 0755 "$SCRIPT_DIR/bin/claude_on_start.sh" /usr/local/bin/claude_on_start.sh
install -m 0755 "$SCRIPT_DIR/bin/claude_on_ask.sh"   /usr/local/bin/claude_on_ask.sh
install -m 0755 "$SCRIPT_DIR/bin/claude_on_stop.sh"  /usr/local/bin/claude_on_stop.sh
install -m 0755 "$SCRIPT_DIR/bin/claude_off.sh"      /usr/local/bin/claude_off.sh

echo ""
echo "Fertig."
echo "  Cleware-Binaries : /usr/src/cleware/"
echo "  Hook-Scripts     : /usr/local/bin/claude_on_start.sh"
echo "                     /usr/local/bin/claude_on_ask.sh"
echo "                     /usr/local/bin/claude_on_stop.sh"
echo "                     /usr/local/bin/claude_off.sh"
echo ""
echo "Smoke-Test:"
echo "  /usr/local/bin/claude_on_start.sh   # Ampel rot"
echo "  /usr/local/bin/claude_on_ask.sh     # Ampel gelb (wartet auf Eingabe)"
echo "  /usr/local/bin/claude_on_stop.sh    # Ampel grün, 5-Min-Timer läuft"
echo "  /usr/local/bin/claude_off.sh        # Ampel aus"
