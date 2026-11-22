#!/bin/sh

PASS=0
FAIL=0

check() {
    NAME="$1"
    shift

    if "$@" >/dev/null 2>&1; then
        echo "[PASS] $NAME"
        PASS=$((PASS + 1))
    else
        echo "[FAIL] $NAME"
        FAIL=$((FAIL + 1))
    fi
}

echo "=================================="
echo " CustomIoT Module 03 Tests"
echo "=================================="

check "OS identity" \
    grep -q 'ID=customiot' /etc/os-release

check "Hostname" \
    test "$(hostname)" = "customiot"

check "System configuration" \
    test -f /etc/customiot/customiot.conf

check "Init script exists" \
    test -x /etc/init.d/S90customiot-system

check "System initialized" \
    test -f /run/customiot-system.ready

check "Runtime directory" \
    test -d /run/customiot

check "Application state directory" \
    test -d /var/lib/customiot

check "Initialization log" \
    test -f /var/log/customiot-system.log

check "System utility" \
    test -x /usr/local/bin/customiot-info

check "Gateway service" \
    test -x /etc/init.d/S95customiot

echo
echo "Passed: $PASS"
echo "Failed: $FAIL"

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi

echo "Module 03 tests successful"
