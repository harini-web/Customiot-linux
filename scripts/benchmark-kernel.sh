#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESULTS="$ROOT/benchmarks/module02"

BASE="$ROOT/output-baseline"
CUSTOM="$ROOT/output"

mkdir -p "$RESULTS"

REPORT="$RESULTS/kernel-comparison.txt"

{
    echo "CustomIoT Linux - Kernel Benchmark"
    echo "================================="
    date -u
    echo

    for mode in baseline custom; do
        if [ "$mode" = baseline ]; then
            OUT="$BASE"
        else
            OUT="$CUSTOM"
        fi

        echo "[$mode]"

        KERNEL="$OUT/images/bzImage"
        ROOTFS="$OUT/images/rootfs.ext2"

        if [ -f "$KERNEL" ]; then
            echo "Kernel bytes:"
            stat -c '%s' "$KERNEL"
            sha256sum "$KERNEL"
        else
            echo "Kernel image missing"
        fi

        if [ -f "$ROOTFS" ]; then
            echo "Rootfs nominal bytes:"
            stat -c '%s' "$ROOTFS"
            echo "Rootfs allocated bytes:"
            du -B1 "$ROOTFS"
        else
            echo "Rootfs image missing"
        fi

        echo
    done

    if [ -f "$BASE/images/bzImage" ] &&
       [ -f "$CUSTOM/images/bzImage" ]; then

        BEFORE=$(stat -c %s "$BASE/images/bzImage")
        AFTER=$(stat -c %s "$CUSTOM/images/bzImage")

        awk -v b="$BEFORE" -v a="$AFTER" \
            'BEGIN {
               printf "Kernel size change: %.2f%%\n",
                   ((b-a)/b)*100
             }'
    fi

} | tee "$REPORT"

echo "Results saved to $REPORT"
