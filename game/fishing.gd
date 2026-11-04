extends RefCounted
## Real-time bite window. Menus and platform pauses do not call advance().
var active := false
var elapsed := 0.0
var bite_at := 2.0
const WINDOW := 1.4
var target := Vector2i.ZERO
func cast(cell: Vector2i, salt: int) -> void:
 target=cell
 elapsed=0
 bite_at=1.8+float(posmod(cell.x*7+cell.y*3+salt,9))*0.1
 active=true
func ready() -> bool: return active and elapsed>=bite_at and elapsed<=bite_at+WINDOW
func advance(delta: float) -> bool:
 if not active or not is_finite(delta) or delta<=0: return false
 elapsed+=delta
 if elapsed>bite_at+WINDOW:
  active=false
  return true
 return false
func reel() -> bool:
 var caught:=ready()
 active=false
 return caught
func cancel() -> void: active=false
