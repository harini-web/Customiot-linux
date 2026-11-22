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

echo "======================================"
echo " CustomIoT Linux - Module 05 Tests"
echo "======================================"

check "UART device exists" \
    test -c /dev/ttyS1

check "UART reader installed" \
    test -x /usr/bin/uart-sensor-reader

check "Simulated sensor installed" \
    test -x /usr/bin/sensor-gateway

check "Gateway supervisor installed" \
    test -x /usr/bin/gateway-supervisor

check "MQTT publisher installed" \
    test -x /usr/bin/mosquitto_pub

check "MQTT subscriber installed" \
    test -x /usr/bin/mosquitto_sub

check "Sensor mode configured" \
    grep -q '^SENSOR_MODE="uart"' \
        /etc/customiot/customiot.conf

check "UART device configured" \
    grep -q '^SENSOR_DEVICE="/dev/ttyS1"' \
        /etc/customiot/customiot.conf

check "Gateway service running" \
    /etc/init.d/S95customiot status

check "MQTT broker running" \
    sh -c 'ps | grep "[m]osquitto"'

echo
echo "--------------------------------------"
echo "Passed: $PASS"
echo "Failed: $FAIL"
echo "--------------------------------------"

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi

echo "Module 05 component tests passed"
