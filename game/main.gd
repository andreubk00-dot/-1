extends Node2D
## A self-contained playable vertical slice. World coordinates use 24px cells.
const Progression = preload("res://game/progression.gd")
const TILE := 24
const WORLD := Vector2i(48, 36)
const SAVE_VERSION := 1
const TOOLS := ["Рука", "Мотыга", "Лейка", "Семена", "Топор", "Кирка", "Строить"]
const TOOL_HINTS := ["Собрать урожай • открыть прилавок или дом", "Подготовить землю под посадку", "Полить грядку — один раз в день", "Посадить репу • созревает за 3 полива", "Срубить дерево • 3 удара", "Разбить камень • 3 удара", "Построить склад 3×2 • 20 дерева, 10 камня"]
const HOUSE := Rect2i(8, 6, 5, 4)
const SHOP := Rect2i(27, 9, 3, 2)
var player := Vector2(19 * TILE, 14 * TILE)
var facing := Vector2.DOWN
var direction := 0
var walk_clock := 0.0
var moving := false
var selected := 0
var day := 1
var minutes := 360.0
var energy := 100
var coins := 80
var bag := {"wood": 0, "stone": 0, "seeds": 8, "turnip": 0, "planks": 0, "crate": 0}
var water: Dictionary = {}
var resources: Dictionary = {}
var plots: Dictionary = {}
var buildings: Array[Vector2i] = []
var camera: Camera2D
var ui: CanvasLayer
var stats: Label
var inventory_label: Label
var hint: Label
var objective: Label
var notice: Label
var clock_label: Label
var tool_buttons: Array[Button] = []
var modal: PanelContainer
var modal_body: VBoxContainer
var overlay: ColorRect
var sound: AudioStreamPlayer
var particles: Array[Dictionary] = []
var notification_time := 0.0
var action_cooldown := 0.0
var queued_action: Variant = null
var autosave_clock := 0.0
var elapsed := 0.0
var quest_stage := 0
var experience := 0
var active_storage := Vector2i(-1, -1)
var stored := {"wood": 0, "stone": 0, "seeds": 0, "turnip": 0, "planks": 0, "crate": 0}
var progression = Progression.new()
var workshop := Vector2i(-1, -1)
var build_kind := "warehouse"
var workshop_status: Label
var muted := false
var test_mode := false
var save_path := "user://farm_v1.json"
var textures: Dictionary = {}
var font: Font
var hovered := Vector2i.ZERO
var load_warning := ""
var test_failures := 0
var styled_tool := -1
var soil_styles: Dictionary = {}
var web_save_callback: JavaScriptObject
var web_platform: JavaScriptObject
var web_paused := false
var web_was_paused := false

func _ready() -> void:
 if OS.has_feature("web"):
  web_platform = JavaScriptBridge.get_interface("ValleyPlatform")
 test_mode = "--self-test" in OS.get_cmdline_user_args()
 if test_mode: save_path = "user://test_farm.json"
 font = load("res://art/ui.ttf")
 for key in ["ground", "tree", "rock", "farmer", "house", "shed", "workshop"]:
  textures[key] = load("res://art/" + key + ".png")
 for cell in JSON.parse_string(FileAccess.get_file_as_string("res://game/water.json")):
  water[Vector2i(int(cell[0]), int(cell[1]))] = true
 _generate_resources()
 var restored := false
 if not test_mode: restored = _load_game()
 camera = Camera2D.new()
 camera.zoom = Vector2(1.5, 1.5)
 camera.position = player
 camera.limit_left = 0
 camera.limit_top = 0
 camera.limit_right = WORLD.x * TILE
 camera.limit_bottom = WORLD.y * TILE
 add_child(camera)
 sound = AudioStreamPlayer.new()
 sound.volume_db = -15
 add_child(sound)
 _make_ui()
 _update_ui()
 if web_platform != null:
  web_save_callback = JavaScriptBridge.create_callback(_web_lifecycle_save)
  web_platform.setSaveCallback(web_save_callback)
  call_deferred("_web_ready")
 if "--capture" in OS.get_cmdline_user_args(): call_deferred("_capture")
 elif test_mode: call_deferred("_self_test")
 elif not load_warning.is_empty(): _notify(load_warning)
 else: _notify("С возвращением! Ваше хозяйство ждёт." if restored else "Добро пожаловать домой. Начните с первой грядки.")

func _generate_resources() -> void:
 var rng := RandomNumberGenerator.new()
 rng.seed = 50178
 for y in range(2, WORLD.y - 2):
  for x in range(2, WORLD.x - 2):
   var c := Vector2i(x, y)
   if water.has(c) or HOUSE.grow(2).has_point(c) or SHOP.grow(2).has_point(c): continue
   if y in [12, 13] or x in [22, 23]: continue
   if Rect2i(14, 14, 13, 9).has_point(c): continue
   if rng.randf() < (0.22 if x < 8 or y < 6 or x > 39 else 0.065):
    resources[c] = {"kind": "tree" if rng.randf() < 0.73 else "rock", "hp": 3}
 # Accessible materials for the first building.
 for c in [Vector2i(14, 16), Vector2i(15, 20), Vector2i(17, 22)]: resources[c] = {"kind": "tree", "hp": 3}
 for c in [Vector2i(26, 16), Vector2i(27, 19), Vector2i(25, 22)]: resources[c] = {"kind": "rock", "hp": 3}

func _process(delta: float) -> void:
 if web_platform != null:
  web_paused = bool(web_platform.paused)
  web_platform.gameplay(not modal.visible and not web_paused)
  AudioServer.set_bus_mute(0, muted or web_paused)
  if web_paused:
   if not web_was_paused: _save_game()
   web_was_paused = true
   queued_action = null
   moving = false
   return
  web_was_paused = false
  if bool(web_platform.takeAction()) and not modal.visible:
   queued_action = _cell(player + facing * TILE)
 elapsed += delta
 action_cooldown = maxf(0, action_cooldown - delta)
 if queued_action != null:
  var action_cell: Vector2i = queued_action
  queued_action = null
  if not modal.visible: _act(action_cell)
 notification_time = maxf(0, notification_time - delta)
 notice.visible = notification_time > 0
 if not modal.visible and not test_mode:
  var input := Vector2.ZERO
  if web_platform != null: input = Vector2(float(web_platform.x), float(web_platform.y))
  if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): input.x -= 1
  if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): input.x += 1
  if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP): input.y -= 1
  if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN): input.y += 1
  moving = input.length_squared() > 0
  if moving:
   facing = input.normalized()
   direction = (3 if input.x > 0 else 2) if absf(input.x) > absf(input.y) else (0 if input.y > 0 else 1)
   walk_clock += delta * 9
   var shift := input.normalized() * 76 * delta
   if _can_stand(player + Vector2(shift.x, 0)): player.x += shift.x
   if _can_stand(player + Vector2(0, shift.y)): player.y += shift.y
  else: walk_clock = 0
  _advance_production(delta * 1.3)
  minutes += delta * 1.3
  if minutes >= 1320: _sleep()
  autosave_clock += delta
  if autosave_clock > 30:
   autosave_clock = 0
   _save_game()
 else: moving = false
 camera.position = camera.position.lerp(player, 1.0 - exp(-delta * 12))
 camera.position = camera.position.snapped(Vector2(0.5, 0.5))
 hovered = _cell(get_global_mouse_position())
 for i in range(particles.size() - 1, -1, -1):
  particles[i].life -= delta
  particles[i].pos += particles[i].vel * delta
  particles[i].vel.y += delta * 45
  if particles[i].life <= 0: particles.remove_at(i)
 _update_ui()
 queue_redraw()

