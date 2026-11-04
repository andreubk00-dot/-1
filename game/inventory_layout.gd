extends RefCounted
const Items = preload("res://game/items.gd")
const SIZE := 24
const TOOLS := ["hand","hoe","water","axe","pick","rod"]
var slots: Array = []
func _init() -> void:
 slots.resize(SIZE)
 slots.fill("")
 for i in range(TOOLS.size()-1): slots[i]=TOOLS[i]
func reconcile(inventory: Dictionary) -> void:
 for i in range(SIZE):
  var id: String=slots[i]
  if id!="" and not TOOLS.has(id) and int(inventory.get(id,0))<=0: slots[i]=""
 for id in TOOLS:
  if id!="rod": _ensure(id)
 for id in inventory:
  if int(inventory[id])>0 and Items.NAMES.has(id): _ensure(id)
 _ensure("rod")
func _ensure(id: String) -> void:
 if slots.has(id): return
 var index:=slots.find("")
 if index>=0: slots[index]=id
func swap(a: int,b: int) -> bool:
 if a<0 or b<0 or a>=SIZE or b>=SIZE: return false
 var item: String=slots[a]
 slots[a]=slots[b]
 slots[b]=item
 return true
func restore(value: Variant) -> bool:
 if not value is Array or value.size()!=SIZE: return false
 var migrated: Array=value.duplicate()
 for i in range(migrated.size()):
  if migrated[i]=="build": migrated[i]=""
 var seen: Dictionary={}
 for id in migrated:
  if not id is String or (id!="" and (not Items.NAMES.has(id) or seen.has(id))): return false
  if id!="": seen[id]=true
 slots=migrated
 return true
