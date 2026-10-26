// Functional UI test with a minimal DOM and simulated worker replies.
// This is not a rendering test and never executes a vehicle patch.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const ROOT=path.join(__dirname,'../../usb');
class Node {
  constructor(tag,doc){this.tagName=tag;this.doc=doc;this.children=[];this.className='';this.disabled=false;this.scrollTop=0;this._text='';this.attributes={};}
  appendChild(node){this.children.push(node);node.parentNode=this;return node;}
  removeChild(node){this.children.splice(this.children.indexOf(node),1);}
  get firstChild(){return this.children[0]||null;}
  set textContent(t){this._text=String(t);this.children=[];}
  get textContent(){return this._text+this.children.map(n=>n.textContent).join('');}
  setAttribute(k,v){this.attributes[k]=v;}
  focus(){this.doc.activeElement=this;}
  getElementsByTagName(tag){let all=[];for(const n of this.children){if(n.tagName===tag)all.push(n);all=all.concat(n.getElementsByTagName(tag));}return all;}
}
function boot(manifestVersion,includeCommand,keepDisclaimer,includeExports){
  const recovery={},restoreOutcomes={},recoveryHints={};
  const nodes={},jobs=[],calls=[],timers=[],intervals=[],listeners={},states={'restore-originals':'uninstalled','backup-jci':'uninstalled','logs-collector':'uninstalled',hello:'uninstalled','list-beep':'uninstalled','main-menu-loop':'installed','ssh':'error'},outcomes={},reasons={ssh:'A required component is missing.'};
  const doc={activeElement:null,createElement(t){return new Node(t,doc);},getElementById(id){return nodes[id]||walk(nodes.app).concat(walk(nodes.overlay)).find(n=>n.id===id)||null;}};
  function walk(n){return [n].concat(n.children.flatMap(walk));}
  for(const id of ['app','header','system-info','tabs','content','cards','empty','footer-status','refresh','exit','overlay','dialog','dialog-heading','dialog-dot','dialog-title','dialog-body','dialog-state','dialog-description','dialog-meta','dialog-output','dialog-actions','back','action','result-ok','transport']){nodes[id]=new Node('div',doc);nodes[id].id=id;}
  for(const id of ['refresh','exit','back','action','result-ok'])nodes[id].tagName='button';
  nodes.app.appendChild(nodes.header);nodes.header.appendChild(nodes.refresh);nodes.header.appendChild(nodes.exit);nodes.app.appendChild(nodes.tabs);nodes.app.appendChild(nodes.content);nodes.content.appendChild(nodes.cards);
  nodes.overlay.appendChild(nodes.dialog);nodes.dialog.appendChild(nodes['dialog-actions']);for(const id of ['back','action','result-ok'])nodes['dialog-actions'].appendChild(nodes[id]);
  nodes.overlay.className='hidden';nodes['result-ok'].className='primary hidden';
  nodes.transport.contentWindow={postMessage(job,origin){assert.equal(origin,'http://127.0.0.1:1234');jobs.push(job);}};
  const win={installerConfig:{origin:'http://127.0.0.1:1234',token:'secret'},innerWidth:800,innerHeight:480,setTimeout(fn){timers.push(fn);},setInterval(fn){intervals.push(fn);},addEventListener(n,f){listeners[n]=f;}};
  const ctx={window:win,document:doc,escape,decodeURIComponent,WaylandManager:function(){this.SetRequiredSurfaces=(...a)=>calls.push(['visible',...a]);this.SetKeyboardFocus=(...a)=>calls.push(['focus',...a]);}};
  vm.runInNewContext(fs.readFileSync(path.join(ROOT,'ui/app.js'),'utf8'),ctx);
  function event(data,origin='http://127.0.0.1:1234',source=nodes.transport.contentWindow){listeners.message({source,origin,data});}
  function ok(stdout='',code=0,stderr=''){return {started:true,exitCode:code,signal:null,stdout,stderr,startError:'',stdoutTruncated:false,stderrTruncated:false};}
  let background=null,polls=0;
  function process(job){
    assert.equal(job.program,'/bin/sh');assert.equal(job.args[0],'./installer.sh');const a=job.args.slice(1);calls.push(a);
    if(a[0]==='event')return ok();
    if(a[0]==='restore-check')return recovery[a[1]]?ok(recovery[a[1]]):ok('',1,'No verified original backup is available.');
    if(a[0]==='restore-original') {const code=restoreOutcomes[a[1]]||0;if(!code)states[a[1]]='uninstalled';return ok(code?'':'Original file restored. You can now retry Install.',code,code===2?'Restore cleanup failed. Do NOT reboot.':code?'Restore refused: file changed.':'');}
    if(a[0]==='package-info')return ok(states[a[1]]==='installed'?'0.7.0\tinstalled\n':'');
    if(a[0]==='metrics')return ok('cpu\t1000\t700\t'+(a[1]==='0'?'-':'30')+'\ndisk\t/\t42\ndisk\t/tmp/mnt/resources\t18\ndisk\t/tmp/mnt/sdb1\t80\n');
    if(a[0]==='start-run'){background=a[1];polls=0;return ok('job.test01\n');}
    if(a[0]==='job-status'){polls++;return ok(polls===1?'running\n0\n0\nCreating archive\n':polls===2?'running\n5\n10\nCopying files\n':'done\n'+(outcomes[background]||0)+'\n');}
    if(a[0]==='job-output')return ok(a[2]==='stdout'?'Saved to USB: /mnt/sdb1/exports/'+background:'');
    if(a[0]==='list')return ok('list-beep\nmain-menu-loop\nssh\nbroken\n'+(includeCommand?'hello\n':'')+(includeExports?'backup-jci\nlogs-collector\nrestore-originals\n':''));
    if(a[0]==='manifest'){if(a[1]==='broken')return ok('{broken');let m=fs.readFileSync(a[1]==='hello'?path.join(ROOT,'../development/examples/hello/manifest.conf'):path.join(ROOT,'tweaks',a[1],'manifest.conf'),'utf8');if(manifestVersion)m=m.replace(/^contract_version=.*$/m,'contract_version='+manifestVersion);return ok(m);}
    if(a[0]==='statuses')return ok(a[1].split(' ').map(id=>id+'\t'+(states[id]==='error'?'error':states[id])+'\t'+(states[id]==='error'?'Patch state is ambiguous.':['unavailable','broken'].includes(states[id])?(reasons[id]||''):'' )+'\n').join(''));
    if(a[2]==='status')return states[a[1]]==='error'?ok('',1,'Patch state is ambiguous.'):ok(states[a[1]]+'\n',0,['unavailable','broken'].includes(states[a[1]])?(reasons[a[1]]||''):'');
    const code=outcomes[a[1]]||0;
    if(code===0)states[a[1]]=a[2]==='install'?'installed':'uninstalled';
    return ok(code?(code===1&&recovery[a[1]]&&recoveryHints[a[1]]!==false?'MZD_RECOVERY_CANDIDATE\n':''):a[2]+' completed. Other changes were preserved.',code,code===2?'Rollback failed. Do NOT reboot.':code?'Installation rejected.':'');
  }
  function pump(){let count=0;while(jobs.length){if(++count>100)throw new Error('request loop');const j=jobs.shift();event({type:'shell-result',token:'secret',id:j.id,result:process(j),error:null});}}
  event({type:'shell-ready',token:'wrong'});event({type:'shell-ready',token:'secret'},'http://wrong');assert.equal(jobs.length,0);
  event({type:'shell-ready',token:'secret'});pump();
  if(!keepDisclaimer){nodes.action.onclick();pump();}
  const click=id=>{const n=doc.getElementById(id);assert(n,'missing '+id);assert(!n.disabled,'disabled '+id);n.onclick();};
  return {nodes,doc,jobs,calls,states,outcomes,reasons,recovery,restoreOutcomes,recoveryHints,timers,intervals,pump,click,ok,event};
}
let x=boot();
assert.equal(x.calls.filter(a=>a[0]==='statuses').length,1);
assert.equal(x.calls.filter(a=>a[0]==='action'&&a[2]==='status').length,0);
assert.equal(x.nodes.tabs.children.length,3); // Errors, Interface, System.
assert.equal(x.nodes.cards.firstChild.id,'tweak-broken');
assert.equal(x.nodes.cards.firstChild.children[0].className,'dot error');
x.click('tweak-broken');assert.equal(x.nodes.action.disabled,true);x.click('back');
x.nodes.tabs.children.find(n=>n.textContent.indexOf('Interface')===0).onclick();
assert.equal(x.doc.getElementById('tweak-main-menu-loop').children[0].className,'dot installed');
assert.equal(x.doc.getElementById('tweak-list-beep').children[0].className,'dot uninstalled');
x.click('tweak-list-beep');assert.equal(x.nodes.action.textContent,'Install');assert.match(x.nodes['dialog-description'].textContent,/beeps/);assert.match(x.nodes['dialog-meta'].textContent,/Restart required:Yes/);
x.click('action');assert.equal(x.nodes['dialog-state'].textContent,'Install in progress...');assert.equal(x.nodes.back.disabled,true);assert.equal(x.nodes.exit.disabled,true);x.pump();
assert.equal(x.nodes['dialog-title'].textContent,'Operation completed');assert.equal(x.nodes['dialog-state'].textContent,'Install completed');assert.doesNotMatch(x.nodes['dialog-output'].textContent,/install in progress|install completed/i);
x.click('result-ok');x.pump();assert.equal(x.doc.getElementById('tweak-list-beep').children[0].className,'dot installed');
x.click('tweak-list-beep');assert.equal(x.nodes.action.textContent,'Uninstall');x.click('action');assert.match(x.nodes['dialog-state'].textContent,/^Uninstall in progress/);x.pump();assert.equal(x.nodes['dialog-state'].textContent,'Uninstall completed');x.click('result-ok');x.pump();assert.equal(x.states['list-beep'],'uninstalled');
x.outcomes['list-beep']=1;x.click('tweak-list-beep');x.click('action');x.pump();assert.equal(x.nodes['dialog-title'].textContent,'Operation failed');assert.equal(x.nodes['dialog-state'].textContent,'Install failed');x.click('result-ok');x.pump();assert.equal(x.nodes.refresh.disabled,false);
x.nodes.tabs.children.find(n=>n.textContent.indexOf('System')===0).onclick();x.click('tweak-ssh');assert.equal(x.nodes.action.textContent,'Retry status');assert.match(x.nodes['dialog-state'].textContent,/ambiguous/);x.click('back');
x.nodes.tabs.children.find(n=>n.textContent.indexOf('Interface')===0).onclick();x.outcomes['list-beep']=2;x.click('tweak-list-beep');x.click('action');x.pump();assert.equal(x.nodes['dialog-title'].textContent,'Manual check required');assert.match(x.nodes['dialog-description'].textContent,/Do NOT reboot/);x.click('result-ok');assert.equal(x.nodes.refresh.disabled,true);x.click('tweak-main-menu-loop');assert.equal(x.nodes.action.disabled,true);x.click('back');
x.click('exit');x.pump();assert.deepEqual(x.calls.filter(a=>a[0]==='focus').at(-1),['focus','JCI_OPERA_PRIMARY']);
// A known start failure cannot have changed the target and must not falsely
// claim that manual rollback or a no-reboot state is required.
x=boot();x.nodes.tabs.children.find(n=>n.textContent.indexOf('Interface')===0).onclick();x.click('tweak-list-beep');x.click('action');
let request=x.jobs.shift();x.event({type:'shell-result',token:'secret',id:request.id,error:null,result:{started:false,exitCode:null,signal:null,stdout:'',stderr:'',startError:'Missing executable'}});
assert.equal(x.nodes['dialog-title'].textContent,'Operation failed');x.click('result-ok');x.pump();assert.equal(x.nodes.refresh.disabled,false);
console.log('INSTALLER_UI_TESTS_PASSED: discovery, tabs, dots, metadata, status errors, install/uninstall, result OK, critical lock, Exit.');

