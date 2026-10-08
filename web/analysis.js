// Audio is analyzed on this device. No recordings are uploaded by this module.
let essentiaReady = null;
window.analyzeUkeBytes = async function(bytes) {
  if (!essentiaReady) essentiaReady = EssentiaWASM().then(m => new Essentia(m));
  const engine = await essentiaReady;
  const context = new AudioContext({sampleRate:44100});
  try {
    const buffer = await context.decodeAudioData(bytes.slice(0));
    if(buffer.duration < 15) throw new Error('Use at least 15 seconds of music.');
    const offset=buffer.duration>60?15:0, duration=Math.min(60,buffer.duration-offset);
    const offline=new OfflineAudioContext(1,Math.floor(duration*44100),44100);
    const source=offline.createBufferSource();source.buffer=buffer;source.connect(offline.destination);source.start(0,offset,duration);
    const rendered=await offline.startRendering(); const samples=rendered.getChannelData(0), vector=engine.arrayToVector(samples);
    try {
      const result=engine.RhythmExtractor2013(vector,208,'multifeature',40);
      const beats=engine.vectorToArray(result.ticks); const bpm=result.bpm;
      // Derive 8-slot accent profiles from positive amplitude-envelope changes.
      const hop=441, envelope=[];let prior=0;
      for(let i=0;i<samples.length;i+=hop){let energy=0;for(let k=i;k<Math.min(i+hop,samples.length);k++)energy+=samples[k]*samples[k];energy=Math.sqrt(energy/hop);envelope.push(Math.max(0,energy-prior));prior=energy;}
      const accent=t=>{const n=Math.round(t*100);return Math.max(...envelope.slice(Math.max(0,n-3),n+4),0);};
      const profiles=[];for(let i=0;i<beats.length-1;i++){profiles.push(accent(beats[i]));profiles.push(accent((beats[i]+beats[i+1])/2));}
      if(beats.length<12||!Number.isFinite(bpm))throw new Error('Not enough clear beats. Try a section with a steady rhythm.');
      const peak=Math.max(...profiles,1e-10), normalized=profiles.map(n=>n/peak);
      const templates={steady:['D','-','D','-','D','-','D','-'],eighths:['D','U','D','U','D','U','D','U'],island:['D','-','D','U','-','U','D','U'],chuck:['D','-','X','U','-','U','X','U']};
      const scores={};for(const [id,steps]of Object.entries(templates)){let best=-Infinity;for(let phase=0;phase<8;phase++){const score=normalized.reduce((sum,n,i)=>sum+(steps[(i+phase)%8]==='-'?.22-n:n-.22),0)/normalized.length;best=Math.max(best,score);}scores[id]=best;}
      // Accent periodicity is an estimate; mixed arrangements can make meter ambiguous.
      const strengths=Array.from(beats,accent);const periodic=n=>{let best=0;for(let phase=0;phase<n;phase++){const groups=Array.from({length:n},(_,k)=>strengths.filter((_,i)=>(i+phase)%n===k));const means=groups.map(g=>g.reduce((a,b)=>a+b,0)/(g.length||1));best=Math.max(best,(Math.max(...means)-Math.min(...means))/(Math.max(...means)+1e-10));}return best;};
      const p3=periodic(3),p4=periodic(4),meter=p3>p4*1.2?3:4;
      const confidence=Math.max(0,Math.min(1,result.confidence/5.32));
      const sorted=Object.entries(scores).sort((a,b)=>b[1]-a[1]);
      return {bpm:Math.round(bpm*10)/10,confidence,meter,meterUncertain:Math.abs(p3-p4)<.15,best:meter===3?'waltz':sorted[0][0],scores,analyzedSeconds:duration,notice:'Audio-based starting arrangement, not a detected original strum. Multiple patterns can fit. Tempo can be half/double; meter is estimated.'};
    } finally {vector.delete();}
  } finally {await context.close();}
};
window.pickAndAnalyzeUke = () => new Promise((resolve,reject)=>{
 const input=document.createElement('input');input.type='file';input.accept='audio/*,video/mp4';
 input.oncancel=()=>resolve('');input.onchange=async()=>{try{const file=input.files[0];if(!file){resolve('');return;}if(file.size>35*1024*1024)throw new Error('Use a file smaller than 35 MB.');resolve(JSON.stringify(await window.analyzeUkeBytes(await file.arrayBuffer())));}catch(e){reject(e);}};input.click();
});

window.analyzeYouTubeUke = async function(id) {
 const response = await fetch('https://uke-converter-test.iy8cnl.workers.dev/audio?id='+encodeURIComponent(id));
 if(!response.ok){let error;try{error=(await response.json()).error;}catch(_){}throw new Error(error||'Converter unavailable. No analysis was invented.');}
 const type=response.headers.get('content-type')||'';
 if(!type.includes('audio/')) throw new Error('Converter did not return audio.');
 const bytes=await response.arrayBuffer();
 if(bytes.byteLength>35*1024*1024)throw new Error('Audio is over the 35 MB analysis limit.');
 const result=await window.analyzeUkeBytes(bytes);result.source='YouTube link via '+(response.headers.get('X-Uke-Provider')||'converter-site')+' audio';
 return JSON.stringify(result);
};

window.getUkeQuota = async function() {
 try {const r=await fetch('https://uke-converter-test.iy8cnl.workers.dev/quota');if(!r.ok)throw new Error('Quota service unavailable');return JSON.stringify(await r.json());}
 catch(e){return JSON.stringify({error:String(e)});}
};
