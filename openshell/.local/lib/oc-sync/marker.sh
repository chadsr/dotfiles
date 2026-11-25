#!/bin/sh
# Write the sandbox layout marker. $1 marker text.
printf "%s\n" "$1" >/sandbox/.oc-layout
