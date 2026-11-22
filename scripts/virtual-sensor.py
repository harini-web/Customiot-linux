#!/usr/bin/env python3

import argparse
import socket
import time


def generate_temperature(seq):
    """
    Return a deterministic temperature
    in millidegrees Celsius.
    """
    return 23500 + (seq % 21) * 125


def run_sensor(socket_path, interval):
    seq = 0

    while True:
        try:
            print(f"Connecting to {socket_path}")

            with socket.socket(
                socket.AF_UNIX,
                socket.SOCK_STREAM
            ) as sock:

                sock.connect(socket_path)

                print("Connected to QEMU UART")

                while True:
                    temperature = generate_temperature(seq)

                    message = f"TEMP_MC={temperature}\n"

                    sock.sendall(message.encode("ascii"))

                    print(
                        f"TX [{seq}]: "
                        f"{message.strip()}"
                    )

                    seq += 1

                    time.sleep(interval)

        except (
            FileNotFoundError,
            ConnectionRefusedError,
            BrokenPipeError,
            ConnectionResetError,
            OSError
        ) as exc:

            print(f"UART disconnected: {exc}")

            time.sleep(2)


if __name__ == "__main__":

    parser = argparse.ArgumentParser(
        description="CustomIoT Virtual UART Sensor"
    )

    parser.add_argument(
        "socket_path",
        help="QEMU UART Unix socket path"
    )

    parser.add_argument(
        "--interval",
        type=float,
        default=1.0,
        help="Seconds between sensor samples"
    )

    args = parser.parse_args()

    if args.interval <= 0:
        parser.error("--interval must be greater than zero")

    try:
        run_sensor(args.socket_path, args.interval)

    except KeyboardInterrupt:
        print("\nVirtual sensor stopped")
