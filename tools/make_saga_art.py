"""Original pixel assets for Guardians of the Valley; no external sprites."""
from PIL import Image,ImageDraw
from pathlib import Path
import random,math,wave,struct
A=Path(__file__).resolve().parents[1]/'art';r=random.Random(7716)
# New building footprints are all 3x2 cells, with a shared 32px roof offset.
for name in ['bakery','well','forge']:
 im=Image.new('RGBA',(72,80));d=ImageDraw.Draw(im)
 d.ellipse((1,63,70,79),fill=(22,40,38,70))
 if name=='well':
  d.ellipse((10,46,63,72),fill='#687b79',outline='#344e48',width=2);d.ellipse((13,46,60,62),fill='#b0b6a0',outline='#405e57',width=2);d.ellipse((20,48,54,57),fill='#497d88');d.line((17,54,28,54),fill='#9ec5bf')
  for y in [59,65]:d.line((13,y,61,y),fill='#455e59')
  for x in [22,37,51]:d.line((x,62,x,67),fill='#455e59')
  d.rectangle((12,21,17,53),fill='#876941');d.rectangle((55,21,60,53),fill='#876941');d.line((14,22,58,22),fill='#ba985f',width=4);d.line((36,23,36,49),fill='#e0cca0');d.rectangle((30,42,41,52),fill='#a07f51',outline='#4d533e')
  d.polygon([(5,23),(35,5),(66,23),(64,28),(8,28)],fill='#647f72',outline='#344e48');d.line((11,21,35,8,59,21),fill='#a6b28e',width=2);d.line((44,62,66,62,66,70),fill='#8aafab',width=3)
 else:
  d.rectangle((7,34,65,70),fill='#8d8570' if name=='forge' else '#c7b38a',outline='#43564b',width=2)
  for y in range(42,70,7):d.line((9,y,63,y),fill='#69766c' if name=='forge' else '#ac936c')
  d.polygon([(1,35),(35,8),(71,35),(69,41),(3,41)],fill='#414f4e');d.polygon([(3,34),(35,6),(69,34)],fill='#536b70' if name=='forge' else '#b87c58')
  for y in [17,24,31]:d.line((35-y,y,35+y,y),fill='#759096' if name=='forge' else '#dfac74')
  d.rectangle((50,8,58,27),fill='#818276',outline='#43564b');d.rectangle((48,7,60,11),fill='#b7b39b')
  if name=='bakery':
   d.rectangle((29,48,43,70),fill='#785c40');d.rectangle((13,46,24,58),fill='#8eb9b6',outline='#716849');d.line((18,47,18,57),fill='#e8d9ad');d.rectangle((49,47,60,58),fill='#7b6547');d.ellipse((49,49,59,57),fill='#e3b86b');d.rectangle((8,63,22,70),fill='#dfd4af',outline='#9d966f');d.line((10,66,19,66),fill='#aa9162');d.rectangle((28,40,45,45),fill='#dbc38c');d.line((33,42,41,42),fill='#8e754c')
  else:
   d.rectangle((11,46,31,66),fill='#354942',outline='#a79875');d.ellipse((15,51,28,66),fill='#cf9254');d.ellipse((18,56,25,66),fill='#efd68a');d.polygon([(40,56),(58,56),(56,62),(43,63),(42,69),(37,69),(39,61)],fill='#92aaa5',outline='#334f4a');d.line((47,47,53,53),fill='#c8ba8a',width=3);d.line((49,46,56,50),fill='#a9bdb2',width=3)
 im.save(A/(name+'.png'))
# Fallen gateway: solid footprint is the lower 5x2 cells, matching the engine.
im=Image.new('RGBA',(120,96));d=ImageDraw.Draw(im)
d.ellipse((0,71,119,95),fill=(21,37,35,70))
for x in [7,89]:
 d.rectangle((x,21,x+24,83),fill='#61746d',outline='#2f514b',width=2);d.rectangle((x+3,22,x+9,78),fill='#98a091')
 for y in [33,47,61,75]:d.line((x,y,x+24,y),fill='#405b55');d.line((x+13,y,x+13,y+10),fill='#49625b')
 d.rectangle((x-3,75,x+27,87),fill='#778b77',outline='#3e5c51');d.rectangle((x-2,19,x+27,26),fill='#9aa28c',outline='#3e5c51')
d.polygon([(15,19),(34,8),(67,5),(99,18),(104,26),(14,28)],fill='#72877a',outline='#34534b');d.line((24,18,38,12,66,10,91,20),fill='#a4b09b',width=3)
d.polygon([(49,12),(61,8),(70,14),(60,25)],fill='#4a7d70',outline='#a3cbb1');d.line((55,14,60,20,65,14),fill='#c0ddba',width=2)
d.polygon([(30,73),(41,63),(49,70),(58,83),(45,89),(29,84)],fill='#8c9783',outline='#476358')
for x,y in [(13,26),(92,49),(24,67),(72,22)]:
 d.ellipse((x,y,x+12,y+6),fill='#7c9b62');d.line((x+2,y,x+7,y),fill='#a9ba7c')
