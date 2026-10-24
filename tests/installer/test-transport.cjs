const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm'),assert=require('node:assert/strict');
const html=fs.readFileSync(path.join(__dirname,'../../usb/ui/transport.html'),'utf8');
const replies=[],requests=[],listeners={};
const parent={postMessage(message){replies.push(message);}};
function XHR(){requests.push(this);this.headers={};this.open=(method,url)=>{this.method=method;this.url=url;};this.setRequestHeader=(k,v)=>{this.headers[k]=v;};this.send=body=>{this.body=body;};}
const context={location:{hash:'#secret'},XMLHttpRequest:XHR,window:{parent,addEventListener(n,f){listeners[n]=f;}}};
vm.runInNewContext(html.match(/<script>([\s\S]*?)<\/script>/)[1],context);
assert.equal(replies[0].type,'shell-ready');
function event(id,token='secret',source=parent){listeners.message({source,data:{type:'shell-exec',token,id,program:'/bin/sh',args:['./installer.sh','manifest','list-beep']}});}
event(1,'wrong');event(1,'secret',{});assert.equal(requests.length,0);
event(1);event(2);assert.equal(requests.length,1);assert.equal(requests[0].headers['X-Poc-Token'],'secret');assert.match(requests[0].body,/program=%2Fbin%2Fsh/);
requests[0].status=200;requests[0].responseText='{"started":true,"exitCode":2,"stdout":"","stderr":"critical"}';requests[0].readyState=4;requests[0].onreadystatechange();
assert.equal(replies.at(-1).id,1);assert.equal(replies.at(-1).result.exitCode,2);assert.equal(requests.length,2);
requests[1].status=502;requests[1].readyState=4;requests[1].onreadystatechange();assert.match(replies.at(-1).error,/Outcome may be unknown/);
console.log('INSTALLER_TRANSPORT_TESTS_PASSED: source/token, serialized requests, critical exit, unknown outcome.');
