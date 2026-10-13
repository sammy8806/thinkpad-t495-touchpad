#!/bin/bash
# Warn (don't fail) when building for a kernel series other than the one
# the bundled pristine sources come from (see KERNEL_SOURCE).
top=$(cd "$(dirname "$0")/.." && pwd)
want=$(cut -c2- "$top/KERNEL_SOURCE"); want=${want%.*}
have=${1%%-*}; have=${have%.*}
[[ $want == "$have" ]] || echo "thinkpad-t495-touchpad: WARNING: sources are from $want.x, building for $1. Refresh the sources if the touchpad falls back to PS/2." >&2
exit 0
