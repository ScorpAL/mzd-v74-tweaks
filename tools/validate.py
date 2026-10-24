"""PR entrypoint: metadata, integrity, syntax and developer test coverage."""
from pathlib import Path
import json
import os
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
SHELL = 'C:/Program Files/Git/bin/bash.exe' if os.name == 'nt' else '/bin/sh'
sys.path.insert(0, str(ROOT / 'tests/contract'))
from cases import CASES

def require(ok, message):
    if not ok:
        raise SystemExit(message)

schema_path = ROOT / 'tweaks/tweak-manifest.schema.json'
schema = json.loads(schema_path.read_text(encoding='utf-8'))
try:
    import jsonschema
except ImportError:
    raise SystemExit('Install developer dependency: python -m pip install jsonschema')
jsonschema.Draft202012Validator.check_schema(schema)
manifests = {}
for folder in sorted((ROOT / 'tweaks').iterdir()):
    if not folder.is_dir():
        continue
    require((folder / 'manifest.json').is_file(), 'Unexpected folder under tweaks/: ' + folder.name)
    m = json.loads((folder / 'manifest.json').read_text(encoding='utf-8'))
    jsonschema.validate(m, schema)
    require(m['id'] == folder.name, 'Manifest ID/folder mismatch: ' + folder.name)
    require(len(m['firmware']) == 1, 'Add explicit multi-firmware worker coverage before advertising it: ' + folder.name)
    require(m['id'] in CASES, 'Register entrypoint tests in tests/contract/cases.py: ' + m['id'])
    source = (folder / 'run.sh').read_text(encoding='utf-8')
    for field, constant in [('requires', 'REQUIRES'), ('conflicts', 'CONFLICTS')]:
        match = re.search(r'^' + constant + r"='([^']*)'$", source, re.M)
        require(match and match.group(1).split() == m[field], 'Dependency metadata/code mismatch: ' + folder.name)
    for field, constant in [('id', 'ID'), ('target', 'APP'), ('original_md5', 'ORIGINAL'), ('firmware', 'FIRMWARE')]:
        if field not in m:
            continue
        expected = m[field][0] if field == 'firmware' else m[field]
        require(re.search(r'^' + constant + '=' + re.escape(expected) + '$', source, re.M),
                'Manifest/worker configuration mismatch: ' + folder.name + ' ' + field)
    require(not re.search(r'(^|\n|;)\s*(/jci/tools/)?(reboot|jci-dialog)(?=\s|$)', '\n'.join(line for line in source.splitlines() if not line.lstrip().startswith('#'))),
            'Workers must not open dialogs or reboot: ' + folder.name)
    manifests[m['id']] = m
for id_, m in manifests.items():
    for other in m['requires'] + m['conflicts']:
        require(other in manifests and other != id_, 'Invalid dependency/conflict for ' + id_)
    require(not set(m['requires']) & set(m['conflicts']), 'A required tweak cannot also conflict: ' + id_)
def visit(id_, trail):
    require(id_ not in trail, 'Dependency cycle: ' + ' -> '.join(trail + [id_]))
    for dependency in manifests[id_]['requires']:
        visit(dependency, trail + [id_])
for id_ in manifests:
    visit(id_, [])
for path in ROOT.rglob('*.sh'):
    subprocess.run([SHELL, '-n', str(path)], check=True)
for name in ['shell-bridge-arm', 'browser-adapter-arm']:
    data = (ROOT / 'bin' / name).read_bytes()
    require(data[:4] == b'\x7fELF' and data[18:20] == b'\x28\x00', 'Not an ARM ELF binary: ' + name)
require((ROOT / 'jci-autoupdate').is_file(), 'USB autoupdate marker missing.')
require(len(list(ROOT.glob('*.up'))) == 1, 'Expected exactly one automatic USB entry file.')
require(not (ROOT / 'start-ssh.sh').exists() and not (ROOT / 'mazda.pub').exists(), 'Temporary SSH must not ship.')
subprocess.run([sys.executable, str(ROOT / 'tools/checksums.py')], check=True)
print('Validated', len(manifests), 'tweaks, dependency graph, syntax and runnable USB structure.')