// A blocked or broken state is a valid inspection, with a required reason.
for(const state of ['unavailable','broken']) {
  x=boot();x.states.ssh=state;x.click('refresh');x.pump();
  x.nodes.tabs.children.find(n=>n.textContent.indexOf('System')===0).onclick();
  assert.equal(x.doc.getElementById('tweak-ssh').children[0].className,'dot '+state);
  x.click('tweak-ssh');assert.equal(x.nodes.action.textContent,'Retry status');
  assert.match(x.nodes['dialog-state'].textContent,/required component/);
  x.click('back');assert.equal(x.nodes.refresh.disabled,false);
}
x=boot();x.states.ssh='unavailable';x.reasons.ssh='';x.click('refresh');x.pump();
x.nodes.tabs.children.find(n=>n.textContent.indexOf('System')===0).onclick();
x.click('tweak-ssh');assert.match(x.nodes['dialog-state'].textContent,/without a reason/);
x=boot(99);assert.equal(x.nodes.tabs.children.length,1);x.click('tweak-list-beep');assert.equal(x.nodes.action.disabled,true);
console.log('CONTRACT_V1_UI_PASSED: unavailable, broken, reasons and unsupported contract version.');

x=boot(undefined,true);
x.nodes.tabs.children.find(n=>n.textContent.indexOf('Examples')===0).onclick();
x.click('tweak-hello');assert.equal(x.nodes.action.textContent,'Run');
x.click('action');x.pump();assert(x.calls.some(a=>a[0]==='action'&&a[1]==='hello'&&a[2]==='run'));
x.click('result-ok');x.pump();assert.equal(x.states.hello,'uninstalled');
console.log('COMMAND_UI_PASSED: manifest discovery, Run and status refresh.');

