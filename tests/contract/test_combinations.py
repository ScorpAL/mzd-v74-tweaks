"""All install/removal orders for the three tweaks sharing List2Ctrl.js."""
from pathlib import Path
import itertools
import os
import shlex
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2] / 'usb'
SHELL = 'C:/Program Files/Git/bin/bash.exe' if os.name == 'nt' else '/bin/sh'
IDS = ['list-beep', 'shorter-delay', 'list-loop']

def bp(path):
    s = Path(path).resolve().as_posix()
    return '/' + s[0].lower() + s[2:] if len(s) > 1 and s[1] == ':' else s

known = {}
for id_ in IDS:
    cursor = None
    for line in (ROOT / 'tweaks' / id_ / 'assets/change.patch').read_text(encoding='utf-8').splitlines(keepends=True):
        if line.startswith('@@ '):
            cursor = int(line.split()[1][1:].split(',')[0])
        elif cursor is not None and line[:1] in [' ', '-']:
            assert cursor not in known or known[cursor] == line[1:], 'Inconsistent shared original context.'
            known[cursor] = line[1:]; cursor += 1
baseline = ''.join(known.get(i, '// shared fixture gap %d\n' % i) for i in range(1, max(known) + 1))
with tempfile.TemporaryDirectory(prefix='cmu-combinations-') as folder:
    base = Path(folder); original = base / 'original'; original.write_text(baseline, encoding='utf-8', newline='\n')
    for name in ['work', 'expected']: (base / name).mkdir()
    script = ['#!/bin/sh', 'set -eu', 'cd ' + shlex.quote(bp(base)), '''apply() {
  folder=$1; flag=$2; id=$3
  (cd "$folder" && patch -N $flag -p0 -i ROOT/tweaks/"$id"/assets/change.patch < /dev/null) >/dev/null
}'''.replace('ROOT', shlex.quote(bp(ROOT)))]
    count = 0
    for install in itertools.permutations(IDS):
        for uninstall in itertools.permutations(IDS):
            script += ['cp original work/target.data']
            for id_ in install: script.append('apply work "" ' + id_)
            remaining = list(install)
            for id_ in uninstall:
                script.append('apply work -R ' + id_); remaining.remove(id_)
                script.append('cp original expected/target.data')
                for other in remaining: script.append('apply expected "" ' + other)
                script.append('cmp work/target.data expected/target.data')
            script.append('cmp work/target.data original'); count += 1
    path = base / 'test.sh'; path.write_text('\n'.join(script) + '\n', encoding='utf-8', newline='\n')
    r = subprocess.run([SHELL, bp(path)], capture_output=True, text=True, timeout=180)
    assert r.returncode == 0, (r.stdout, r.stderr)
print('COMBINATIONS_PASSED:', count, 'install/uninstall order pairs; remaining tweaks preserved exactly.')
