#!/bin/bash
# Ampel auf "Claude fertig" (grün) — armt einen 5-Min-Off-Timer
# (oder erneuert ihn, falls schon einer läuft).

/usr/src/cleware/USBswitchCmd G

PIDFILE="/tmp/claude_off_timer_${USER}.pid"
OFF_SCRIPT="/usr/local/bin/claude_off.sh"
DELAY_SECONDS=300

if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        kill -- "-$OLD_PID" 2>/dev/null
    fi
    rm -f "$PIDFILE"
fi

# Timer in eigener Session/PG — überlebt Shell-Exit, killbar via PGID.
setsid bash -c "echo \$\$ > \"$PIDFILE\"; sleep $DELAY_SECONDS && \"$OFF_SCRIPT\"; rm -f \"$PIDFILE\"" </dev/null >/dev/null 2>&1 &
disown
