"""Original pixel art for the expanded valley: natural silhouettes and restrained palettes."""
from PIL import Image,ImageDraw
from pathlib import Path
import random, math
A=Path(__file__).resolve().parents[1]/'art';r=random.Random(5317)
# More expressive four-direction character. Feet remain at the same origin as v0.4.
def person(row,frame,role=-1):
 im=Image.new('RGBA',(24,32));d=ImageDraw.Draw(im)
 outline='#314541';skin='#ddb58d';skinshadow='#b9886b';shirt=['#567b83','#739061','#607e94','#a47d60'][role+1];darkshirt=['#395d69','#4b6b4f','#405c79','#70543f'][role+1]
 step=[0,2,0,-2][frame];bob=1 if frame in (1,3) else 0
 def box(coords,c):d.rectangle((coords[0],coords[1]+bob,coords[2],coords[3]+bob),fill=c)
 d.ellipse((5,28,20,31),fill=(25,43,40,65))
 # Alternating legs, boot toes and visible overall straps.
 side=row in (2,3)
 for x,sy in [(8,step),(14,-step)]:
  box((x,22,x+3,27+sy//2),outline);box((x,22,x+2,25+sy//2),'#516677');box((x-1,27+sy//2,x+3,29+sy//2),'#584c40');box((x,27+sy//2,x+2,27+sy//2),'#8c7658')
 box((7,15,18,23),outline);box((8,15,17,22),shirt);box((8,20,17,23),darkshirt)
 if row!=1:
  box((9,15,10,21),'#c5b48b');box((15,15,16,21),'#c5b48b');box((9,21,16,24),darkshirt);box((11,20,14,22),shirt)
 else:box((10,16,15,22),darkshirt)
 for x,dy in [(5,-step//2),(18,step//2)]:
  box((x,16+dy,x+2,19+dy),shirt);box((x,20+dy,x+2,22+dy),skinshadow);box((x,20+dy,x+1,21+dy),skin)
 box((8,7,17,15),skinshadow);box((9,8,17,14),skin);box((8,7,17,9),'#6b5140')
 if row==1:box((8,9,17,14),'#76573e');box((9,13,16,15),'#916343')
 elif side:
  if row==2:box((7,10,8,12),skin);box((9,10,9,11),outline);box((16,9,17,14),'#76573e')
  else:box((17,10,18,12),skin);box((16,10,16,11),outline);box((8,9,9,14),'#76573e')
 else:
  box((10,10,10,11),outline);box((15,10,15,11),outline);box((12,13,14,13),skinshadow)
 # Hat band and asymmetrical brim, with a tiny green ribbon for the farmer.
 hat=['#c6a36c','#91a36a','#7f99a2','#a47c59'][role+1];hatlight=['#ebcd8b','#b1c284','#a9bdba','#c5a27a'][role+1]
 box((8,3,17,6),outline);box((9,3,16,6),hat);box((9,3,14,4),hatlight);box((7,6,18,7),hat);box((6,7,19,8),outline);box((6,7,18,7),hatlight);box((9,5,17,6),'#9a714c')
 if role==-1:box((17,4,18,5),'#76955c')
 if role==1:box((10,13,16,15),'#b5b5a1')
 if role==2:box((8,19,17,24),'#745b48');box((11,17,15,23),'#b49161')
 return im
im=Image.new('RGBA',(96,128))
for row in range(4):
 for f in range(4):im.alpha_composite(person(row,f),(f*24,row*32))
im.save(A/'farmer.png')
im=Image.new('RGBA',(96,96))
for role in range(3):
 for f in range(4):
  # Slow idle animation: keep feet planted, shift one arm and blink periodically.
  sprite=person(0,0,role);d=ImageDraw.Draw(sprite)
  if f==2:d.line((10,10,11,10),fill='#76573e');d.line((15,10,16,10),fill='#76573e')
  if f==1:d.rectangle((19,19,21,20),fill='#ddb58d')
  im.alpha_composite(sprite,(f*24,role*32))
im.save(A/'npc.png')
im=Image.new('RGBA',(192,64))
for role in range(3):
 tile=Image.new('RGBA',(64,64));d=ImageDraw.Draw(tile)
 d.rounded_rectangle((1,1,62,62),radius=5,fill=['#73845b','#6d8990','#93846b'][role],outline='#c8b484',width=2)
 crop=person(0,0,role).crop((3,2,22,23)).resize((49,54),Image.Resampling.NEAREST)
 tile.alpha_composite(crop,(7,8));im.alpha_composite(tile,(64*role,0))
im.save(A/'portraits.png')
# Tall firs: staggered angular branches, layered light and darker undersides.
im=Image.new('RGBA',(48,80));d=ImageDraw.Draw(im);d.ellipse((3,66,44,77),fill=(22,41,38,65));d.rectangle((21,42,26,72),fill='#74583e');d.line((22,49,22,70),fill='#b18a56',width=2)
for y,w in [(48,22),(36,18),(25,14),(15,10),(7,6)]:
 p=[(24,y-12),(24+w,y+16),(24+w-6,y+15),(24+w-3,y+20),(24,y+17),(24-w+3,y+20),(24-w+6,y+15),(24-w,y+16)]
 d.polygon(p,fill='#31594a',outline='#2a4c41');d.polygon([(24,y-10),(24+w-5,y+12),(24,y+9),(24-w+3,y+15)],fill='#49795a');d.polygon([(24,y-10),(22,y+9),(24-w+3,y+15)],fill='#70925f')
 for j in range(6):
  x=24+r.randrange(-max(2,w-5),max(3,w-5));yy=y+r.randrange(6,14);d.line((x,yy,x+2,yy),fill='#7a9b65' if x<24 else '#567f5b')
im.save(A/'pine.png')
# Berry bushes, ready and picked, same footprint and silhouette.
im=Image.new('RGBA',(48,28))
for state in range(2):
 tile=Image.new('RGBA',(24,28));d=ImageDraw.Draw(tile);d.ellipse((1,20,23,27),fill=(32,51,36,60));d.line((12,16,12,24),fill='#7a5c3c',width=2)
 for box,col in [((1,12,17,23),'#416a45'),((8,9,23,22),'#507c48'),((3,7,17,19),'#6b904e'),((6,6,14,14),'#92ac62')]:d.ellipse(box,fill=col)
 if state==0:
  for x,y in [(5,14),(11,11),(17,14),(10,19),(19,18)]:d.rectangle((x,y,x+2,y+2),fill='#b16d68');d.point((x,y),fill='#e3ab8d')
 im.alpha_composite(tile,(state*24,0))
im.save(A/'bush.png')
# Append icons without changing any existing atlas coordinates.
im=Image.open(A/'icons.png').convert('RGBA');atlas=Image.new('RGBA',(256,192));atlas.alpha_composite(im)
for i,name in enumerate(['rod','berry','fish','ore','ingot','map','rain','person'],start=35):
 tile=Image.new('RGBA',(32,32));d=ImageDraw.Draw(tile);dark='#304b46'
 if name=='rod':
  d.line((6,27,21,5),fill='#9f714b',width=3);d.line((7,25,21,5),fill='#d8b77e');d.line((21,5,27,24),fill='#d7d6b8');d.rectangle((25,22,28,26),fill='#e6c59b');d.rectangle((25,22,28,23),fill='#bb7360')
 elif name=='berry':
  for x,y in [(9,12),(19,10),(16,20)]:d.ellipse((x-5,y-4,x+5,y+5),fill='#b56569',outline=dark);d.rectangle((x-2,y-2,x,y),fill='#e1a398')
  d.polygon([(8,10),(5,4),(13,7),(19,2),(23,7),(17,10)],fill='#759652',outline=dark)
 elif name=='fish':
  d.polygon([(23,15),(30,7),(29,24)],fill='#749e9e',outline=dark);d.ellipse((3,9,25,24),fill='#87b4b5',outline=dark);d.polygon([(10,10),(16,4),(19,11)],fill='#698d97',outline=dark);d.line((7,19,21,19),fill='#d0ddd0',width=2);d.point((7,14),fill=dark)
 elif name=='ore':
  d.polygon([(3,24),(6,11),(15,5),(25,9),(29,22),(22,27)],fill='#6b8589',outline=dark)
  for x,y in [(10,16),(18,12),(22,22)]:d.polygon([(x,y-4),(x+4,y),(x+1,y+3),(x-3,y)],fill='#c78f59',outline='#956440');d.point((x,y-1),fill='#e2b57e')
 elif name=='ingot':d.polygon([(4,14),(10,6),(24,6),(29,18),(25,25),(7,25)],fill='#af774f',outline=dark);d.polygon([(4,14),(10,6),(24,6),(22,15)],fill='#e0b47d',outline=dark);d.line((7,18,22,18,25,11),fill='#ce9664',width=2)
 elif name=='map':
  d.polygon([(3,5),(11,8),(20,4),(29,7),(29,27),(20,24),(11,28),(3,25)],fill='#e4d2a2',outline=dark);d.line((11,8,11,28),fill='#b9a273');d.line((20,4,20,24),fill='#b9a273');d.line((5,18,12,15,17,21,25,11),fill='#699591',width=2);d.ellipse((22,8,26,12),fill='#a96f50')
 elif name=='rain':
  d.ellipse((5,7,20,19),fill='#98b2b0',outline=dark);d.ellipse((13,3,27,20),fill='#b0c5ba',outline=dark);d.rectangle((8,12,24,19),fill='#a5c0b6')
  for x,y in [(8,23),(17,25),(25,23)]:d.line((x,y,x-2,y+4),fill='#84bec3',width=2)
 else:
  d.ellipse((10,3,22,16),fill='#dcaf83',outline=dark);d.polygon([(6,29),(7,19),(12,15),(20,15),(25,20),(26,29)],fill='#7f9b69',outline=dark);d.rectangle((8,5,24,8),fill='#d4b278');d.rectangle((12,2,21,6),fill='#be9d65')
 atlas.alpha_composite(tile,((i%8)*32,(i//8)*32))
atlas.save(A/'icons.png')
# Minimap uses the same ground raster as the playable world.
Image.open(A/'ground.png').resize((480,336),Image.Resampling.BOX).save(A/'map.png')

# Seamless quiet outdoor ambience: soft wind and sparse original synthesized birds.
import wave,struct
rate=22050;duration=16
samples=[]
for i in range(rate*duration):
 t=i/rate
 wind=sum(math.sin(math.tau*f*t/duration+f*.37)/f for f in [17,29,43,71,113])*3500
 bird=0
 for start in [1.2,5.4,9.1,12.8]:
  dt=t-start
  if 0<dt<.46:
   pulse=math.sin(math.pi*dt/.46)**2
   bird+=math.sin(math.tau*(2100*dt+500*dt*dt+30*math.sin(dt*21)))*pulse*2400
 samples.append(struct.pack('<h',int(wind+bird)))
with wave.open(str(A/'nature.wav'),'w') as f:
 f.setnchannels(1);f.setsampwidth(2);f.setframerate(rate);f.writeframes(b''.join(samples))
