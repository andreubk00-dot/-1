"""Original pixel scenery and crops. Collision-water footprint stays unchanged."""
from PIL import Image,ImageDraw,ImageFilter,ImageChops
from pathlib import Path
import random,math,json
root=Path(__file__).resolve().parents[1];a=root/'art';r=random.Random(4096)
T=24;W,H=48*T,36*T
water={tuple(p) for p in json.loads((root/'game/water.json').read_text())}
def path(x,y):return (y in (12,13) and 6<=x<=33)or(x in (22,23) and 14<=y<=31)or(9<=x<=11 and 10<=y<=11)or(27<=x<=29 and y==11)
im=Image.new('RGB',(W,H),'#799655');d=ImageDraw.Draw(im)
# Low-frequency patches break up the tile grid; small marks are intentionally sparse.
colors=['#789552','#7b9856','#809d59','#759351','#829e59']
for y in range(0,H,2):
 for x in range(0,W,2):
  wave=math.sin(x/89)+math.cos(y/73)+math.sin((x+y)/137)
  k=max(0,min(4,int(2+wave*.7)))
  if r.random()<.08:k=max(0,min(4,k+r.choice([-1,1])))
  d.rectangle((x,y,x+1,y+1),fill=colors[k])
pm=Image.new('L',(W,H));pd=ImageDraw.Draw(pm)
wm=Image.new('L',(W,H));wd=ImageDraw.Draw(wm)
for y in range(36):
 for x in range(48):
  if path(x,y):pd.rectangle((x*T,y*T,x*T+23,y*T+23),fill=255)
  if (x,y) in water:wd.rectangle((x*T,y*T,x*T+23,y*T+23),fill=255)
