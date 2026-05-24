#!/bin/bash
# Gemeinsame Helfer für die Claude-Ampel-Drop-in-Skripte.
# Wird von den Skripten in start.d/, ask.d/ und stop.d/ per `. ../lib.sh`
# eingebunden. Kein eigenständiges Skript.

# Verzeichnis dieser Bibliothek – um Geschwister-Skripte (z. B. ring.sh) zu
# finden, unabhängig davon, wohin der Baum installiert/kopiert wurde.
CLAUDE_AMPEL_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Pfad zum Cleware-Schaltbefehl – zentral, damit er nur hier zu pflegen ist.
: "${USBSWITCH_CMD:=/usr/src/cleware/USBswitchCmd}"

# USB-Vendor-ID der Cleware GmbH. Dient zur verlässlichen Erkennung, ob überhaupt
# eine Ampel am USB-Bus hängt – der Schaltbefehl selbst meldet das NICHT zuverlässig
# (er liefert auch ohne Hardware Status 0), darum prüfen wir die physische Präsenz
# über sysfs. Zentral pflegbar.
: "${CLEWARE_USB_VENDOR:=0d50}"

# PID-Dateien der verwalteten Hintergrundjobs (pro User).
OFF_TIMER_PID="/tmp/claude_off_timer_${USER:-$(id -un)}.pid"
RING_PID="/tmp/claude_ring_${USER:-$(id -un)}.pid"

# Prüft (read-only über sysfs), ob eine Cleware-USB-Ampel am Bus hängt.
# Liefert 0 = vorhanden, 1 = nicht gefunden. Bewusst nicht über USBswitchCmd, da
# dessen Geräteliste unzuverlässig ist (meldet auch ohne Hardware ein „Gerät").
ampel_present() {
    grep -qix "$CLEWARE_USB_VENDOR" /sys/bus/usb/devices/*/idVendor 2>/dev/null
}

# Schaltet die Ampel (R|Y|G|0). Bei Problemen wird eine deutliche Fehlermeldung
# nach stderr geschrieben und ein von 0 verschiedener Status zurückgegeben:
#   - Schaltbefehl fehlt / nicht ausführbar
#   - keine Ampel eingesteckt (USB-Gerät nicht gefunden)
#   - Schalten schlägt trotz vorhandener Ampel fehl
ampel() {
    local color="$1" out rc

    if [ ! -x "$USBSWITCH_CMD" ]; then
        echo "claude-ampel: FEHLER – Cleware-Schaltbefehl nicht gefunden oder nicht ausführbar:" >&2
        echo "claude-ampel:   $USBSWITCH_CMD" >&2
        echo "claude-ampel: Bitte den Installer ausführen (cleware-install.sh baut/installiert USBswitchCmd)." >&2
        return 1
    fi

    if ! ampel_present; then
        echo "claude-ampel: FEHLER – keine Cleware-USB-Ampel gefunden – ist sie eingesteckt?" >&2
        echo "claude-ampel: Erwartet wird ein USB-Gerät mit Vendor-ID $CLEWARE_USB_VENDOR. Prüfen mit:" >&2
        echo "claude-ampel:   lsusb | grep -i $CLEWARE_USB_VENDOR" >&2
        return 1
    fi

    # Ausgabe einsammeln, damit wir bei Erfolg ruhig bleiben (Hook-Kontext) und
    # nur im Fehlerfall die Originalmeldung des Binaries mit anzeigen.
    out="$("$USBSWITCH_CMD" "$color" 2>&1)"
    rc=$?
    if [ "$rc" -ne 0 ]; then
        echo "claude-ampel: FEHLER – Ampel gefunden, aber Schalten fehlgeschlagen (Farbe: $color, Status $rc)." >&2
        [ -n "$out" ] && echo "claude-ampel: Meldung von USBswitchCmd: $out" >&2
        return "$rc"
    fi
    return 0
}

# Schaltet die Ampel komplett aus. Der Cleware-Ampel-Multiplexer hat immer nur
# einen Kanal an; daher erst Rot (definierter Kanal) einschalten und dann diesen
# Kanal wieder ausschalten -> alle Lampen aus. Etwaige Fehlermeldungen (z. B. keine
# Ampel eingesteckt) kommen aus ampel(); bei Fehler entfällt der zweite Schritt.
ampel_off() {
    ampel R && ampel 0
}

# Bricht einen via job_spawn gestarteten Hintergrundjob ab (per PGID).
job_cancel() {
    local pidfile="$1" pid
    [ -f "$pidfile" ] || return 0
    pid="$(cat "$pidfile" 2>/dev/null)"
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
        kill -- "-$pid" 2>/dev/null
    fi
    rm -f "$pidfile"
}

# Startet <cmd> als Hintergrundjob in eigener Session/Prozessgruppe und legt die
# PGID in <pidfile> ab (überlebt Shell-Exit, killbar via job_cancel).
# Aufruf: job_spawn <pidfile> <shell-kommando-als-string>
job_spawn() {
    local pidfile="$1" cmd="$2"
    setsid bash -c "echo \$\$ > \"$pidfile\"; $cmd; rm -f \"$pidfile\"" \
        </dev/null >/dev/null 2>&1 &
    disown
}

# Off-Timer (er)neuern: schaltet die Ampel nach DELAY Sekunden aus.
# Default 300 s, per CLAUDE_OFF_DELAY überschreibbar.
off_timer_arm() {
    local delay="${CLAUDE_OFF_DELAY:-300}"
    job_cancel "$OFF_TIMER_PID"
    # Der Hintergrundjob läuft in einer frischen Shell ohne unsere Funktionen –
    # daher lib.sh erneut sourcen und die zentrale ampel_off nutzen.
    job_spawn "$OFF_TIMER_PID" \
        "sleep $delay && . \"$CLAUDE_AMPEL_LIB_DIR/lib.sh\" && ampel_off"
}

# Off-Timer abbrechen.
off_timer_cancel() {
    job_cancel "$OFF_TIMER_PID"
}

# Ring-Ton-Job starten (vorher evtl. laufenden abbrechen, damit sich Töne
# nicht stapeln).
ring_start() {
    job_cancel "$RING_PID"
    job_spawn "$RING_PID" "\"$CLAUDE_AMPEL_LIB_DIR/ring.sh\""
}

# Ring-Ton-Job abbrechen.
ring_cancel() {
    job_cancel "$RING_PID"
}
