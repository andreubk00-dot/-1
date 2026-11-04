extends RefCounted
const OFFERS := [
 {"name":"Для деревенской кухни", "customer":"Кухня долины", "cost":{"turnip":5}, "coins":210, "xp":20},
 {"name":"Свежие овощи", "customer":"Лавка у переправы", "cost":{"carrot":4}, "coins":280, "xp":30},
 {"name":"Подготовка к ярмарке", "customer":"Мастерская долины", "cost":{"planks":6,"crate":1}, "coins":260, "xp":35},
 {"name":"Большой урожай", "customer":"Торговцы долины", "cost":{"turnip":4,"carrot":4,"crate":2}, "coins":720, "xp":50}
]
var completed := 0
var last_day := 0
func current() -> Dictionary: return OFFERS[completed%OFFERS.size()]
func can_submit(bag: Dictionary, day: int) -> bool:
 if day<=last_day: return false
 for id in current().cost:
  if bag.get(id,0)<current().cost[id]: return false
 return true
func submit(bag: Dictionary, day: int) -> Dictionary:
 if not can_submit(bag,day): return {}
 var offer: Dictionary=current()
 for id in offer.cost: bag[id]-=offer.cost[id]
 completed+=1
 last_day=day
 return {"coins":offer.coins,"xp":offer.xp}
func state() -> Dictionary: return {"completed":completed,"last_day":last_day}
func valid(value: Variant) -> bool:
 if not value is Dictionary: return false
 if value.is_empty(): return true
 for key in ["completed","last_day"]:
  if not value.has(key): return false
  var n: Variant=value[key]
  if not n is int and not n is float: return false
  if not is_finite(float(n)) or n!=floorf(n) or n<0 or n>10000000: return false
 return (value.completed==0 and value.last_day==0) or (value.completed>0 and value.last_day>0)
func restore(value: Variant) -> bool:
 if not valid(value): return false
 completed=int(value.get("completed",0))
 last_day=int(value.get("last_day",0))
 return true
