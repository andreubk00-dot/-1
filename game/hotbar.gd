extends RefCounted
const Items = preload("res://game/items.gd")
const SIZE := 10
var slots: Array = ["hand", "hoe", "water", "seeds", "axe", "pick", "", "", "", ""]
var active := 0
func assign(index: int, id: String) -> bool:
 if index < 0 or index >= SIZE or (id != "" and not Items.NAMES.has(id)): return false
 slots[index] = id
 return true
func swap(a: int, b: int) -> bool:
 if a < 0 or b < 0 or a >= SIZE or b >= SIZE: return false
 var previous: String = slots[a]
 slots[a] = slots[b]
 slots[b] = previous
 return true
func restore(value: Variant, index: Variant = 0) -> bool:
 if not value is Array or value.size() != SIZE: return false
 var migrated: Array=value.duplicate()
 for i in range(migrated.size()):
  if migrated[i]=="build": migrated[i]=""
 for id in migrated:
  if not id is String or (id != "" and not Items.NAMES.has(id)): return false
 if not index is float and not index is int: return false
 if not is_finite(float(index)) or float(index) != floorf(float(index)) or index < 0 or index >= SIZE: return false
 slots = migrated
 active = int(index)
 return true
