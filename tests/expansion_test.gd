extends RefCounted
const Hotbar=preload("res://game/hotbar.gd")
const Inventory=preload("res://game/inventory_layout.gd")
const Orders=preload("res://game/orders.gd")
func run(game: Node2D) -> void:
 var bar=Hotbar.new()
 var legacy: Array=bar.slots.duplicate()
 legacy[2]="build"
 legacy[8]="axe"
 game._check(bar.restore(legacy,2) and bar.slots[2]=="" and bar.slots[8]=="axe", "legacy construction slot is removed without moving other tools")
 game._check(not bar.assign(2,"build") and not bar.slots.has("build"), "construction cannot be assigned as an item")
 var inv=Inventory.new()
 var old: Array=inv.slots.duplicate()
 old[12]="build"
 game._check(inv.restore(old) and not inv.slots.has("build"), "legacy construction disappears from inventory too")
 var before: Array=game.hotbar.slots.duplicate()
 var active: int=game.hotbar.active
 game._begin_build("warehouse")
 game._check(game.building_mode and game.hotbar.slots==before and game.hotbar.active==active, "construction mode leaves active tool and hotbar untouched")
 game._cancel_build()
 game._check(not game.building_mode, "construction cancellation restores normal interaction")
 game._begin_build("warehouse")
 game._inventory_menu()
 game._check(not game.building_mode and game.hotbar.slots==before, "opening an ordinary window cancels construction mode safely")
 game.modal.hide()
 game.player=Vector2(19*24,17*24)
 var cell:=Vector2i(20,17)
 game.resources.erase(cell)
 game.plots.erase(cell)
 game.energy=100
 game._check(game._test_action(cell,1), "new crop starts on normal prepared soil")
 game.bag.carrot_seeds=1
 game._check(game._test_action(cell,6) and game.bag.carrot_seeds==0 and game.plots[cell].crop=="carrot", "carrot planting consumes the correct seed")
 for i in range(3):
  game._test_action(cell,2)
  game._sleep()
 game._check(game.plots[cell].stage==3 and not game._test_action(cell,0), "carrot is not ready after only three watered days")
 game._test_action(cell,2)
 game._sleep()
 game._check(game._test_action(cell,0) and game.bag.carrot==1, "four watered days produce harvestable carrot")
 game._check(not game._test_action(cell,0) and game.bag.carrot==1, "carrot cannot be harvested twice")
 var coins: int=game.coins
 game.bag.turnip=0
 game.bag.crate=0
 game._sell()
 game.modal.hide()
 game._check(game.coins==coins+55 and game.bag.carrot==0, "carrot sells at its own crop price")
 game.coins=30
 game._buy_seeds("carrot_seeds")
 game.modal.hide()
 game._check(game.coins==0 and game.bag.carrot_seeds==5, "carrot seed pack charges 30 coins for five")
 var model=Orders.new()
 var bag: Dictionary={"turnip":4,"carrot":4,"planks":6,"crate":2}
 game._check(model.submit(bag,1).is_empty() and bag.turnip==4, "incomplete order does not partially charge products")
 bag.turnip=5
 var reward: Dictionary=model.submit(bag,1)
 game._check(reward.coins==210 and bag.turnip==0 and model.completed==1, "order consumes exact products and awards quoted reward")
 game._check(model.submit(bag,1).is_empty() and bag.carrot==4, "only one delivery is allowed per game day")
 reward=model.submit(bag,2)
 game._check(reward.coins==280 and bag.carrot==0 and model.completed==2, "next-day order uses the new crop")
 game._check(model.restore(model.state()) and model.completed==2, "order progress survives serialization")
 game._check(not model.restore({"completed":2,"last_day":-1}) and model.completed==2, "invalid order data cannot mutate progress")
 game.orders=Orders.new()
 game.bag.turnip=5
 game.coins=0
 game.player=Vector2(456,336)
 game._check(not game._submit_order() and game.bag.turnip==5, "orders cannot be delivered remotely")
 game.player=Vector2(684,276)
 game._check(game._submit_order() and game.coins==210 and game.bag.turnip==0, "delivery works at the village shop")
 game.modal.hide()
 game._save_game()
 game.orders=Orders.new()
 game._check(game._load_game() and game.orders.completed==1, "farm save restores completed delivery")
 game.plots[cell]={"stage":2,"wet":true,"crop":"carrot"}
 game._save_game()
 game.plots.clear()
 game._check(game._load_game() and game.plots[cell].crop=="carrot" and game.plots[cell].stage==2, "save preserves crop identity and intermediate growth")
 var f:=FileAccess.open(game.save_path,FileAccess.READ)
 var saved: Dictionary=JSON.parse_string(f.get_as_text())
 f.close()
 game._check(saved.version==2,"new crop save format declares its schema version")
 saved.version=1
 saved.orders={"completed":0,"last_day":0}
 saved.plots=[[18,18,2,true]]
 saved.hotbar[6]="build"
 saved.inventory_layout[22]="build"
 saved.bag.erase("carrot")
 saved.bag.erase("carrot_seeds")
 saved.stored.erase("carrot")
 saved.stored.erase("carrot_seeds")
 var out:=FileAccess.open(game.save_path,FileAccess.WRITE)
 out.store_string(JSON.stringify(saved));out.close()
 game._check(game._load_game() and game.plots[Vector2i(18,18)].crop=="turnip" and not game.hotbar.slots.has("build") and game.bag.carrot==0, "v0.3 save migrates original crops, bag and build shortcuts safely")
 game._catalog()
 game._check(game.hud.window_tabs.visible and game.hud.window_tabs.get_child_count()==3, "construction is a separate persistent window tab")
 game.modal.hide()

 game.experience=0
 game.energy=10
 game._gain_xp(50)
 game._check(game.experience==50 and game.energy==30, "large order reward restores energy for each gained level")
