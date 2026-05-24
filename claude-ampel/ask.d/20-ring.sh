#!/bin/bash
# Signal "ask": echte Rückfrage -> Ring-Ton (5x, alle 20 s = 3x/Min) als
# Erinnerung, dass Claude blockiert auf eine Antwort wartet.
. "$(dirname "$0")/../lib.sh"

ring_start
