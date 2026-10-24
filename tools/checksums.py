"""Check or intentionally refresh runtime checksum sidecars; no package build."""
from pathlib import Path
import hashlib
import sys

ROOT = Path(__file__).resolve().parents[1]
USB = ROOT / 'usb'
UPDATE = '--update' in sys.argv
paths = list((USB / 'lib').glob('*.sh'))
paths += [p for p in (USB / 'bin').iterdir() if p.is_file() and p.name.endswith('-arm')]
for base in ['tweaks', 'examples']:
    paths += [p for p in (USB / base if base == 'tweaks' else ROOT / base).rglob('*') if p.is_file() and
              (p.name in ['run.sh', 'manifest.json'] or 'assets' in p.parts) and
              not p.name.endswith('.md5')]
for name in ['autorun.sh', 'installer.sh']:
    paths.append(USB / name)
failures = []
for target in sorted(set(paths)):
    digest = hashlib.md5(target.read_bytes()).hexdigest()
    sidecar = Path(str(target) + '.md5')
    if UPDATE:
        sidecar.write_text(digest + '\n', encoding='ascii', newline='\n')
    elif not sidecar.is_file() or sidecar.read_text().strip().split()[0] != digest:
        failures.append(target.relative_to(ROOT).as_posix())
if failures:
    raise SystemExit('Checksum mismatch or missing sidecar: ' + ', '.join(failures))
print(('Updated' if UPDATE else 'Verified'), len(set(paths)), 'runtime checksums.')
