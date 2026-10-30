"""Component schema agreement; fixtures are data only, no native code is loaded."""
from pathlib import Path
import os
import shlex
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT/'tools'))
from manifest import read
SHELL = 'C:/Program Files/Git/bin/bash.exe' if os.name == 'nt' else '/bin/sh'

def bp(p):
    s=Path(p).resolve().as_posix()
    return '/'+s[0].lower()+s[2:] if len(s)>1 and s[1]==':' else s

checks=0
with tempfile.TemporaryDirectory(prefix='cmu-component-schema-') as temporary:
    folder=Path(temporary)/'bundle-example'
    shutil.copytree(ROOT/'development/examples/bundle', folder)
    original=(folder/'components.tsv').read_text()
    manifest=folder/'manifest.conf'
    def check(text, expected):
        global checks
        (folder/'components.tsv').write_text(text,encoding='utf-8',newline='')
        valid=True
        try: read(manifest)
        except ValueError: valid=False
        assert valid==expected,(text,valid)
        args=['awk','-v','id=bundle-example','-v','storage=/tmp/mnt/data_persist','-v','primary=/jci/sm/sm.conf','-v','original=74d9fc389b74fb01d0cfc2615a82c782','-v','mode=validate','-f',bp(ROOT/'usb/lib/components.awk'),bp(folder/'components.tsv')]
        r=subprocess.run([SHELL,'-c',' '.join(shlex.quote(a) for a in args)],capture_output=True,text=True,timeout=15)
        assert (r.returncode==0)==expected,(r.stdout,r.stderr,text)
        checks+=1
    check(original,True)
    for text in [original+original, original.replace('assets/alpha.so','assets/../alpha.so'),original.replace('/alpha.so','/nested/alpha.so'),original.replace('jciMMUI','bad service'),original.replace('shim\t','unknown\t',1),original.replace('74d9fc389b74fb01d0cfc2615a82c782','bad'),original.replace('/shims/bundle-example/','/shims/foreign/'),original.replace('loader\t/jci/sm/sm.conf','loader\t/jci//sm/sm.conf'),original.replace('assets/alpha.so\tjciMMUI\t-','assets/alpha.so\tjciMMUI\t-\textra')]:
        check(text,False)
    check(original.replace('\n','\r\n'),True)
    mapping=folder/'assets/libpatch.map'
    mapping.write_text('hud_display_language\tnot_a_setting\n',encoding='utf-8')
    try:read(manifest)
    except ValueError:checks+=1
    else:raise AssertionError('Unknown mapped setting accepted')
print('COMPONENT_SCHEMA_PASSED:',checks,'developer/runtime grammar and unknown configuration-key checks.')