// Real CMU controller codes: rotate M/N, tilt arrows, Backspace on release.
x=boot(undefined,false,false,true);
function controller(type,key,whichOnly=false){
  let prevented=false;const event={preventDefault(){prevented=true;}};
  event[whichOnly?'which':'keyCode']=key;x.doc[type](event);assert.equal(prevented,true);
}
x.nodes.refresh.focus();controller('onkeydown',77);assert.equal(x.doc.activeElement,x.nodes.exit);
controller('onkeydown',78,true);assert.equal(x.doc.activeElement,x.nodes.refresh);
controller('onkeydown',40);assert.equal(x.doc.activeElement,x.nodes.exit);
controller('onkeydown',38);assert.equal(x.doc.activeElement,x.nodes.refresh);
const interfaceTab=x.nodes.tabs.children.find(n=>n.textContent.indexOf('Interface')===0);
const systemTab=x.nodes.tabs.children.find(n=>n.textContent.indexOf('System')===0);
interfaceTab.onclick();assert.equal(x.doc.activeElement,interfaceTab);
controller('onkeydown',77);assert.equal(x.doc.activeElement,systemTab);
controller('onkeydown',13);assert.equal(x.doc.activeElement,systemTab);
assert.equal(systemTab.attributes['aria-selected'],'true');
assert.equal(interfaceTab.attributes['aria-selected'],'false');
controller('onkeydown',78);assert.equal(x.doc.activeElement,interfaceTab);
controller('onkeydown',13);assert.equal(x.doc.activeElement,interfaceTab);
systemTab.onclick();assert.equal(x.doc.activeElement,systemTab);
controller('onkeydown',77);assert.equal(x.doc.activeElement,x.nodes.cards.children[0]);
x.nodes.tabs.children.find(n=>n.textContent.indexOf('Interface')===0).onclick();
x.click('tweak-list-beep');controller('onkeydown',77);assert.equal(x.doc.activeElement,x.nodes.action);
controller('onkeydown',78);assert.equal(x.doc.activeElement,x.nodes.back);
const top=x.nodes['dialog-body'].scrollTop;
controller('onkeydown',40);assert.equal(x.nodes['dialog-body'].scrollTop,top+70);
controller('onkeydown',38);assert.equal(x.nodes['dialog-body'].scrollTop,top);
controller('onkeydown',8);assert(!x.nodes.overlay.className.includes('hidden'));
controller('onkeyup',8);assert(x.nodes.overlay.className.includes('hidden'));
// Back cannot dismiss an in-flight operation or skip result acknowledgement.
x.click('tweak-list-beep');x.click('action');controller('onkeydown',8);controller('onkeyup',8);
assert(!x.nodes.overlay.className.includes('hidden'));x.pump();controller('onkeyup',8);
assert.equal(x.nodes['dialog-title'].textContent,'Operation completed');
x.click('result-ok');x.pump();controller('onkeydown',8);controller('onkeyup',8);x.pump();
assert.equal(x.nodes['dialog-title'].textContent,'Restart recommended');
controller('onkeyup',8);x.pump();
assert(x.calls.some(a=>a[0]==='event'&&a[1]==='close'));
console.log('MULTICONTROLLER_PASSED: rotate, tilt up/down, Back on release, browser-history suppression and action guards.');

