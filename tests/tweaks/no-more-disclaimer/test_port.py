"""Optional full-OEM verification: pass private original and Piotr's modified JS.

No vehicle originals are committed. CI covers synthetic worker fixtures and the
shipped context behavior; this additional check uses real full-file inputs.
"""
from pathlib import Path
import hashlib
import os
import shlex
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools'))
from manifest import read

if len(sys.argv) != 3:
    raise SystemExit('Usage: python test_port.py OEM_systemApp.js PIOTR_systemApp.js')
original = Path(sys.argv[1]).read_bytes()
upstream = Path(sys.argv[2]).read_bytes()
folder = ROOT / 'usb/tweaks/no-more-disclaimer'
m = read(folder / 'manifest.conf')
assert hashlib.md5(original).hexdigest() == m['oem_backup_md5']

def context(text, label):
    start = text.index(label)
    end = text.index(b'        }, // end of Disclaimer', start) + len(b'        }, // end of Disclaimer')
    return start, end

a, b = context(original, b'        "Disclaimer" : {')
c, d = context(upstream, b'        "Disclaimer": {')
expected = original[:a] + upstream[c:d] + original[b:]
SHELL = 'C:/Program Files/Git/bin/bash.exe' if os.name == 'nt' else '/bin/sh'
def bp(p):
    value = Path(p).resolve().as_posix()
    return '/' + value[0].lower() + value[2:] if len(value) > 1 and value[1] == ':' else value

with tempfile.TemporaryDirectory(prefix='cmu-disclaimer-port-') as directory:
    work = Path(directory); target = work / 'target.data'
    def patch(reverse=False):
        command = 'cd "$1" && patch -N ' + ('-R ' if reverse else '') + '-p0 -i "$2" < /dev/null'
        r = subprocess.run([SHELL, '-c', command, '--', bp(work), bp(folder / 'assets/change.patch')],
                           capture_output=True, text=True, timeout=15)
        assert r.returncode == 0, (r.stdout, r.stderr)
    target.write_bytes(original)
    patch(); assert target.read_bytes() == expected
    patch(True); assert target.read_bytes() == original
    prefix = b'// unrelated prefix modification\n'
    suffix = b'\n// unrelated suffix modification\n'
    target.write_bytes(prefix + original + suffix)
    patch(); assert target.read_bytes() == prefix + expected + suffix
    # Also preserve a later modification added after installing this tweak.
    later = b'\n// modification added after installation\n'
    target.write_bytes(target.read_bytes() + later)
    patch(True); assert target.read_bytes() == prefix + original + suffix + later
print('FULL_OEM_PORT_PASSED: v74 hash, exact upstream active context, no other OEM edits, inverse and unrelated-change preservation.')
