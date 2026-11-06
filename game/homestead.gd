extends RefCounted
const Frontier=preload("res://game/frontier.gd")
const KINDS := ["bakery","well","forge"]
const RECIPES := {
 "bread":{"name":"Деревенский хлеб","building":"bakery","cost":{"wheat":3},"minutes":35.0,"output":"bread"},
 "ironbar":{"name":"Железный слиток","building":"forge","cost":{"iron":3,"wood":2},"minutes":60.0,"output":"ironbar"}
}
var structures: Array=[]
var jobs: Array=[]
var products: Dictionary={"bread":0,"ironbar":0}
func has(kind: String) -> bool:
 for b in structures:
  if b.kind==kind: return true
 return false
func at(c: Vector2i) -> String:
 for b in structures:
  if Rect2i(b.cell,Vector2i(3,2)).has_point(c): return b.kind
 return ""
func place(kind: String,c: Vector2i) -> bool:
 if not KINDS.has(kind) or has(kind): return false
 structures.append({"kind":kind,"cell":c})
 return true
func irrigate(plots: Dictionary) -> int:
 var count:=0
 for b in structures:
  if b.kind!="well": continue
  for c in plots:
   if Vector2(c).distance_to(Vector2(b.cell)+Vector2(1,1))<=4 and plots[c].stage>=0:
    if not plots[c].wet: count+=1
    plots[c].wet=true
 return count
func can_start(id: String,bag: Dictionary) -> bool:
 if not RECIPES.has(id) or jobs.size()>=3 or not has(RECIPES[id].building): return false
 for item in RECIPES[id].cost:
  if bag.get(item,0)<RECIPES[id].cost[item]: return false
 return true
func start(id: String,bag: Dictionary) -> bool:
 if not can_start(id,bag): return false
 for item in RECIPES[id].cost: bag[item]-=int(RECIPES[id].cost[item])
 jobs.append({"recipe":id,"remaining":RECIPES[id].minutes})
 return true
func advance(minutes: float) -> int:
 if not is_finite(minutes) or minutes<=0: return 0
 var count:=0
 while minutes>0 and not jobs.is_empty():
  var step:=minf(minutes,float(jobs[0].remaining))
  jobs[0].remaining-=step
  minutes-=step
  if jobs[0].remaining>0.00001: break
  products[RECIPES[jobs[0].recipe].output]+=1
  jobs.pop_front()
  count+=1
 return count
func collect(bag: Dictionary) -> int:
 var count:=0
 for id in products:
  count+=int(products[id])
  bag[id]=int(bag.get(id,0))+int(products[id])
  products[id]=0
 return count
func removable(kind: String) -> bool:
 for job in jobs:
  if RECIPES[job.recipe].building==kind: return false
 for id in products:
  if products[id]>0 and RECIPES[id].building==kind: return false
 return has(kind)
func remove(kind: String) -> bool:
 if not removable(kind): return false
 for i in range(structures.size()):
  if structures[i].kind==kind: structures.remove_at(i); return true
 return false
func state() -> Dictionary:
 var rows: Array=[]
 for b in structures: rows.append([b.kind,b.cell.x,b.cell.y])
 return {"structures":rows,"jobs":jobs.duplicate(true),"products":products.duplicate()}
func valid(value: Variant) -> bool:
 if not value is Dictionary: return false
 if value.is_empty(): return true
 for key in ["structures","jobs","products"]:
  if not value.has(key): return false
 if not value.structures is Array or value.structures.size()>KINDS.size(): return false
 var seen: Array=[]
 for row in value.structures:
  if not row is Array or row.size()!=3 or not row[0] is String or not KINDS.has(row[0]) or seen.has(row[0]): return false
  if not Frontier.integer(row[1],1,Frontier.SIZE.x-4) or not Frontier.integer(row[2],1,Frontier.SIZE.y-3): return false
  seen.append(row[0])
 if not value.jobs is Array or value.jobs.size()>3 or not value.products is Dictionary: return false
 for job in value.jobs:
  if not job is Dictionary or not job.has("recipe") or not job.has("remaining") or not RECIPES.has(job.recipe): return false
  if not seen.has(RECIPES[job.recipe].building): return false
  var t: Variant=job.remaining
  if (not t is float and not t is int) or not is_finite(float(t)) or t<=0 or t>RECIPES[job.recipe].minutes: return false
 for id in products:
  if not value.products.has(id) or not Frontier.integer(value.products[id],0,10000000): return false
  if value.products[id]>0 and not seen.has(RECIPES[id].building): return false
 return true
func restore(value: Dictionary) -> bool:
 if not valid(value): return false
 structures=[]
 for row in value.get("structures",[]):structures.append({"kind":row[0],"cell":Vector2i(int(row[1]),int(row[2]))})
 jobs=value.get("jobs",[]).duplicate(true)
 for id in products: products[id]=int(value.get("products",{}).get(id,0))
 return true
