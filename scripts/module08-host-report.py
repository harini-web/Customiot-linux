#!/usr/bin/env python3
"""Compare exact rootfs image metrics; do not mistake virtual capacity for usage."""
import argparse, csv, hashlib, json, os, pathlib, re, subprocess, time
from datetime import datetime, timezone

def run(*cmd):
    p=subprocess.run(cmd,text=True,capture_output=True)
    return p.stdout if p.returncode==0 else ''

def sha256(path):
    h=hashlib.sha256()
    with open(path,'rb') as f:
        for chunk in iter(lambda:f.read(1024*1024),b''):h.update(chunk)
    return h.hexdigest()

def image_stats(path):
    p=pathlib.Path(path)
    if not p.is_file(): return None
    st=p.stat()
    d={'path':str(p),'virtual_bytes':st.st_size,'host_allocated_bytes':st.st_blocks*512,'sha256':sha256(p)}
    info=run('tune2fs','-l',str(p))
    def field(name):
        m=re.search(r'^'+re.escape(name)+r':\s*(\d+)',info,re.M)
        return int(m.group(1)) if m else None
    count,free,size=field('Block count'),field('Free blocks'),field('Block size')
    if None not in (count,free,size):
        d.update(filesystem_bytes=count*size, filesystem_used_bytes=(count-free)*size, filesystem_free_bytes=free*size)
    return d

def package_count(out):
    # Buildroot legal-info manifest is authoritative for installed target packages.
    p=out/'legal-info'/'manifest.csv'
    if not p.exists(): return {'value':None,'source':'Run make legal-info; manifest.csv unavailable'}
    lines=p.read_text(errors='replace').splitlines()
    if len(lines)<2:return {'value':None,'source':str(p)}
    reader=csv.reader(lines[1:])
    count=sum(bool(row) and bool(row[0].strip()) for row in reader)
    return {'value':count,'source':str(p),'note':'Manifest package entries; verify manifest format manually'}

def one(out):
    images=out/'images'
    root=images/'rootfs.ext2'
    kernel=images/'bzImage'
    info={'output':str(out),'rootfs':image_stats(root),'kernel':image_stats(kernel) if kernel.exists() else None,
          'package_manifest':package_count(out)}
    for name in ('rootfs.ext2','bzImage'):
        p=images/name
        if p.is_file() and name=='rootfs.ext2':
            import gzip
            dest=out.parent/'benchmarks'/'module08'/('custom' if 'baseline' not in str(out) else 'baseline')
            dest.mkdir(parents=True,exist_ok=True)
            z=dest/(name+'.gz')
            with open(p,'rb') as src,gzip.GzipFile(filename=str(z),mode='wb',compresslevel=9,mtime=0) as dst:
                import shutil; shutil.copyfileobj(src,dst)
            info['rootfs_gzip_bytes']=z.stat().st_size
    return info

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--project',default='.')
    ap.add_argument('--stock-image',help='actual comparable stock Linux rootfs ext image')
    args=ap.parse_args(); root=pathlib.Path(args.project).resolve()
    result={'timestamp_utc':datetime.now(timezone.utc).isoformat(),
            'baseline_buildroot':one(root/'output-baseline'), 'custom':one(root/'output'),
            'stock':image_stats(args.stock_image) if args.stock_image else None,
            'comparison_rules':{'image':'same filesystem payload and method; not A/B disk capacity',
                                'baseline':'Buildroot baseline, not stock distro',
                                'guest':'same QEMU CPU/RAM/IO and boot-ready definition'}}
    resultdir=root/'benchmarks'/'module08';resultdir.mkdir(parents=True,exist_ok=True)
    (resultdir/'host-metrics.json').write_text(json.dumps(result,indent=2)+'\n')
    custom=result['custom']['rootfs'];baseline=result['baseline_buildroot']['rootfs'];stock=result['stock']
    lines=['# Module 08 — Host Image Metrics','',f"Captured: {result['timestamp_utc']}",'',
           '| Metric | Buildroot baseline | CustomIoT | Stock distro |','|---|---:|---:|---:|']
    for key in ('virtual_bytes','host_allocated_bytes','filesystem_used_bytes'):
        def val(d):return f"{d[key]/1048576:.2f} MiB" if d and key in d else 'N/A'
        lines.append(f'| {key} | {val(baseline)} | {val(custom)} | {val(stock)} |')
    lines.append('')
    if stock and custom and 'filesystem_used_bytes' in stock and 'filesystem_used_bytes' in custom:
        a=stock['filesystem_used_bytes'];b=custom['filesystem_used_bytes']
        lines.append(f'Filesystem used-byte reduction vs stock: **{100*(a-b)/a:.2f}%**' if a else 'Stock usage invalid')
    else: lines.append('**40% requirement: not yet evaluated against a stock distro.**')
    lines+=['','Package counts refer to Buildroot legal-info target manifests, not executable/file counts.','Compressed image sizes should use the same codec/settings on stock and custom images.']
    (resultdir/'host-report.md').write_text('\n'.join(lines)+'\n')
    print('\n'.join(lines));print('\nSaved',resultdir/'host-metrics.json')
if __name__=='__main__':main()
