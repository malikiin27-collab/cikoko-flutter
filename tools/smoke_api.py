#!/usr/bin/env python3
"""Read-only authenticated deployment checks. Never logs credentials or tokens."""
import argparse, getpass, json, urllib.request, urllib.error
p=argparse.ArgumentParser();p.add_argument('--base',default='https://cikoko.datawebs.my.id');args=p.parse_args()
if not args.base.startswith('https://'):raise SystemExit('HTTPS diperlukan.')
base=args.base.rstrip('/')+'/api/flutter/index.php?action='
def request(action,data=None,token=None):
 req=urllib.request.Request(base+action,data=json.dumps(data).encode() if data is not None else None,headers={'Content-Type':'application/json',**({'Authorization':'Bearer '+token} if token else {})})
 with urllib.request.urlopen(req,timeout=30) as r:return json.load(r)
try:
 request('me');raise AssertionError('Endpoint me harus menolak akses tanpa token.')
except urllib.error.HTTPError as e:
 assert e.code==401,f'Expected 401, got {e.code}'
username=input('Username / email akun uji: ');password=getpass.getpass('Kata sandi: ')
login=request('login',{'username':username,'password':password});password='';token=login['token'];role=login['user']['role']
try:
 for action in ['me','dashboard','attendance','leaves','reports']:
  assert request(action,token=token)['ok'] is True;print(action+': OK')
 if role=='admin':
  for action in ['employees','settings','monthly']:assert request(action,token=token)['ok'] is True;print(action+': OK')
 else:
  try:request('employees',token=token);raise AssertionError('Akun pegawai tidak boleh mengakses seluruh pegawai.')
  except urllib.error.HTTPError as e:assert e.code==403
  if role=='pppk':assert request('monthly',token=token)['ok'] is True
 print('Pemeriksaan baca dan pembatasan role lulus.')
finally:
 request('logout',{},token);token=''
