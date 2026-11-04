extends CanvasLayer
const Items = preload("res://game/items.gd")
const Slot = preload("res://game/ui/item_slot.gd")
var game: Node2D
var font: Font
var root: Control
var modal: PanelContainer
var modal_body: VBoxContainer
var shade: ColorRect
var header_title: Label
var header_subtitle: Label
var header_icon: TextureRect
var window_tabs: HBoxContainer
var slots: Array[Button] = []
var money: Label
var day_label: Label
var time_label: Label
var weather_icon: TextureRect
var energy_label: Label
var energy_bar: ProgressBar
var xp_bar: ProgressBar
var level_label: Label
var goal: Label
var held_label: Label
var toast: Label
var dusk: ColorRect
var pause_shield: ColorRect
var tooltip: PanelContainer
var tooltip_title: Label
var tooltip_desc: Label
var view := ""
var pending_item := ""
var modal_notice := ""
var toast_modal_state := false
var inspection: VBoxContainer
var inventory_grid: GridContainer
var product_status: Label
var modal_scroll: ScrollContainer
var action_buttons: Dictionary = {}
var styles: Dictionary = {}

func setup(owner_game: Node2D) -> void:
 game = owner_game
 font = game.font
 root = Control.new()
 root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 root.mouse_filter = Control.MOUSE_FILTER_IGNORE
 add_child(root)
 dusk = ColorRect.new()
 dusk.size = Vector2(960,540)
 dusk.mouse_filter = Control.MOUSE_FILTER_IGNORE
 dusk.color = Color(0.12,0.18,0.28,0)
 root.add_child(dusk)
 _build_hud()
 shade = ColorRect.new()
 shade.size = Vector2(960,540)
 shade.color = Color(0.06,0.12,0.12,0.64)
 shade.hide()
 root.add_child(shade)
 _build_hotbar()
 _build_window()
 _build_tooltip()
 root.move_child(toast,root.get_child_count()-2)
 pause_shield=ColorRect.new()
 pause_shield.size=Vector2(960,540)
 pause_shield.color=Color(0,0,0,0)
 pause_shield.mouse_filter=Control.MOUSE_FILTER_STOP
 pause_shield.hide()
 root.add_child(pause_shield)

func style(bg: String, border: String = "715e44", radius: int = 7, padding: int = 12) -> StyleBoxFlat:
 var key := bg+border+str(radius)+str(padding)
 if styles.has(key): return styles[key]
 var s := StyleBoxFlat.new()
 s.bg_color = Color(bg)
 s.border_color = Color(border)
 s.set_border_width_all(2)
 s.set_corner_radius_all(radius)
 s.set_content_margin_all(padding)
 s.shadow_color = Color(0.06,0.12,0.10,0.25)
 s.shadow_size = 4
 s.shadow_offset = Vector2(0,3)
 styles[key]=s
 return s

func label(text: String, size: int = 13, color: String = "344b40") -> Label:
 var l := Label.new()
 l.text = text
 l.add_theme_font_override("font",font)
 l.add_theme_font_size_override("font_size",size)
 l.add_theme_color_override("font_color",Color(color))
 l.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return l

func icon(id: String, size: int = 32) -> TextureRect:
 var t := TextureRect.new()
 t.texture = Items.icon(id)
 t.custom_minimum_size = Vector2(size,size)
 t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 t.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return t

func button(text: String, callback: Callable, id: String = "", enabled: bool = true, token: String = "") -> Button:
 var b := Button.new()
 b.text = text
 b.custom_minimum_size.y = 36
 b.add_theme_font_override("font",font)
 b.add_theme_font_size_override("font_size",13)
 b.add_theme_color_override("font_color",Color("f3e6c5"))
 b.add_theme_color_override("font_disabled_color",Color("a3aa8d"))
 b.add_theme_stylebox_override("normal",style("496b54","304c40",5,8))
 b.add_theme_stylebox_override("hover",style("66815b","d0b67e",5,8))
 b.add_theme_stylebox_override("pressed",style("345744","d9c18c",5,8))
 b.add_theme_stylebox_override("disabled",style("7e8b72","697761",5,8))
 if id != "":
  b.icon = Items.icon(id)
  b.expand_icon = true
  b.add_theme_constant_override("icon_max_width",24)
  b.add_theme_constant_override("h_separation",6)
 b.focus_mode = Control.FOCUS_NONE
 b.disabled = not enabled
 b.pressed.connect(callback)
 if not token.is_empty(): action_buttons[token] = b
 return b

