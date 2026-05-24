#!/bin/bash
# Signal "stop": Zwischenschritt/fertig -> Ring-Ton (einmalig, 3x direkt
# hintereinander) als Erinnerung, dass Claude fertig ist.
. "$(dirname "$0")/../lib.sh"

ring_start
