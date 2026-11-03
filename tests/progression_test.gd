extends RefCounted
const Progression = preload("res://game/progression.gd")

func run(game: Node2D) -> void:
 var model = Progression.new()
 var bag := {"wood": 12, "stone": 30, "planks": 0, "turnip": 1, "crate": 0}
 game._check(not model.start_recipe("unknown", bag) and bag.wood == 12, "unknown recipe cannot charge inventory")
 game._check(not model.start_recipe("crate", bag) and bag.turnip == 1, "missing recipe materials do not partially charge")
 for i in range(3): game._check(model.start_recipe("planks", bag), "enqueue boards order %d" % i)
 game._check(not model.start_recipe("planks", bag) and bag.wood == 0, "production queue capacity enforced")
 game._check(model.advance(29) == 0 and model.products.planks == 0, "unfinished orders cannot be collected")
 game._check(model.advance(-100) == 0 and model.jobs[0].remaining == 1, "negative time cannot reverse production")
 game._check(model.advance(1) == 1 and model.products.planks == 2, "order completes at exact boundary")
 game._check(model.advance(60) == 2 and model.jobs.is_empty(), "surplus time advances subsequent queued orders")
 game._check(model.collect(bag) == 6 and bag.planks == 6, "collect completed output")
 game._check(model.collect(bag) == 0 and bag.planks == 6, "collect cannot duplicate production")
 game._check(model.start_recipe("crate", bag) and bag.planks == 4 and bag.turnip == 0, "crate recipe charges both ingredients")
 model.advance(60)
 model.collect(bag)
 game._check(bag.crate == 1, "crate output delivered")
 game._check(model.can_upgrade(bag, 100), "upgrade prerequisites checked")
 var coins: int = model.upgrade(bag, 100)
 game._check(coins == 0 and model.tool_level == 2 and bag.planks == 0 and bag.stone == 25, "upgrade charges once and increases level")
 game._check(model.upgrade(bag, 0) == 0 and model.tool_level == 2, "unaffordable upgrade has no effect")
 bag.planks = 10
 coins = model.upgrade(bag, 250)
 game._check(coins == 0 and model.tool_level == 3 and bag.planks == 0 and bag.stone == 13, "master tools use correct second upgrade cost")
 game._check(not model.can_upgrade(bag, 99999), "maximum tool level enforced")
 game._check(model.restore(model.state()) and model.tool_level == 3, "production state round trip")
 game._check(not model.restore({"tool_level": 99}) and model.tool_level == 3, "invalid state cannot partially mutate progression")
 game._check(model.restore({}) and model.tool_level == 1, "old save defaults to basic tools")
 game.workshop = Vector2i(24, 18)
 game.player = Vector2(19 * 24, 17 * 24)
 game.bag.wood = 4
 game._start_recipe("planks")
 game.modal.hide()
 game._check(not game._dismantle_workshop() and game.workshop == Vector2i(24, 18), "cannot dismantle active production")
 game._sleep()
 game._check(game.progression.jobs.is_empty() and game.progression.products.planks == 2, "sleep completes production queue")
 game._check(not game._dismantle_workshop(), "uncollected goods prevent dismantling")
 game._check(game._save_game(), "save workshop and completed goods")
 game.progression.products.planks = 0
 game.workshop = Vector2i(-1, -1)
 game._check(game._load_game() and game.workshop == Vector2i(24, 18) and game.progression.products.planks == 2, "reload restores workshop and uncollected goods")
 game._collect_products()
 game.modal.hide()
 game._check(game.bag.planks == 2 and not game.progression.has_products(), "world production collection")
 game.bag.planks = 4
 game.bag.stone = 10
 game.coins = 100
 game._check(game._upgrade_tools() and game.progression.tool_level == 2 and game.coins == 0, "world upgrade transaction")
 game.modal.hide()
 var c := Vector2i(20, 17)
 game.resources[c] = {"kind": "tree", "hp": 3}
 game.energy = 100
 game._test_action(c, 4)
 game._check(game.resources[c].hp == 1 and game.energy == 99, "upgraded axe applies damage and stamina benefits")
 game._test_action(c, 4)
 game._check(not game.resources.has(c), "level-two axe fells tree in two hits")
 game.bag.crate = 2
 game.bag.turnip = 0
 game._sell()
 game.modal.hide()
 game._check(game.coins == 240 and game.bag.crate == 0 and game.progression.crates_sold == 2, "manufactured crates sell at premium price")
 game._check(game._dismantle_workshop() and game.workshop == Vector2i(-1, -1) and game.progression.tool_level == 2, "dismantling retains earned tool upgrades")
 game._save_game()
 var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
 old.erase("progression")
 old.erase("workshop")
 old.bag.erase("planks")
 old.bag.erase("crate")
 old.stored.erase("planks")
 old.stored.erase("crate")
 game._check(game._valid_save(old), "pre-update save with original inventory is accepted")
 var f := FileAccess.open(game.save_path, FileAccess.WRITE)
 f.store_string(JSON.stringify(old))
 f.close()
 game._check(game._load_game() and game.bag.planks == 0 and game.bag.crate == 0 and game.progression.tool_level == 1, "old save migration initializes new fields without resetting farm")

 var target := Vector2i(20, 18)
 game.player = Vector2(19 * 24, 17 * 24)
 game.resources.erase(target)
 game.plots[target] = {"stage": -1, "wet": false}
 game.bag.seeds = 1
 game.selected = 1
 game.queued_action = target
 game.selected = 3
 game.action_cooldown = 0
 game.modal.hide()
 game._process(0.016)
 game._check(game.plots[target].stage == 0 and game.bag.seeds == 0 and game.queued_action == null, "queued world action uses tool selected in the same input frame")
 var energy_after: int = game.energy
 game._process(0.016)
 game._check(game.energy == energy_after, "queued input cannot repeat in following frames")
