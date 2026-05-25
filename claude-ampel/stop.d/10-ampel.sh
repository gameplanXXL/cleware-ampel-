#!/bin/bash
# Signal "stop": Zwischenschritt/fertig -> Ampel grün, Off-Timer (5 Min) armen.
# ABER nur, wenn der HAUPT-Agent fertig ist. Meldet nur ein Sub-Agent sein Ende
# (SubagentStop), arbeitet der Haupt-Agent weiter -> Ampel unverändert lassen
# (bleibt rot = arbeitet), nichts armen.
. "$(dirname "$0")/../lib.sh"

is_subagent_stop && exit 0

ampel G
off_timer_arm
