extends Button
const Items = preload("res://game/items.gd")
var item_id := ""
var amount := -1
var number := ""
var source_index := -1
var ui_owner: Node
var active := false
var is_inventory := false
func _ready() -> void:
 focus_mode = Control.FOCUS_NONE
 mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
 mouse_entered.connect(func() -> void: ui_owner.show_tooltip(item_id))
 mouse_exited.connect(func() -> void: ui_owner.hide_tooltip())
func _draw() -> void:
 if item_id != "":
  var texture := Items.icon(item_id)
  draw_texture_rect(texture, Rect2(Vector2(size.x / 2 - 20, 9), Vector2(40, 40)), false)
 if not number.is_empty(): draw_string(ui_owner.font, Vector2(7, 13), number, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("b9b99b"))
 if amount >= 0:
  draw_string_outline(ui_owner.font, Vector2(0, size.y - 7), str(amount), HORIZONTAL_ALIGNMENT_RIGHT, size.x - 7, 12, 3, Color("20332f"))
  draw_string(ui_owner.font, Vector2(0, size.y - 7), str(amount), HORIZONTAL_ALIGNMENT_RIGHT, size.x - 7, 12, Color("f5e1b8"))
 if is_hovered(): draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), Color(0.96, 0.86, 0.62, 0.15))
func _get_drag_data(_position: Vector2) -> Variant:
 if item_id == "": return null
 var preview := TextureRect.new()
 preview.texture = Items.icon(item_id)
 preview.custom_minimum_size = Vector2(48, 48)
 preview.modulate.a = 0.85
 set_drag_preview(preview)
 ui_owner.hide_tooltip()
 return {"kind":"farm_item", "item":item_id, "slot":source_index, "from":"inventory" if is_inventory else "hotbar"}
func _can_drop_data(_position: Vector2, data: Variant) -> bool:
 return data is Dictionary and data.get("kind") == "farm_item" and Items.NAMES.has(data.get("item", "")) and (not is_inventory or ui_owner.game.inventory_layout.slots.has(data.item))
func _drop_data(_position: Vector2, data: Variant) -> void:
 if is_inventory: ui_owner.drop_into_inventory(source_index,data)
 else: ui_owner.drop_on_slot(source_index, data)

func _gui_input(event: InputEvent) -> void:
 if is_inventory or ui_owner.modal.visible: return
 if event is InputEventMouseButton and event.pressed:
  if event.button_index==MOUSE_BUTTON_WHEEL_UP:
   ui_owner.game._select_slot(posmod(ui_owner.game.hotbar.active-1,10),false)
   accept_event()
  elif event.button_index==MOUSE_BUTTON_WHEEL_DOWN:
   ui_owner.game._select_slot((ui_owner.game.hotbar.active+1)%10,false)
   accept_event()
