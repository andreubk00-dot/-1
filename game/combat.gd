extends RefCounted
const Frontier=preload("res://game/frontier.gd")
const RUIN := Rect2i(88,48,5,2)
const TYPES := {
 "moss":{"name":"Моховик","hp":28,"damage":8,"speed":30.0,"reach":43.0,"row":0,"iron":1,"essence":1},
 "shard":{"name":"Осколочник","hp":48,"damage":12,"speed":24.0,"reach":43.0,"row":1,"iron":2,"essence":2},
 "warden":{"name":"Корневой страж","hp":140,"damage":18,"speed":21.0,"reach":58.0,"row":2,"iron":4,"essence":6}
}
const ANCHORS := [[81,16,"moss"],[86,19,"moss"],[89,29,"shard"],[80,38,"moss"],[87,43,"shard"],[90,52,"warden"]]
var health:=100
var weapon_level:=1
var defeated:=0
var killed: Dictionary={}
var saved_hp: Dictionary={}
var mobs: Array=[]
var shots: Array=[]
var events: Array=[]
var immunity:=0.0
var attack_left:=0.0
var aim:=Vector2.DOWN
static func dangerous(p: Vector2) -> bool: return p.x>=78*24 and p.x<95*24 and p.y>=5*24 and p.y<61*24
static func ruin_solid(c: Vector2i) -> bool:
 return RUIN.has_point(c) and c.x!=RUIN.position.x+2
static func reserved(c: Vector2i) -> bool:
 if RUIN.has_point(c): return true
 for a in ANCHORS:
  if Vector2(c).distance_to(Vector2(a[0],a[1]))<=2: return true
 return false
func initialize(day: int) -> void:
 mobs=[]
 shots=[]
 events=[]
 immunity=0
 attack_left=0
 for i in range(ANCHORS.size()):
  if killed.has(i) and day-int(killed[i])<2: continue
  var a: Array=ANCHORS[i]
  var spec: Dictionary=TYPES[a[2]]
  var pos:=Vector2(a[0]*24+12,a[1]*24+12)
  mobs.append({"id":i,"kind":a[2],"pos":pos,"home":pos,"hp":int(saved_hp.get(i,spec.hp)),"cooldown":0.6,"windup":0.0,"flash":0.0})
func cancel_attacks() -> void:
 shots.clear()
 attack_left=0
 for mob in mobs: mob.windup=0;mob.cooldown=0.8
func _down(mob: Dictionary,day: int) -> void:
 if mob.hp>0 or killed.get(mob.id,-1)==day: return
 killed[mob.id]=day
 saved_hp.erase(mob.id)
 defeated+=1
 events.append({"kind":"loot","iron":TYPES[mob.kind].iron,"essence":TYPES[mob.kind].essence,"pos":mob.pos,"boss":mob.kind=="warden"})
func _hurt_mob(mob: Dictionary,damage: int,day: int) -> void:
 if mob.hp<=0: return
 mob.hp=maxi(0,int(mob.hp)-damage)
 mob.flash=0.18
 if mob.kind=="moss":
  mob.windup=0
  mob.cooldown=maxf(mob.cooldown,0.35)
 if mob.hp>0: saved_hp[mob.id]=mob.hp
 _down(mob,day)
func _clear_line(a: Vector2,b: Vector2,can_stand: Callable) -> bool:
 for t in [0.25,0.5,0.75]:
  if not bool(can_stand.call(a.lerp(b,t))): return false
 return true
func strike(player: Vector2,target: Vector2,day: int,can_stand: Callable) -> bool:
 if attack_left>0: return false
 aim=(target-player).normalized()
 if aim==Vector2.ZERO: aim=Vector2.DOWN
 attack_left=0.44
 for mob in mobs:
  var offset: Vector2=mob.pos-player
  if mob.hp<=0 or offset.length()>57 or (offset.length()>1 and aim.dot(offset.normalized())<0.15): continue
  if not _clear_line(player,mob.pos,can_stand): continue
  _hurt_mob(mob,14+(weapon_level-1)*9,day)
  var push: Vector2=mob.pos+aim*7
  if bool(can_stand.call(push)): mob.pos=push
 return true
