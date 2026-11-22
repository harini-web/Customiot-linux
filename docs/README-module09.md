# CustomIoT Module 09 — Final integration and validation

1. Keep the last known working A/B disk images safe. Do not run prepare-disks or overwrite the active slot.
2. Install this overlay and rebuild `./scripts/build.sh custom`; deploy the new rootfs using Module 07 signed update before expecting the guest utility to appear.
3. Boot with `./scripts/module07-run-qemu.sh A` or `B`. Start the host UART sensor in another terminal.
4. Inside guest as root, run `customiot-benchmark-all` and also run a manual `mosquitto_sub -t customiot/sensors/temperature -C 10 -W 20` end-to-end check.
5. Shutdown QEMU with `poweroff` to make the persistent state disk consistent.
6. On the Ubuntu host, run `python3 scripts/module09-collect-all.py --project .`.
7. The single output is `benchmarks/module09/ALL_BENCHMARKS.txt`.
8. Optional stock references: `--stock-image /path/to/stock-rootfs.ext4` and `--stock-report /path/to/stock-guest-metrics.txt`.
9. If debugfs cannot extract guest data, copy it from the guest using a supported transport, then use `--guest-report /path/to/guest-benchmarks.txt`.
10. Pass criteria: UART-to-MQTT; service stop/restart; read-only root; persistent data across shutdown; signed update accepted, tampered update rejected; A and B boot and manual rollback; 3 repeated MQTT batches; measurement coverage reported without fabrication.

NOTE: The boot marker records init-script completion, not time to verified MQTT readiness. Automatic boot rollback and full secure boot are not implemented. Keep separate evidence/logs for signed update acceptance/rejection and power-loss recovery limits.
