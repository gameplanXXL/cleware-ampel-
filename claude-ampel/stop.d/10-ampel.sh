#!/bin/bash
# Signal "stop": Zwischenschritt/fertig -> Ampel grün, Off-Timer (5 Min) armen.
. "$(dirname "$0")/../lib.sh"

ampel G
off_timer_arm
