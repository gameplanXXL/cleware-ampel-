#!/bin/bash
# Spielt einen Ton mehrfach im festen Abstand – als akustische Erinnerung, dass
# Claude auf eine Antwort wartet (Rückfrage) oder fertig ist (Stop).
#
# Läuft als Hintergrundjob, gestartet über lib.sh ring_start. Einstellbar per
# Umgebungsvariablen:
#   CLAUDE_RING_COUNT     Anzahl der Töne            (Default 5)
#   CLAUDE_RING_INTERVAL  Sekunden zwischen den Tönen (Default 20 = 3× pro Minute)
#   CLAUDE_RING_SOUND     Pfad zu einer Sounddatei   (sonst System-Sound)
#
# Findet sich kein Player/Sound, wird ersatzweise die Terminal-Glocke (BEL)
# ausgegeben.

COUNT="${CLAUDE_RING_COUNT:-5}"
INTERVAL="${CLAUDE_RING_INTERVAL:-20}"   # 20 s ⇒ 3× pro Minute

# Erste lesbare Sounddatei ermitteln (oder die explizit vorgegebene).
find_sound() {
    if [ -n "${CLAUDE_RING_SOUND:-}" ] && [ -r "$CLAUDE_RING_SOUND" ]; then
        printf '%s' "$CLAUDE_RING_SOUND"
        return 0
    fi
    local c
    for c in \
        /usr/share/sounds/freedesktop/stereo/complete.oga \
        /usr/share/sounds/freedesktop/stereo/bell.oga \
        /usr/share/sounds/freedesktop/stereo/message.oga \
        /usr/share/sounds/alsa/Front_Center.wav; do
        [ -r "$c" ] && { printf '%s' "$c"; return 0; }
    done
    return 1
}

# Einen Ton abspielen – nimmt den ersten verfügbaren Player.
play_once() {
    local sound
    sound="$(find_sound)" || { printf '\a'; return; }
    if   command -v paplay  >/dev/null 2>&1; then paplay "$sound"
    elif command -v pw-play >/dev/null 2>&1; then pw-play "$sound"
    elif command -v ffplay  >/dev/null 2>&1; then ffplay -nodisp -autoexit -loglevel quiet "$sound"
    elif command -v play    >/dev/null 2>&1; then play -q "$sound"
    elif command -v aplay   >/dev/null 2>&1 && [ "${sound%.wav}" != "$sound" ]; then aplay -q "$sound"
    else printf '\a'
    fi
}

i=0
while [ "$i" -lt "$COUNT" ]; do
    play_once
    i=$((i + 1))
    [ "$i" -lt "$COUNT" ] && sleep "$INTERVAL"
done
