#!/bin/bash
# Signal "stop": Zwischenschritt/fertig -> Ring-Ton (5x, alle 20 s = 3x/Min) als
# Erinnerung, dass Claude fertig ist.
. "$(dirname "$0")/../lib.sh"

ring_start