func panel(parent: Node, pos: Vector2, size: Vector2, dark: bool = true) -> PanelContainer:
 var p := PanelContainer.new()
 p.position = pos
 p.size = size
 p.add_theme_stylebox_override("panel",style("263f38" if dark else "e8d9b2","9b845a" if dark else "8e7753"))
 parent.add_child(p)
 return p

func _bar(color: String, height: int = 7) -> ProgressBar:
 var p := ProgressBar.new()
 p.show_percentage = false
 p.custom_minimum_size.y = height
 p.add_theme_stylebox_override("background",style("172e2a","172e2a",3,0))
 p.add_theme_stylebox_override("fill",style(color,color,3,0))
 return p

func _build_hud() -> void:
 var player_card := panel(root,Vector2(18,18),Vector2(226,98))
 var column := VBoxContainer.new()
 column.add_theme_constant_override("separation",5)
 player_card.add_child(column)
 var title := HBoxContainer.new()
 title.add_child(icon("leaf",26))
 title.add_child(label("ТИХАЯ ДОЛИНА",15,"eddbb0"))
 column.add_child(title)
 var info := HBoxContainer.new()
 info.add_child(icon("energy",18))
 energy_label = label("",11,"dcd4b6")
 info.add_child(energy_label)
 var space := Control.new()
 space.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 info.add_child(space)
 level_label=label("",11,"c5c899")
 info.add_child(level_label)
 column.add_child(info)
 energy_bar=_bar("b5c185",8)
 column.add_child(energy_bar)
 xp_bar=_bar("ccac66",3)
 column.add_child(xp_bar)
 var wallet := panel(root,Vector2(256,18),Vector2(124,43))
 var wallet_row := HBoxContainer.new()
 wallet_row.add_child(icon("coin",25))
 money=label("",16,"f0d494")
 wallet_row.add_child(money)
 wallet.add_child(wallet_row)
 var date := panel(root,Vector2(742,18),Vector2(200,94))
 var date_row := HBoxContainer.new()
 date_row.add_theme_constant_override("separation",10)
 weather_icon=icon("sun",42)
 date_row.add_child(weather_icon)
 var dates := VBoxContainer.new()
 day_label=label("",11,"c5c99f")
 time_label=label("",21,"efdfba")
 dates.add_child(day_label)
 dates.add_child(time_label)
 dates.add_child(label("ВЕСНА · ЯСНО",10,"aebd9c"))
 date_row.add_child(dates)
 date.add_child(date_row)
 var quest := panel(root,Vector2(18,130),Vector2(226,84))
 var quests := VBoxContainer.new()
 var qtitle := HBoxContainer.new()
 qtitle.add_child(icon("book",18))
 qtitle.add_child(label("ЗАПИСИ ХОЗЯИНА",10,"d9c18a"))
 quests.add_child(qtitle)
 goal=label("",12,"e0dfbc")
 goal.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 goal.custom_minimum_size=Vector2(192,34)
 quests.add_child(goal)
 quest.add_child(quests)
 for row in [["bag","I",144], ["build","B",205], ["orders","J",266], ["book","H",327]]:
  var id: String=row[0]
  var action: Callable=game._inventory_menu if id=="bag" else game._catalog if id=="build" else game._orders_menu if id=="orders" else game._help
  var b:=button(str(row[1]),action,id)
  b.position=Vector2(886,int(row[2]))
  b.size=Vector2(56,48)
  root.add_child(b)
 toast=label("",13,"f7e6be")
 toast.position=Vector2(200,386)
 toast.size=Vector2(560,28)
 toast.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 toast.add_theme_color_override("font_shadow_color",Color("203a31"))
 toast.add_theme_constant_override("shadow_offset_x",1)
 toast.add_theme_constant_override("shadow_offset_y",2)
 root.add_child(toast)
 held_label=label("",12,"f0dfb8")
 held_label.position=Vector2(180,428)
 held_label.size=Vector2(600,18)
 held_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 held_label.add_theme_color_override("font_shadow_color",Color("1d352f"))
 held_label.add_theme_constant_override("shadow_offset_y",1)
 root.add_child(held_label)

