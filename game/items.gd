extends RefCounted
const IDS := ["hand", "hoe", "water", "seeds", "axe", "pick", "build", "wood", "stone", "turnip", "planks", "crate", "bag", "coin", "energy", "sun", "moon", "leaf", "house", "warehouse", "workshop", "clock", "star", "book", "close", "sort", "arrow", "check", "hammer", "spark", "empty", "settings", "carrot", "carrot_seeds", "orders", "rod", "berry", "fish", "ore", "ingot", "map", "rain", "person"]
const ACTIONS := ["hand", "hoe", "water", "seeds", "axe", "pick", "carrot_seeds", "rod", "berry"]
const NAMES := {"rod":"Удочка", "berry":"Лесные ягоды", "fish":"Озёрная рыба", "ore":"Медная руда", "ingot":"Медный слиток", "hand":"Свободная рука", "hoe":"Мотыга", "water":"Лейка", "seeds":"Семена репы", "axe":"Топор", "pick":"Кирка", "wood":"Древесина", "stone":"Камень", "turnip":"Репа", "planks":"Доски", "crate":"Ящик урожая", "carrot":"Морковь", "carrot_seeds":"Семена моркови"}
const DESCRIPTIONS := {"rod":"Нажмите на воду рядом. На зелёной полосе — E или кнопка действия. Заброс стоит 4 энергии.", "berry":"Съешьте из хотбара: +8 энергии. Куст восстанавливается через два дня.", "fish":"Свежий улов. Продажа: 45 монет. Нужен для поручения Саввы.", "ore":"Добывается киркой из камней в кряже. Переплавьте в мастерской.", "ingot":"3 руды + 1 дерево в мастерской. Нужен для поручения Бориса.", "hand":"Сбор урожая и взаимодействие с хозяйством.","hoe":"Подготавливает землю для посадки.","water":"Поливает грядки. Репе нужно 3 политых дня, моркови — 4.","seeds":"Посадите на подготовленную грядку, затем полейте.","axe":"Добывает древесину. Улучшения доступны в мастерской.","pick":"Добывает камень. Улучшения доступны в мастерской.","wood":"Материал для построек и производства досок.","stone":"Материал для зданий и улучшения инструментов.","turnip":"Урожай. Продажа: 35 монет. Нужна для ящиков урожая.","planks":"Продукция мастерской. Нужна для ящиков и улучшений.","crate":"Готовая продукция для продажи за 120 монет.","carrot":"Созревает за 4 политых дня. Продажа: 55 монет. Нужна для заказов.","carrot_seeds":"Посадите на грядку и поливайте четыре дня. Пакет из 5 семян стоит 30 монет."}
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
