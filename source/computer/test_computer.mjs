import vm from 'node:vm';
import fs from 'node:fs';
import assert from 'node:assert/strict';
import {spawn} from 'node:child_process';
const commands=[];
class Worker {
  constructor() {
    this.process=spawn(process.execPath,['webapp/stockfish/stockfish-19-lite-single.js']);
    let pending='';
    this.process.stdout.on('data',data=>{pending+=data;let i;while((i=pending.indexOf('\n'))>=0){const line=pending.slice(0,i).trim();pending=pending.slice(i+1);this.onmessage?.({data:line});}});
    this.process.on('error',e=>this.onerror?.(e));
  }
  postMessage(command) {commands.push(command);this.process.stdin.write(command+'\n');}
  terminate(){this.process.kill();}
}
const context={window:{},Worker,setTimeout,clearTimeout};
vm.runInNewContext(fs.readFileSync('webapp/computer.js','utf8'),context);
const engine=context.window.shatranjComputer;
const fen='rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';
const legal=['a2a3','a2a4','b2b3','b2b4','c2c3','c2c4','d2d3','d2d4','e2e3','e2e4','f2f3','f2f4','g2g3','g2g4','h2h3','h2h4','b1a3','b1c3','g1f3','g1h3'];
async function result(){for(let i=0;i<350;i++){const r=JSON.parse(engine.poll());if(r)return r;await new Promise(r=>setTimeout(r,100));}throw Error('No response');}
for(const level of [1,4,5,10]){
 engine.search(fen,level,JSON.stringify(legal));const reply=await result();assert.equal(reply.fen,fen);assert(legal.includes(reply.move),JSON.stringify(reply));console.log('PASS actual Stockfish level',level,reply.move);
}
engine.search(fen,5,JSON.stringify(legal));engine.cancel();await new Promise(r=>setTimeout(r,250));assert.equal(engine.poll(),'null');
engine.search(fen,4,JSON.stringify(legal));engine.search('7k/P7/8/8/8/8/8/7K w - - 0 1',5,JSON.stringify(['a7a8q','a7a8r','a7a8b','a7a8n']));
assert.match((await result()).move,/^a7a8[qrbn]$/);
assert(commands.includes('setoption name Skill Level value 7'));assert(commands.includes('setoption name Skill Level value 9'));
engine.search(fen,4,'[]');assert((await result()).error);engine.cancel();
console.log('PASS cancellation, replacement, promotion, skill settings and invalid request');