func _cell(p: Vector2) -> Vector2i:
 return Vector2i(floori(p.x / TILE), floori(p.y / TILE))

func _in_world(c: Vector2i) -> bool:
 return c.x >= 1 and c.y >= 1 and c.x < WORLD.x - 1 and c.y < WORLD.y - 1

func _solid(c: Vector2i) -> bool:
 if workshop != Vector2i(-1, -1) and Rect2i(workshop, Vector2i(3, 2)).has_point(c): return true
 if not _in_world(c) or water.has(c) or resources.has(c) or HOUSE.has_point(c) or SHOP.has_point(c): return true
 for b in buildings:
  if Rect2i(b, Vector2i(3, 2)).has_point(c): return true
 return false

func _can_stand(p: Vector2) -> bool:
 for offset in [Vector2(-5, -3), Vector2(5, -3), Vector2(-5, 3), Vector2(5, 3)]:
  if _solid(_cell(p + offset)): return false
 return true

func _unhandled_input(event: InputEvent) -> void:
 if web_platform != null and bool(web_platform.paused): return
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode == KEY_ESCAPE:
   if modal.visible: modal.hide()
   else: _help()
   get_viewport().set_input_as_handled()
   return
  if modal.visible: return
  if event.keycode >= KEY_1 and event.keycode <= KEY_7: selected = event.keycode - KEY_1
  if event.keycode == KEY_7: _catalog()
  if event.physical_keycode == KEY_E or event.keycode == KEY_SPACE: queued_action = _cell(player + facing * TILE)
  if event.physical_keycode == KEY_H: _help()
  if event.keycode == KEY_F5:
   if _save_game(): _notify("Хозяйство сохранено")
  if event.physical_keycode == KEY_M:
   muted = not muted
   _notify("Звук выключен" if muted else "Звук включён")
 if modal.visible: return
 if event is InputEventMouseButton and event.pressed:
  if event.button_index == MOUSE_BUTTON_LEFT: queued_action = _cell(get_global_mouse_position())
  elif event.button_index == MOUSE_BUTTON_WHEEL_UP: selected = posmod(selected - 1, 7)
  elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN: selected = (selected + 1) % 7

func _act(c: Vector2i) -> bool:
 var success := _perform_action(c)
 if success and web_platform != null: _save_game()
 return success

func _perform_action(c: Vector2i) -> bool:
 if action_cooldown > 0 or modal.visible: return false
 action_cooldown = 0.18
 if Vector2(c * TILE + Vector2i(12, 12)).distance_to(player) > TILE * 2.25:
  _notify("Подойдите ближе"); return false
 if HOUSE.has_point(c):
  _home(); return true
 if SHOP.has_point(c):
  _shop(); return true
 for building in buildings:
  if Rect2i(building, Vector2i(3, 2)).has_point(c):
   _storage(building); return true
 if workshop != Vector2i(-1, -1) and Rect2i(workshop, Vector2i(3, 2)).has_point(c):
  _workshop_menu(); return true
 if not _in_world(c) or water.has(c):
  _notify("Здесь нельзя работать"); return false
 if selected == 0:
  if plots.has(c) and plots[c].stage >= 3:
   bag.turnip += 1
   _gain_xp(5)
   plots[c] = {"stage": -1, "wet": false}
   quest_stage = maxi(quest_stage, 3)
   _burst(c, Color("e9c7a0")); _play("pick"); _notify("Репа собрана! Продайте её у прилавка.")
   return true
  _notify("Выберите инструмент внизу или клавишами 1–7"); return false
 if selected == 6: return _build(c)
 var energy_cost := maxi(1, 3 - progression.tool_level)
 if energy < energy_cost:
  _notify("Нужен отдых. Вернитесь в дом и завершите день."); _play("error"); return false
 if selected in [4, 5]:
  if not resources.has(c): _notify("Здесь нет подходящего ресурса"); return false
  var kind: String = resources[c].kind
  if (selected == 4 and kind != "tree") or (selected == 5 and kind != "rock"):
   _notify("Для дерева нужен топор, для камня — кирка"); return false
  energy -= energy_cost
  resources[c].hp -= progression.tool_level
  _burst(c, Color("d9bb83") if kind == "tree" else Color("adb4b3")); _play("pick")
  if resources[c].hp <= 0:
   resources.erase(c)
   _gain_xp(3)
   bag["wood" if kind == "tree" else "stone"] += 8 if kind == "tree" else 5
   _notify("+8 дерева" if kind == "tree" else "+5 камня")
  return true
 if _solid(c): _notify("Это место занято"); return false
 if selected == 1:
  if plots.has(c): _notify("Грядка уже подготовлена"); return false
  if c.y in [12, 13] or c.x in [22, 23]: _notify("Оставим дорожки свободными"); return false
  plots[c] = {"stage": -1, "wet": false}
  energy -= energy_cost
  quest_stage = maxi(quest_stage, 1)
 elif selected == 2:
  if not plots.has(c): _notify("Сначала подготовьте грядку мотыгой"); return false
  if plots[c].wet: _notify("Сегодня уже полито"); return false
  plots[c].wet = true
  energy -= energy_cost
  _burst(c, Color("9dc7d1"))
 elif selected == 3:
  if not plots.has(c): _notify("Сначала подготовьте землю мотыгой"); return false
  if plots[c].stage != -1: _notify("На грядке уже что-то растёт"); return false
  if bag.seeds <= 0: _notify("Купите семена у прилавка"); return false
  plots[c].stage = 0
  bag.seeds -= 1
  energy -= energy_cost
  quest_stage = maxi(quest_stage, 2)
 else: return false
 _play("plant")
 return true

