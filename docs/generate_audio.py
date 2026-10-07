"""Generate original practice instrumentals with standard Python only."""
import math,wave,struct,json,pathlib
ROOT=pathlib.Path(__file__).parent; SR=16000
patterns={'steady':'D-D-D-D-','eighths':'DUDUDUDU','island':'D-DU-UDU','chuck':'D-XU-UXU','waltz':'D-D-D-'}
lessons=[('morning',88,4,'steady'),('sunshine',104,4,'island'),('lantern',90,3,'waltz'),('spark',112,4,'eighths'),('backbeat',96,4,'chuck')]
chords=[[261.63,329.63,392,440],[349.23,440,523.25,698.46],[392,493.88,587.33,698.46],[220,261.63,329.63,440]]
index={}; (ROOT/'clips').mkdir(exist_ok=True)
def note(out,t,f,dur,vol):
 start=int(t*SR)
 for j in range(min(int(dur*SR),len(out)-start)):
  x=j/SR; env=min(1,x/.006)*math.exp(-x*8)
  out[start+j]+=vol*env*(math.sin(2*math.pi*f*x)+.25*math.sin(4*math.pi*f*x))
for id,bpm,meter,best in lessons:
 step=60/bpm/2; bars=4; n=int((bars*meter*2*step+.8)*SR)
 for mode in ['song','guide']+list(patterns):
  out=[0.0]*n
  for k in range(bars*meter*2):
   t=.1+k*step; bar=k//(meter*2); c=chords[bar%4]
   if k%2==0:note(out,t,c[0]/2,.3,.22 if k%(meter*2)==0 else .12)
   active=k%2==0 if best in ['steady','waltz'] else (k%8 in [0,3,5,6,7] if best in ['island','chuck'] else True)
   if active:note(out,t,[523.25,659.25,783.99,880][(k+bar)%4],.25,.15)
   if mode=='guide' and k%2==0:note(out,t,1400 if k%(meter*2)==0 else 1000,.06,.12)
   if mode in patterns:
    s=patterns[mode][k%len(patterns[mode])]
    if s=='X':
     for j in range(int(.06*SR)):
      at=int(t*SR)+j
      if at<len(out):out[at]+=.18*math.exp(-j/(SR*.008))*math.sin(j*j*.23)
    elif s!='-':
     for j,f in enumerate(c if s=='D' else c[::-1]):note(out,t+j*.009,f,.4,.09)
  file=f'clips/{id}-{mode}.wav'; index[f'{id}-{mode}']=file
  with wave.open(str(ROOT/file),'wb') as w:
   w.setparams((1,2,SR,0,'NONE','not compressed'));w.writeframes(struct.pack('<'+'h'*len(out),*[int(max(-1,min(1,v)) * 30000) for v in out]))
(ROOT/'audio.json').write_text(json.dumps(index))
