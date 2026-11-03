from PIL import Image, ImageDraw
from pathlib import Path
import random, math, wave, struct
ROOT=Path(__file__).resolve().parents[1]; A=ROOT/'art'; A.mkdir(exist_ok=True)
r=random.Random(38); T=24; W=48; H=36
im=Image.new('RGB',(W*T,H*T)); d=ImageDraw.Draw(im)
water=[]
for y in range(H):
 for x in range(W):
  px,py=x*T,y*T
  pond=((x-36)/6)**2+((y-24)/4.5)**2<1
  path=(y in (12,13) and 5<x<34) or (x in (22,23) and 12<y<32)
  color=r.choice(['#719454','#759958','#7b9e59','#789b56'])
  if path: color=r.choice(['#c2ae7d','#c6b181','#bcaa7b'])
  if pond: color=r.choice(['#548e9b','#508a99','#598f9d']);water.append([x,y])
  d.rectangle((px,py,px+23,py+23),fill=color)
  for i in range(7):
   a,b=px+r.randrange(23),py+r.randrange(23)
   if pond: d.line((a,b,a+4,b),fill='#78b0b0')
   elif path: d.point((a,b),fill='#a9966e')
   else:
    d.line((a,b,a,b-2),fill=r.choice(['#87a961','#648448','#97b66a']))
  if not pond and not path and r.random()<.13:
   a,b=px+r.randrange(4,20),py+r.randrange(4,20)
   d.line((a,b,a,b+3),fill='#456c42');d.rectangle((a-1,b-1,a+1,b+1),fill=r.choice(['#e9cf8b','#dcb4a1','#cdd8ae']))
im.save(A/'ground.png')
# Trees: layered clusters with a consistent north-west light source.
im=Image.new('RGBA',(64,80));d=ImageDraw.Draw(im)
d.ellipse((8,65,58,77),fill=(28,49,42,75));d.rectangle((28,39,35,70),fill='#66513e');d.rectangle((29,41,31,69),fill='#917052')
for box,c in [((10,25,57,64),'#365e48'),((4,18,52,57),'#477650'),((14,6,56,49),'#4f8053'),((7,17,43,47),'#608e59'),((17,4,43,33),'#79a263')]:
 d.ellipse(box,fill=c)
for i in range(55):
 x,y=r.randrange(10,50),r.randrange(12,51)
 if im.getpixel((x,y))[3]: d.rectangle((x,y,x+2,y+1),fill=r.choice(['#81a968','#6c985c','#54814f']))
im.save(A/'tree.png')
im=Image.new('RGBA',(32,28));d=ImageDraw.Draw(im);d.ellipse((1,18,30,27),fill=(25,40,42,70));d.polygon([(3,20),(5,9),(12,3),(24,5),(29,14),(26,23),(9,24)],fill='#7a8790');d.polygon([(5,9),(12,3),(24,5),(19,12),(8,14)],fill='#b6b7ad');d.line((19,12,24,20,26,21),fill='#596878',width=2);im.save(A/'rock.png')
# Character, four directions and four walking frames, original pixel sprite.
im=Image.new('RGBA',(96,128)); d=ImageDraw.Draw(im)
for direction in range(4):
 for f in range(4):
  ox=f*24;oy=direction*32; bob=1 if f in (1,3) else 0
  def rect(b,c):d.rectangle((b[0]+ox,b[1]+oy+bob,b[2]+ox,b[3]+oy+bob),fill=c)
  d.ellipse((ox+5,oy+27,ox+20,oy+31),fill=(27,43,42,70))
  step=[0,1,0,-1][f]
  rect((8,23+step,11,29+step),'#443e40');rect((14,23-step,17,29-step),'#443e40')
  rect((7,15,18,24),'#476c79');rect((10,16,15,24),'#6b9199');rect((6,17,8,22),'#dcab80');rect((18,17,20,22),'#dcab80')
  rect((8,7,17,15),'#deb48b');rect((7,6,18,9),'#79543e')
  if direction==1:rect((8,9,17,14),'#79543e')
  else:
   eye=9 if direction==2 else 16 if direction==3 else 10
   rect((eye,11,eye,12),'#303b3e')
   if direction==0:rect((15,11,15,12),'#303b3e')
  rect((7,3,18,7),'#d5b474');rect((5,7,20,9),'#e5c78a');rect((8,6,17,7),'#a87c4d')
im.save(A/'farmer.png')
# Building sprites.
for name,w,h,roof in [('house',120,112,'#a65f4e'),('shed',72,72,'#657d80'),('workshop',72,80,'#596e82')]:
 im=Image.new('RGBA',(w,h));d=ImageDraw.Draw(im)
 d.ellipse((2,h-17,w-2,h-1),fill=(23,43,38,70));d.rectangle((9,35,w-10,h-10),fill='#c9ae7d');d.rectangle((12,38,w-13,h-14),fill='#ddc697')
 for y in range(43,h-14,8):d.line((12,y,w-13,y),fill='#bba275')
 d.polygon([(2,42),(w//2,5),(w-3,42),(w-3,48),(2,48)],fill='#493f42');d.polygon([(2,38),(w//2,1),(w-3,38)],fill=roof)
 for y in range(13,38,6):d.line((w//2-(w//2-2)*y/38,y,w//2+(w//2-2)*y/38,y),fill='#c18465' if name=='house' else '#829794')
 d.rectangle((w//2-9,h-39,w//2+9,h-11),fill='#665342');d.rectangle((w//2-6,h-35,w//2+5,h-12),fill='#8d7352');d.rectangle((w//2+3,h-24,w//2+4,h-22),fill='#eac985')
 for x in (18,w-32):
  d.rectangle((x,h-40,x+15,h-24),fill='#756747');d.rectangle((x+2,h-38,x+13,h-26),fill='#9fc4c2');d.line((x+7,h-38,x+7,h-26),fill='#eee0b5');d.line((x+2,h-32,x+13,h-32),fill='#eee0b5')
 if name=='workshop':
  d.rectangle((49,9,57,30),fill='#7c6b61');d.rectangle((47,8,59,12),fill='#b7a18c')
  d.rectangle((4,53,26,65),fill='#876d4c');d.rectangle((2,51,28,54),fill='#d0ad78')
  d.rectangle((5,65,8,75),fill='#67533e');d.rectangle((22,65,25,75),fill='#67533e')
  d.line((8,50,14,41),fill='#b3c3bc',width=3);d.line((14,41,22,46),fill='#b3c3bc',width=3)
  d.rectangle((31,48,45,55),fill='#e0c38c');d.line((34,51,42,51),fill='#756240',width=2)
 im.save(A/(name+'.png'))
# Short, quiet interface tones; no external audio dependencies.
for name,freq in [('pick',660),('plant',440),('build',330),('error',150)]:
 with wave.open(str(A/(name+'.wav')),'w') as f:
  f.setnchannels(1); f.setsampwidth(2); f.setframerate(22050)
  f.writeframes(b''.join(struct.pack('<h',int(3500*math.sin(2*math.pi*freq*i/22050)*max(0,1-i/3500)**2)) for i in range(3500)))
import json
(ROOT/'game'/'water.json').write_text(json.dumps(water))
