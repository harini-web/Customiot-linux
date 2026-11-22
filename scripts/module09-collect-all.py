#!/usr/bin/env python3
"""Collect CustomIoT host + persisted guest + optional stock metrics into ONE text file.
Run on HOST after guest shutdown. Python stdlib; optional tune2fs/debugfs installed via e2fsprogs.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import zlib
from pathlib import Path
import re
import subprocess
import sys


def command(*args):
    try:
        p = subprocess.run(args, capture_output=True, text=True, timeout=90)
        return p.returncode, p.stdout, p.stderr
    except (FileNotFoundError, subprocess.TimeoutExpired) as ex:
        return 127, '', str(ex)


def hash_file(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda: f.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def image_stats(path):
    if not path.is_file():
        return f'NOT AVAILABLE: {path}\n', None
    st = path.stat()
    parts = [f'path={path}', f'image_file_bytes={st.st_size}',
             f'host_allocated_bytes={st.st_blocks * 512}', f'sha256={hash_file(path)}']
    rc, out, err = command('tune2fs', '-l', str(path))
    used = None
    if rc == 0:
        fields = {}
        for label in ('Block count', 'Free blocks', 'Block size'):
            m = re.search(r'^' + re.escape(label) + r':\s*(\d+)', out, re.M)
            if m:
                fields[label] = int(m.group(1))
        if len(fields) == 3:
            used = (fields['Block count'] - fields['Free blocks']) * fields['Block size']
            parts.extend((f'ext_used_bytes={used}', f'ext_capacity_bytes={fields["Block count"] * fields["Block size"]}'))
    else:
        parts.append('ext_used_bytes=N/A (not ext filesystem or tune2fs unavailable)')
    if path.name.startswith('rootfs') or path.name.startswith('root-'):
        compressor = zlib.compressobj(level=9, wbits=31)  # reproducible gzip stream, no original filename
        compressed = 0
        with path.open('rb') as stream:
            for block in iter(lambda: stream.read(1024 * 1024), b''):
                compressed += len(compressor.compress(block))
        compressed += len(compressor.flush())
        parts.append(f'gzip_level9_bytes={compressed}')
    return '\n'.join(parts) + '\n', used


def manifest_info(path):
    if not path.is_file():
        return 'N/A (run Buildroot make legal-info; ensure manifest.csv exists)'
    import csv
    with path.open(newline='', errors='replace') as f:
        rows = list(csv.reader(f))
    # Manifest includes licensing metadata; count nonempty package rows; confirm schema in report.
    rows = [r for r in rows[1:] if r and r[0].strip()]
    return f'{len(rows)} entries in {path} (Buildroot legal manifest; not dpkg package count)'


def guest_from_debugfs(state):
    if not state.is_file():
        return 'NOT AVAILABLE: persistent state.img not found.\n'
    name = '/overlay/upper/benchmarks/module09/guest-benchmarks.txt'
    rc, out, err = command('debugfs', '-R', f'cat {name}', str(state))
    if rc == 0 and 'File not found' not in err and 'File not found' not in out and out.strip():
        return out
    return ('NOT AVAILABLE: guest report not found inside state.img.\n'
            'Run customiot-benchmark-all in guest, poweroff, then rerun this host script.\n'
            f'debugfs detail: {err.strip()}\n')


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--project', default='.', help='customiot-linux repository directory')
    ap.add_argument('--stock-image', help='comparable stock Linux ext4 root filesystem image')
    ap.add_argument('--stock-report', help='stock guest metrics in a separate text file')
    ap.add_argument('--guest-report', help='guest text report copied manually from VM (if not using state.img)')
    ap.add_argument('--output', help='output report filename')
    args = ap.parse_args()
    root = Path(args.project).resolve()
    target = Path(args.output).resolve() if args.output else root / 'benchmarks/module09/ALL_BENCHMARKS.txt'
    target.parent.mkdir(parents=True, exist_ok=True)
    sections = ['CUSTOMIOT LINUX — ALL BENCHMARKS AND MODULE 09 VALIDATION',
                f'Captured UTC: {datetime.now(timezone.utc).isoformat()}',
                'Units: bytes unless otherwise noted. Unavailable measurements are NOT estimates.',
                'CONFIGURATION: 2 vCPU / 512 MiB RAM / VirtIO network in provided QEMU launcher.', '']
    measured = {}
    for label, rel in [('Buildroot baseline rootfs', 'output-baseline/images/rootfs.ext2'),
                       ('CustomIoT rootfs build', 'output/images/rootfs.ext2'),
                       ('Kernel baseline', 'output-baseline/images/bzImage'),
                       ('Kernel custom', 'output/images/bzImage'),
                       ('A/B slot A', 'module07-disks/root-a.img'),
                       ('A/B slot B', 'module07-disks/root-b.img'),
                       ('Persistent state disk', 'module07-disks/state.img')]:
        info, used = image_stats(root / rel)
        sections += [f'===== {label} =====', info]
        measured[label] = used
    for label, out in [('Buildroot baseline', 'output-baseline'), ('CustomIoT', 'output')]:
        sections.append(f'===== {label} package inventory =====')
        sections.append(manifest_info(root / out / 'legal-info/manifest.csv'))
    if args.stock_image:
        info, stock_used = image_stats(Path(args.stock_image).resolve())
        sections += ['===== Stock distro rootfs =====', info]
        custom_used = measured['CustomIoT rootfs build']
        if stock_used and custom_used is not None:
            sections.append(f'COMPARABLE EXT FILESYSTEM USED-BYTE REDUCTION VS STOCK: {(stock_used-custom_used)/stock_used*100:.2f}%')
        else:
            sections.append('STOCK REDUCTION: N/A (could not read comparable ext filesystem usage)')
    else:
        sections.append('STOCK REDUCTION: NOT MEASURED. Provide --stock-image with comparable stock ext filesystem.')
    sections.append('===== Guest measurements, service tests, MQTT =====')
    if args.guest_report:
        gp = Path(args.guest_report)
        sections.append(gp.read_text(errors='replace') if gp.is_file() else f'NOT FOUND: {gp}')
    else:
        sections.append(guest_from_debugfs(root / 'module07-disks/state.img'))
    sections.append('===== Stock guest metrics (optional) =====')
    if args.stock_report:
        sp = Path(args.stock_report)
        sections.append(sp.read_text(errors='replace') if sp.is_file() else f'NOT FOUND: {sp}')
    else:
        sections.append('NOT PROVIDED. Collect stock RAM, uptime, package count and MQTT workload under equivalent QEMU settings.')
    sections += ['', 'METHODOLOGY / LIMITATIONS',
                 '- Buildroot baseline is NOT a stock Debian/Ubuntu distribution.',
                 '- A/B slot sizes and state-disk capacity are reported separately from the active OS footprint.',
                 '- ext_used_bytes includes filesystem metadata; compare consistent image types.',
                 '- Buildroot legal-info manifest is not equivalent to dpkg package count; label appropriately.',
                 '- MQTT batch throughput and delivery are not per-message latency. Latency NOT MEASURED by this collector.',
                 '- CPU clock ticks and RSS are observations; repeated idle/active CPU tests need same workloads.',
                 '- Boot marker excludes QEMU firmware time and may precede actual end-to-end sensor readiness.',
                 '- Root filesystem updates must be booted/validated separately on both slots.', '']
    target.write_text('\n'.join(sections), encoding='utf-8')
    print(f'Wrote one combined benchmark file: {target}')
    print(f'Size: {target.stat().st_size} bytes')


if __name__ == '__main__':
    main()
