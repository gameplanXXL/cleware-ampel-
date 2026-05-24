#!/bin/bash
# Gemeinsame Helfer für die Claude-Ampel-Drop-in-Skripte.
# Wird von den Skripten in start.d/, ask.d/ und stop.d/ per `. ../lib.sh`
# eingebunden. Kein eigenständiges Skript.

# Verzeichnis dieser Bibliothek – um Geschwister-Skripte (z. B. ring.sh) zu
# finden, unabhängig davon, wohin der Baum installiert/kopiert wurde.
CLAUDE_AMPEL_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Pfad zum Cleware-Schaltbefehl – zentral, damit er nur hier zu pflegen ist.
: "${USBSWITCH_CMD:=/usr/src/cleware/USBswitchCmd}"

# PID-Dateien der verwalteten Hintergrundjobs (pro User).
OFF_TIMER_PID="/tmp/claude_off_timer_${USER:-$(id -un)}.pid"
RING_PID="/tmp/claude_ring_${USER:-$(id -un)}.pid"

# Schaltet die Ampel (R|Y|G|0), sofern das Binary vorhanden ist.
ampel() {
    [ -x "$USBSWITCH_CMD" ] && "$USBSWITCH_CMD" "$1"
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
    job_spawn "$OFF_TIMER_PID" \
        "sleep $delay && { \"$USBSWITCH_CMD\" R; \"$USBSWITCH_CMD\" 0; }"
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
