// Parse failures in app.js must be reportable before app.js initializes the UI.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const html=fs.readFileSync(path.join(__dirname,'../../usb/ui/index-template.html'),'utf8');
const source=Array.from(html.matchAll(/<script>([\s\S]*?)<\/script>/g)).find(m=>m[1].includes('window.onerror'))[1];
function boot(){
  const sent=[],listeners={},frame={src:'',contentWindow:{postMessage(job,origin){sent.push({job,origin});}}};
  const window={installerConfig:{origin:'http://127.0.0.1:1234',token:'test-token'},addEventListener(k,fn){listeners[k]=fn;}};
  vm.runInNewContext(source,{window,document:{getElementById(id){assert.equal(id,'transport');return frame;}}});
  const ready=(origin='http://127.0.0.1:1234',token='test-token',sender=frame.contentWindow)=>listeners.message({origin,source:sender,data:{type:'shell-ready',token}});
  return {window,frame,sent,ready};
}
let x=boot();assert.equal(x.sent.length,0);assert.equal(x.frame.src,'');
x.window.onerror('Syntax error','file:///tmp/ui/app.js#private',198);
assert.equal(x.frame.src,'http://127.0.0.1:1234/#test-token');assert.equal(x.sent.length,0);
x.ready('http://wrong');x.ready(undefined,'wrong');x.ready(undefined,undefined,{});assert.equal(x.sent.length,0);
x.ready();assert.equal(x.sent.length,1);
assert.deepEqual(Array.from(x.sent[0].job.args).slice(0,3),['./installer.sh','event','ui-error']);
assert.match(x.sent[0].job.args[3],/Syntax error.*app.js.*line=198/);assert(!x.sent[0].job.args[3].includes('private'));
assert.equal(x.sent[0].job.program,'/bin/sh');assert(x.sent[0].job.id<0);
x.ready();assert.equal(x.sent.length,1,'Repeated readiness must not replay logged errors');
for(let i=0;i<20;i++)x.window.onerror('Repeated error','app.js',1);
assert.equal(x.sent.length,5,'Error logging is bounded');
x=boot();x.frame.src='http://127.0.0.1:1234/#test-token';x.ready();x.window.onerror('Runtime error','app.js',3);
assert.equal(x.sent.length,1);assert.equal(x.frame.src,'http://127.0.0.1:1234/#test-token');
console.log('EARLY_UI_ERROR_LOGGING_PASSED: parse/runtime failures, origin/token/source validation, independent transport and bounded reporting.');
