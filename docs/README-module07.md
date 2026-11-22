# Module 07: Persistent state and signed A/B rootfs updates (QEMU demonstration)

## Prerequisites
- Modules 01–06 working.
- A pinned Buildroot configuration with OpenSSL CLI installed on the guest (`BR2_PACKAGE_LIBOPENSSL_BIN=y`, inspect `package/libopenssl/Config.in`).
- Kernel has built-in VirtIO block, ext4 and OverlayFS support.
- Host: openssl, e2fsprogs (`mkfs.ext4`), qemu-system-x86_64.
- Required immutable mountpoint directory: `/mnt/customiot-data` in the rootfs overlay.
- QEMU loads the kernel separately via `-kernel`. The updater intentionally updates only rootfs slots.

## Build order
1. Add Module07 patch files to project, preserve your previous Module06 `S85customiot-storage` as a backup.
2. `scripts/module07-generate-key.sh` ONCE. Keep private key secret, don't commit it.
3. Enable OpenSSL CLI in Buildroot using `menuconfig`, save defconfig; rebuild the image. Verify `output/target/usr/bin/openssl` (or available binary path).
4. `scripts/module07-prepare-disks.sh`: copies first image to both root slots, creates a persistent data disk. Never run it while QEMU is using the disks.
5. `scripts/module07-run-qemu.sh A`; host virtual sensor: `python3 scripts/virtual-sensor.py /tmp/customiot-uart-$(id -u).sock`.
6. In guest: `/usr/local/bin/test-module07`, `echo hello >/var/lib/customiot/reboot-test`. Shut down QEMU, boot slot A again and confirm it persists.
7. To make an actual update, change an OS file or version in rootfs overlay (e.g. `/etc/os-release`) then rebuild; `scripts/module07-create-media.sh 0.7.1 1`. This signs the image bytes and creates update-media.img.
8. Boot slot A with update media attached: `scripts/module07-run-qemu.sh A`, then guest `customiot-update apply`. Shut down; `scripts/module07-run-qemu.sh B`.
9. Verify new OS identity, UART/MQTT operation, and persistent state; guest `customiot-confirm` commits the monotonic sequence and clears pending marker.
10. Tamper test: shut down QEMU, create a separate malicious image or alter a signed manifest on a test media disk; verify `customiot-update apply` rejects it BEFORE overwriting the inactive slot. Do not deliberately overwrite your working disk without backup.

## Boundaries
- No automatic boot-slot selection, health-based rollback, secure boot, or signed kernel update.
- Slot switching is a manual host action; the boot kernel is external to rootfs.
- The private key is generated and held on the Ubuntu host only; the public key is built into the read-only root.
- The persistent ext4 data disk is not encrypted. Back up data before intentional disk reformatting.
- `customiot-confirm` is a **manual** confirmation step; it checks a health marker and running gateway but not a complete test suite. Run complete tests before confirming.
- The updater must not be deployed on an untrusted physical device as a production OTA mechanism.

## Important safety notes
- Shut down all QEMU instances before running `prepare-disks`, `create-media` or modifying images. The launcher uses non-snapshot writable root/data disks by design.
- Preserve previous kernel `bzImage` and `rootfs.ext2` before each Buildroot rebuild. Do not overwrite slot disk images by re-running setup.
- For first boot, ensure `output/images/rootfs.ext2` includes `S85customiot-storage`, OpenSSL CLI, `customiot-update`, public key, and the `/mnt` mountpoints before copying it into A/B disks.
- To keep a test image from accidentally becoming a real update, `manifest.sig` must cover the exact `manifest.txt`, and `sha256` within that signed file must match rootfs.img.

## Root filesystem capacity (before creating slots)
In Buildroot `menuconfig`, select ext4 image (`BR2_TARGET_ROOTFS_EXT2_4=y`) and a generous initial size (e.g. `BR2_TARGET_ROOTFS_EXT2_SIZE="128M"`). Save your configuration and build before calling `module07-prepare-disks.sh`. Later signed images MUST be no larger than the inactive slot. Setting slot capacity at the start avoids updates failing due to larger packages.
