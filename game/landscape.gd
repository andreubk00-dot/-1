extends RefCounted
const Frontier=preload("res://game/frontier.gd")
static func is_path(c: Vector2i) -> bool:
 return Frontier.is_path(c) or ((c.y in [12,13]) and c.x>=6 and c.x<=33) or ((c.x in [22,23]) and c.y>=14 and c.y<=31) or Rect2i(9,10,3,2).has_point(c) or Rect2i(27,11,3,1).has_point(c)
static func draw_ambient(game: Node2D, elapsed: float, minutes: float) -> void:
 if minutes<1080:
  for i in range(6):
   var origin:=Vector2(300+i*80,390+sin(i*3.0)*120)
   var pos:=origin+Vector2(sin(elapsed*0.55+i*4)*18,cos(elapsed*0.7+i)*10)
   var wing:=1+int(absf(sin(elapsed*7+i))*2)
   game.draw_rect(Rect2(pos-Vector2(wing,1),Vector2(wing,2)),Color("e3d697"))
   game.draw_rect(Rect2(pos+Vector2(1,-1),Vector2(wing,2)),Color("e8d4b2"))
   game.draw_rect(Rect2(pos,Vector2.ONE),Color("576549"))
 else:
  for i in range(12):
   var pos:=Vector2(760+(i*43)%230,470+(i*37)%190)+Vector2(sin(elapsed+i)*9,cos(elapsed*0.7+i)*8)
   var glow:=0.35+absf(sin(elapsed*1.6+i))*0.65
   game.draw_rect(Rect2(pos-Vector2(2,2),Vector2(5,5)),Color(0.89,0.91,0.5,glow*0.1))
   game.draw_rect(Rect2(pos,Vector2.ONE),Color(0.95,0.94,0.61,glow))