func _build_hotbar() -> void:
 var frame:=panel(root,Vector2(146,453),Vector2(668,75))
 frame.add_theme_stylebox_override("panel",style("263b31","a58b5a",7,8))
 var row:=HBoxContainer.new()
 row.add_theme_constant_override("separation",5)
 frame.add_child(row)
 for i in range(10):
  var slot=Slot.new()
  slot.ui_owner=self
  slot.source_index=i
  slot.number=str((i+1)%10)
  slot.custom_minimum_size=Vector2(60,57)
  slot.add_theme_stylebox_override("normal",style("354c3e","52634a",4,0))
  slot.add_theme_stylebox_override("hover",style("4b624a","d9be81",4,0))
  slot.add_theme_stylebox_override("pressed",style("68764d","edcf8b",4,0))
  slot.pressed.connect(func() -> void: slot_pressed(i))
  slot.gui_input.connect(func(event: InputEvent) -> void:
   if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT:
    game.hotbar.assign(i,"")
    game._sync_hotbar()
    game._save_game()
    refresh())
  slots.append(slot)
  row.add_child(slot)

func _build_window() -> void:
 modal=PanelContainer.new()
 modal.position=Vector2(100,30)
 modal.size=Vector2(760,404)
 modal.add_theme_stylebox_override("panel",style("e8d9b4","8f7954",8,18))
 root.add_child(modal)
 var outer:=VBoxContainer.new()
 outer.add_theme_constant_override("separation",10)
 modal.add_child(outer)
 var header:=HBoxContainer.new()
 header.add_theme_constant_override("separation",12)
 header_icon=icon("bag",42)
 header.add_child(header_icon)
 var titles:=VBoxContainer.new()
 titles.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 header_title=label("",23)
 header_subtitle=label("",11,"68775d")
 header_subtitle.clip_text=true
 header_subtitle.custom_minimum_size.x=180
 titles.add_child(header_title)
 titles.add_child(header_subtitle)
 header.add_child(titles)
 window_tabs=HBoxContainer.new()
 window_tabs.add_theme_constant_override("separation",4)
 header.add_child(window_tabs)
 var close:=button("",func() -> void: modal.hide(),"close")
 close.custom_minimum_size=Vector2(36,36)
 header.add_child(close)
 outer.add_child(header)
 var separator:=HSeparator.new()
 outer.add_child(separator)
 modal_scroll=ScrollContainer.new()
 modal_scroll.custom_minimum_size=Vector2(716,280)
 modal_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
 modal_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 outer.add_child(modal_scroll)
 modal_body=VBoxContainer.new()
 modal_body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 modal_body.add_theme_constant_override("separation",10)
 modal_scroll.add_child(modal_body)
 modal.visibility_changed.connect(func() -> void:
  shade.visible=modal.visible
  if game.web_platform!=null: game.web_platform.setModal(modal.visible)
  hide_tooltip()
  if not modal.visible:
   pending_item=""
   view=""
   game.queued_action=null)
 modal.hide()

func _build_tooltip() -> void:
 tooltip=panel(root,Vector2.ZERO,Vector2(270,76))
 tooltip.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var v:=VBoxContainer.new()
 v.mouse_filter=Control.MOUSE_FILTER_IGNORE
 tooltip.add_child(v)
 tooltip_title=label("",14,"e9cb8e")
 tooltip_desc=label("",11,"d0d6b7")
 tooltip_desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 tooltip_desc.custom_minimum_size.x=240
 v.add_child(tooltip_title)
 v.add_child(tooltip_desc)
 tooltip.hide()

func show_tooltip(id: String) -> void:
 if id=="": return
 tooltip_title.text=Items.item_name(id)
 tooltip_desc.text=Items.DESCRIPTIONS.get(id,"")
 tooltip.reset_size()
 tooltip.show()
func hide_tooltip() -> void:
 if is_instance_valid(tooltip): tooltip.hide()

