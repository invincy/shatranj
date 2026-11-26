import fs from 'node:fs';
import vm from 'node:vm';
import assert from 'node:assert/strict';
class Element {
  constructor(tag='div'){this.tag=tag;this.children=[];this.textContent='';this.listeners={};}
  appendChild(child){this.children.push(child);return child;}
  replaceChildren(){this.children=[];}
  setAttribute(k,v){this[k]=v;}
  addEventListener(k,v){this.listeners[k]=v;}
}
const source=fs.readFileSync('webapp/startup-recovery.js','utf8');
function run(message,ua='Android Chrome'){
 const notice=new Element(),intro=new Element();let reloads=0,events=0;
 const window={dispatchEvent(e){assert.equal(e.type,'shatranj-startup-failed');events++;}};
 vm.runInNewContext(source,{window,document:{getElementById:()=>notice,querySelector:()=>intro,createElement:tag=>new Element(tag)},navigator:{userAgent:ua},location:{reload(){reloads++;}},Event:class{constructor(type){this.type=type;}}});
 window.shatranjShowStartupFailure(message);
 assert(window.shatranjStartupFailed);assert.equal(events,1);assert.equal(notice.role,'alert');
 assert(!intro.textContent.includes('Loading'));
 const nodes=[];function walk(node){nodes.push(node);node.children.forEach(walk);}walk(notice);
 nodes.find(n=>n.tag==='button').listeners.click();assert.equal(reloads,1);
 return nodes;
}
let nodes=run('WebGL2 - Check web browser configuration and hardware support');
assert(nodes.some(n=>n.textContent==='3D graphics could not start'));
assert(nodes.some(n=>n.href?.includes('package=com.android.chrome;')));
assert(nodes.some(n=>n.textContent.includes('does not necessarily mean')));
nodes=run('Unable to download game data','Desktop');
assert(nodes.some(n=>n.textContent==='The game could not load'));
assert(!nodes.some(n=>n.href?.startsWith('intent:')));
run('<img src=x onerror=alert(1)>'); // Technical details are text nodes, not HTML.
const html=fs.readFileSync('browser-site/github-pages/index.html','utf8');
assert(html.includes('window.shatranjShowStartupFailure(err)'));
assert(html.indexOf('src="startup-recovery.js"')<html.indexOf('function displayFailureNotice'));
console.log('PASS WebGL/general failures, text-only details, retry, Android link, failure event and generated loader hook');
