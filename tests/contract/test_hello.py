"""Execute the stateless command example with isolated firmware data."""
from pathlib import Path
import os
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
SHELL = 'C:/Program Files/Git/bin/bash.exe' if os.name == 'nt' else '/bin/sh'

def bp(path):
    s = Path(path).resolve().as_posix()
    return '/' + s[0].lower() + s[2:] if len(s) > 1 and s[1] == ':' else s

with tempfile.TemporaryDirectory(prefix='cmu-hello-') as folder:
    base = Path(folder); version = base / 'version.ini'; script = base / 'usb/tweaks/hello/run.sh'
    script.parent.mkdir(parents=True)
    (base / 'usb/lib').mkdir()
    shutil.copyfile(ROOT / 'usb/lib/manifest.sh', base / 'usb/lib/manifest.sh')
    manifest = script.parent / 'manifest.conf'
    shutil.copyfile(ROOT / 'examples/hello/manifest.conf', manifest)
    source = (ROOT / 'examples/hello/run.sh').read_text(encoding='utf-8')
    script.write_text(source.replace('/jci/version.ini', bp(version)), encoding='utf-8', newline='\n')
    def run(args, code, stdout=None):
        r = subprocess.run([SHELL, bp(script)] + args, capture_output=True, text=True, timeout=10)
        assert r.returncode == code, (args, r.stdout, r.stderr)
        if stdout is not None: assert r.stdout == stdout, (args, r.stdout)
        return r
    run([], 0); run(['--help'], 0); run(['status', 'extra'], 1, '')
    run(['status'], 1, '')
    version.write_text('JCI_SW_VER="MAZ_CMU-150_99.00.000"\n')
    r = run(['status'], 0, 'unavailable\n'); assert r.stderr.strip()
    run(['run'], 1, '')
    version.write_text('JCI_SW_VER="MAZ_CMU-150_74.00.324"\n')
    run(['status'], 0, 'uninstalled\n')
    run(['run'], 0, 'Hello from the CMU shell!\n')
    run(['install'], 1, '')
    assert sorted(p.name for p in base.iterdir()) == ['usb', 'version.ini']
print('HELLO_CONTRACT_PASSED: help, errors, ready, unavailable, Run and no extra files.')
