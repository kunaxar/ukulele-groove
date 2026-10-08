import puppeteer from '@cloudflare/puppeteer';
export {QuotaGate} from './quota.js';
const headers={'Access-Control-Allow-Origin':'https://kunaxar.github.io','Access-Control-Allow-Methods':'GET,OPTIONS','Access-Control-Expose-Headers':'X-Uke-Provider','Content-Type':'application/json','Cache-Control':'no-store'};
const providers=[{name:'yotomp3',advertisedDailyLimit:10,backendTest:'passed'},{name:'ezconv',advertisedDailyLimit:null,backendTest:'passed',note:'Provider claims no daily cap; actual availability can vary.'}];
async function convert(page,id,provider){
 if(provider==='ezconv'){
  await page.evaluateOnNewDocument(()=>{const original=window.fetch;window.ukeDownload='';window.fetch=async function(...args){const response=await original.apply(this,args);try{if(response.url.includes('/api/convert/status'))response.clone().json().then(j=>{if(j.downloadUrl)window.ukeDownload=j.downloadUrl;}).catch(()=>{});}catch(_){}return response;};});
   await page.goto('https://ezconv.cc/en',{waitUntil:'domcontentloaded',timeout:15000});
   await page.waitForSelector('input[placeholder="https://youtube.com/watch?v=..."]',{timeout:8000});
   await page.type('input[placeholder="https://youtube.com/watch?v=..."]','https://www.youtube.com/watch?v='+id);
   await page.waitForSelector('button[type=submit]:not([disabled])',{timeout:8000});
   await page.click('button[type=submit]');
   await page.waitForFunction(()=>Array.from(document.querySelectorAll('button')).some(a=>/Download MP3/i.test(a.innerText)),{timeout:25000});
   const downloadUrl=await page.evaluate(()=>window.ukeDownload);
   if(!downloadUrl)throw new Error('No converter audio URL received');
   const target=new URL(downloadUrl);if(target.protocol!=='https:'||!/^dl[0-9]*\.ezsrv\.net$/.test(target.hostname))throw new Error('Unexpected audio host');
   const mp3=await fetch(downloadUrl);if(!mp3.ok)throw new Error('Converter download failed');
   return mp3;
 }
  await page.goto('https://yotomp3.com/',{waitUntil:'domcontentloaded',timeout:20000});
  await page.waitForSelector('#youtube_input',{timeout:10000});
  await page.type('#youtube_input','https://www.youtube.com/watch?v='+id);
  await page.click('#youtube-form button[type=submit]');
  await page.waitForSelector('#notification a[href^="/download-file/"]',{timeout:55000});
  const audioUrl=await page.$eval('#notification a[href^="/download-file/"]',a=>a.href);
  if(new URL(audioUrl).hostname!=='yotomp3.com')throw new Error('Unexpected converter download host');
  const mp3=await fetch(audioUrl);if(!mp3.ok)throw new Error('Converter download failed');return mp3;
}
export default {async fetch(request,env){
 const url=new URL(request.url),gate=env.QUOTA.getByName('global');
 if(request.method==='OPTIONS')return new Response(null,{headers});
 if(request.method!=='GET')return Response.json({error:'Method not allowed'},{status:405,headers});
 if(url.pathname==='/health')return Response.json({status:'converter-chain-v1',providers:providers.map(p=>p.name)},{headers});
 if(url.pathname==='/quota'){
  try{return Response.json({cloudflare:await puppeteer.limits(env.BROWSER),state:await gate.status(),sharedDailyBrowserMinutes:10,providers,note:'Minutes are shared across providers. Attempt counts are app usage, not provider-reported remaining quota.'},{headers});}
  catch(e){return Response.json({error:'Capacity check unavailable.'},{status:503,headers});}
 }
 if(url.pathname!=='/audio')return Response.json({error:'Not found'},{status:404,headers});
 if(request.headers.get('Origin')!=='https://kunaxar.github.io')return Response.json({error:'Open Ukulele Groove to analyze a song.'},{status:403,headers});
 const id=url.searchParams.get('id');if(!/^[A-Za-z0-9_-]{11}$/.test(id||''))return Response.json({error:'Invalid video ID'},{status:400,headers});
 let browser,reserved=false;const errors=[];
 try{
  const limits=await puppeteer.limits(env.BROWSER);
  if(!limits.allowedBrowserAcquisitions)return Response.json({error:'Free browser cooldown or capacity limit. Try after 25 seconds or after the daily reset.'},{status:429,headers});
  const reservation=await gate.reserve(limits.usedBrowserTimeSeconds||0);
  if(!reservation.ok)return Response.json({error:reservation.error},{status:429,headers});
  reserved=true;
  browser=await puppeteer.launch(env.BROWSER);
  for(const provider of ['yotomp3','ezconv']){
   if(!await gate.attempt(provider)){errors.push(provider+': app daily allowance exhausted');continue;}
   const current=await puppeteer.limits(env.BROWSER);if((current.usedBrowserTimeSeconds||0)>=510){errors.push('Shared free browser budget nearly exhausted');break;}
   const page=await browser.newPage();
   try{
    const mp3=await convert(page,id,provider);
    if(!(mp3.headers.get('content-type')||'').includes('audio/'))throw new Error('Converter did not return audio');
    if(Number(mp3.headers.get('content-length')||0)>35*1024*1024)throw new Error('Audio exceeds 35 MB limit');
    return new Response(mp3.body,{headers:{...headers,'Content-Type':'audio/mpeg','X-Uke-Provider':provider}});
   }catch(e){errors.push(provider+': '+String(e).slice(0,180));}
   finally{await page.close();}
  }
  return Response.json({error:'All available free converters failed or reached their limits. Saved songs remain usable. No result was invented.',providers:errors},{status:503,headers});
 }catch(e){return Response.json({error:'Free conversion unavailable: '+String(e).slice(0,200)},{status:503,headers});}
 finally{if(browser)await browser.close();if(reserved)await gate.finish();}
}};
