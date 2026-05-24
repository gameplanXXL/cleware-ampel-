#!/bin/bash
# Signal "off": alles ruhig -> Ampel ganz aus, Off-Timer stoppen.
. "$(dirname "$0")/../lib.sh"

ampel_off
off_timer_cancel