im.save(A/'ruin.png')
# Distinct silhouettes: hopping moss creature, stone beetle, ancient rooted guardian.
im=Image.new('RGBA',(128,96))
for row in range(3):
 for frame in range(4):
  tile=Image.new('RGBA',(32,32));d=ImageDraw.Draw(tile);bob=[0,1,0,-1][frame]
  d.ellipse((3,24,29,31),fill=(19,35,33,70))
  if row==0:
   for x in [7,21]:d.rectangle((x,24+bob,x+4,28+bob),fill='#3d624b')
   d.polygon([(3,23+bob),(5,12+bob),(10,7+bob),(22,6+bob),(28,14+bob),(29,25+bob),(23,28+bob),(8,28+bob)],fill='#638a52',outline='#2f5445')
   d.polygon([(6,13+bob),(12,8+bob),(21,8+bob),(25,14+bob),(19,13+bob),(12,16+bob)],fill='#9ab56d');d.rectangle((9,18+bob,11,20+bob),fill='#e6daa5');d.rectangle((21,17+bob,23,19+bob),fill='#e6daa5');d.line((13,23+bob,19,23+bob),fill='#304c3d')
   d.line((17,9+bob,16,2+bob),fill='#9eb46c',width=2);d.rectangle((14,1+bob,18,4+bob),fill='#d8c08b')
  elif row==1:
   for x,off in [(4,-1),(24,1)]:
    for y in [17,22,26]:d.line((x,y,x+off*3,y+3+(frame%2)),fill='#6c7e70',width=2)
   d.polygon([(5,24),(6,11+bob),(14,5+bob),(23,8+bob),(28,19),(24,28),(10,28)],fill='#788b86',outline='#334e49');d.polygon([(7,12+bob),(14,5+bob),(23,8+bob),(18,16)],fill='#b0b8a4');d.polygon([(18,16),(23,8+bob),(27,19),(24,26)],fill='#586c6d')
   d.polygon([(12,12+bob),(16,3+bob),(20,11+bob),(17,17)],fill='#99bdb4',outline='#456b66');d.rectangle((9,21,11,23),fill='#e7cb8d');d.rectangle((21,21,23,23),fill='#e7cb8d')
  else:
   for x in [6,21]:d.polygon([(x,20),(x+5,21),(x+6,29),(x-3,30)],fill='#6e684b',outline='#354d3e')
   d.polygon([(5,24),(5,10+bob),(12,5+bob),(22,5+bob),(28,13+bob),(27,26),(18,29)],fill='#79784f',outline='#2d4f3e');d.line((10,12,8,24),fill='#a99b66',width=2);d.line((24,14,25,24),fill='#555b3f',width=2)
   d.polygon([(4,12),(1,5),(5,6),(6,1),(10,8),(16,4),(23,6),(27,1),(27,8),(31,6),(28,14)],fill='#658b57',outline='#365640');d.line((6,10,13,6,22,9),fill='#9ab270',width=2)
   for x in [10,21]:d.rectangle((x,15+bob,x+2,18+bob),fill='#b6d6a0')
   d.polygon([(13,21),(17,17),(20,22),(17,26)],fill='#a3c59c',outline='#4d7861');d.line((2,18,5,22),fill='#9e9263',width=3);d.line((28,18,30,25),fill='#9e9263',width=3)
  im.alpha_composite(tile,(frame*32,row*32))
im.save(A/'mobs.png')
# Extend the crop sheet; two mature heads per plot are represented by two grain bundles.
old=Image.open(A/'crops.png').convert('RGBA');im=Image.new('RGBA',(120,72));im.alpha_composite(old)
d=ImageDraw.Draw(im)
for stage in range(5):
 for ox,oy in [(7,20),(17,18)]:
  x=stage*24+ox;y=48+oy;h=4+min(stage,2)*4
  d.line((x,y,x,y-h),fill='#929253' if stage>=2 else '#698f4e',width=2)
  d.line((x,y-3,x-4,y-7),fill='#a7aa61' if stage>=2 else '#8fac5c');d.line((x,y-4,x+4,y-9),fill='#b9b472' if stage>=2 else '#8fac5c')
  if stage>=2:
   for dx,dy in [(-2,-h),(1,-h-2),(-2,-h-4)]:d.rectangle((x+dx,y+dy,x+dx+2,y+dy+3),fill='#e0c27c');d.point((x+dx,y+dy),fill='#f0d99c')
