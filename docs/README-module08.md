# Module 08 — Optimization & benchmarking

## Install
Copy patch contents into existing CustomIoT repo, maintaining relative paths; `chmod +x` new scripts. Rebuild custom rootfs using `./scripts/build.sh custom`. Do not rerun Module 07 disk preparation or overwrite your persistent disk.

If testing a Module 07 A/B disk, the newly built rootfs does **not** appear in the running slot until deployed as a signed image. Build and apply a signed update through Module 07 and boot the updated slot; then run guest tools.

## Host metrics
`python3 scripts/module08-host-report.py --project .`

Optional stock comparison (ONLY if a real, comparable ext4 stock rootfs image has been prepared):
`python3 scripts/module08-host-report.py --project . --stock-image /path/to/stock-rootfs.ext4`

Report JSON/Markdown are written to `benchmarks/module08`. The tool distinguishes virtual image length, host allocated bytes, and ext4 used bytes. The latter requires tune2fs. No stock percentage is reported unless a stock image is explicitly supplied.

`output-baseline` is Buildroot's baseline, **not** a stock Ubuntu/Debian distribution.

## Guest measurements
Inside the updated QEMU guest:

`module08-guest-metrics run01`

`module08-mqtt-batch 200`

Repeat in fresh VM sessions at least 3 times, with identical `-m`, `-smp`, CPU model, root storage mode and emulator load. For boot readiness, record `CUSTOMIOT_BOOT_READY uptime_s=...` from the boot serial output; boot-to-readiness excludes QEMU launch/firmware and is only comparable with the **same readiness marker** installed in the stock image. `/proc/uptime` after login is not a boot time.

## Comparability and interpretation
1. Stock distro: install minimal Debian/Ubuntu server into a VM with same QEMU hardware, configure its app services equivalently and record the exact image file and rootfs FS usage. Do not compare our raw ext4 size with Debian ISO download size.
2. Image metric to report: ext4 used bytes or compressed rootfs at identical compression level, for both sides. Report A/B capacity and state disk separately.
3. Stock package count: `dpkg-query -W -f='${binary:Package}\n' | wc -l`; custom package count from Buildroot `make legal-info` target manifest. Explain package definition differences.
4. RAM: compare MemAvailable-derived used RAM (`MemTotal - MemAvailable`) after system settles, and optionally report application RSS (do not sum shared RSS as unique memory).
5. Boot readiness: same functional milestone on both OSes; compare 3+ boots, median and range; remove login typing latency.
6. MQTT benchmark: loopback delivery count and aggregate throughput, includes shell/CLI overhead and subscription setup sleep is **excluded** from timed interval. It does not measure individual network latency.
7. Do not optimize out drivers needed for `/dev/ttyS1`, VirtIO, ext4, OverlayFS, TCP/IP, or signatures.

## Suggested evidence
- host-metrics.json and host-report.md
- `uname -a`, `/proc/cmdline`, `mount`, `/proc/meminfo`
- serial logs containing boot-ready marker
- 3 guest metric samples; 3 MQTT batch samples
- saved `output/.config`, external kernel config, package manifest and licenses

## Buildroot size attribution and legal manifest
`make -C buildroot O="$PWD/output" legal-info`
`make -C buildroot O="$PWD/output" graph-size`

Save results outside generated build directories. `graph-size` may need optional host Python plotting dependencies.