func open_window(title: String, subtitle: String, id: String, kind: String) -> void:
 game.building_mode=false
 game.queued_action=null
 pending_item=""
 modal_notice=""
 product_status=null
 inspection=null
 inventory_grid=null
 action_buttons.clear()
 hide_tooltip()
 for child in modal_body.get_children():
  modal_body.remove_child(child)
  child.queue_free()
 header_title.text=title
 header_subtitle.text=subtitle
 header_icon.texture=Items.icon(id)
 view=kind
 for child in window_tabs.get_children():
  window_tabs.remove_child(child)
  child.queue_free()
 window_tabs.visible=kind in ["inventory","catalog","orders"]
 if window_tabs.visible:
  for tab in [["inventory","bag","I"],["catalog","build","B"],["orders","orders","J"]]:
   var target: String=tab[0]
   var action: Callable=game._inventory_menu if target=="inventory" else game._catalog if target=="catalog" else game._orders_menu
   var b:=button({"inventory":"Рюкзак","catalog":"Постройки","orders":"Заказы"}[target],action,tab[1])
   b.add_theme_constant_override("icon_max_width",18)
   b.custom_minimum_size.x=108 if target=="catalog" else 92
   b.tooltip_text={"inventory":"Инвентарь","catalog":"Строительство","orders":"Заказы"}[target]
   if target==kind: b.add_theme_stylebox_override("normal",style("74815a","b69a61",5,8))
   window_tabs.add_child(b)
 modal_scroll.scroll_vertical=0
 modal.show()
 modal.modulate.a=0
 var tween:=create_tween()
 tween.tween_property(modal,"modulate:a",1.0,0.12)

func row_card(id: String, title: String, description: String) -> VBoxContainer:
 var card:=PanelContainer.new()
 card.add_theme_stylebox_override("panel",style("f3e7c8","c6b58d",5,12))
 var row:=HBoxContainer.new()
 row.add_theme_constant_override("separation",14)
 card.add_child(row)
 row.add_child(icon(id,48))
 var column:=VBoxContainer.new()
 column.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 column.add_child(label(title,16))
 var desc:=label(description,12,"758067")
 desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 column.add_child(desc)
 row.add_child(column)
 modal_body.add_child(card)
 return column

func cost_text(cost: Dictionary) -> String:
 var parts:=PackedStringArray()
 for id in cost:
  if id not in ["wood","stone","coins","planks"]: continue
  if int(cost[id])>0: parts.append(str(cost[id])+" "+{"wood":"дерева","stone":"камня","coins":"монет","planks":"досок"}.get(id,id))
 return " · ".join(parts)

func show_inventory() -> void:
 open_window("Рюкзак хозяина","ПРЕДМЕТЫ И ИНСТРУМЕНТЫ     /     ПАНЕЛЬ БЫСТРОГО ДОСТУПА","bag","inventory")
 var split:=HBoxContainer.new()
 split.add_theme_constant_override("separation",20)
 modal_body.add_child(split)
 var left:=VBoxContainer.new()
 left.custom_minimum_size.x=380
 split.add_child(left)
 left.add_child(label("ВАШИ ПРЕДМЕТЫ",10,"68775d"))
 inventory_grid=GridContainer.new()
 inventory_grid.columns=6
 inventory_grid.add_theme_constant_override("h_separation",6)
 inventory_grid.add_theme_constant_override("v_separation",6)
 left.add_child(inventory_grid)
 rebuild_inventory()
 inspection=VBoxContainer.new()
 inspection.custom_minimum_size.x=290
 inspection.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 inspection.add_theme_constant_override("separation",9)
 split.add_child(inspection)
 inspect_item("hoe")
 modal_body.add_child(label("В инвентаре — перемещение, на хотбар — назначение. ПКМ по хотбару — очистить ячейку.",11,"68775d"))

func inspect_item(id: String) -> void:
 pending_item=id
 for child in inspection.get_children():
  inspection.remove_child(child)
  child.queue_free()
 var top:=HBoxContainer.new()
 top.add_child(icon(id,48))
 top.add_child(label(Items.item_name(id),18))
 inspection.add_child(top)
 var desc:=label(Items.DESCRIPTIONS.get(id,"Перетащите сюда предмет, чтобы изменить его положение."),13,"69785e")
 desc.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 desc.custom_minimum_size=Vector2(260,62)
 inspection.add_child(desc)
 var quantity: String="Постоянный инструмент" if id!="" else ""
 if game.bag.has(id): quantity="В рюкзаке: %d"%game.bag[id]
 if id in ["axe","pick","hoe","water"]: quantity="Уровень инструментов: %d / 3"%game.progression.tool_level
 inspection.add_child(label(quantity,12))
 inspection.add_child(button("Назначить на панель",func() -> void:
  pending_item=id
  game._notify("Выберите ячейку хотбара внизу экрана"),"arrow",id!=""))
 inspection.add_child(button("Сбросить хотбар",func() -> void:
  game.hotbar=load("res://game/hotbar.gd").new()
  game._sync_hotbar()
  game._save_game()
  refresh(),"sort"))

