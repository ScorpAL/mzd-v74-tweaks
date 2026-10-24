// Functional UI test with a minimal DOM and simulated worker replies.
// This is not a rendering test and never executes a vehicle patch.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const ROOT=path.join(__dirname,'../..');
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
function boot(manifestVersion,includeCommand){
  const nodes={},jobs=[],calls=[],listeners={},states={hello:'uninstalled','list-beep':'uninstalled','main-menu-loop':'installed','ssh':'error'},outcomes={},reasons={ssh:'A required component is missing.'};
  const doc={activeElement:null,createElement(t){return new Node(t,doc);},getElementById(id){return nodes[id]||walk(nodes.app).concat(walk(nodes.overlay)).find(n=>n.id===id)||null;}};
  function walk(n){return [n].concat(n.children.flatMap(walk));}
  for(const id of ['app','header','tabs','content','cards','empty','footer-status','refresh','exit','overlay','dialog','dialog-heading','dialog-dot','dialog-title','dialog-body','dialog-state','dialog-description','dialog-meta','dialog-output','dialog-actions','back','action','result-ok','transport']){nodes[id]=new Node('div',doc);nodes[id].id=id;}
  for(const id of ['refresh','exit','back','action','result-ok'])nodes[id].tagName='button';
  nodes.app.appendChild(nodes.header);nodes.header.appendChild(nodes.refresh);nodes.header.appendChild(nodes.exit);nodes.app.appendChild(nodes.tabs);nodes.app.appendChild(nodes.content);nodes.content.appendChild(nodes.cards);
  nodes.overlay.appendChild(nodes.dialog);nodes.dialog.appendChild(nodes['dialog-actions']);for(const id of ['back','action','result-ok'])nodes['dialog-actions'].appendChild(nodes[id]);
  nodes.overlay.className='hidden';nodes['result-ok'].className='primary hidden';
  nodes.transport.contentWindow={postMessage(job,origin){assert.equal(origin,'http://127.0.0.1:1234');jobs.push(job);}};
  const win={installerConfig:{origin:'http://127.0.0.1:1234',token:'secret'},innerWidth:800,innerHeight:480,addEventListener(n,f){listeners[n]=f;}};
  const ctx={window:win,document:doc,escape,decodeURIComponent,WaylandManager:function(){this.SetRequiredSurfaces=(...a)=>calls.push(['visible',...a]);this.SetKeyboardFocus=(...a)=>calls.push(['focus',...a]);}};
  vm.runInNewContext(fs.readFileSync(path.join(ROOT,'ui/app.js'),'utf8'),ctx);
  function event(data,origin='http://127.0.0.1:1234',source=nodes.transport.contentWindow){listeners.message({source,origin,data});}
  function ok(stdout='',code=0,stderr=''){return {started:true,exitCode:code,signal:null,stdout,stderr,startError:'',stdoutTruncated:false,stderrTruncated:false};}
  function process(job){
    assert.equal(job.program,'/bin/sh');assert.equal(job.args[0],'./installer.sh');const a=job.args.slice(1);calls.push(a);
    if(a[0]==='event')return ok();
    if(a[0]==='list')return ok('list-beep\nmain-menu-loop\nssh\nbroken\n'+(includeCommand?'hello\n':''));
    if(a[0]==='manifest'){if(a[1]==='broken')return ok('{broken');const m=JSON.parse(fs.readFileSync(a[1]==='hello'?path.join(ROOT,'examples/hello/manifest.json'):path.join(ROOT,'tweaks',a[1],'manifest.json'),'utf8'));if(manifestVersion)m.contract_version=manifestVersion;return ok(JSON.stringify(m));}
    if(a[2]==='status')return states[a[1]]==='error'?ok('',1,'Patch state is ambiguous.'):ok(states[a[1]]+'\n',0,['unavailable','broken'].includes(states[a[1]])?(reasons[a[1]]||''):'');
    const code=outcomes[a[1]]||0;
    if(code===0)states[a[1]]=a[2]==='install'?'installed':'uninstalled';
    return ok(code?'':a[2]+' completed. Other changes were preserved.',code,code===2?'Rollback failed. Do NOT reboot.':code?'Installation rejected.':'');
  }
  function pump(){let count=0;while(jobs.length){if(++count>100)throw new Error('request loop');const j=jobs.shift();event({type:'shell-result',token:'secret',id:j.id,result:process(j),error:null});}}
  event({type:'shell-ready',token:'wrong'});event({type:'shell-ready',token:'secret'},'http://wrong');assert.equal(jobs.length,0);
  event({type:'shell-ready',token:'secret'});pump();
  const click=id=>{const n=doc.getElementById(id);assert(n,'missing '+id);assert(!n.disabled,'disabled '+id);n.onclick();};
  return {nodes,doc,jobs,calls,states,outcomes,reasons,pump,click,ok,event};
}
let x=boot();
assert.equal(x.nodes.tabs.children.length,3); // Errors, Interface, System.
assert.equal(x.nodes.cards.firstChild.id,'tweak-broken');
assert.equal(x.nodes.cards.firstChild.children[0].className,'dot error');
x.click('tweak-broken');assert.equal(x.nodes.action.disabled,true);x.click('back');
x.nodes.tabs.children.find(n=>n.textContent.indexOf('Interface')===0).onclick();
assert.equal(x.doc.getElementById('tweak-main-menu-loop').children[0].className,'dot installed');
assert.equal(x.doc.getElementById('tweak-list-beep').children[0].className,'dot uninstalled');
x.click('tweak-list-beep');assert.equal(x.nodes.action.textContent,'Install');assert.match(x.nodes['dialog-description'].textContent,/beeps/);assert.match(x.nodes['dialog-meta'].textContent,/Restart required:Yes/);
x.click('action');assert.equal(x.nodes.back.disabled,true);assert.equal(x.nodes.exit.disabled,true);x.pump();
assert.equal(x.nodes['dialog-title'].textContent,'Operation completed');assert.match(x.nodes['dialog-output'].textContent,/install completed/);
x.click('result-ok');x.pump();assert.equal(x.doc.getElementById('tweak-list-beep').children[0].className,'dot installed');
x.click('tweak-list-beep');assert.equal(x.nodes.action.textContent,'Uninstall');x.click('action');x.pump();x.click('result-ok');x.pump();assert.equal(x.states['list-beep'],'uninstalled');
x.outcomes['list-beep']=1;x.click('tweak-list-beep');x.click('action');x.pump();assert.equal(x.nodes['dialog-title'].textContent,'Operation failed');x.click('result-ok');x.pump();assert.equal(x.nodes.refresh.disabled,false);
x.nodes.tabs.children.find(n=>n.textContent.indexOf('System')===0).onclick();x.click('tweak-ssh');assert.equal(x.nodes.action.textContent,'Retry status');assert.match(x.nodes['dialog-state'].textContent,/ambiguous/);x.click('back');
x.nodes.tabs.children.find(n=>n.textContent.indexOf('Interface')===0).onclick();x.outcomes['list-beep']=2;x.click('tweak-list-beep');x.click('action');x.pump();assert.equal(x.nodes['dialog-title'].textContent,'Manual check required');assert.match(x.nodes['dialog-state'].textContent,/Do NOT reboot/);x.click('result-ok');assert.equal(x.nodes.refresh.disabled,true);x.click('tweak-main-menu-loop');assert.equal(x.nodes.action.disabled,true);x.click('back');
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
