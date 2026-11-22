#!/bin/sh
set -eu
fail=0
check() { if eval "$2"; then printf '[PASS] %s\n' "$1"; else printf '[FAIL] %s\n' "$1"; fail=$((fail+1)); fi; }
check 'Persistent ext4 mounted' "awk '\$2==\"/mnt/customiot-data\" && \$3==\"ext4\" {ok=1} END {exit !ok}' /proc/mounts"
check 'OverlayFS mounted' "awk '\$2==\"/var/lib/customiot\" && \$3==\"overlay\" {ok=1} END {exit !ok}' /proc/mounts"
check 'Verified update utility installed' 'test -x /usr/local/sbin/customiot-update'
check 'Public verification key installed' 'test -r /etc/customiot/update-public.pem'
check 'System root read-only' "awk '\$2==\"/\" && \$4 ~ /(^|,)ro(,|\$)/ {ok=1} END {exit !ok}' /proc/mounts"
check 'Can write persistent state' 'echo persistent >/var/lib/customiot/module07-persistence-test && test -f /mnt/customiot-data/overlay/upper/module07-persistence-test'
check 'UART gateway still running' '/etc/init.d/S95customiot status >/dev/null 2>&1'
echo "Failures: $fail"
[ "$fail" -eq 0 ]