// Exercise the production manifest parser directly with literal text values.
const appSource=fs.readFileSync(path.join(ROOT,'ui/app.js'),'utf8');
const manifestFunction=appSource.slice(appSource.indexOf('    function parseManifest('),appSource.indexOf('    function discover('));
const parseConf=vm.runInNewContext('(function(){function trim(v){return String(v||" ").replace(/^\\s+|\\s+$/g,"");}'+manifestFunction+';return parseManifest;}())');
const rawConf=fs.readFileSync(path.join(ROOT,'tweaks/list-beep/manifest.conf'),'utf8');
const literal='Text = # "quotes" $(not_a_command) `not_a_command`';
const parsedConf=parseConf('list-beep',rawConf.replace(/^name=.*$/m,'name='+literal));
assert.equal(parsedConf.name,literal);assert.equal(parsedConf.actions.join(' '),'install uninstall status');
assert.equal(parsedConf.requires.length,0);assert.equal(parsedConf.reboot_required,true);
for(const raw of [rawConf+'id=list-beep\n',rawConf+'unknown=value\n',rawConf.replace(/^id=.*\n/m,''),rawConf+'# tab\t\n']) {
  assert.throws(()=>parseConf('list-beep',raw));
}
console.log('MANIFEST_UI_PASSED: literal values, lists, booleans, duplicate/unknown/missing/control rejection.');

