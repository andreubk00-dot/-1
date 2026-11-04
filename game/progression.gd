extends RefCounted
## Production and upgrades use game minutes, not wall-clock time.
## Inventory is charged only after all prerequisites have been checked.
const BUILDINGS := {
 "warehouse": {"name": "Склад", "wood": 20, "stone": 10, "coins": 0},
 "workshop": {"name": "Мастерская", "wood": 40, "stone": 20, "coins": 60}
}
const RECIPES := {
 "planks": {"name": "Доски", "cost": {"wood": 4}, "output": "planks", "count": 2, "minutes": 30.0},
 "crate": {"name": "Ящик урожая", "cost": {"planks": 2, "turnip": 1}, "output": "crate", "count": 1, "minutes": 60.0},
 "ingot": {"name":"Медный слиток", "cost":{"ore":3,"wood":1}, "output":"ingot", "count":1, "minutes":45.0}
}
const UPGRADES := {
 2: {"coins": 100, "planks": 4, "stone": 5},
 3: {"coins": 250, "planks": 10, "stone": 12}
}
const MAX_QUEUE := 3
var tool_level := 1
var jobs: Array[Dictionary] = []
var products := {"planks": 0, "crate": 0, "ingot":0}
var crates_sold := 0

func start_recipe(id: String, inventory: Dictionary) -> bool:
 if not RECIPES.has(id) or jobs.size() >= MAX_QUEUE: return false
 var recipe: Dictionary = RECIPES[id]
 for key in recipe.cost:
  if inventory.get(key, 0) < recipe.cost[key]: return false
 for key in recipe.cost: inventory[key] -= recipe.cost[key]
 jobs.append({"recipe": id, "remaining": float(recipe.minutes)})
 return true

func advance(game_minutes: float) -> int:
 if not is_finite(game_minutes) or game_minutes <= 0: return 0
 var completed := 0
 var budget := game_minutes
 while not jobs.is_empty() and budget > 0:
  var step := minf(budget, float(jobs[0].remaining))
  jobs[0].remaining -= step
  budget -= step
  if jobs[0].remaining > 0.00001: break
  var recipe: Dictionary = RECIPES[jobs[0].recipe]
  products[recipe.output] += recipe.count
  jobs.pop_front()
  completed += 1
 return completed

func collect(inventory: Dictionary) -> int:
 var count := 0
 for key in products:
  count += products[key]
  inventory[key] = int(inventory.get(key, 0)) + int(products[key])
  products[key] = 0
 return count

func has_products() -> bool:
 return products.planks > 0 or products.crate > 0 or products.ingot>0

func can_upgrade(inventory: Dictionary, coins: int) -> bool:
 if not UPGRADES.has(tool_level + 1): return false
 var cost: Dictionary = UPGRADES[tool_level + 1]
 return coins >= cost.coins and inventory.get("planks", 0) >= cost.planks and inventory.get("stone", 0) >= cost.stone

func upgrade(inventory: Dictionary, coins: int) -> int:
 if not can_upgrade(inventory, coins): return coins
 var cost: Dictionary = UPGRADES[tool_level + 1]
 inventory.planks -= cost.planks
 inventory.stone -= cost.stone
 tool_level += 1
 return coins - cost.coins

func state() -> Dictionary:
 return {"tool_level": tool_level, "jobs": jobs.duplicate(true), "products": products.duplicate(), "crates_sold": crates_sold}

func valid_state(value: Variant) -> bool:
 if not value is Dictionary: return false
 if value.is_empty(): return true # Compatibility with pre-production saves.
 for key in ["tool_level", "jobs", "products", "crates_sold"]:
  if not value.has(key): return false
 if not _integer(value.tool_level, 1, 3) or not _integer(value.crates_sold, 0, 10000000): return false
 if not value.jobs is Array or value.jobs.size() > MAX_QUEUE: return false
 for job in value.jobs:
  if not job is Dictionary or not job.has("recipe") or not job.has("remaining"): return false
  if not job.recipe is String or not RECIPES.has(job.recipe): return false
  if not job.remaining is float and not job.remaining is int: return false
  if not is_finite(float(job.remaining)) or job.remaining <= 0 or job.remaining > RECIPES[job.recipe].minutes: return false
 if not value.products is Dictionary: return false
 for key in products:
  if key=="ingot" and not value.products.has(key): continue
  if not value.products.has(key) or not _integer(value.products[key], 0, 10000000): return false
 return true

func restore(value: Variant) -> bool:
 if not valid_state(value): return false
 tool_level = 1
 jobs.clear()
 products = {"planks": 0, "crate": 0, "ingot":0}
 crates_sold = 0
 if value.is_empty(): return true
 tool_level = int(value.tool_level)
 crates_sold = int(value.crates_sold)
 for job in value.jobs: jobs.append({"recipe": job.recipe, "remaining": float(job.remaining)})
 for key in products: products[key] = int(value.products.get(key,0))
 return true

func _integer(value: Variant, minimum: int, maximum: int) -> bool:
 if not value is float and not value is int: return false
 return is_finite(float(value)) and float(value) == floorf(float(value)) and value >= minimum and value <= maximum
