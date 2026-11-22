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

echo "===================================="
echo " CustomIoT Module 04 Tests"
echo "===================================="

check "Sensor binary" \
    test -x /usr/bin/sensor-gateway

check "Gateway supervisor" \
    test -x /usr/bin/gateway-supervisor

check "MQTT publisher" \
    test -x /usr/bin/mosquitto_pub

check "MQTT subscriber" \
    test -x /usr/bin/mosquitto_sub

check "MQTT configuration" \
    test -f /etc/mosquitto/mosquitto.conf

check "Gateway configuration" \
    test -f /etc/customiot/customiot.conf

check "Gateway service" \
    test -x /etc/init.d/S95customiot

check "Gateway running" \
    /etc/init.d/S95customiot status

check "Sensor JSON output" \
    sh -c '/usr/bin/sensor-gateway 1 | grep -q temperature_mC'

echo
echo "Testing MQTT communication..."

TOPIC="customiot/test/module04"
MESSAGE="customiot-test-message"

# Subscribe first and save one received message.
mosquitto_sub \
    -h 127.0.0.1 \
    -t "$TOPIC" \
    -C 1 \
    -W 5 \
    > /tmp/customiot-mqtt-test.txt &

SUB_PID=$!

sleep 1

mosquitto_pub \
    -h 127.0.0.1 \
    -t "$TOPIC" \
    -m "$MESSAGE"

wait "$SUB_PID"
SUB_RESULT=$?

if [ "$SUB_RESULT" -eq 0 ] &&
   grep -q "$MESSAGE" /tmp/customiot-mqtt-test.txt; then
    echo "[PASS] MQTT publish/subscribe"
    PASS=$((PASS + 1))
else
    echo "[FAIL] MQTT publish/subscribe"
    FAIL=$((FAIL + 1))
fi

rm -f /tmp/customiot-mqtt-test.txt

echo
echo "Passed: $PASS"
echo "Failed: $FAIL"

if [ "$FAIL" -ne 0 ]; then
    exit 1
fi

echo "Module 04 tests successful"
