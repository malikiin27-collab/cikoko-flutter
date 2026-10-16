#!/usr/bin/env python3
"""Static package integrity checks; not a replacement for Flutter/PHP runtime tests."""
from pathlib import Path
import re
root=Path(__file__).resolve().parents[1]
dart='\n'.join(p.read_text() for p in (root/'flutter_app/lib').glob('*.dart'))
router=(root/'website_patch/api/flutter/index.php').read_text()
actions=set(re.findall(r"\.call\('([a-z_]+)'",dart))
missing=[a for a in actions if f"'{a}'" not in router]
assert not missing,('Unmapped API action',missing)
paths=set(re.findall(r"(?:request|bytes)\('(flutter/[^'$]+\.php)'",dart))
for path in paths:
 assert (root/'website_patch/api'/path).is_file(),('Missing endpoint',path)
for filename in ['config.php','*.sql','*.apk','*.jks','*.keystore']:
 assert not list(root.rglob(filename)),('Unexpected sensitive/binary source',filename)
assert 'WebView' not in dart
assert 'badCertificateCallback' not in dart
assert 'api/flutter' not in str(root/'flutter_app/lib')
print(f'PASS: {len(actions)} actions; {len(paths)} direct endpoints; no database/config/old APK included.')