func _build_valid(c: Vector2i) -> bool:
 var area := Rect2i(c, Vector2i(3, 2))
 for y in range(c.y, c.y + 2):
  for x in range(c.x, c.x + 3):
   var p := Vector2i(x, y)
   if _solid(p) or plots.has(p) or p.y in [12, 13] or p.x in [22, 23]: return false
 return not area.has_point(_cell(player))

func _build(c: Vector2i) -> bool:
 if build_kind == "workshop" and workshop != Vector2i(-1, -1):
  _notify("Мастерская уже построена"); return false
 if not _build_valid(c): _notify("Нужен свободный участок 3×2 без грядок и дорог"); return false
 var cost: Dictionary = Progression.BUILDINGS[build_kind]
 if bag.wood < cost.wood or bag.stone < cost.stone or coins < cost.coins:
  _notify("Нужно: %d дерева, %d камня, %d монет" % [cost.wood, cost.stone, cost.coins]); return false
 bag.wood -= cost.wood
 bag.stone -= cost.stone
 coins -= cost.coins
 if build_kind == "workshop": workshop = c
 else:
  buildings.append(c)
  if quest_stage < 5: _gain_xp(15)
  quest_stage = maxi(quest_stage, 5)
 _play("build")
 _notify(cost.name + " готова!" if build_kind == "workshop" else "Склад построен!")
 _save_game()
 return true

func _sleep() -> void:
 _advance_production(1440.0 - minutes + 360.0)
 day += 1
 minutes = 360
 energy = 100
 for c in plots:
  if plots[c].wet and plots[c].stage >= 0: plots[c].stage = mini(3, plots[c].stage + 1)
  plots[c].wet = false
 modal.hide()
 _save_game()
 _notify("День %d. Новый рассвет — новые возможности." % day)

func _sell() -> void:
 if bag.turnip <= 0 and bag.crate <= 0: _notify("Пока нечего продавать. Репа растёт за 3 политых дня."); return
 var earned: int = bag.turnip * 35 + bag.crate * 120
 progression.crates_sold += bag.crate
 bag.crate = 0
 coins += earned
 bag.turnip = 0
 quest_stage = maxi(quest_stage, 4)
 _play("pick")
 _notify("Продано на %d монет" % earned)
 _save_game()
 _shop()

func _buy_seeds() -> void:
 if coins < 20: _notify("Нужно 20 монет"); return
 coins -= 20
 bag.seeds += 5
 _play("pick")
 _save_game()
 _shop()

func _play(key: String) -> void:
 if muted or test_mode: return
 sound.stream = load("res://art/" + key + ".wav")
 sound.play()

func _burst(c: Vector2i, color: Color) -> void:
 for i in range(7):
  particles.append({"pos": Vector2(c * TILE + Vector2i(12, 12)), "vel": Vector2(randf_range(-22, 22), randf_range(-35, -12)), "life": 0.55, "color": color})

func _draw() -> void:
 draw_texture(textures.ground, Vector2.ZERO)
 # Field rows are inset so individual tiles remain legible.
 for c in plots:
  var p := Vector2(c * TILE)
  var soil := Color("69503f") if plots[c].wet else Color("997150")
  draw_style_box(_world_style(soil), Rect2(p + Vector2(1, 1), Vector2(22, 22)))
  for y in [6, 12, 18]: draw_line(p + Vector2(4, y), p + Vector2(20, y), soil.lightened(0.12))
  var stage: int = plots[c].stage
  if stage >= 0:
   for offset in [Vector2(7, 8), Vector2(16, 15)]:
    var at: Vector2 = p + offset
    if stage == 3:
     draw_circle(at + Vector2(0, 1), 4, Color("e6cab3"))
     draw_rect(Rect2(at + Vector2(-2, -5), Vector2(3, 5)), Color("649055"))
    else:
     var h := 3 + stage * 2
     draw_line(at, at + Vector2(0, -h), Color("3d6c45"), 2)
     draw_rect(Rect2(at + Vector2(-4, -h), Vector2(4, 3)), Color("96b85e"))
     draw_rect(Rect2(at + Vector2(1, -h + 2), Vector2(4, 3)), Color("73a357"))
 # Pond sparkles have no collision and use the same pixel scale as the shore.
 for c in water:
  if (c.x * 7 + c.y * 3) % 11 == 0:
   var p := Vector2(c * TILE) + Vector2(4 + int(elapsed * 2 + c.y) % 12, 9)
   draw_line(p, p + Vector2(5, 0), Color(0.75, 0.87, 0.81, 0.5 + sin(elapsed * 2 + c.x) * 0.25))
 # Painter's sorting by feet position, including tall trees and buildings.
 var objects: Array[Dictionary] = []
 for c in resources:
  objects.append({"y": (c.y + 1) * TILE, "kind": resources[c].kind, "cell": c})
 objects.append({"y": HOUSE.end.y * TILE, "kind": "house", "cell": HOUSE.position})
 objects.append({"y": SHOP.end.y * TILE, "kind": "shop", "cell": SHOP.position})
 if workshop != Vector2i(-1, -1): objects.append({"y": (workshop.y + 2) * TILE, "kind": "workshop", "cell": workshop})
 for b in buildings: objects.append({"y": (b.y + 2) * TILE, "kind": "shed", "cell": b})
 objects.append({"y": player.y, "kind": "player", "cell": Vector2i.ZERO})
 objects.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.y < b.y)
 for item in objects:
  var p := Vector2(item.cell * TILE)
  match item.kind:
   "tree": draw_texture(textures.tree, p + Vector2(-20 + round(sin(elapsed * 1.5 + p.x) * 0.6), -52))
   "rock": draw_texture(textures.rock, p + Vector2(-4, -4))
   "house": draw_texture(textures.house, p + Vector2(0, -16))
   "shed": draw_texture(textures.shed, p + Vector2(0, -24))
   "workshop":
    draw_texture(textures.workshop, p + Vector2(0, -32))
    if not progression.jobs.is_empty():
     for i in range(3):
      var drift := fmod(elapsed * 8 + i * 7, 26.0)
      draw_rect(Rect2(p + Vector2(52 + sin(elapsed + i) * 2, -24 - drift), Vector2(4 + i, 3)), Color(0.78, 0.81, 0.7, (1.0 - drift / 26.0) * 0.6))
    if progression.has_products():
     draw_rect(Rect2(p + Vector2(27, -40), Vector2(18, 13)), Color("e1c47c"))
     draw_string(font, p + Vector2(33, -30), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("34574a"))
   "shop": _draw_shop(p)
   "player":
    var frame := int(walk_clock) % 4 if moving else 0
    draw_texture_rect_region(textures.farmer, Rect2(player.round() - Vector2(12, 28), Vector2(24, 32)), Rect2(frame * 24, direction * 32, 24, 32))
    if action_cooldown > 0 and selected in [1, 2, 4, 5]:
     var swing := facing.rotated((action_cooldown / 0.18 - 0.5) * 1.5)
     var hand := player.round() + Vector2(0, -11)
     draw_line(hand, hand + swing * 16, Color("c8aa71"), 2)
     draw_rect(Rect2(hand + swing * 16 - Vector2(3, 2), Vector2(7, 4)), Color("a4bcc0"))
 if not modal.visible:
  var target := hovered
  var near := Vector2(target * TILE + Vector2i(12, 12)).distance_to(player) <= TILE * 2.25
  if _in_world(target) and near:
   var size := Vector2(72, 48) if selected == 6 else Vector2(24, 24)
   var valid := _build_valid(target) if selected == 6 else not water.has(target)
   var color := Color(0.9, 0.87, 0.66, 0.8) if valid else Color(0.88, 0.42, 0.36, 0.8)
   draw_rect(Rect2(Vector2(target * TILE), size), Color(color, 0.12), true)
   draw_rect(Rect2(Vector2(target * TILE) + Vector2.ONE, size - Vector2(2, 2)), color, false, 1)
 for part in particles: draw_rect(Rect2(part.pos.round(), Vector2(2, 2)), part.color)

