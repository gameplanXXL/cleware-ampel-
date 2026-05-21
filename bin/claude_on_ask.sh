#!/bin/bash
# Ampel auf "Claude arbeitet" (rot) — cancelt einen evtl. laufenden Off-Timer.

/usr/src/cleware/USBswitchCmd Y

PIDFILE="/tmp/claude_off_timer_${USER}.pid"

if [ -f "$PIDFILE" ]; then
    OLD_PID=$(cat "$PIDFILE" 2>/dev/null)
    if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
        kill -- "-$OLD_PID" 2>/dev/null
    fi
    rm -f "$PIDFILE"
fi