func slot_pressed(index: int) -> void:
 if modal.visible:
  if view=="inventory" and pending_item!="":
   game.hotbar.assign(index,pending_item)
   game._sync_hotbar()
   game._save_game()
   refresh()
  return
 game._select_slot(index)

func drop_on_slot(index: int, data: Dictionary) -> void:
 if data.get("from")=="hotbar": game.hotbar.swap(int(data.slot),index)
 else: game.hotbar.assign(index,str(data.item))
 game._sync_hotbar()
 game._save_game()
 refresh()
 hide_tooltip()

func show_catalog() -> void:
 open_window("Строительство","ОБУСТРОЙСТВО УСАДЬБЫ     /     ВЫБЕРИТЕ ПОСТРОЙКУ","build","catalog")
 for id in game.Progression.BUILDINGS:
  var kind: String=id
  var cost: Dictionary=game.Progression.BUILDINGS[id]
  var column:=row_card(id,cost.name,"3 × 2 клетки · "+cost_text(cost))
  var enabled: bool=not (id=="workshop" and game.workshop!=Vector2i(-1,-1))
  var text: String="Построить" if enabled else "Уже построено"
  column.add_child(button(text,func() -> void:
   game._begin_build(kind),"hammer",enabled,"build_"+id))
 modal_body.add_child(label("Выберите здание и место рядом. Красный контур — поставить нельзя. ПКМ / Esc — отменить.",11,"68775d"))

func show_home() -> void:
 open_window("Дом, милый дом","ТИШИНА ВЕЧЕРА     /     ОТДЫХ И НОВЫЙ ДЕНЬ","house","home")
 var column:=row_card("moon","До нового рассвета","Энергия полностью восстановится. Политые растения подрастут, а мастерская завершит ночные заказы.")
 column.add_child(button("Отдохнуть до утра",game._sleep,"moon",true,"sleep"))
 modal_body.add_child(label("Растения растут после полива. Сухая грядка не потеряет урожай, но её рост остановится.",12,"68775d"))

func show_shop() -> void:
 open_window("Прилавок долины","СЕМЕНА И УРОЖАЙ     /     У ВАС %d МОНЕТ"%game.coins,"coin","shop")
 var seeds:=row_card("seeds","Семена для огорода","Репа: 3 политых дня · Морковь: 4 политых дня")
 var offers:=HBoxContainer.new()
 for id in ["seeds","carrot_seeds"]:
  var seed: String=id
  var price: int=20 if id=="seeds" else 30
  var b:=button("5 репы · 20 монет" if id=="seeds" else "5 моркови · 30 монет",func() -> void: game._buy_seeds(seed),id,game.coins>=price,"buy_"+id)
  b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  offers.add_child(b)
 seeds.add_child(offers)
 var earned: int=game.bag.turnip*35+game.bag.carrot*55+game.bag.crate*120
 var produce:=row_card("crate","Ваш урожай","Репа: %d × 35 · Морковь: %d × 55 · Ящики: %d × 120"%[game.bag.turnip,game.bag.carrot,game.bag.crate])
 produce.add_child(button("Продать всё · %d монет"%earned,game._sell,"coin",earned>0,"sell"))