func shoot(player: Vector2,target: Vector2,bag: Dictionary) -> bool:
 if attack_left>0 or bag.get("stone",0)<1 or target.distance_to(player)<1 or target.distance_to(player)>185: return false
 bag.stone-=1
 aim=(target-player).normalized()
 attack_left=0.55
 shots.append({"pos":player+Vector2(0,-8),"vel":aim*230,"life":0.8})
 return true
func step(delta: float,player: Vector2,can_stand: Callable,shot_clear: Callable,day: int) -> void:
 if not is_finite(delta) or delta<=0: return
 var dt:=minf(delta,0.1)
 immunity=maxf(0,immunity-dt)
 attack_left=maxf(0,attack_left-dt)
 for mob in mobs:
  if mob.hp<=0: continue
  var spec: Dictionary=TYPES[mob.kind]
  mob.flash=maxf(0,mob.flash-dt)
  mob.cooldown=maxf(0,mob.cooldown-dt)
  var distance: float=mob.pos.distance_to(player)
  if mob.windup>0:
   mob.windup=maxf(0,mob.windup-dt)
   if mob.windup<=0:
    mob.cooldown=1.4 if mob.kind!="warden" else 1.8
    if dangerous(player) and distance<float(spec.reach) and immunity<=0:
     health=maxi(0,health-int(spec.damage))
     immunity=0.9
     events.append({"kind":"hurt","damage":spec.damage,"pos":mob.pos})
   continue
  var aggro:=dangerous(player) and distance<155 and player.distance_to(mob.home)<210
  if aggro and distance<(46 if mob.kind=="warden" else 36) and mob.cooldown<=0:
   mob.windup=0.65 if mob.kind!="warden" else 0.9
   continue
  var target: Vector2=player if aggro else mob.home
  var diff: Vector2=target-mob.pos
  if diff.length()>5 and (not aggro or distance>26):
   var move: Vector2=diff.normalized()*float(spec.speed)*dt
   if bool(can_stand.call(mob.pos+Vector2(move.x,0))): mob.pos.x+=move.x
   if bool(can_stand.call(mob.pos+Vector2(0,move.y))): mob.pos.y+=move.y
 for i in range(shots.size()-1,-1,-1):
  var shot: Dictionary=shots[i]
  var previous: Vector2=shot.pos
  shot.pos+=shot.vel*dt
  shot.life-=dt
  var hit:=false
  for t in [0.33,0.67,1.0]:
   if not bool(shot_clear.call(previous.lerp(shot.pos,t))): hit=true; break
  if not hit:
   for mob in mobs:
    if mob.hp<=0: continue
    var nearest:=Geometry2D.get_closest_point_to_segment(mob.pos+Vector2(0,-8),previous,shot.pos)
    if nearest.distance_to(mob.pos+Vector2(0,-8))<13:
     _hurt_mob(mob,12+weapon_level*6,day);hit=true;break
  if hit or shot.life<=0: shots.remove_at(i)
func state() -> Dictionary:
 var dead: Array=[]
 var alive: Array=[]
 for id in killed:dead.append([id,killed[id]])
 for mob in mobs:
  if mob.hp>0:alive.append([mob.id,mob.hp])
 return {"health":health,"weapon_level":weapon_level,"defeated":defeated,"killed":dead,"living":alive}
