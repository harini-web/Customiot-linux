#!/bin/sh

# CustomIoT Linux Telemetry Publisher
# Module 05

CONFIG="/etc/customiot/customiot.conf"

MQTT_HOST="127.0.0.1"
MQTT_PORT="1883"
MQTT_TOPIC="customiot/sensors/temperature"

SENSOR_MODE="simulated"
SENSOR_DEVICE="/dev/ttyS1"

if [ -f "$CONFIG" ]; then
    . "$CONFIG"
fi

case "$SENSOR_MODE" in

    simulated)
        SENSOR_PROGRAM="/usr/bin/sensor-gateway"
        ;;

    uart)
        SENSOR_PROGRAM="/usr/bin/uart-sensor-reader"
        ;;

    *)
        echo "Invalid SENSOR_MODE: $SENSOR_MODE" >&2
        exit 1
        ;;

esac

echo "=================================="
echo " CustomIoT Telemetry Publisher"
echo "=================================="

echo "Sensor mode: $SENSOR_MODE"
echo "MQTT broker: $MQTT_HOST:$MQTT_PORT"
echo "MQTT topic : $MQTT_TOPIC"

while true
do
    if [ "$SENSOR_MODE" = "uart" ]; then

        "$SENSOR_PROGRAM" "$SENSOR_DEVICE" |
            mosquitto_pub \
                -h "$MQTT_HOST" \
                -p "$MQTT_PORT" \
                -t "$MQTT_TOPIC" \
                -q 1 \
                -l

    else

        "$SENSOR_PROGRAM" |
            mosquitto_pub \
                -h "$MQTT_HOST" \
                -p "$MQTT_PORT" \
                -t "$MQTT_TOPIC" \
                -q 1 \
                -l
    fi

    echo "Telemetry pipeline exited"
    echo "Retrying in 3 seconds"

    sleep 3
done