func show_workshop() -> void:
 open_window("Мастерская","РЕМЕСЛО И ПРОИЗВОДСТВО     /     ЗАКАЗЫ ИДУТ ВО ВРЕМЯ ИГРЫ И СНА","workshop","workshop")
 var tabs:=HBoxContainer.new()
 tabs.add_child(button("Производство",show_workshop,"planks"))
 tabs.add_child(button("Инструменты · ур. %d"%game.progression.tool_level,game._upgrade_menu,"axe",true,"tools"))
 tabs.add_child(button("Здание",func() -> void: manage_building("workshop"),"workshop",true,"manage_workshop"))
 modal_body.add_child(tabs)
 product_status=label(game._production_status(),12,"6c775d")
 modal_body.add_child(product_status)
 var rows:=HBoxContainer.new()
 rows.add_theme_constant_override("separation",10)
 modal_body.add_child(rows)
 for id in game.Progression.RECIPES:
  var recipe: String=id
  var spec: Dictionary=game.Progression.RECIPES[id]
  var p:=PanelContainer.new()
  p.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  p.add_theme_stylebox_override("panel",style("f3e7c8","c6b58d",5,12))
  var col:=VBoxContainer.new()
  col.add_theme_constant_override("separation",6)
  p.add_child(col)
  var r:=HBoxContainer.new()
  r.add_child(icon(id,36))
  r.add_child(label("2 доски" if id=="planks" else "Ящик урожая",16))
  col.add_child(r)
  col.add_child(label("4 дерева · 30 мин." if id=="planks" else "2 доски + 1 репа · 60 мин.",12,"68775d"))
  var enabled: bool=game.progression.jobs.size()<3
  for material in spec.cost:
   if game.bag[material]<spec.cost[material]: enabled=false
  col.add_child(button("В очередь",func() -> void: game._start_recipe(recipe),"hammer",enabled,"recipe_"+id))
  rows.add_child(p)
 modal_body.add_child(button("Забрать готовое · %d досок, %d ящиков"%[game.progression.products.planks,game.progression.products.crate],game._collect_products,"crate",game.progression.has_products(),"collect"))

func show_upgrade() -> void:
 open_window("Инструменты мастера","ПРОЧНОСТЬ И ЭФФЕКТИВНОСТЬ     /     ТЕКУЩИЙ УРОВЕНЬ %d / 3"%game.progression.tool_level,"axe","upgrade")
 var top:=HBoxContainer.new()
 top.add_child(icon("axe",56))
 top.add_child(icon("pick",56))
 top.add_child(icon("hoe",56))
 top.add_child(icon("water",56))
 modal_body.add_child(top)
 if game.progression.tool_level>=3:
  modal_body.add_child(label("Ваши инструменты достигли максимального уровня.",17))
 else:
  var cost: Dictionary=game.Progression.UPGRADES[game.progression.tool_level+1]
  var column:=row_card("star","Уровень %d → %d"%[game.progression.tool_level,game.progression.tool_level+1],cost_text(cost))
  column.add_child(label("Быстрее добыча дерева и камня. Работа стоит 1 энергию.",12,"68775d"))
  column.add_child(button("Улучшить инструменты",game._upgrade_tools,"hammer",game.progression.can_upgrade(game.bag,game.coins),"upgrade"))
 modal_body.add_child(button("К производству",game._workshop_menu,"workshop"))

func show_storage() -> void:
 open_window("Склад усадьбы","ЗАПАСЫ ХОЗЯЙСТВА     /     ОБЩЕЕ ХРАНИЛИЩЕ ВСЕХ СКЛАДОВ","warehouse","storage")
 var grid:=GridContainer.new()
 grid.columns=3
 grid.add_theme_constant_override("h_separation",12)
 grid.add_theme_constant_override("v_separation",10)
 modal_body.add_child(grid)
 for id in game.stored:
  var row:=HBoxContainer.new()
  row.custom_minimum_size.x=220
  row.add_child(icon(id,32))
  row.add_child(label("%s · %d"%[Items.item_name(id),game.stored[id]],13))
  grid.add_child(row)
 var buttons:=HBoxContainer.new()
 buttons.add_child(button("Оставить запасы",func() -> void: game._move_storage(true),"bag",true,"deposit"))
 buttons.add_child(button("Забрать запасы",func() -> void: game._move_storage(false),"arrow",true,"withdraw"))
 modal_body.add_child(buttons)
 if game.buildings.has(game.active_storage): modal_body.add_child(button("Управление складом",func() -> void: manage_building("warehouse"),"warehouse",true,"manage_storage"))