func _draw_shop(p: Vector2) -> void:
 draw_rect(Rect2(p + Vector2(0, 27), Vector2(72, 20)), Color("795a42"))
 draw_rect(Rect2(p + Vector2(2, 27), Vector2(68, 5)), Color("d0ad74"))
 draw_rect(Rect2(p + Vector2(3, -5), Vector2(3, 34)), Color("795a42"))
 draw_rect(Rect2(p + Vector2(66, -5), Vector2(3, 34)), Color("795a42"))
 for i in range(6):
  draw_rect(Rect2(p + Vector2(i * 12, -10), Vector2(12, 16)), Color("dbc594") if i % 2 == 0 else Color("779685"))
 for i in range(4):
  draw_circle(p + Vector2(12 + i * 15, 23), 4, Color("d7b88a"))
 draw_string(font, p + Vector2(10, 43), "ПРИЛАВОК", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("f0dfb9"))

func _world_style(color: Color) -> StyleBoxFlat:
 if soil_styles.has(color): return soil_styles[color]
 var s := StyleBoxFlat.new()
 s.bg_color = color
 s.corner_radius_top_left = 2
 s.corner_radius_bottom_right = 2
 soil_styles[color] = s
 return s

func _panel_style(bg: String = "263f3d", border: String = "6f8270") -> StyleBoxFlat:
 var s := StyleBoxFlat.new()
 s.bg_color = Color(bg)
 s.border_color = Color(border)
 s.set_border_width_all(1)
 s.set_corner_radius_all(5)
 s.content_margin_left = 14
 s.content_margin_right = 14
 s.content_margin_top = 10
 s.content_margin_bottom = 10
 return s

func _label(text: String, size: int = 14, color: String = "f1e6c9") -> Label:
 var label := Label.new()
 label.text = text
 label.add_theme_font_override("font", font)
 label.add_theme_font_size_override("font_size", size)
 label.add_theme_color_override("font_color", Color(color))
 return label

func _button(text: String, callback: Callable) -> Button:
 var b := Button.new()
 b.text = text
 b.add_theme_font_override("font", font)
 b.add_theme_font_size_override("font_size", 13)
 b.add_theme_color_override("font_color", Color("f2e5c5"))
 b.add_theme_stylebox_override("normal", _panel_style("304a45", "5f7566"))
 b.add_theme_stylebox_override("disabled", _panel_style("293e39", "465c50"))
 b.add_theme_color_override("font_disabled_color", Color("86988a"))
 b.add_theme_stylebox_override("hover", _panel_style("496456", "c1b481"))
 b.add_theme_stylebox_override("pressed", _panel_style("667855", "e0c58d"))
 b.focus_mode = Control.FOCUS_NONE
 b.pressed.connect(callback)
 return b

func _make_ui() -> void:
 ui = CanvasLayer.new()
 add_child(ui)
 var top := PanelContainer.new()
 top.position = Vector2(18, 16)
 top.size = Vector2(260, 76)
 top.add_theme_stylebox_override("panel", _panel_style())
 ui.add_child(top)
 var v := VBoxContainer.new()
 top.add_child(v)
 v.add_child(_label("ТИХАЯ ДОЛИНА", 19))
 v.add_child(_label("УСАДЬБА У СТАРОГО ПРУДА · 0.2", 10, "aabd9d"))
 stats = _label("", 13)
 v.add_child(stats)
 var time_panel := PanelContainer.new()
 time_panel.position = Vector2(734, 16)
 time_panel.size = Vector2(208, 65)
 time_panel.add_theme_stylebox_override("panel", _panel_style())
 ui.add_child(time_panel)
 var time_v := VBoxContainer.new()
 time_panel.add_child(time_v)
 clock_label = _label("", 17)
 time_v.add_child(clock_label)
 time_v.add_child(_label("ВЕСНА   /   СОЛНЕЧНО", 10, "b6c4a5"))
 var tasks := PanelContainer.new()
 tasks.position = Vector2(18, 105)
 tasks.size = Vector2(258, 65)
 tasks.add_theme_stylebox_override("panel", _panel_style("30483e", "6b8068"))
 ui.add_child(tasks)
 var task_v := VBoxContainer.new()
 tasks.add_child(task_v)
 task_v.add_child(_label("НОВОЕ НАЧАЛО", 11, "d9c48e"))
 objective = _label("", 12)
 task_v.add_child(objective)
 var footer := PanelContainer.new()
 footer.position = Vector2(155, 442)
 footer.size = Vector2(650, 82)
 footer.add_theme_stylebox_override("panel", _panel_style())
 ui.add_child(footer)
 var foot_v := VBoxContainer.new()
 footer.add_child(foot_v)
 var row := HBoxContainer.new()
 row.add_theme_constant_override("separation", 5)
 foot_v.add_child(row)
 for i in range(7):
  var index := i
  var b := _button(str(i + 1) + "  " + TOOLS[i], func() -> void:
   selected = index
   if index == 6: _catalog())
  b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  row.add_child(b)
  tool_buttons.append(b)
 inventory_label = _label("", 12, "cfceac")
 inventory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 foot_v.add_child(inventory_label)
 hint = _label("", 12)
 hint.position = Vector2(0, 416)
 hint.size.x = 960
 hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 hint.add_theme_color_override("font_shadow_color", Color("243d36"))
 hint.add_theme_constant_override("shadow_offset_x", 1)
 hint.add_theme_constant_override("shadow_offset_y", 1)
 ui.add_child(hint)
 var bag_button := _button("Рюкзак", _inventory_menu)
 bag_button.position = Vector2(18, 181)
 ui.add_child(bag_button)
 var help_b := _button("?  Помощь", _help)
 help_b.position = Vector2(829, 487)
 ui.add_child(help_b)
 notice = _label("", 14)
 notice.position = Vector2(75, 373)
 notice.size = Vector2(810, 28)
 notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 notice.add_theme_color_override("font_shadow_color", Color("172c2b"))
 notice.add_theme_constant_override("shadow_offset_x", 2)
 notice.add_theme_constant_override("shadow_offset_y", 2)
 ui.add_child(notice)
 overlay = ColorRect.new()
 overlay.color = Color(0.12, 0.17, 0.26, 0)
 overlay.size = Vector2(960, 540)
 overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
 ui.add_child(overlay)
 modal = PanelContainer.new()
 modal.position = Vector2(245, 86)
 modal.size = Vector2(470, 250)
 modal.add_theme_stylebox_override("panel", _panel_style("263f3d", "b1ac7b"))
 ui.add_child(modal)
 modal_body = VBoxContainer.new()
 modal_body.add_theme_constant_override("separation", 10)
 modal.add_child(modal_body)
 modal.hide()

