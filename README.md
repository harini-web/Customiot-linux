# CustomIoT Linux (academic assignment)

Standalone minimal Linux gateway built with **Buildroot 2026.08.2**, with x86-64 QEMU as the first target. No NVIDIA/CUDA dependency in the required build.

## Host prerequisites (Ubuntu 24.04/22.04 or WSL2 Ubuntu)

Run inside an Ubuntu Linux filesystem, **not** `/mnt/c`.

```sh
sudo apt update
sudo apt install -y build-essential git wget curl bc bison flex make gcc g++ \
  libncurses-dev libssl-dev python3 rsync cpio unzip file \
  perl tar gzip xz-utils patch sed gawk diffutils findutils \
  qemu-system-x86 ca-certificates
```

Host must have adequate free disk (suggest 30 GB) and RAM (suggest 8 GB). Avoid using `sudo` for Buildroot builds.

## Module 00 — toolchain and source

```sh
./scripts/setup.sh
```

Verified source tag is requested at `2026.08.2`. Check the logged Git revision.

## Module 01 — baseline OS

```sh
./scripts/configure.sh baseline
./scripts/build.sh baseline
./scripts/run-qemu.sh baseline
```

The first `make` downloads/builds a cross-toolchain, kernel, rootfs, and optionally host tools. In QEMU press Enter if the login prompt is delayed, then log in as `root` (no password in the stock example; **not production-safe**). Try:

```sh
uname -a
cat /proc/cmdline
cat /proc/meminfo | head
ip addr
mount
```

Shutdown with `poweroff`; QEMU's `-no-reboot` is enabled. You may exit via Ctrl+A, X. Run `./scripts/measure-host.sh` on the host.

## Module 02 — kernel customisation

```sh
./scripts/enable-kernel-custom.sh
./scripts/configure.sh custom
make -C buildroot O="$PWD/output" linux-menuconfig
./scripts/save-kernel-config.sh
```

Do not strip VirtIO block, VirtIO net, serial console, ext4/ext2, UNIX sockets, TCP/IP, or OverlayFS. Use `menuconfig` to remove unneeded subsystems conservatively. Enable `CONFIG_OVERLAY_FS=y` for module 06. Record changed options and benchmark before/after images.

## Module 03 — filesystem and init

The custom defconfig sets `BR2_ROOTFS_OVERLAY` to `external/board/customiot/rootfs-overlay`. That tree provides `/etc/hostname`, a broker configuration, a telemetry publisher, and its `/etc/init.d/S95customiot` service. Build and boot:

```sh
./scripts/build.sh custom
./scripts/run-qemu.sh custom
```

Inside the VM verify `/etc/hostname`, `/etc/init.d/S95customiot` and `/usr/bin/sensor-gateway` exist. This is a **writable** root filesystem during modules 01–05. The read-only root/OverlayFS requirement is a separate module 06 task.

## Module 04 — sensor program

The package recipe is `external/package/sensor-gateway/`; source is `app/sensor-gateway.c`. First test on Linux host:

```sh
cc -Wall -Wextra -O2 app/sensor-gateway.c -o /tmp/sensor-gateway
/tmp/sensor-gateway 3
```

Then in the custom guest:

```sh
sensor-gateway 3
```

It emits 3 JSON objects. This first implementation uses deterministic **simulated** readings, not UART data. For the track's sensor-driver demonstration, extend to actual emulated `/dev/ttyS1` with a second QEMU serial endpoint after the basic pipeline works.

## Module 05 — MQTT

Custom defconfig enables Mosquitto broker and CLI clients. Build and boot as above. Mosquitto's packaged init script must start the broker before S95customiot; check with `ps` and verify `mosquitto_sub` output:

```sh
ps | grep mosquitto
mosquitto_sub -h 127.0.0.1 -t customiot/sensors/temperature -C 3 -v
```

The publisher streams JSON lines from sensor-gateway to `mosquitto_pub -l`. Test service logs at `/var/log/customiot-telemetry.log`. The sample broker is bound to localhost only. Anonymous local access is acceptable **only for this development demonstration**. Real LAN deployment requires broker authentication, ACLs and ideally TLS.

## Module 06 — security + persistent overlay (planned, not yet implemented)

1. Configure a read-only lower root, and a separate writable data partition for upper/work directories. An ext2/ext4 virtual-disk-based overlay cannot simply be mounted read-only without arranging an upper layer and an early initramfs/init hook.
2. Mount OverlayFS via an early boot stage before normal init, and keep `/run` on tmpfs. Store keys, messages and update state in the writable data partition.
3. Replace the passwordless root console with proper access controls, run service under dedicated unprivileged UID, configure MQTT authentication/TLS and limit listening addresses.
4. Create an update bundle manifest (version, image SHA-256, signature). Verify using a pinned public key **before** staging an update. Test altered bundle rejection and rollback. This is signed update validation, **not secure boot**.

Do not claim these requirements are completed just because an overlay directory exists in the repository.

## Module 07 — evaluation

```sh
./scripts/measure-host.sh
```

Build a **stock Debian reference** using a documented Debian minimal install under equivalent 2-vCPU, 512 MB QEMU settings. Measure size of equivalent image contents, RAM (`/proc/meminfo`), kernel size, boot readiness, installed package count/manifest, and 100+ MQTT latencies. The Buildroot baseline from module 01 is a useful internal reference, but is *not* a substitute for the assignment's stock distribution comparison.

## Module 08 — reproducibility, report, licensing

```sh
make -C buildroot O="$PWD/output" legal-info
sha256sum output/images/*
```

Keep source code, `external/` recipes, scripts, version pins and recorded package licenses in Git. Use a second clean output directory to verify rebuild reproducibility, then record output hashes (builds may not be byte-for-byte identical until timestamps etc. are normalized). Attach demo video and a separate technical report.

## Module 09 — optional NVIDIA/CUDA

QEMU with a generic virtio GPU does not provide an NVIDIA CUDA device. NVIDIA acceleration would require supported **physical GPU access** on a suitable Linux host, PCI passthrough, or a second deployment image for an NVIDIA-equipped machine/Jetson. The CUDA toolkit and proprietary driver must be tracked, licensed, size-counted, and version-matched. Treat this as a hardware-dependent separate variant after the base assignment is finished.

## Notes on tested status

Starter scripts have been syntax-checked, but **the full Buildroot toolchain, kernel and QEMU guest have not been compiled and boot-tested in the supplied environment**. Treat build/boot and MQTT validation as your module checkpoints, not as reported results.