func show_help() -> void:
 open_window("Записи хозяина","УПРАВЛЕНИЕ И ПЕРВЫЕ ШАГИ","book","help")
 row_card("hoe","Первый урожай","Мотыга → семена → полив. Репе нужно 3 политых дня, моркови — 4. Урожай собирается свободной рукой. Отдохните в доме, чтобы начать новый день.")
 row_card("bag","Всё под рукой","I или Tab — инвентарь. Перетащите инструменты и предметы в любые ячейки хотбара. 1–9 и 0 выбирают ячейку; колесо — соседнюю. ПКМ очищает ячейку.")
 row_card("build","Развивайте хозяйство","B — отдельная вкладка построек, J — заказы. В мастерской делайте доски и ящики урожая, улучшайте инструменты. WASD — движение, ЛКМ — работа рядом, E — перед собой. F5 — сохранить, M — звук, Esc — закрыть окно.")

func refresh() -> void:
 game.inventory_layout.reconcile(game.bag)
 money.text=str(game.coins)
 energy_label.text="Энергия %d / 100"%game.energy
 energy_bar.value=game.energy
 level_label.text="УР. %d"%(1+game.experience/25)
 xp_bar.max_value=25
 xp_bar.value=game.experience%25
 day_label.text="ДЕНЬ %02d"%game.day
 time_label.text="%02d:%02d"%[int(game.minutes)/60,int(game.minutes)%60]
 weather_icon.texture=Items.icon("moon" if game.minutes>=1080 else "sun")
 var goals: Array=["Подготовьте первую грядку","Посадите семена репы","Поливайте и отдыхайте дома","Продайте первый урожай","Постройте склад [B]"]
 var text: String=goals[mini(game.quest_stage,4)]
 if game.quest_stage>=5:
  if game.workshop==Vector2i(-1,-1): text="Постройте мастерскую [B]"
  elif game.progression.tool_level==1: text="Изготовьте доски и улучшите инструменты"
  elif game.progression.crates_sold==0: text="Продайте первый ящик урожая"
  elif game.orders.completed==0: text="Выполните первый заказ [J]"
  else: text="Заказы выполнены: %d · Следующий урожай!"%game.orders.completed
 goal.text=text
 var held: String=game.temporary_item if game.temporary_item!="" else game.hotbar.slots[game.hotbar.active]
 held_label.text=Items.item_name(held)
 if held in ["axe","pick","hoe","water"]: held_label.text+=" · ур. %d"%game.progression.tool_level
 if game.building_mode:
  var cost: Dictionary=game.Progression.BUILDINGS[game.build_kind]
  held_label.text="%s · %s · ПКМ / Esc: отмена"%[cost.name,cost_text(cost)]
 if not game.building_mode and not modal.visible and game.plots.has(game.hovered) and game.plots[game.hovered].stage>=0:
  var plot: Dictionary=game.plots[game.hovered]
  var crop: Dictionary=game.Crops.spec(plot)
  held_label.text+=" · %s %d/%d · %s"%[crop.name,plot.stage,crop.days,"Готово" if plot.stage>=crop.days else "Полито" if plot.wet else "Нужна вода"]
 if pending_item!="" and view=="inventory": held_label.text="Назначить: "+Items.item_name(pending_item)+" · выберите ячейку"
 for i in range(slots.size()):
  var slot=slots[i]
  var id: String=game.hotbar.slots[i]
  var amount: int=int(game.bag[id]) if game.bag.has(id) else -1
  if slot.item_id!=id or slot.amount!=amount or slot.active!=(game.hotbar.active==i and game.temporary_item=="" and not game.building_mode):
   slot.item_id=id
   slot.amount=amount
   slot.active=game.hotbar.active==i and game.temporary_item=="" and not game.building_mode
   slot.add_theme_stylebox_override("normal",style("5f704b","e5c683",4,0) if slot.active else style("354c3e","52634a",4,0))
   slot.queue_redraw()
 toast.visible=game.notification_time>0 and (not modal.visible or modal_notice!="")
 if toast_modal_state!=modal.visible:
  toast_modal_state=modal.visible
  toast.position=Vector2(200,408 if modal.visible else 386)
  toast.add_theme_color_override("font_color",Color("344b40" if modal.visible else "f7e6be"))
  toast.add_theme_color_override("font_shadow_color",Color("e8d9b4" if modal.visible else "203a31"))
 held_label.visible=not modal.visible
 dusk.color.a=clampf((game.minutes-1050)/600,0,0.35)
 if is_instance_valid(product_status): product_status.text=game._production_status()
 if tooltip.visible:
  var mouse:=root.get_global_mouse_position()
  tooltip.position=Vector2(clampf(mouse.x+16,8,680),clampf(mouse.y-tooltip.size.y-12,8,420))