func _update_ui() -> void:
 if not is_instance_valid(stats): return
 stats.text = "%d монет  •  Силы %d  •  Ур. %d" % [coins, energy, 1 + experience / 25]
 clock_label.text = "День %02d    %02d:%02d" % [day, int(minutes) / 60, int(minutes) % 60]
 inventory_label.text = "Дерево %d · Камень %d · Семена %d · Репа %d · Доски %d · Ящики %d" % [bag.wood, bag.stone, bag.seeds, bag.turnip, bag.planks, bag.crate]
 inventory_label.clip_text = true
 var objectives := ["1. Подготовьте первую грядку [2]", "2. Посадите репу [4]", "3. Поливайте и отдыхайте дома", "4. Продайте урожай у прилавка", "5. Постройте первый склад [7]", "Усадьба оживает. Продолжайте!"]
 objective.text = objectives[clampi(quest_stage, 0, 5)]
 if quest_stage >= 5:
  if workshop == Vector2i(-1, -1): objective.text = "6. Постройте мастерскую [7]"
  elif progression.tool_level == 1: objective.text = "7. Доски → улучшение инструментов"
  elif progression.crates_sold == 0: objective.text = "8. Продайте ящик урожая"
  else: objective.text = "Усадьба процветает. Развивайтесь!"
 hint.text = TOOL_HINTS[selected]
 if selected in [4, 5]:
  var hits := ceili(3.0 / progression.tool_level)
  hint.text = "%s · уровень %d · %d %s · %d энергии за действие" % [TOOLS[selected], progression.tool_level, hits, "удар" if hits == 1 else "удара", maxi(1, 3 - progression.tool_level)]
 if selected == 6:
  var cost: Dictionary = Progression.BUILDINGS[build_kind]
  hint.text = "%s 3×2 · %d дерева · %d камня · %d монет · [7] выбор" % [cost.name, cost.wood, cost.stone, cost.coins]
 if is_instance_valid(workshop_status): workshop_status.text = _production_status()
 if styled_tool != selected:
  styled_tool = selected
  for i in range(tool_buttons.size()):
   tool_buttons[i].add_theme_stylebox_override("normal", _panel_style("647451", "d7bd80") if selected == i else _panel_style("304a45", "5f7566"))
 overlay.color.a = clampf((minutes - 1050) / 600, 0, 0.35)

func _notify(text: String) -> void:
 if is_instance_valid(notice): notice.text = text
 notification_time = 4.5

func _open(title: String, body: String) -> void:
 workshop_status = null
 for child in modal_body.get_children():
  modal_body.remove_child(child)
  child.queue_free()
 modal_body.add_child(_label(title, 21))
 var desc := _label(body, 13, "c7d1b5")
 desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 desc.custom_minimum_size.x = 420
 modal_body.add_child(desc)
 modal.show()
 modal.reset_size()

func _close_button() -> void:
 modal_body.add_child(_button("Вернуться  [Esc]", func() -> void: modal.hide()))

func _home() -> void:
 _open("Дом, милый дом", "Сон восстанавливает энергию. Политые растения подрастут, а утром грядки снова потребуют воды.")
 modal_body.add_child(_button("Завершить день и сохранить", _sleep))
 _close_button()

func _shop() -> void:
 _open("Прилавок долины", "Монет: %d. Репа: %d. Ящики: %d.\nСемена: 5 за 20 монет. Репа: 35, ящик урожая: 120 монет." % [coins, bag.turnip, bag.crate])
 modal_body.add_child(_button("Купить 5 семян — 20 монет", _buy_seeds))
 modal_body.add_child(_button("Продать весь урожай", _sell))
 _close_button()

func _help() -> void:
 _open("Добро пожаловать в долину", "WASD / стрелки — движение.\n1–7 или колесо мыши — инструмент.\nЛКМ — действие по клетке рядом. E / пробел — перед собой.\nМотыга → семена → полив → отдых дома.\nРепа созревает за три политых дня. Собирайте рукой.\nПрилавок находится на дороге к востоку от дома.\n7 — каталог построек. Мастерская: доски, ящики, улучшения.\nЯщик урожая продаётся за 120 монет.\nF5 — сохранить, M — звук, Esc — пауза / закрыть.")
 _close_button()

func _save_game() -> bool:
 var data := {"version": SAVE_VERSION, "player": [player.x, player.y], "day": day, "minutes": minutes, "energy": energy, "coins": coins, "bag": bag, "quest": quest_stage, "experience": experience, "stored": stored, "progression": progression.state(), "workshop": [workshop.x, workshop.y] if workshop != Vector2i(-1, -1) else null, "plots": [], "resources": [], "buildings": []}
 for c in plots: data.plots.append([c.x, c.y, plots[c].stage, plots[c].wet])
 for c in resources: data.resources.append([c.x, c.y, resources[c].kind, resources[c].hp])
 for c in buildings: data.buildings.append([c.x, c.y])
 if web_platform != null:
  var success := bool(web_platform.save(save_path, JSON.stringify(data)))
  if not success: _notify("Браузер не разрешил сохранение. Проверьте настройки хранилища.")
  return success
 var file := FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
 if file == null: _notify("Не удалось записать сохранение"); return false
 file.store_string(JSON.stringify(data))
 file.close()
 var result := DirAccess.rename_absolute(save_path + ".tmp", save_path)
 if result != OK: _notify("Не удалось заменить сохранение"); return false
 return true

