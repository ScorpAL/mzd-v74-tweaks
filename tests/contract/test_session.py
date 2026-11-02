"""Real RAM-session helper and event adapter; no native UI or vehicle writes."""
from pathlib import Path
import os,shlex,shutil,subprocess,tempfile,time
ROOT=Path(__file__).resolve().parents[2]
SHELL='C:/Program Files/Git/bin/bash.exe' if os.name=='nt' else '/bin/sh'
def bp(p):
 s=Path(p).resolve().as_posix();return '/'+s[0].lower()+s[2:] if len(s)>1 and s[1]==':' else s
def write(p,s):
 p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf-8',newline='\n')
with tempfile.TemporaryDirectory(prefix='cmu-installer.session-') as directory:
 b=Path(directory);registry=b/'registry';first=b/'first';first.mkdir();second=b/'second';second.mkdir()
 helper=b/'session.sh';write(helper,(ROOT/'usb/lib/session.sh').read_text().replace('MZD_SESSION_DIR=/tmp/mzd-installer-session','MZD_SESSION_DIR='+shlex.quote(bp(registry))).replace('/tmp/cmu-installer.*',shlex.quote(bp(b))+'/*'))
 prefix='HERE='+shlex.quote(bp(b/'usb-new'))+'\n. '+shlex.quote(bp(helper))+'\n'
 driver=b/'owner.sh';write(driver,prefix+'STATE='+shlex.quote(bp(first))+'\nmzd_session_claim || exit 1\necho ready\nwhile [ ! -f '+shlex.quote(bp(b/'release'))+' ];do sleep 0.1;done\nmzd_session_release\n')
 owner=subprocess.Popen([SHELL,bp(driver)],stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
 try:
  assert owner.stdout.readline().strip()=='ready'
  command=prefix+'STATE='+shlex.quote(bp(second))+'\nmzd_session_claim\n'
  def claim():return subprocess.run([SHELL,'-c',command],capture_output=True,text=True,timeout=5)
  r=claim();assert r.returncode==2,(r.stdout,r.stderr);assert (first/'ui-refocus-request').exists();assert (first/'usb-root').read_text().strip()==bp(b/'usb-new')
  assert len(list(registry.glob('owner')))==1
  write(first/'ui-closing','');assert claim().returncode==1;(first/'ui-closing').unlink()
  write(b/'release','');assert owner.wait(timeout=5)==0;assert not registry.exists()
 finally:
  if owner.poll() is None:owner.kill();owner.wait()
 # The real entry wrapper returns while its fully detached child remains alive.
 launcher=(ROOT/'usb/autorun.sh').read_text()
 wrapper=launcher[launcher.index('if [ "${1:-}" != --session ]; then'):launcher.index('\n. "$HERE/lib/defines.sh"')]
 fake=b/'child.sh';write(fake,'echo $$ > '+shlex.quote(bp(b/'child.pid'))+'\nwhile [ ! -f '+shlex.quote(bp(b/'child.release'))+' ];do sleep 0.1;done\n')
 wrapper_driver=b/'wrapper.sh';write(wrapper_driver,'SELF='+shlex.quote(bp(fake))+'\n'+wrapper)
 started=time.monotonic();r=subprocess.run([SHELL,bp(wrapper_driver)],capture_output=True,text=True,timeout=4)
 assert r.returncode==0 and time.monotonic()-started<3
 for _ in range(30):
  if (b/'child.pid').exists():break
  time.sleep(.1)
 assert (b/'child.pid').exists();write(b/'child.release','')
 # Dead owner and reused PID with a different start time are reclaimed.
 for pid,stamp in [('99999999','1'),(str(os.getpid()),'0')]:
  registry.mkdir();write(registry/'owner',pid+'\n'+stamp+'\n'+bp(first)+'\n')
  r=subprocess.run([SHELL,'-c',command+'r=$?;[ "$r" = 0 ] || exit "$r";mzd_session_release'],capture_output=True,text=True,timeout=5)
  assert r.returncode==0,(r.stdout,r.stderr);assert not registry.exists()
 registry.mkdir();assert claim().returncode==1;assert registry.exists();registry.rmdir()
 # Polling consumes just one request and emits no idle log entries.
 usb=b/'usb';shutil.copytree(ROOT/'usb/lib',usb/'lib');write(usb/'installer.sh',(ROOT/'usb/installer.sh').read_text())
 env=dict(os.environ,INSTALLER_STATE=bp(first),INSTALLER_LOG=bp(first),MZD_DATETIME_ASKED='1')
 def event(name):return subprocess.run([SHELL,bp(usb/'installer.sh'),'event',name],env=env,capture_output=True,text=True,timeout=5)
 assert event('focus-poll').stdout=='requested\n'
 assert event('focus-poll').stdout=='';assert not (first/'ui.log').exists()
 assert event('refocus-ready').returncode==0;assert (first/'ui-refocus-ready').exists()
 write(first/'ui-close','');write(first/'ui-refocus-request','');assert event('focus-poll').stdout==''
print('SESSION_REPLUG_PASSED: live reuse, closing refusal, stale/reused PID recovery, incomplete publisher, release and one-shot event handshake.')
