#!/bin/bash
# Signal "start": Claude arbeitet wieder -> evtl. laufenden Ring-Ton stoppen.
. "$(dirname "$0")/../lib.sh"

ring_cancel
