#!/bin/bash
# Signal "ask": echte Rückfrage -> Ring-Ton (einmalig, 3x direkt hintereinander)
# als Erinnerung, dass Claude blockiert auf eine Antwort wartet.
. "$(dirname "$0")/../lib.sh"

ring_start
