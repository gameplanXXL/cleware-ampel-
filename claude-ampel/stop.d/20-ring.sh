#!/bin/bash
# Signal "stop": Zwischenschritt/fertig -> Ring-Ton (einmalig) als Erinnerung,
# dass Claude fertig ist. KEIN Ton, wenn nur ein Sub-Agent fertig ist
# (SubagentStop) und der Haupt-Agent weiterarbeitet.
. "$(dirname "$0")/../lib.sh"

is_subagent_stop && exit 0

ring_start