func _load_game() -> bool:
 var serialized := ""
 if web_platform != null:
  serialized = str(web_platform.load(save_path))
 else:
  if not FileAccess.file_exists(save_path): return false
  serialized = FileAccess.get_file_as_string(save_path)
 if serialized.is_empty(): return false
 var data: Variant = JSON.parse_string(serialized)
 if not _valid_save(data):
  load_warning = "Сохранение повреждено или несовместимо. Исходный слот сохранён."
  # Preserve the original and use a recovery slot for this session.
  save_path = "user://farm_recovery.json"
  return false
 player = Vector2(data.player[0], data.player[1])
 day = int(data.day)
 minutes = float(data.minutes)
 energy = int(data.energy)
 coins = int(data.coins)
 for key in bag: bag[key] = int(data.bag.get(key, 0))
 progression.restore(data.get("progression", {}))
 workshop = Vector2i(-1, -1)
 if data.get("workshop") != null: workshop = Vector2i(int(data.workshop[0]), int(data.workshop[1]))
 quest_stage = clampi(int(data.quest), 0, 5)
 experience = int(data.get("experience", 0))
 for key in stored: stored[key] = int(data.get("stored", {}).get(key, 0))
 plots.clear()
 for row in data.plots: plots[Vector2i(int(row[0]), int(row[1]))] = {"stage": int(row[2]), "wet": row[3]}
 resources.clear()
 for row in data.resources: resources[Vector2i(int(row[0]), int(row[1]))] = {"kind": row[2], "hp": int(row[3])}
 buildings.clear()
 for row in data.buildings: buildings.append(Vector2i(int(row[0]), int(row[1])))
 if not _can_stand(player): player = Vector2(19 * TILE, 17 * TILE)
 return true

func _valid_save(data: Variant) -> bool:
 if not data is Dictionary: return false
 for key in ["version", "player", "day", "minutes", "energy", "coins", "bag", "quest", "plots", "resources", "buildings"]:
  if not data.has(key): return false
 if data.version != SAVE_VERSION or not data.bag is Dictionary: return false
 if not progression.valid_state(data.get("progression", {})): return false
 if not _valid_workshop(data): return false
 if data.has("experience") and (not _number(data.experience) or data.experience < 0 or data.experience > 10000000): return false
 if data.has("stored"):
  if not data.stored is Dictionary: return false
  for key in stored:
   if not data.stored.has(key):
    if key in ["planks", "crate"]: continue
    return false
   if not _number(data.stored[key]) or data.stored[key] < 0 or data.stored[key] > 10000000: return false
 for key in bag:
  if not data.bag.has(key):
   if key in ["planks", "crate"]: continue
   return false
  if not _number(data.bag[key]) or data.bag[key] < 0 or data.bag[key] > 10000000: return false
 for key in ["day", "minutes", "energy", "coins", "quest"]:
  if not _number(data[key]): return false
 if data.day < 1 or data.minutes < 360 or data.minutes >= 1320 or data.energy < 0 or data.energy > 100 or data.coins < 0: return false
 if not data.player is Array or data.player.size() != 2: return false
 for n in data.player:
  if not _number(n) or n < 0 or n > 1200: return false
 for key in ["plots", "resources", "buildings"]:
  if not data[key] is Array or data[key].size() > WORLD.x * WORLD.y: return false
  var seen := {}
  for row in data[key]:
   if not row is Array or row.size() != (2 if key == "buildings" else 4): return false
   if not _number(row[0]) or not _number(row[1]): return false
   var c := Vector2i(int(row[0]), int(row[1]))
   if not _in_world(c) or water.has(c) or seen.has(c): return false
   seen[c] = true
   if key == "plots":
    if not _number(row[2]) or row[2] < -1 or row[2] > 3 or not row[3] is bool: return false
   if key == "resources":
    if row[2] not in ["tree", "rock"] or not _number(row[3]) or row[3] < 1 or row[3] > 3: return false
 return true

func _number(value: Variant) -> bool:
 return (value is int or value is float) and is_finite(float(value))

func _notification(what: int) -> void:
 if what == NOTIFICATION_WM_CLOSE_REQUEST:
  _save_game()

func _check(condition: bool, message: String) -> void:
 if not condition:
  push_error("FAIL: " + message)
  test_failures += 1
 else:
  print("PASS: " + message)

func _test_action(c: Vector2i, tool: int) -> bool:
 selected = tool
 action_cooldown = 0
 return _act(c)