// Startup is entirely in the styled UI; no discovery or worker runs before OK.
x=boot(undefined,false,true);
assert.equal(x.nodes['dialog-title'].textContent,'Before you begin');
assert.equal(x.nodes.action.textContent,'OK');assert.equal(x.nodes.back.textContent,'Exit');
assert.equal(x.doc.activeElement,x.nodes.action);assert.equal(x.nodes.refresh.disabled,true);
assert(!x.calls.some(a=>['list','manifest','action'].includes(a[0])));
controller('onkeydown',77);assert.equal(x.doc.activeElement,x.nodes.back);
controller('onkeydown',78);assert.equal(x.doc.activeElement,x.nodes.action);
controller('onkeydown',13);x.pump();assert.equal(x.calls.filter(a=>a[0]==='list').length,1);
assert.equal(x.nodes.back.textContent,'Back');assert.equal(x.nodes.refresh.disabled,false);
x=boot(undefined,false,true);x.click('back');x.pump();
assert(x.calls.some(a=>a[0]==='event'&&a[1]==='close'));
assert(!x.calls.some(a=>['list','manifest','action'].includes(a[0])));
x=boot(undefined,false,true);controller('onkeydown',8);
assert(!x.calls.some(a=>a[0]==='event'&&a[1]==='close'));
controller('onkeyup',8);x.pump();assert(x.calls.some(a=>a[0]==='event'&&a[1]==='close'));
x.nodes.action.onclick();x.pump();assert(!x.calls.some(a=>a[0]==='list'));
x=boot(undefined,false,true);controller('onkeydown',27);x.pump();
assert(x.calls.some(a=>a[0]==='event'&&a[1]==='close'));
assert(!fs.readFileSync(path.join(ROOT,'autorun.sh'),'utf8').includes('/jci/tools/jci-dialog'));
console.log('STARTUP_NOTICE_PASSED: controller OK/Exit/Back/Escape, no discovery before acceptance, no native dialog.');

