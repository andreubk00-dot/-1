extends RefCounted
## Persistent exploration and one-time villagers' requests, independent of the UI.
const SIZE := Vector2i(80,56)
const NPCS := {
 "lina":{"name":"Лина · лесничая","cell":Vector2i(49,11),"portrait":0,"item":"berry","count":6,"coins":160,"xp":25,"intro":"Лес снова открыт для прогулок. Собирайте ягоды рукой: кусты восстанавливаются через два дня. Ягоды можно съесть из хотбара — они возвращают 8 энергии.","request":"Принесите 6 лесных ягод для питомника."},
 "sava":{"name":"Савва · рыбак","cell":Vector2i(64,25),"portrait":1,"item":"fish","count":3,"coins":240,"xp":30,"intro":"Удочка уже лежит в рюкзаке. Назначьте её на хотбар и нажмите на воду рядом. Дождитесь зелёной полосы и нажмите E или кнопку действия. В окнах время рыбалки останавливается.","request":"Поймайте и принесите 3 рыбы для нашего причала."},
 "boris":{"name":"Борис · каменщик","cell":Vector2i(57,40),"portrait":2,"item":"ingot","count":3,"coins":360,"xp":40,"intro":"В каменном кряже из валунов выпадает медная руда. В мастерской переплавьте 3 руды и 1 дерево в слиток. Дикие ресурсы восстанавливаются раз в три дня, ферму они не затрагивают.","request":"Для ремонта инструментов нужны 3 медных слитка."}
}
const BUSHES := [Vector2i(49,8),Vector2i(51,10),Vector2i(50,17),Vector2i(53,19),Vector2i(58,8),Vector2i(61,10),Vector2i(58,27),Vector2i(69,28),Vector2i(72,19),Vector2i(68,8),Vector2i(47,37),Vector2i(50,41)]
const REGIONS := {"farm":"Усадьба", "forest":"Сосновый лес", "lake":"Лазурное озеро", "ridge":"Каменный кряж"}
var completed: Array = []
var picked: Dictionary = {}
var visited: Array = ["farm"]
var catches := 0
static func region(c: Vector2i) -> String:
 if c.x>=48 and c.y>=33: return "ridge"
 if c.x>=58 and c.y>=14 and c.y<33: return "lake"
 if c.x>=46 or c.y>=36: return "forest"
 return "farm"
static func is_frontier(c: Vector2i) -> bool: return c.x>=48 or c.y>=36
static func is_path(c: Vector2i) -> bool:
 return (c.y in [12,13] and c.x>=34 and c.x<=72) or (c.x in [54,55] and c.y>=14 and c.y<=45) or (c.y in [25,26] and c.x>=56 and c.x<=64) or (c.y in [40,41] and c.x>=56 and c.x<=61)
static func reserved(c: Vector2i) -> bool:
 if BUSHES.has(c): return true
 for npc in NPCS.values():
  if Rect2i(npc.cell-Vector2i(2,2),Vector2i(5,5)).has_point(c): return true
 return false
static func rainy(day: int) -> bool: return day%6==0
func berry_ready(c: Vector2i, day: int) -> bool: return BUSHES.has(c) and day-int(picked.get(c,-99))>=2
func gather(c: Vector2i, day: int, bag: Dictionary) -> bool:
 if not berry_ready(c,day): return false
 picked[c]=day
 bag.berry=int(bag.get("berry",0))+2
 return true
func can_complete(id: String, bag: Dictionary) -> bool:
 return NPCS.has(id) and not completed.has(id) and int(bag.get(NPCS[id].item,0))>=int(NPCS[id].count)
func complete(id: String, bag: Dictionary) -> Dictionary:
 if not can_complete(id,bag): return {}
 var npc: Dictionary=NPCS[id]
 bag[npc.item]-=int(npc.count)
 completed.append(id)
 return {"coins":npc.coins,"xp":npc.xp}
func state() -> Dictionary:
 var rows: Array=[]
 for c in picked: rows.append([c.x,c.y,picked[c]])
 return {"completed":completed.duplicate(),"picked":rows,"visited":visited.duplicate(),"catches":catches}
static func integer(n: Variant, minimum: int, maximum: int) -> bool:
 return (n is int or n is float) and is_finite(float(n)) and n==floorf(n) and n>=minimum and n<=maximum
func valid(value: Variant, day: int) -> bool:
 if not value is Dictionary: return false
 if value.is_empty(): return true
 for key in ["completed","picked","visited","catches"]:
  if not value.has(key): return false
 if not value.completed is Array or value.completed.size()>NPCS.size(): return false
 var seen: Array=[]
 for id in value.completed:
  if not id is String or not NPCS.has(id) or seen.has(id): return false
  seen.append(id)
 if not value.visited is Array or value.visited.size()>REGIONS.size(): return false
 seen=[]
 for id in value.visited:
  if not id is String or not REGIONS.has(id) or seen.has(id): return false
  seen.append(id)
 if not integer(value.catches,0,10000000) or not value.picked is Array or value.picked.size()>BUSHES.size(): return false
 seen=[]
 for row in value.picked:
  if not row is Array or row.size()!=3: return false
  if not integer(row[0],0,SIZE.x-1) or not integer(row[1],0,SIZE.y-1) or not integer(row[2],1,day): return false
  var c:=Vector2i(int(row[0]),int(row[1]))
  if not BUSHES.has(c) or seen.has(c): return false
  seen.append(c)
 return true
func restore(value: Dictionary, day: int) -> bool:
 if not valid(value,day): return false
 completed=value.get("completed",[]).duplicate()
 visited=value.get("visited",["farm"]).duplicate()
 catches=int(value.get("catches",0))
 picked.clear()
 for row in value.get("picked",[]):picked[Vector2i(int(row[0]),int(row[1]))]=int(row[2])
 return true
