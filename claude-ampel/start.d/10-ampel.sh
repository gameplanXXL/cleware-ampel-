#!/bin/bash
# Signal "start": Claude arbeitet -> Ampel rot, Off-Timer stoppen.
. "$(dirname "$0")/../lib.sh"

ampel R
off_timer_cancel
