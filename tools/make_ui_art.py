"""Original hand-authored pixel icons. All geometry is snapped to a 32px grid."""
from PIL import Image,ImageDraw
from pathlib import Path
names=['hand','hoe','water','seeds','axe','pick','build','wood','stone','turnip','planks','crate','bag','coin','energy','sun','moon','leaf','house','warehouse','workshop','clock','star','book','close','sort','arrow','check','hammer','spark','empty','settings','carrot','carrot_seeds','orders']
atlas=Image.new('RGBA',(256,160))
for i,name in enumerate(names):
 im=Image.new('RGBA',(32,32));d=ImageDraw.Draw(im)
 dark='#273a3b';gold='#e8be73';light='#f6dca1';wood='#a76d47';steel='#91bfc0'
 def rect(box,c,outline=None):d.rectangle(box,fill=c,outline=outline)
 def line(points,c,w=2):d.line(points,fill=c,width=w)
 def poly(points,c):d.polygon(points,fill=c,outline=dark)
 if name=='carrot':
  poly([(8,13),(24,10),(14,29)],'#dd8d4d');line([(10,16),(17,18)],'#f4bb6e');line([(12,22),(16,23)],'#ad6d42');line([(16,12),(14,3)],'#558b51',3);line([(17,11),(23,4)],'#82a75b',3);line([(15,11),(8,5)],'#6f9b58',3)
 elif name=='carrot_seeds':
  poly([(7,5),(24,5),(25,27),(6,27)],'#c89b64');rect((8,10,23,23),'#f1d99d');rect((7,6,24,9),'#8c6947');poly([(11,15),(20,13),(14,22)],'#df9454');line([(16,14),(14,10)],'#668e4e')
 elif name=='orders':
  rect((4,3,28,28),'#926b47',dark);rect((7,6,25,25),'#d0ac74');rect((9,7,23,23),'#efe0b5');rect((14,6,17,8),'#b87154');line([(11,12),(20,12)],'#9f9675');line([(11,16),(20,16)],'#9f9675');line([(11,20),(17,20)],'#9f9675')
 elif name in ['hoe','axe','pick','hammer']:
  line([(9,27),(23,6)],dark,5);line([(10,26),(23,7)],wood,3);line([(11,25),(21,9)],'#d9a969',1)
  if name=='axe':poly([(18,5),(24,6),(29,13),(23,18),(19,12)],steel);line([(24,8),(27,13),(24,16)],'#e2ebda',2)
  elif name=='pick':poly([(11,7),(19,3),(25,5),(29,12),(24,9),(18,7)],steel)
  elif name=='hoe':poly([(19,5),(26,9),(25,17),(20,17),(22,10),(17,8)],steel)
  else:poly([(15,4),(20,2),(29,9),(25,15)],'#adc3bc')
 elif name=='water':
  poly([(6,12),(22,12),(24,25),(5,25)],'#6c9fa9');rect((7,14,20,22),'#91bcc0');poly([(22,17),(27,13),(30,15),(25,24),(22,23)],steel);line([(8,12),(8,5),(19,5),(22,12)],dark,3);line([(9,11),(9,6),(18,6),(21,12)],gold,2);rect((6,24,23,26),'#46747e');rect((9,15,11,20),'#c9dfd1')
 elif name=='seeds':
  poly([(7,5),(24,5),(25,27),(6,27)],'#c89b64');rect((8,10,23,23),'#f1d99d');rect((7,6,24,9),'#8c6947');line([(16,22),(16,15)],'#54704b');d.ellipse((10,13,16,17),fill='#83a85f');d.ellipse((16,10,22,15),fill='#638c4c')
 elif name=='wood':
  for x,y in [(6,6),(4,14),(14,12)]:
   rect((x,y,x+11,y+14),wood,dark);line([(x+4,y+2),(x+4,y+12)],'#d2a06a');d.ellipse((x,y,x+11,y+5),fill='#dfba80',outline=dark);d.ellipse((x+3,y+1,x+8,y+4),outline='#a9754d')
 elif name=='stone':
  poly([(3,23),(5,12),(13,5),(24,7),(29,18),(25,26),(10,27)],'#788c95');poly([(5,12),(13,5),(24,7),(18,15),(8,17)],'#bac8c3');line([(18,15),(22,23)],'#526e78',2)
 elif name=='turnip':
  line([(15,13),(14,4)],'#46734d',3);d.ellipse((7,3,15,9),fill='#86b46a',outline=dark);d.ellipse((15,1,25,8),fill='#6d9c59',outline=dark);d.ellipse((7,11,25,27),fill='#f0d5c1',outline=dark);d.ellipse((8,11,24,18),fill='#d7a6a0');line([(16,27),(14,30)],'#dfc39b');rect((10,18,12,22),'#fff0d4')
 elif name=='planks':
  for y in [6,13,20]:poly([(3,y+2),(23,y),(29,y+6),(9,y+9)],'#b98a55');line([(10,y+5),(22,y+3)],'#e2b673');line([(9,y+8),(28,y+5)],'#6b5239')
 elif name=='crate':
  poly([(4,11),(15,6),(28,11),(28,26),(15,30),(4,25)],'#bb8a51');line([(15,15),(15,29)],dark);poly([(4,11),(15,6),(28,11),(15,16)],'#ddbb7a');line([(6,15),(13,18)],'#785a3c');line([(18,18),(26,15)],'#785a3c');line([(18,24),(26,21)],'#785a3c');d.ellipse((9,4,15,10),fill='#b6c577',outline=dark);d.ellipse((16,3,23,10),fill='#e2bb9c',outline=dark)
 elif name=='hand':
  poly([(8,16),(7,10),(10,8),(12,14),(11,5),(14,4),(17,13),(17,5),(20,6),(21,14),(23,11),(26,12),(25,24),(19,28),(11,26),(5,20),(5,16)],'#dcb28a');line([(12,18),(19,21),(22,18)],'#b27e62')
 elif name in ['build','house','warehouse','workshop']:
  rect((6,14,26,28),'#d8bc87',dark);poly([(2,15),(16,3),(30,15)],'#7c9393' if name in ['workshop','warehouse'] else '#b36c55');rect((13,19,19,28),'#72533c');rect((8,17,11,22),'#a3c6bd',dark);rect((22,17,25,22),'#a3c6bd',dark)
  if name=='workshop':rect((23,4,27,13),'#9a8f7b',dark)
  if name=='build':line([(21,6),(29,6)],gold,3);line([(25,2),(25,10)],gold,3)
 elif name=='bag':
  line([(11,9),(11,4),(21,4),(21,9)],dark,3);rect((6,8,26,29),'#ad7c50',dark);rect((7,10,25,17),'#d8b375');rect((10,20,22,27),'#be9562',dark);rect((14,15,18,20),gold,dark);line([(8,11),(23,11)],'#f0ce89')
 elif name=='coin':
  d.ellipse((5,3,27,28),fill='#b17c3f',outline=dark);d.ellipse((5,3,26,25),fill='#e6b85f',outline=dark);d.ellipse((9,6,23,22),outline='#a87a3e',width=2);line([(16,8),(12,13),(19,15),(15,20)],light,2);rect((8,7,10,10),light)
 elif name=='energy':
  poly([(15,29),(3,16),(3,9),(8,5),(14,5),(17,9),(20,5),(26,5),(30,10),(29,17)],'#bd715e');line([(6,10),(9,8),(12,8)],'#e7b59a',2)
 elif name in ['sun','moon']:
  if name=='sun':
   for a,b in [((16,1),(16,5)),((16,27),(16,31)),((1,16),(5,16)),((27,16),(31,16)),((5,5),(8,8)),((24,24),(27,27)),((24,8),(27,5)),((5,27),(8,24))]:line([a,b],gold,2)
   d.ellipse((8,8,24,24),fill=gold,outline=dark);d.ellipse((10,10,21,21),fill=light)
  else:d.ellipse((5,3,27,28),fill='#ecd99f',outline=dark);d.ellipse((13,1,30,20),fill=(0,0,0,0))
 elif name=='leaf':poly([(5,27),(7,12),(16,5),(29,3),(25,18),(16,25)],'#86ac69');line([(5,27),(22,10)],'#d1d28a')
 elif name=='clock':d.ellipse((4,4,28,28),fill='#e1cda2',outline=dark,width=2);line([(16,9),(16,16),(22,19)],'#5a7061',2)
 elif name in ['star','spark']:poly([(16,2),(20,12),(30,14),(22,20),(24,30),(16,24),(6,29),(8,19),(1,13),(12,11)],gold)
 elif name=='book':poly([(4,5),(16,8),(28,5),(28,26),(16,29),(4,26)],'#c3a36e');rect((6,7,14,24),'#eee0b7');rect((18,8,26,24),'#e1cea0');line([(16,8),(16,28)],dark)
 elif name=='close':line([(9,9),(23,23)],gold,3);line([(23,9),(9,23)],gold,3)
 elif name=='sort':
  for y,w in [(8,20),(15,14),(22,8)]:rect((5,y,5+w,y+3),gold)
 elif name=='arrow':poly([(4,13),(19,13),(19,7),(29,16),(19,26),(19,20),(4,20)],gold)
 elif name=='check':line([(6,16),(13,24),(27,7)],'#b9cd8a',4)
 elif name=='settings':d.ellipse((5,5,27,27),fill='#93aaa1',outline=dark);d.ellipse((11,11,21,21),fill='#263f3d',outline=gold)
 atlas.alpha_composite(im,((i%8)*32,(i//8)*32))
root=Path(__file__).resolve().parents[1]
atlas.save(root/'art'/'icons.png')

# Distinct work sounds; deterministic noise, no third-party samples.
import wave, math, random, struct
r = random.Random(42)
for name, freq, duration in [('chop',145,.18),('stone',920,.22),('soil',110,.15),('pour',310,.32)]:
 samples=[]; filtered=0
 for i in range(int(22050*duration)):
  t=i/22050; envelope=(1-t/duration)**2
  filtered=filtered*.7+(r.random()*2-1)*.3
  tone=math.sin(2*math.pi*freq*t)*.35+filtered*(.9 if name!='stone' else .18)
  if name=='stone': tone+=math.sin(2*math.pi*1570*t)*.2
  samples.append(struct.pack('<h',int(tone*5200*envelope)))
 with wave.open(str(root/'art'/(name+'.wav')),'w') as f:
  f.setnchannels(1); f.setsampwidth(2); f.setframerate(22050); f.writeframes(b''.join(samples))
