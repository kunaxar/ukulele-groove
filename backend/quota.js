import {DurableObject} from 'cloudflare:workers';
export class QuotaGate extends DurableObject {
 constructor(ctx,env){super(ctx,env);}
 async status(){return await this.ctx.storage.get('state')||{day:new Date().toISOString().slice(0,10),attempts:{yotomp3:0,ezconv:0},lockUntil:0,lastStart:0};}
 async reserve(usedSeconds){return await this.ctx.blockConcurrencyWhile(async()=>{
  let s=await this.status();const day=new Date().toISOString().slice(0,10),now=Date.now();if(s.day!==day)s={day,attempts:{yotomp3:0,ezconv:0},lockUntil:0,lastStart:0};
  if(usedSeconds>=510)return {ok:false,error:'Shared free browser budget nearly exhausted. Try after the daily reset; saved songs remain usable.',state:s};
  if(s.lockUntil>now||now-s.lastStart<21000)return {ok:false,error:'Another conversion is running or cooling down. Please wait 25 seconds.',state:s};
  s.lockUntil=now+100000;s.lastStart=now;await this.ctx.storage.put('state',s);return {ok:true,state:s};
 });}
 async attempt(provider){return await this.ctx.blockConcurrencyWhile(async()=>{let s=await this.status();if(provider==='yotomp3'&&s.attempts.yotomp3>=10)return false;s.attempts[provider]=(s.attempts[provider]||0)+1;await this.ctx.storage.put('state',s);return true;});}
 async finish(){return await this.ctx.blockConcurrencyWhile(async()=>{let s=await this.status();s.lockUntil=0;await this.ctx.storage.put('state',s);return s;});}
}
