extends RefCounted
const IDS := ["hand", "hoe", "water", "seeds", "axe", "pick", "build", "wood", "stone", "turnip", "planks", "crate", "bag", "coin", "energy", "sun", "moon", "leaf", "house", "warehouse", "workshop", "clock", "star", "book", "close", "sort", "arrow", "check", "hammer", "spark", "empty", "settings"]
const ACTIONS := ["hand", "hoe", "water", "seeds", "axe", "pick", "build"]
const NAMES := {"hand":"Свободная рука", "hoe":"Мотыга", "water":"Лейка", "seeds":"Семена репы", "axe":"Топор", "pick":"Кирка", "build":"Строительство", "wood":"Древесина", "stone":"Камень", "turnip":"Репа", "planks":"Доски", "crate":"Ящик урожая"}
const DESCRIPTIONS := {"hand":"Сбор урожая и взаимодействие с хозяйством.","hoe":"Подготавливает землю для посадки.","water":"Поливает грядки. Рост требует трёх политых дней.","seeds":"Посадите на подготовленную грядку, затем полейте.","axe":"Добывает древесину. Улучшения доступны в мастерской.","pick":"Добывает камень. Улучшения доступны в мастерской.","build":"Открывает каталог построек усадьбы.","wood":"Материал для построек и производства досок.","stone":"Материал для зданий и улучшения инструментов.","turnip":"Урожай. Продажа: 35 монет. Нужна для ящиков урожая.","planks":"Продукция мастерской. Нужна для ящиков и улучшений.","crate":"Готовая продукция для продажи за 120 монет."}
static var icons: Dictionary = {}
static func icon(id: String) -> Texture2D:
 if not IDS.has(id) or id.is_empty(): return null
 if not icons.has(id):
  var texture := AtlasTexture.new()
  texture.atlas = load("res://art/icons.png")
  var i := IDS.find(id)
  texture.region = Rect2((i % 8) * 32, (i / 8) * 32, 32, 32)
  icons[id] = texture
 return icons[id]
static func item_name(id: String) -> String:
 return NAMES.get(id, "Свободная ячейка")
