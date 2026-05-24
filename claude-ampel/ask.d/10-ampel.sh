#!/bin/bash
# Signal "ask": echte Rückfrage -> Ampel gelb, Off-Timer stoppen.
. "$(dirname "$0")/../lib.sh"

ampel Y
off_timer_cancel