// Export jobs release the serial bridge and update progress between polls.
for(const id of ['backup-jci','logs-collector']){
 x=boot(undefined,false,false,true);
 x.nodes.tabs.children.find(n=>n.textContent.indexOf('System')===0).onclick();
 x.click('tweak-'+id);assert.equal(x.nodes.action.textContent,'Run');x.click('action');x.pump();
 assert.match(x.nodes['dialog-state'].textContent,/Creating archive/);assert.equal(x.nodes.exit.disabled,true);
 assert.equal(x.timers.length,1);x.timers.shift()();x.pump();assert.match(x.nodes['dialog-state'].textContent,/5\/10/);
 x.timers.shift()();x.pump();assert.equal(x.nodes['dialog-title'].textContent,'Operation completed');
 assert.match(x.nodes['dialog-output'].textContent,/Saved to USB/);x.click('result-ok');x.pump();assert.equal(x.nodes.exit.disabled,false);
 assert(!x.calls.some(a=>a[0]==='action'&&a[1]===id&&a[2]==='run'));
}
console.log('EXPORT_PROGRESS_UI_PASSED: background start, phase/file progress, final output and operation guards.');

// Read-only header telemetry, periodic refresh and no polling during a worker.
x=boot();assert.match(x.nodes['system-info'].textContent,/CPU: --/);
assert.match(x.nodes['system-info'].textContent,/Resources: 18% free/);
x.intervals[0]();x.pump();assert.match(x.nodes['system-info'].textContent,/CPU: 30%/);
x.nodes.tabs.children.find(n=>n.textContent.indexOf('Interface')===0).onclick();
x.click('tweak-list-beep');x.click('action');
let metricCount=x.calls.filter(a=>a[0]==='metrics').length;
x.intervals[0]();x.pump();assert.equal(x.calls.filter(a=>a[0]==='metrics').length,metricCount);
x.click('result-ok');x.pump();x.intervals[0]();x.pump();
assert.equal(x.calls.filter(a=>a[0]==='metrics').length,metricCount+1);
console.log('SYSTEM_METRICS_UI_PASSED: CPU sampling, partition free space and paused polling during operations.');

// Restore is a deliberate second confirmation and refreshes every tweak afterwards.
x=boot(undefined,false,false,true);
x.nodes.tabs.children.find(n=>n.textContent.indexOf('System')===0).onclick();
x.click('tweak-restore-originals');x.click('action');
assert.match(x.nodes['dialog-title'].textContent,/Confirm:/);
assert.match(x.nodes['dialog-description'].textContent,/Tweak services may stop/);
assert.equal(x.nodes.action.textContent,'Continue');
assert(!x.calls.some(a=>a[0]==='start-run'));
x.click('back');assert.equal(x.nodes.action.textContent,'Run');
x.click('action');x.click('action');x.pump();
while(x.timers.length){x.timers.shift()();x.pump();}
assert.equal(x.nodes['dialog-title'].textContent,'Operation completed');
let statusBefore=x.calls.filter(a=>a[0]==='statuses').length;
x.click('result-ok');x.pump();
assert.equal(x.calls.filter(a=>a[0]==='statuses').length,statusBefore+1);
x.click('exit');assert.equal(x.nodes['dialog-title'].textContent,'Restart recommended');x.click('back');x.pump();
for(const blockedState of ['broken','unavailable']) {
 x=boot();x.states['list-beep']=blockedState;x.reasons['list-beep']='Target mismatch';x.click('refresh');x.pump();
 x.nodes.tabs.children.find(n=>n.textContent.indexOf('Interface')===0).onclick();x.click('tweak-list-beep');
 assert.match(x.nodes['dialog-description'].textContent,/System > Restore originals/);
 assert.match(x.nodes['dialog-description'].textContent,/ALL patches/);
}
console.log('RESTORE_UI_PASSED: confirmation/cancel, reset action, full status refresh and repair guidance.');

