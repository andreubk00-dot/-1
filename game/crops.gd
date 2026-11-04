extends RefCounted
const SPECS := {
 "turnip": {"name":"Репа", "seed":"seeds", "days":3, "price":35, "pack":20, "row":0, "xp":5},
 "carrot": {"name":"Морковь", "seed":"carrot_seeds", "days":4, "price":55, "pack":30, "row":1, "xp":8}
}
static func from_seed(id: String) -> String:
 for crop in SPECS:
  if SPECS[crop].seed==id: return crop
 return ""
static func spec(plot: Dictionary) -> Dictionary:
 return SPECS.get(plot.get("crop","turnip"),SPECS.turnip)