func manage_building(id: String) -> void:
 var workshop: bool=id=="workshop"
 open_window("Управление зданием","РАЗБОР И ВОЗВРАТ МАТЕРИАЛОВ",id,"manage")
 var cost: Dictionary=game.Progression.BUILDINGS[id]
 var column:=row_card(id,cost.name,"Вернётся в рюкзак: "+cost_text(cost))
 var allowed: bool=not workshop or (game.progression.jobs.is_empty() and not game.progression.has_products())
 var desc: String="Улучшения инструментов сохранятся. Сначала завершите заказы и заберите готовые товары." if workshop else "При разборе последнего склада все запасы будут возвращены в рюкзак."
 column.add_child(label(desc,12,"68775d"))
 column.add_child(button("Разобрать здание",game._dismantle_workshop if workshop else game._dismantle,"hammer",allowed,"remove_workshop" if workshop else "remove_storage"))
 modal_body.add_child(button("Вернуться",game._workshop_menu if workshop else game._storage,id))

func rebuild_inventory() -> void:
 game.inventory_layout.reconcile(game.bag)
 for child in inventory_grid.get_children():
  inventory_grid.remove_child(child)
  child.queue_free()
 for i in range(24):
  var index: int=i
  var item: String=game.inventory_layout.slots[i]
  var slot=Slot.new()
  slot.item_id=item
  slot.source_index=i
  slot.amount=int(game.bag[item]) if game.bag.has(item) else -1
  slot.ui_owner=self
  slot.is_inventory=true
  slot.custom_minimum_size=Vector2(56,54)
  slot.add_theme_stylebox_override("normal",style("ddcca4" if item!="" else "e2d4af","b5a17c" if item!="" else "caba94",4,0))
  slot.add_theme_stylebox_override("hover",style("efe1b8","9b7947",4,0))
  slot.add_theme_stylebox_override("pressed",style("cbba8c","6b7955",4,0))
  slot.pressed.connect(func() -> void: inspect_item(str(game.inventory_layout.slots[index])))
  inventory_grid.add_child(slot)

func drop_into_inventory(index: int, data: Dictionary) -> void:
 var source: int=game.inventory_layout.slots.find(str(data.item))
 if source<0: return
 game.inventory_layout.swap(source,index)
 game._save_game()
 rebuild_inventory()
 hide_tooltip()

func block_pointer(blocked: bool) -> void:
 pause_shield.visible=blocked
 if blocked: hide_tooltip()

func show_orders() -> void:
 open_window("Заказы долины","ДОСТАВКА ПРОДУКЦИИ     /     СДАЙТЕ ЗАКАЗ У ПРИЛАВКА","orders","orders")
 var offer: Dictionary=game.orders.current()
 if game.day<=game.orders.last_day:
  row_card("check","На сегодня всё выполнено","Следующий заказ появится утром. Выполнено заказов: %d"%game.orders.completed)
  return
 var column:=row_card("orders",offer.name,offer.customer+" · Награда: %d монет и %d опыта"%[offer.coins,offer.xp])
 var row:=HBoxContainer.new()
 row.add_theme_constant_override("separation",14)
 for id in offer.cost:
  var part:=HBoxContainer.new()
  part.add_child(icon(id,30))
  part.add_child(label("%s · %d / %d"%[Items.item_name(id),game.bag[id],offer.cost[id]],13))
  row.add_child(part)
 column.add_child(row)
 column.add_child(button("Сдать заказ",game._submit_order,"check",game._can_deliver() and game.orders.can_submit(game.bag,game.day),"submit_order"))
 var text: String="Заказ можно сдать здесь." if game._can_deliver() else "Подойдите к прилавку долины, чтобы сдать продукцию."
 modal_body.add_child(label(text,12,"68775d"))
 modal_body.add_child(label("Не более одного заказа в день. Продукция расходуется только при успешной сдаче.",11,"68775d"))