function finishPatch(action='install',code=0) {
 const y=boot();y.nodes.tabs.children.find(n=>n.textContent.indexOf('Interface')===0).onclick();
 const id=action==='uninstall'?'main-menu-loop':'list-beep';y.outcomes[id]=code;
 y.click('tweak-'+id);y.click('action');y.pump();y.click('result-ok');y.pump();return y;
}
for(const action of ['install','uninstall']) {
 x=finishPatch(action);x.click('exit');x.pump();
 assert.equal(x.nodes['dialog-title'].textContent,'Restart recommended');
 assert.equal(x.nodes.back.textContent,'Exit');assert.equal(x.nodes.action.textContent,'Restart');
 assert(!x.calls.some(a=>a[0]==='event'&&['restart','close'].includes(a[1])));
 x.click('back');x.pump();assert(x.calls.some(a=>a[0]==='event'&&a[1]==='close'));
 assert(!x.calls.some(a=>a[0]==='event'&&a[1]==='restart'));
}
x=finishPatch();x.click('exit');x.click('action');x.pump();
assert(x.calls.some(a=>a[0]==='event'&&a[1]==='restart'));
for(const code of [1,2]) {
 x=finishPatch('install',code);x.click('exit');x.pump();
 assert(x.calls.some(a=>a[0]==='event'&&a[1]==='close'));
 assert(!x.calls.some(a=>a[0]==='event'&&a[1]==='restart'));
}
x=boot();x.click('exit');x.pump();assert(x.calls.some(a=>a[0]==='event'&&a[1]==='close'));
x=boot();x.states.ssh='uninstalled';x.click('refresh');x.pump();
x.nodes.tabs.children.find(n=>n.textContent.indexOf('System')===0).onclick();
x.click('tweak-ssh');x.click('action');x.pump();x.click('result-ok');x.pump();x.click('exit');x.pump();
assert(x.calls.some(a=>a[0]==='event'&&a[1]==='close'));assert(!x.calls.some(a=>a[0]==='event'&&a[1]==='restart'));
// A rejected restart request leaves both choices usable.
x=finishPatch();x.click('exit');x.click('action');
let restartRequest=x.jobs.shift();assert.equal(restartRequest.args[2],'restart');
x.event({type:'shell-result',token:'secret',id:restartRequest.id,result:x.ok('',1,'Restart unavailable')});
assert.equal(x.nodes.back.disabled,false);assert.equal(x.nodes.action.disabled,false);
x.click('back');x.pump();assert(x.calls.some(a=>a[0]==='event'&&a[1]==='close'));
console.log('RESTART_UI_PASSED: successful install/uninstall, optional Exit, explicit restart, failed/critical/no-restart actions and request failure.');

// Read-only scanning does not trap the user in the installer.
x=boot();let beforeScan=x.calls.filter(a=>a[0]==='statuses').length;
x.click('refresh');assert.equal(x.nodes.exit.disabled,false);
x.click('exit');x.pump();assert(x.calls.some(a=>a[0]==='event'&&a[1]==='close'));
assert.equal(x.calls.filter(a=>a[0]==='statuses').length,beforeScan+1);
console.log('SCAN_EXIT_PASSED: Exit stays available and stops subsequent read-only status requests.');