im.save(A/'crops.png')
# New item and construction icons retain every older atlas coordinate.
old=Image.open(A/'icons.png').convert('RGBA');im=Image.new('RGBA',(256,224));im.alpha_composite(old)
for i,name in enumerate(['sword','sling','wheat','wheat_seeds','iron','ironbar','essence','bread','well','bakery','forge','health','shield'],start=43):
 tile=Image.new('RGBA',(32,32));d=ImageDraw.Draw(tile);dark='#304d45'
 if name=='sword':
  d.polygon([(7,25),(21,6),(27,2),(26,9),(11,27)],fill='#a5c4ba',outline=dark);d.line((11,23,24,6),fill='#e2e7cb');d.line((6,20,15,28),fill='#d7b06a',width=3);d.line((5,29,10,24),fill='#8d6a44',width=4)
 elif name=='sling':
  d.line((7,5,15,26,25,8),fill='#c4ad78',width=2);d.ellipse((11,22,19,29),fill='#8d6c49',outline=dark);d.ellipse((20,4,28,12),fill='#aebaa4',outline=dark)
 elif name in ['wheat','wheat_seeds']:
  if name=='wheat_seeds':d.rectangle((6,4,26,28),fill='#caab72',outline=dark);d.rectangle((8,10,24,25),fill='#e7d6a4')
  for x,y in [(12,26),(20,25)]:
   d.line((x,y,x-2,y-17),fill='#9ba063',width=2)
   for dy in [9,14,19]:d.ellipse((x-5,y-dy,x-1,y-dy+5),fill='#e1bd70',outline='#aa8c51');d.ellipse((x-1,y-dy-2,x+3,y-dy+3),fill='#e9d18a',outline='#aa8c51')
 elif name=='iron':
  d.polygon([(3,24),(5,12),(14,4),(25,7),(29,22),(22,28)],fill='#657d7e',outline=dark);d.polygon([(5,12),(14,4),(25,7),(17,16)],fill='#a0b8b3');d.line((8,20,12,15,16,22),fill='#d8d8bb',width=3);d.line((20,11,23,20),fill='#cad3ba',width=2)
 elif name=='ironbar':d.polygon([(4,15),(11,6),(24,6),(29,19),(25,26),(6,26)],fill='#718d8c',outline=dark);d.polygon([(4,15),(11,6),(24,6),(22,16)],fill='#c0d1c1',outline=dark);d.line((8,19,22,19,26,11),fill='#97b0a8',width=2)
 elif name=='essence':d.polygon([(16,2),(25,12),(22,26),(15,30),(6,22),(8,10)],fill='#78a987',outline=dark);d.polygon([(16,4),(18,16),(8,21),(10,11)],fill='#c7ddb0');d.line((18,16,21,25,15,28),fill='#a5cc9f',width=2)
 elif name=='bread':d.ellipse((3,8,29,28),fill='#ac7c48',outline=dark);d.ellipse((4,7,28,24),fill='#d6aa64',outline=dark);d.line((8,14,12,10),fill='#efcf88',width=3);d.line((14,16,18,11),fill='#efcf88',width=3);d.line((20,17,23,13),fill='#efcf88',width=3)
 elif name in ['bakery','forge']:
  d.rectangle((6,14,26,28),fill='#bca77c' if name=='bakery' else '#7d8c7e',outline=dark);d.polygon([(2,15),(16,3),(30,15)],fill='#b17b54' if name=='bakery' else '#5c7775',outline=dark);d.rectangle((22,3,26,11),fill='#9aa28b');d.rectangle((12,20,21,28),fill='#5c674e');d.ellipse((14,22,20,28),fill='#e1b969' if name=='bakery' else '#dd9b55')
 elif name=='well':d.ellipse((5,18,27,29),fill='#8ca297',outline=dark);d.ellipse((7,17,25,24),fill='#b9c6ad',outline=dark);d.ellipse((10,19,22,23),fill='#6da4a7');d.line((7,9,7,22),fill='#a17f52',width=3);d.line((25,9,25,22),fill='#a17f52',width=3);d.polygon([(3,11),(16,2),(29,11)],fill='#819c83',outline=dark);d.line((16,11,16,21),fill='#e2d2a5')
 elif name=='health':d.polygon([(16,28),(3,16),(4,7),(10,4),(16,9),(22,4),(28,7),(29,16)],fill='#bd7c66',outline=dark);d.line((16,11,16,22),fill='#efd7b2',width=3);d.line((11,16,21,16),fill='#efd7b2',width=3)
 else:d.polygon([(4,5),(16,2),(28,5),(26,21),(16,30),(6,21)],fill='#698f79',outline=dark);d.polygon([(8,8),(16,6),(24,8),(22,19),(16,25),(10,19)],fill='#adc39a',outline='#d6c48b');d.line((16,8,16,23),fill='#577b65',width=2)
 im.alpha_composite(tile,((i%8)*32,(i//8)*32))
im.save(A/'icons.png')
Image.open(A/'ground.png').resize((480,320),Image.Resampling.BOX).save(A/'map.png')
for name,duration,freq in [('swing',.22,440),('hurt',.2,165)]:
 samples=[]
 for i in range(int(22050*duration)):
  t=i/22050;e=(1-t/duration)**2
  val=(math.sin(math.tau*freq*t*(1-t/duration))*.35+(r.random()*2-1)*.3)*e
  samples.append(struct.pack('<h',int(val*5000)))
 with wave.open(str(A/(name+'.wav')),'w') as f:f.setnchannels(1);f.setsampwidth(2);f.setframerate(22050);f.writeframes(b''.join(samples))