func _self_test() -> void:
 print("=== Quiet Valley integration tests ===")
 player = Vector2(19 * TILE, 17 * TILE)
 var c := Vector2i(19, 18)
 _check(_test_action(c, 1), "prepare soil")
 _check(not _test_action(c, 1), "duplicate till rejected")
 _check(_test_action(c, 3) and bag.seeds == 7, "plant consumes seed")
 _check(not _test_action(c, 3), "occupied crop rejected")
 _check(_test_action(c, 2), "water crop")
 var before := energy
 _check(not _test_action(c, 2) and energy == before, "duplicate watering costs nothing")
 _sleep()
 _check(plots[c].stage == 1 and not plots[c].wet and energy == 100, "sleep advances watered crop and restores energy")
 _sleep()
 _check(plots[c].stage == 1, "dry crop does not grow")
 for i in range(2):
  _test_action(c, 2)
  _sleep()
 _check(plots[c].stage == 3, "three watered days mature crop")
 _check(_test_action(c, 0) and bag.turnip == 1, "harvest gives produce")
 _check(not _test_action(c, 0) and bag.turnip == 1, "cannot harvest twice")
 _sell()
 modal.hide()
 _check(coins == 115 and bag.turnip == 0, "sale exchanges produce for coins")
 _buy_seeds()
 modal.hide()
 _check(coins == 95 and bag.seeds == 12, "shop purchase")
 coins = 0
 var seeds: int = bag.seeds
 _buy_seeds()
 _check(bag.seeds == seeds, "insufficient money rejected")
 var tree := Vector2i(14, 16)
 player = Vector2(15 * TILE, 17 * TILE)
 _check(not _test_action(tree, 5), "wrong resource tool rejected")
 for i in range(3): _test_action(tree, 4)
 _check(not resources.has(tree) and bag.wood == 8, "tree takes three hits and yields wood")
 _check(not _test_action(Vector2i(40, 2), 1), "remote action rejected")
 player = Vector2(19 * TILE, 17 * TILE)
 energy = 0
 _check(not _test_action(Vector2i(20, 17), 1), "exhaustion blocks work")
 energy = 100
 player = Vector2(19.5 * TILE, 18.5 * TILE)
 var b := Vector2i(19, 19)
 _check(not _test_action(b, 6), "insufficient construction materials rejected")
 bag.wood = 20
 bag.stone = 10
 _check(_test_action(b, 6), "building placed with sufficient materials")
 _check(bag.wood == 0 and bag.stone == 0 and buildings.size() == 1, "building cost charged once")
 _check(_solid(b) and not _build_valid(b), "building blocks movement and overlapping construction")
 _check(not _build_valid(Vector2i(22, 17)), "roads protected from construction")
 _check(not _can_stand(Vector2(36 * TILE, 24 * TILE)), "pond collision")
 _check(not _can_stand(Vector2(0, 0)), "map boundary collision")
 _check(experience >= 23, "harvest, gathering and construction award experience")
 bag.wood = 4
 _move_storage(true)
 modal.hide()
 _check(bag.wood == 0 and stored.wood == 4, "warehouse deposit")
 _move_storage(false)
 modal.hide()
 _check(bag.wood == 4 and stored.wood == 0, "warehouse withdrawal")
 bag.wood = 0
 _check(_save_game(), "atomic save succeeds")
 var expected_player := player
 bag.wood = 999
 plots.clear()
 _check(_load_game() and bag.wood == 0 and plots.has(c) and player == expected_player and buildings.size() == 1, "save/load restores world, inventory and player")
 _check(not _valid_save({"version": 1}), "incomplete save rejected")
 _check(not _valid_save(null), "malformed save rejected")
 var reachable := _reachable_cells(Vector2i(19, 14))
 _check(_near_reachable(HOUSE.position + Vector2i(2, 3), reachable), "house entrance reachable from spawn")
 _check(_near_reachable(SHOP.position + Vector2i(1, 1), reachable), "shop reachable from spawn")
 _check(_near_reachable(Vector2i(15, 20), reachable) and _near_reachable(Vector2i(26, 16), reachable), "initial wood and stone reachable")
 _check(_near_reachable(b, reachable), "new warehouse accessible")
 _storage(b)
 stored.seeds = 2
 var original_seeds: int = bag.seeds
 _dismantle()
 _check(buildings.is_empty() and bag.wood == 20 and bag.stone == 10, "warehouse dismantle refunds materials")
 _check(bag.seeds == original_seeds + 2 and stored.seeds == 0, "last warehouse returns stored contents")
 var wood_before: int = bag.wood
 _dismantle()
 _check(bag.wood == wood_before, "dismantle cannot duplicate refunds")
 _home()
 _check(modal.visible, "home dialog opens")
 _sleep()
 _check(not modal.visible, "sleep closes dialog")
 _help()
 _check(modal.visible, "help opens")
 modal.hide()
 load("res://tests/progression_test.gd").new().run(self)
 DirAccess.remove_absolute(save_path)
 print("ALL INTEGRATION CHECKS PASSED" if test_failures == 0 else "%d CHECKS FAILED" % test_failures)
 get_tree().quit(0 if test_failures == 0 else 1)

func _capture() -> void:
 # Capture the live renderer; never writes to the player's save slot.
 await get_tree().process_frame
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("res://tests/first-frame.png")
 for y in range(15, 19):
  for x in range(17, 21):
   plots[Vector2i(x, y)] = {"stage": (x + y) % 4, "wet": y % 2 == 0}
 buildings.append(Vector2i(24, 15))
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("res://tests/farm-scene.png")
 _help()
 await get_tree().process_frame
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png("res://tests/help-screen.png")
 get_tree().quit()

func _gain_xp(amount: int) -> void:
 var old_level := 1 + experience / 25
 experience += amount
 if 1 + experience / 25 > old_level:
  energy = mini(100, energy + 10)
  _notify("Новый уровень хозяйства! +10 энергии")

