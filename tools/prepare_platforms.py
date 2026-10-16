#!/usr/bin/env python3
"""Generate official Flutter platform scaffolding while preserving application code."""
import argparse, pathlib, shutil, subprocess, tempfile, xml.etree.ElementTree as ET, plistlib
p=argparse.ArgumentParser();p.add_argument('--platforms',default='android',choices=['android','android,ios']);args=p.parse_args()
root=pathlib.Path(__file__).resolve().parents[1]/'flutter_app'
if not shutil.which('flutter'):raise SystemExit('Flutter SDK belum tersedia. Instal Flutter stable 3.35+ lalu jalankan kembali.')
with tempfile.TemporaryDirectory(prefix='cikoko_platforms_') as tmp:
 generated=pathlib.Path(tmp)/'scaffold'
 subprocess.run(['flutter','create','--no-pub','--platforms',args.platforms,'--org','id.my.datawebs.cikoko','--project-name','cikoko_native',str(generated)],check=True)
 for name in args.platforms.split(','):
  dest=root/name
  if dest.exists():raise SystemExit(f'{dest} sudah ada. Platform tidak ditimpa; hapus hanya jika memang ingin regenerasi.')
  shutil.copytree(generated/name,dest)
 metadata=generated/'.metadata'
 if metadata.exists():shutil.copy2(metadata,root/'.metadata')
ns='http://schemas.android.com/apk/res/android';ET.register_namespace('android',ns)
manifest=root/'android/app/src/main/AndroidManifest.xml';tree=ET.parse(manifest);doc=tree.getroot()
for perm in ['INTERNET','ACCESS_FINE_LOCATION','ACCESS_COARSE_LOCATION']:
 ET.SubElement(doc,'uses-permission',{f'{{{ns}}}name':f'android.permission.{perm}'})
app=doc.find('application');app.set(f'{{{ns}}}label','Cikoko');app.set(f'{{{ns}}}allowBackup','false');app.set(f'{{{ns}}}usesCleartextTraffic','false')
tree.write(manifest,encoding='utf-8',xml_declaration=True)
if 'ios' in args.platforms:
 path=root/'ios/Runner/Info.plist'
 with path.open('rb') as f: data=plistlib.load(f)
 data.update(CFBundleDisplayName='Cikoko',NSCameraUsageDescription='Foto dokumentasi mulai, selesai, dan laporan kerja.',NSPhotoLibraryUsageDescription='Memilih bukti kegiatan PPPK.',NSLocationWhenInUseUsageDescription='Mencatat lokasi saat mulai, selesai, dan dokumentasi kerja.')
 with path.open('wb') as f:plistlib.dump(data,f)
print('Platform siap. Jalankan flutter pub get, flutter analyze, dan flutter test di flutter_app.')
