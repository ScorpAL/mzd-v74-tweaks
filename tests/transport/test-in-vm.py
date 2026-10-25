"""Private offline test of original CMU Lua/modules inside the existing Linux appliance.
No vehicle connection, physical USB, original filesystem edits or private files in Git.
"""
from pathlib import Path
import argparse
import stat
import subprocess
import tempfile
import shutil
import sys

HERE=Path(__file__).resolve().parent
REPO=HERE.parents[1]
WORKSPACE=REPO.parent
CACHE=HERE/'.test-cache'
EMU=WORKSPACE/'mzd-cmu-emulator'

def main():
 parser=argparse.ArgumentParser()
 mode=parser.add_mutually_exclusive_group()
 mode.add_argument('--probe',action='store_true')
 mode.add_argument('--packages',action='store_true',help='Run only persistent packages with the original CMU shell')
 args=parser.parse_args()
 sys.path.insert(0,str(EMU));import appliance
 CACHE.mkdir(exist_ok=True)
 run=Path(tempfile.mkdtemp(prefix="run-",dir=CACHE))
 basefile=CACHE/'base.cpio.gz'
 if not basefile.exists():
  entries=appliance.tar_entries(EMU/'cache/minirootfs.tar.gz')
  entries.update(appliance.tar_entries(EMU/'cache/qemu-arm-10.0.0-r1.apk'))
  modules=appliance.cpio_entries((EMU/'cache/initramfs-virt').read_bytes())
  entries.update({n:v for n,v in modules.items() if n.startswith('lib/modules/')})
  private=appliance.tar_entries(WORKSPACE/'mcu_backup_20261021_203342/03_root_system.tar.gz')
  for n,v in private.items():
   if (n.startswith('lib/') and ('.so' in n or '/ld-' in n)) or n in ['usr/bin/lua','usr/bin/luac'] or n.startswith(('usr/share/lua/5.1/','usr/lib/lua/5.1/','usr/lib/liblua','usr/lib/libreadline','usr/lib/libhistory','usr/lib/libncurses','usr/lib/libtinfo')):
    entries['cmu/'+n]=v
  appliance.write_cpio(entries,basefile)
 overlay={}
 def add(name,data,mode=0o644):overlay[name]=(stat.S_IFREG|mode,data.encode() if isinstance(data,str) else data)
 for path in (REPO/'usb/lib/lua-bridge').glob('*.lua'):add('experiment/'+path.name,path.read_bytes())
 for path in [HERE/name for name in ["backend.lua", "demo.sh", "start-helper.sh", "package-test.sh"]]:
  if path.is_file():add('experiment/tests/'+path.name,path.read_bytes(),0o755 if path.suffix=='.sh' else 0o644)
 for name in ['installer.sh','lib/manifest.sh','lib/jobs.sh','lib/transport.sh','ui/transport.html']:
  target='experiment/transport.html' if name=='ui/transport.html' else 'experiment/package/'+name
  add(target,(REPO/'usb'/name).read_bytes(),0o755 if name.endswith('.sh') else 0o644)
 add('experiment/package/tweaks/demo/run.sh',(HERE/'demo.sh').read_bytes(),0o755)
 add('experiment/package/tweaks/demo/manifest.conf',"""contract_version=1
id=demo
name=Synthetic test
description=Read-only synthetic command
version=0.8.0
type=command
group=system
firmware=74.00.324
entrypoint=run.sh
actions=run status
status_scope=configuration
reboot_required=false
requires=
conflicts=
progress=true
""")
 import tarfile
 with tarfile.open(WORKSPACE/'mcu_backup_20261021_203342/03_root_system.tar.gz') as archive:
  add('cmu/bin/busybox',archive.extractfile('bin/busybox').read(),0o755)
 for name in ['lib/export.sh','tweaks/backup-jci/run.sh','tweaks/backup-jci/manifest.conf']:
  add('experiment/package/'+name,(REPO/'usb'/name).read_bytes(),0o755 if name.endswith('.sh') else 0o644)
 for folder in ['lib','tweaks']:
  for path in (REPO/'usb'/folder).rglob('*'):
   if path.is_file():add('experiment/package/'+path.relative_to(REPO/'usb').as_posix(),path.read_bytes(),0o755 if path.suffix=='.sh' else 0o644)
 import re
 # Synthetic full-context fixture, with the original shell and patch applet.
 lines=[];active=False
 for line in (REPO/'usb/tweaks/list-loop/assets/change.patch').read_text().splitlines():
  if line.startswith('@@ '):
   at=int(re.match(r'@@ -(\d+)',line).group(1))
   while len(lines)<at-1:lines.append('// synthetic gap')
   active=True
  elif active and line[:1] in [' ','-']:lines.append(line[1:])
 add('jci/gui/common/controls/List2/js/List2Ctrl.js','\n'.join(lines)+'\n')
 for applet in ['patch','diff','awk']:
  add('experiment/bin/'+applet,'#!/bin/sh\nexec /usr/bin/qemu-arm -L /cmu /cmu/lib/ld-linux.so.3 --library-path /cmu/lib:/cmu/usr/lib /cmu/bin/busybox '+applet+' "$@"\n',0o755)
 add('jci/version.ini','JCI_SW_VER="MAZ_CMU-150_74.00.324"\n')
 for path in (REPO/'usb/lib/lua-bridge').glob('*.lua'):add('experiment/package/lib/lua-bridge/'+path.name,path.read_bytes())
 add('experiment/package/ui/transport.html',(REPO/'usb/ui/transport.html').read_bytes())
 add('experiment/bin/lua','#!/bin/sh\nexec /usr/bin/qemu-arm -L /cmu /cmu/lib/ld-linux.so.3 --library-path /cmu/lib:/cmu/usr/lib /cmu/usr/bin/lua "$@"\n',0o755)
 add('probe.lua',"""print(_VERSION)
local p=require('posix');print(p.version)
local s=require('socket');print(s._VERSION)
for _,k in ipairs({'fork','exec','pipe','dup2','poll','read','write','wait','fcntl','F_SETFD','FD_CLOEXEC','SIGTERM','SIGPIPE'}) do print(k,type(p[k]),tostring(p[k])) end
local a,b=p.pipe();print('pipe',a,b);p.close(a);p.close(b)
local pid=p.fork()
if pid==0 then p.exec('/bin/sh','-c','echo child-started; exit 7');p._exit(99) end
print('wait',p.wait(pid))
""")
 add('init',"""#!/bin/sh
export PATH=/experiment/bin:/bin:/usr/bin:/sbin:/usr/sbin
mount -t proc proc /proc
mount -t devtmpfs devtmpfs /dev
ip link set lo up
export LUA_PATH='/experiment/?.lua;/cmu/usr/share/lua/5.1/?.lua;/cmu/usr/share/lua/5.1/?/init.lua'
export LUA_CPATH='/cmu/usr/lib/lua/5.1/?.so'
mkdir -p /tmp/lua-session /tmp/lua-logs
export INSTALLER_STATE=/tmp/lua-session
export INSTALLER_LOG=/tmp/lua-logs
lua() { /usr/bin/qemu-arm -L /cmu /cmu/lib/ld-linux.so.3 --library-path /cmu/lib:/cmu/usr/lib /cmu/usr/bin/lua "$@"; }
cmush() { /usr/bin/qemu-arm -L /cmu /cmu/lib/ld-linux.so.3 --library-path /cmu/lib:/cmu/usr/lib /cmu/bin/busybox sh "$@"; }
echo LUA_TEST_START
"""+('lua /probe.lua\n' if args.probe else 'cmush /experiment/tests/package-test.sh\n' if args.packages else 'cd /experiment\nlua /experiment/tests/backend.lua\n')+"""result=$?
echo "LUA_TEST_RESULT=$result"
sync
poweroff -f
""",0o755)
 appliance.write_cpio(overlay,run/'overlay.cpio.gz')
 (run/'test.cpio.gz').write_bytes(basefile.read_bytes()+(run/'overlay.cpio.gz').read_bytes())
 command=[str(EMU/'runtime/qemu/qemu-system-x86_64.exe'),'-machine','q35','-accel','tcg,thread=multi','-m','512','-smp','1','-display','none','-monitor','none','-no-reboot','-kernel',str(EMU/'cache/vmlinuz-virt'),'-initrd',str(run/'test.cpio.gz'),'-append','console=ttyS0 quiet noapic pci=nomsi panic=-1 rdinit=/init','-serial','file:'+str(run/'test.log'),'-nic','none']
 result=subprocess.run(command,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,timeout=300,creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
 log=(run/'test.log').read_text(errors='replace');shutil.copyfile(run/'test.log',CACHE/'test.log');print(log[-12000:])
 assert result.returncode==0 and 'LUA_TEST_RESULT=0' in log,(result.returncode,result.stdout)
if __name__=='__main__':main()