// Exiting a scan is safe, but Restart must wait for its result.
x=finishPatch();x.click('refresh');x.click('exit');assert.equal(x.nodes.action.disabled,true);
let pendingStatus=x.jobs.shift();x.event({type:'shell-result',token:'secret',id:pendingStatus.id,result:x.ok('',2,'Critical status result')});
assert.equal(x.nodes.action.disabled,true);x.click('back');x.pump();
assert(!x.calls.some(a=>a[0]==='event'&&a[1]==='restart'));
console.log('SCAN_RESTART_GUARD_PASSED: critical scan cannot be bypassed by a queued restart.');

// A newer USB manifest does not replace the installed version in the details.
x=boot();x.nodes.tabs.children.find(n=>n.textContent.indexOf('Interface')===0).onclick();
x.click('tweak-main-menu-loop');x.pump();
assert.match(x.nodes['dialog-meta'].textContent,/0\.7\.0 installed \/ [0-9]+\.[0-9]+\.[0-9]+ on USB/);
assert.equal(x.nodes.action.textContent,'Uninstall');
console.log('SAVED_VERSION_UI_PASSED: installed and USB versions shown in one row, existing uninstall action retained.');

function recoveryOffer(raw='available\t'+'a'.repeat(32)+'\t/jci/test.js\n',hint=true) {
  const r=boot();r.outcomes['list-beep']=1;r.recovery['list-beep']=raw;r.recoveryHints['list-beep']=hint;
  r.nodes.tabs.children.find(n=>n.textContent.indexOf('Interface')===0).onclick();
  r.click('tweak-list-beep');r.click('action');r.pump();return r;
}
x=recoveryOffer();assert.equal(x.nodes['dialog-title'].textContent,'Restore original file?');
assert.match(x.nodes['dialog-description'].textContent,/ALL tweaks/);
assert.match(x.nodes['dialog-description'].textContent,/saved to USB/);
assert(!x.calls.some(a=>a[0]==='restore-original'));
x.click('back');assert.equal(x.nodes['dialog-title'].textContent,'Operation failed');
assert(!x.calls.some(a=>a[0]==='restore-original'));
x=recoveryOffer();controller('onkeyup',8);assert.equal(x.nodes['dialog-title'].textContent,'Operation failed');
x=recoveryOffer(undefined,false);assert.equal(x.nodes['dialog-title'].textContent,'Operation failed');
assert(!x.calls.some(a=>a[0]==='restore-check'),'An unrelated install error must not trigger recovery');
x=recoveryOffer();x.click('action');x.pump();
assert.deepEqual(Array.from(x.calls.find(a=>a[0]==='restore-original')),['restore-original','list-beep','a'.repeat(32)]);
assert.equal(x.nodes['dialog-state'].textContent,'Restore completed');
assert.equal(x.calls.filter(a=>a[0]==='action'&&a[2]==='install').length,1,'Restore must not automatically reinstall');
x.click('result-ok');x.pump();x.outcomes['list-beep']=0;x.click('tweak-list-beep');assert.equal(x.nodes.action.textContent,'Install');
x=recoveryOffer();x.restoreOutcomes['list-beep']=2;x.click('action');x.pump();
assert.match(x.nodes['dialog-description'].textContent,/Do NOT reboot/);x.click('result-ok');assert.equal(x.nodes.refresh.disabled,true);
for(const raw of ['available\tbad-hash\t/jci/test.js\n','available\t'+'a'.repeat(32)+'\t/jci/test.js','available\t'+'a'.repeat(32)+'\t/jci/test.js\nextra\n']) {
  x=recoveryOffer(raw);assert.equal(x.nodes['dialog-title'].textContent,'Operation failed');assert(!x.calls.some(a=>a[0]==='restore-original'));
}
console.log('TARGET_RECOVERY_UI_PASSED: validated offer, explicit confirmation, Back, no automatic install and critical restore failures.');
