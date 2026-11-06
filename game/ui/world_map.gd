extends Control
var game: Node2D
func _init() -> void:
 custom_minimum_size=Vector2(680,238)
 mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
 if game==null: return
 var rect:=Rect2(10,6,336,224)
 draw_rect(rect.grow(3),Color("947b55"))
 draw_texture_rect(game.textures.map,rect,false)
 var scale:=rect.size/Vector2(game.WORLD*24)
 for c in game.resources:
  var point:=rect.position+Vector2(c*24)*scale
  draw_rect(Rect2(point,Vector2(2,2)),Color("41624c") if game.resources[c].kind=="tree" else Color("b9b8a2"))
 for marker in [["house",game.HOUSE.position],["coin",game.SHOP.position]]:
  var point: Vector2=rect.position+Vector2(marker[1]*24+Vector2i(24,24))*scale
  draw_texture_rect(game.Items.icon(marker[0]),Rect2(point-Vector2(6,6),Vector2(12,12)),false)
 if game.workshop!=Vector2i(-1,-1):
  var point: Vector2=rect.position+Vector2(game.workshop*24)*scale
  draw_texture_rect(game.Items.icon("workshop"),Rect2(point-Vector2(5,5),Vector2(10,10)),false)
 for id in game.Frontier.NPCS:
  var npc: Dictionary=game.Frontier.NPCS[id]
  var p:=rect.position+Vector2(npc.cell*24+Vector2i(12,12))*scale
  draw_circle(p,5,Color("e4c16e"))
  draw_circle(p,3,Color("4e6f5a" if game.frontier.completed.has(id) else "ab6c45"))
 for b in game.homestead.structures:
  var point: Vector2=rect.position+Vector2(b.cell*24)*scale
  draw_texture_rect(game.Items.icon(b.kind),Rect2(point-Vector2(5,5),Vector2(10,10)),false)
 var danger: Vector2=rect.position+Vector2(game.Combat.RUIN.position*24)*scale
 draw_circle(danger,5,Color("b8755c"))
 var at: Vector2=rect.position+game.player*scale
 draw_circle(at,6,Color("203e38"))
 draw_circle(at,3,Color("f5e8bd"))
 draw_line(at+Vector2(-8,0),at+Vector2(8,0),Color("f5e8bd"),1)
 draw_line(at+Vector2(0,-8),at+Vector2(0,8),Color("f5e8bd"),1)
 var y:=22
 for row in [["Усадьба","Дом, огород и прилавок"],["Сосновый лес","Лина · ягоды · древесина"],["Лазурное озеро","Савва · рыбалка"],["Каменный кряж","Борис · камень · медь"],["Дикие руины","Враги · железо · эссенция"]]:
  draw_string(game.font,Vector2(355,y),row[0],HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("344b40"))
  draw_string(game.font,Vector2(355,y+20),row[1],HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("68775d"))
  y+=37
 draw_string(game.font,Vector2(355,215),"Светлая метка — вы · золотые — жители",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("68775d"))