func valid(value: Variant,day: int) -> bool:
 if not value is Dictionary: return false
 if value.is_empty(): return true
 for key in ["health","weapon_level","defeated","killed","living"]:
  if not value.has(key): return false
 if not Frontier.integer(value.health,1,100) or not Frontier.integer(value.weapon_level,1,3) or not Frontier.integer(value.defeated,0,10000000): return false
 if not value.killed is Array or value.killed.size()>ANCHORS.size() or not value.living is Array or value.living.size()>ANCHORS.size(): return false
 var dead: Array=[]
 for row in value.killed:
  if not row is Array or row.size()!=2 or not Frontier.integer(row[0],0,ANCHORS.size()-1) or not Frontier.integer(row[1],1,day) or dead.has(row[0]): return false
  dead.append(row[0])
 var seen: Array=[]
 for row in value.living:
  if not row is Array or row.size()!=2 or not Frontier.integer(row[0],0,ANCHORS.size()-1) or seen.has(row[0]): return false
  if not Frontier.integer(row[1],1,int(TYPES[ANCHORS[int(row[0])][2]].hp)): return false
  for d in value.killed:
   if d[0]==row[0] and day-int(d[1])<2: return false
  seen.append(row[0])
 return true
func restore(value: Dictionary,day: int) -> bool:
 if not valid(value,day): return false
 health=int(value.get("health",100))
 weapon_level=int(value.get("weapon_level",1))
 defeated=int(value.get("defeated",0))
 killed.clear();saved_hp.clear()
 for row in value.get("killed",[]):killed[int(row[0])]=int(row[1])
 for row in value.get("living",[]):saved_hp[int(row[0])]=int(row[1])
 initialize(day)
 return true
func draw_mob(game: Node2D,mob: Dictionary) -> void:
 if mob.hp<=0: return
 var spec: Dictionary=TYPES[mob.kind]
 var pos: Vector2=mob.pos.round()
 if mob.windup>0:
  game.draw_circle(pos,float(spec.reach),Color(0.8,0.33,0.22,0.25))
  game.draw_arc(pos,float(spec.reach),0,TAU,24,Color("e4a76a"),1)
 var frame:=int(game.elapsed*5+mob.id)%4
 var size:=Vector2(48,48) if mob.kind=="warden" else Vector2(32,32)
 game.draw_texture_rect_region(game.textures.mobs,Rect2(pos-Vector2(size.x/2,size.y-5),size),Rect2(frame*32,spec.row*32,32,32),Color(1,0.55,0.5) if mob.flash>0 else Color.WHITE)
 if mob.hp<spec.hp or mob.kind=="warden":
  var width:=36.0 if mob.kind=="warden" else 24.0
  game.draw_rect(Rect2(pos+Vector2(-width/2,-size.y-1),Vector2(width,3)),Color("343b36"))
  game.draw_rect(Rect2(pos+Vector2(-width/2,-size.y-1),Vector2(width*float(mob.hp)/float(spec.hp),2)),Color("c39c69"))
func draw_attacks(game: Node2D) -> void:
 if attack_left>0 and game.selected in [10,11]:
  var shoulder: Vector2=game.player+Vector2(0,-13)
  if game.selected==10:
   var t:=clampf(1.0-attack_left/0.44,0,1)
   var angle:=aim.angle()+PI/2+lerpf(-1.3,1.2,smoothstep(0.1,0.8,t))
   game.draw_set_transform(shoulder,angle,Vector2.ONE)
   game.draw_texture_rect(game.Items.icon("sword"),Rect2(-8,-34,20,34),false)
   game.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
   if t>0.15 and t<0.8:
    var points:=PackedVector2Array()
    for i in range(8):points.append(shoulder+Vector2(0,-30).rotated(angle-i*0.12))
    game.draw_polyline(points,Color(0.86,0.91,0.74,0.6),2)
  else:
   game.draw_line(shoulder,shoulder+aim*15,Color("bd9e6d"),2)
 for shot in shots:
  game.draw_line(shot.pos-shot.vel.normalized()*8,shot.pos,Color("d6d1af"),1)
  game.draw_rect(Rect2(shot.pos-Vector2(2,2),Vector2(4,4)),Color("b8c1b4"))
