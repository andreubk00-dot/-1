extends RefCounted
const Items = preload("res://game/items.gd")
const DURATIONS := [0.38,0.48,0.62,0.42,0.52,0.52]
var time := 10.0
var duration := 0.5
var tool := 0
var target := Vector2i.ZERO
var direction := Vector2.DOWN
var impact := false
var ghost := ""
var planting_item := "seeds"
func active() -> bool: return time<duration
func progress() -> float: return clampf(time/duration,0,1)
func start(index: int, player: Vector2, cell: Vector2i, removed_kind: String = "", seed_id: String="seeds") -> void:
 planting_item=seed_id
 tool=index
 target=cell
 direction=(Vector2(cell*24+Vector2i(12,12))-player).normalized()
 duration=DURATIONS[index]
 time=0
 impact=false
 ghost=removed_kind
func update(delta: float, game: Node2D) -> void:
 if not active(): return
 time+=delta
 if not impact and progress()>=0.52:
  impact=true
  var colors: Array=[Color("e6cf9b"),Color("bca072"),Color("9bcbd0"),Color("a0c477"),Color("d1b07c"),Color("b1c5c4")]
  game._burst(target,colors[tool])
  game._play(["pick","soil","pour","plant","chop","stone"][tool])
func body_offset() -> Vector2:
 if not active(): return Vector2.ZERO
 var p:=progress()
 if tool==3 or tool==0: return Vector2(0,round(sin(p*PI)*2))
 return Vector2(round(direction.x*sin(p*PI)),round(-sin(p*PI)*1.5))
func draw_ghost(game: Node2D) -> void:
 if ghost=="" or not active(): return
 var p:=Vector2(target*24)
 var t:=progress()
 var fade:=1.0-clampf((t-0.55)/0.45,0,1)
 var rotation:=maxf(0,t-0.5)*0.8*(1 if direction.x>=0 else -1)
 if ghost=="tree":
  game.draw_set_transform(p+Vector2(12,21),rotation,Vector2.ONE)
  game.draw_texture(game.textures.tree,Vector2(-32,-73),Color(1,1,1,fade))
 else: game.draw_texture(game.textures.rock,p+Vector2(-4,-4),Color(1,1,1,fade))
 game.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
func draw_tool(game: Node2D, player: Vector2) -> void:
 if not active(): return
 var t:=progress()
 var shoulder:=player+Vector2(0,-13)+body_offset()
 var hand:=shoulder+direction*8
 var target_pos:=Vector2(target*24+Vector2i(12,12))
 if tool==2:
  game.draw_line(shoulder,hand,Color("dcb28b"),3)
  game.draw_set_transform(hand, sin(t*PI)*0.35*signf(direction.x+0.01),Vector2.ONE)
  game.draw_texture_rect(Items.icon("water"),Rect2(-8,-8,19,19),false)
  game.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  if t>0.2 and t<0.88:
   for i in range(6):
    var f:=fmod(t*3+i*0.16,1)
    var at:=hand.lerp(target_pos,f)+Vector2(sin(i*2.0)*2,-sin(f*PI)*6)
    game.draw_rect(Rect2(at.round(),Vector2(1,2)),Color("b3e2e0"))
 elif tool in [1,4,5]:
  var swing:=smoothstep(0.2,0.65,t)
  var angle:=direction.angle()+PI/2+lerpf(-1.7,0.65,swing)
  var end:=shoulder+Vector2(0,-13).rotated(angle)
  game.draw_line(shoulder,end.lerp(shoulder,0.4),Color("dcb28b"),3)
  game.draw_set_transform(shoulder,angle,Vector2.ONE)
  game.draw_texture_rect(Items.icon(Items.ACTIONS[tool]),Rect2(-8,-28,22,28),false)
  game.draw_set_transform(Vector2.ZERO,0,Vector2.ONE)
  if t>0.36 and t<0.72:
   var points:=PackedVector2Array()
   for i in range(6): points.append(shoulder+Vector2(0,-24).rotated(angle-i*0.13))
   game.draw_polyline(points,Color(0.94,0.91,0.73,(0.72-t)*1.5),1)
 else:
  hand=shoulder.lerp(target_pos, sin(t*PI)*0.65)
  game.draw_line(shoulder,hand,Color("e2b98c"),3)
  game.draw_texture_rect(Items.icon(planting_item if tool==3 else "hand"),Rect2(hand-Vector2(5,6),Vector2(12,12)),false)