func _storage(cell: Vector2i = Vector2i(-1, -1)) -> void:
 if cell != Vector2i(-1, -1): active_storage = cell
 _open("Склад усадьбы", "Запасы под надёжной крышей.
Дерево: %d   Камень: %d
Семена: %d   Репа: %d
Доски: %d   Ящики: %d" % [stored.wood, stored.stone, stored.seeds, stored.turnip, stored.planks, stored.crate])
 modal_body.add_child(_button("Оставить все запасы на складе", func() -> void: _move_storage(true)))
 modal_body.add_child(_button("Забрать все запасы", func() -> void: _move_storage(false)))
 if buildings.has(active_storage): modal_body.add_child(_button("Разобрать склад • вернуть материалы", _dismantle))
 _close_button()

func _move_storage(deposit: bool) -> void:
 for key in bag:
  if deposit:
   stored[key] += bag[key]
   bag[key] = 0
  else:
   bag[key] += stored[key]
   stored[key] = 0
 _save_game()
 _storage()

func _reachable_cells(start: Vector2i) -> Dictionary:
 var visited := {start: true}
 var pending: Array[Vector2i] = [start]
 var index := 0
 while index < pending.size():
  var current := pending[index]
  index += 1
  for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
   var next: Vector2i = current + offset
   if not visited.has(next) and not _solid(next):
    visited[next] = true
    pending.append(next)
 return visited

func _near_reachable(target: Vector2i, reachable: Dictionary) -> bool:
 for c in reachable:
  if Vector2(c).distance_to(Vector2(target)) <= 2.0: return true
 return false

func _dismantle() -> void:
 if not buildings.has(active_storage): return
 buildings.erase(active_storage)
 bag.wood += 20
 bag.stone += 10
 if buildings.is_empty():
  for key in bag:
   bag[key] += stored[key]
   stored[key] = 0
 active_storage = Vector2i(-1, -1)
 modal.hide()
 _save_game()
 _notify("Склад разобран. Материалы и запасы возвращены.")

func _web_ready() -> void:
 await get_tree().process_frame
 if web_platform != null: web_platform.ready()

func _web_lifecycle_save(_args: Array) -> void:
 _save_game()

func _catalog() -> void:
 _open("Постройки усадьбы", "Выберите здание, затем нажмите на свободный участок рядом с персонажем. Размер: 3×2 клетки.")
 for id in Progression.BUILDINGS:
  var kind: String = id
  var cost: Dictionary = Progression.BUILDINGS[id]
  var b := _button("%s · %d дерева · %d камня · %d монет" % [cost.name, cost.wood, cost.stone, cost.coins], func() -> void:
   build_kind = kind
   selected = 6
   modal.hide())
  b.disabled = id == "workshop" and workshop != Vector2i(-1, -1)
  modal_body.add_child(b)
 _close_button()

func _inventory_menu() -> void:
 _open("Рюкзак хозяина", "Монеты: %d. Инструменты: уровень %d / 3.\nЗапасы на складе нужно забрать перед использованием." % [coins, progression.tool_level])
 var names := {"wood": "Дерево", "stone": "Камень", "seeds": "Семена репы", "turnip": "Репа", "planks": "Доски", "crate": "Ящики урожая"}
 for key in bag:
  modal_body.add_child(_label("%s: %d" % [names[key], bag[key]], 14))
 _close_button()

func _workshop_menu() -> void:
 _open("Мастерская", "Производство идёт во время игры и сна. В меню время остановлено. Очередь: не более 3 заказов.")
 workshop_status = _label(_production_status(), 12, "d8c58e")
 modal_body.add_child(workshop_status)
 var boards := _button("2 доски · 4 дерева · 30 игровых минут", func() -> void: _start_recipe("planks"))
 boards.disabled = progression.jobs.size() >= Progression.MAX_QUEUE or bag.wood < 4
 modal_body.add_child(boards)
 var crates := _button("Ящик урожая · 2 доски + 1 репа · 60 минут", func() -> void: _start_recipe("crate"))
 crates.disabled = progression.jobs.size() >= Progression.MAX_QUEUE or bag.planks < 2 or bag.turnip < 1
 modal_body.add_child(crates)
 var collect_button := _button("Забрать готовую продукцию", _collect_products)
 collect_button.disabled = not progression.has_products()
 modal_body.add_child(collect_button)
 modal_body.add_child(_button("Улучшение инструментов · уровень %d / 3" % progression.tool_level, _upgrade_menu))
 var remove := _button("Разобрать мастерскую · вернуть материалы", _dismantle_workshop)
 remove.disabled = not progression.jobs.is_empty() or progression.has_products()
 modal_body.add_child(remove)
 _close_button()

func _production_status() -> String:
 var status := "Очередь пуста"
 if not progression.jobs.is_empty():
  var job: Dictionary = progression.jobs[0]
  status = "%s · ещё %d мин. · в очереди %d / 3" % [Progression.RECIPES[job.recipe].name, ceili(job.remaining), progression.jobs.size()]
 return status + "\nГотово: %d досок, %d ящиков" % [progression.products.planks, progression.products.crate]

func _start_recipe(id: String) -> bool:
 if workshop == Vector2i(-1, -1) or not progression.start_recipe(id, bag):
  _notify("Не хватает материалов или очередь заполнена"); return false
 _play("build")
 _save_game()
 _workshop_menu()
 return true

func _advance_production(game_minutes: float) -> void:
 var finished: int = progression.advance(game_minutes)
 if finished > 0:
  _notify("Заказ готов! Заберите продукцию в мастерской.")
  _save_game()

func _collect_products() -> void:
 if workshop == Vector2i(-1, -1): return
 var count: int = progression.collect(bag)
 if count > 0:
  _play("pick")
  _save_game()
  _notify("Продукция добавлена в рюкзак")
 _workshop_menu()

func _upgrade_menu() -> void:
 if progression.tool_level >= 3:
  _open("Инструменты мастера", "Достигнут максимальный уровень. Деревья и камни добываются за один удар. Работа стоит 1 энергию.")
 else:
  var cost: Dictionary = Progression.UPGRADES[progression.tool_level + 1]
  _open("Надёжные инструменты", "Уровень %d → %d. Цена: %d монет, %d досок, %d камня.\nТопор и кирка наносят больше урона, работа требует меньше энергии.\nСейчас: %d монет, %d досок, %d камня." % [progression.tool_level, progression.tool_level + 1, cost.coins, cost.planks, cost.stone, coins, bag.planks, bag.stone])
  var buy := _button("Улучшить инструменты", _upgrade_tools)
  buy.disabled = not progression.can_upgrade(bag, coins)
  modal_body.add_child(buy)
 modal_body.add_child(_button("К производству", _workshop_menu))
 _close_button()

func _upgrade_tools() -> bool:
 if workshop == Vector2i(-1, -1) or not progression.can_upgrade(bag, coins):
  _notify("Для улучшения нужны доски, камень и монеты"); return false
 coins = progression.upgrade(bag, coins)
 _play("build")
 _save_game()
 _upgrade_menu()
 _notify("Инструменты улучшены до уровня %d!" % progression.tool_level)
 return true

func _dismantle_workshop() -> bool:
 if workshop == Vector2i(-1, -1): return false
 if not progression.jobs.is_empty() or progression.has_products():
  _notify("Сначала завершите заказы и заберите продукцию"); return false
 var cost: Dictionary = Progression.BUILDINGS.workshop
 bag.wood += cost.wood
 bag.stone += cost.stone
 coins += cost.coins
 workshop = Vector2i(-1, -1)
 modal.hide()
 _save_game()
 _notify("Мастерская разобрана. Материалы возвращены.")
 return true

func _valid_workshop(data: Dictionary) -> bool:
 var value: Variant = data.get("workshop")
 if value == null:
  var state: Dictionary = data.get("progression", {})
  return state.get("jobs", []).is_empty() and state.get("products", {}).get("planks", 0) == 0 and state.get("products", {}).get("crate", 0) == 0
 if not value is Array or value.size() != 2: return false
 for n in value:
  if not _number(n) or float(n) != floorf(float(n)): return false
 var origin := Vector2i(int(value[0]), int(value[1]))
 var area := Rect2i(origin, Vector2i(3, 2))
 for y in range(origin.y, origin.y + 2):
  for x in range(origin.x, origin.x + 3):
   var c := Vector2i(x, y)
   if not _in_world(c) or water.has(c) or HOUSE.has_point(c) or SHOP.has_point(c) or c.x in [22, 23] or c.y in [12, 13]: return false
 for key in ["resources", "plots", "buildings"]:
  if not data[key] is Array: return false
  for row in data[key]:
   if not row is Array or row.size() < 2 or not _number(row[0]) or not _number(row[1]): return false
   var cell := Vector2i(int(row[0]), int(row[1]))
   if key == "buildings":
    if Rect2i(cell, Vector2i(3, 2)).intersects(area): return false
   elif area.has_point(cell): return false
 return true