im.paste('#718d4d',mask=pm.filter(ImageFilter.MaxFilter(7)))
im.paste('#a49065',mask=pm.filter(ImageFilter.MaxFilter(3)))
im.paste('#c5b17c',mask=pm)
# Single-pixel worn stones, soft wheel ruts and grass tufts.
d=ImageDraw.Draw(im)
for i in range(13500):
 x,y=r.randrange(3,W-3),r.randrange(3,H-3)
 if pm.getpixel((x,y)):
  if r.random()<.4:d.line((x,y,x+r.randrange(1,3),y),fill=r.choice(['#b6a26e','#d0bc89','#bdab76']))
 elif (x//T,y//T) not in water:
  if r.random()<.3:
   c=r.choice(['#9bb66c','#6b874b','#8ba85f']);d.line((x,y,x,y-2),fill=c);d.point((x+1,y-1),fill=c)
# Shore mask follows collision tiles exactly; sand outside it remains walkable.
im.paste('#637e4b',mask=wm.filter(ImageFilter.MaxFilter(13)))
im.paste('#b5ac75',mask=wm.filter(ImageFilter.MaxFilter(7)))
im.paste('#d2c28b',mask=wm.filter(ImageFilter.MaxFilter(3)))
im.paste('#528b95',mask=wm)
inner=wm.filter(ImageFilter.MinFilter(9));im.paste('#4c8290',mask=inner)
d=ImageDraw.Draw(im)
for i in range(420):
 x,y=r.randrange(29*T,43*T),r.randrange(19*T,30*T)
 if wm.getpixel((x,y)):
  d.line((x,y,x+r.randrange(2,7),y),fill=r.choice(['#679fa7','#70a5aa','#598e98']))
# Flowers cluster in small patches instead of covering every tile equally.
for cx,cy in [(13,18),(18,24),(29,17),(7,19),(31,30),(17,8)]:
 for i in range(15):
  x=cx*T+r.randrange(-25,26);y=cy*T+r.randrange(-20,21)
  if not(0<x<W and 0<y<H)or pm.getpixel((x,y))or wm.getpixel((x,y)):continue
  d.line((x,y,x,y+3),fill='#577a45');d.rectangle((x-1,y-1,x+1,y+1),fill=r.choice(['#e7cb89','#e6d7ac','#bba7bb']));d.point((x,y),fill='#e9b969')
# Reeds on dry banks are decorative plants, not obstacles.
for i in range(26):
 x=r.randrange(29*T,43*T);y=r.randrange(19*T,30*T)
 if not wm.getpixel((x,y)) and wm.filter(ImageFilter.MaxFilter(15)).getpixel((x,y)):
  for off in [-2,0,2]:d.line((x,y,x+off,y-r.randrange(5,10)),fill='#6d8654')
  d.line((x,y-8,x,y-12),fill='#a28e60',width=2)
# Visible boundary fences lie entirely in the non-walkable outer cell ring.
for x in range(12,W,24):
 for y in [10,H-12]:
  d.rectangle((x-12,y+2,x+12,y+4),fill='#92724d');d.rectangle((x-2,y-3,x+1,y+9),fill='#b89965');d.line((x-2,y-3,x+1,y-3),fill='#dec18a')
for y in range(24,H-20,24):
 for x in [10,W-12]:
  d.rectangle((x,y-12,x+2,y+12),fill='#92724d');d.rectangle((x-3,y-2,x+5,y+1),fill='#bb9b68')
im.save(a/'ground.png')
# Irregular leaf clusters, bark and a consistent upper-left highlight.
im=Image.new('RGBA',(64,80));d=ImageDraw.Draw(im)
d.ellipse((6,65,60,77),fill=(30,47,35,65))
d.polygon([(26,71),(29,39),(36,39),(37,71),(33,69)],fill='#654c38');d.line((30,67,31,39),fill='#ae8053',width=2);d.line((34,61,34,40),fill='#7f5c3c',width=2)
d.line((31,49,18,34),fill='#74563d',width=4);d.line((34,44,47,31),fill='#74563d',width=4)
for cx,cy,rad in [(20,38,18),(43,38,17),(31,22,20),(12,44,10),(50,45,10)]:
 points=[]
 for i in range(20):
  ang=i*math.tau/20;rr=rad+r.choice([-2,-1,0,1])
  points.append((round(cx+math.cos(ang)*rr),round(cy+math.sin(ang)*rr*.86)))
 mask=Image.new('L',(64,80));md=ImageDraw.Draw(mask);md.polygon(points,fill=255)
 layer=Image.new('RGBA',(64,80));ld=ImageDraw.Draw(layer)
 ld.polygon(points,fill='#365d43',outline='#31553e')
 for yy in range(max(0,cy-rad),min(65,cy+rad)):
  for xx in range(max(0,cx-rad),min(64,cx+rad)):
   if mask.getpixel((xx,yy))==0:continue
   if any(mask.getpixel((max(0,min(63,xx+dx)),max(0,min(79,yy+dy))))==0 for dx,dy in [(1,0),(-1,0),(0,1),(0,-1)]):continue
   band=(yy-(cy-rad))+(xx-cx)*.28
   color='#8aaa61' if band<rad*.65 else '#719653' if band<rad*1.15 else '#588147' if band<rad*1.55 else '#416b44'
   ld.point((xx,yy),fill=color)
 for i in range(12):
  x=cx+r.randrange(-rad+3,rad-2);y=cy+r.randrange(-rad//2,rad//2)
  if 0<=x<62 and 0<=y<64 and mask.getpixel((x,y)):
   ld.line((x,y,x+2,y),fill='#94b56b' if y<cy else '#6e9653')
 im.alpha_composite(layer)
im.save(a/'tree.png')
im=Image.new('RGBA',(32,28));d=ImageDraw.Draw(im);d.ellipse((1,19,30,27),fill=(28,44,37,65));d.polygon([(3,20),(6,9),(13,3),(24,6),(29,15),(26,24),(9,25)],fill='#758e92',outline='#4b676c');d.polygon([(6,9),(13,3),(24,6),(19,13),(8,15)],fill='#b4c4b8');d.polygon([(19,13),(24,6),(29,15),(26,23)],fill='#667e87');d.line((8,15,17,13,20,19),fill='#8fa9a4',width=2);d.line((6,18,11,20),fill='#91a775',width=2);im.save(a/'rock.png')
# Crop sprites: two plants per cell, five stages for each culture.
im=Image.new('RGBA',(120,48));d=ImageDraw.Draw(im)
for row in range(2):
 for stage in range(5):
  for ox,oy in [(7,13),(17,18)]:
   x=stage*24+ox;y=row*24+oy
   mature=stage>=(3 if row==0 else 4)
   if mature:
    if row==0:
     d.ellipse((x-4,y-4,x+4,y+3),fill='#efcfb6',outline='#b19775');d.rectangle((x-3,y-4,x+3,y-2),fill='#ce9f9d');d.point((x-2,y),fill='#fff0d1')
    else:d.polygon([(x-3,y-4),(x+3,y-4),(x,y+5)],fill='#df9852',outline='#ab6e3c');d.line((x-2,y-2,x+1,y-2),fill='#f0bd71')
   h=3+min(stage,3)*2
   d.line((x,y-1,x,y-h),fill='#426a40',width=2)
   d.polygon([(x,y-h+2),(x-4,y-h-1),(x-5,y-h+2),(x-1,y-h+4)],fill='#7eaa59')
   d.polygon([(x,y-h+2),(x+4,y-h-2),(x+5,y-h),(x+1,y-h+4)],fill='#98ba69')
im.save(a/'crops.png')
