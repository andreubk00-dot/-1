extends RefCounted
const Frontier=preload("res://game/frontier.gd")
const Fishing=preload("res://game/fishing.gd")
const Progression=preload("res://game/progression.gd")
func run(game: Node2D) -> void:
 var model=Frontier.new()
 var bag: Dictionary={"berry":0,"fish":3,"ingot":3}
 var bush: Vector2i=Frontier.BUSHES[0]
 game._check(game.WORLD==Vector2i(96,64),"expanded world has 6144 cells without moving original landmarks")
 game._check(Frontier.region(Vector2i(19,14))=="farm" and Frontier.region(Vector2i(50,10))=="forest" and Frontier.region(Vector2i(64,25))=="lake" and Frontier.region(Vector2i(57,40))=="ridge","four regions map to their actual landmarks")
 game._check(model.gather(bush,1,bag) and bag.berry==2,"ready berry bush awards two berries")
 game._check(not model.gather(bush,1,bag) and not model.gather(bush,2,bag) and bag.berry==2,"picked bush cannot duplicate berries before cooldown")
 game._check(model.gather(bush,3,bag) and bag.berry==4,"berry bush recovers after two days")
 game._check(not model.gather(Vector2i.ZERO,3,bag),"foraging requires a real bush")
 game._check(model.complete("lina",bag).is_empty() and bag.berry==4,"villager cannot partially charge missing goods")
 bag.berry=6
 var reward: Dictionary=model.complete("lina",bag)
 game._check(reward.coins==160 and bag.berry==0 and model.completed.has("lina"),"villager awards exact one-time reward")
 bag.berry=6
 game._check(model.complete("lina",bag).is_empty() and bag.berry==6,"completed villager request cannot pay twice")
 var state: Dictionary=model.state()
 game._check(model.restore(state,3) and model.picked[bush]==3,"forage cooldown and villager state round trip")
 state.picked[0][2]=4
 game._check(not model.restore(state,3) and model.picked[bush]==3,"future forage timestamps cannot mutate progress")
 state=model.state();state.completed=["lina","lina"]
 game._check(not model.valid(state,3),"duplicate quest completion data rejected")
 var fishing=Fishing.new()
 fishing.cast(Vector2i(36,20),1)
 game._check(fishing.active and not fishing.ready() and not fishing.reel(),"early fishing input cannot award a fish")
 fishing.cast(Vector2i(36,20),1)
 fishing.advance(fishing.bite_at)
 game._check(fishing.ready() and fishing.reel() and not fishing.active,"fishing bite window awards one catch")
 game._check(not fishing.reel(),"same bite cannot be reeled twice")
 fishing.cast(Vector2i(36,20),1)
 game._check(fishing.advance(10) and not fishing.active,"missed bite expires without reward")
 fishing.cast(Vector2i(36,20),1)
 fishing.advance(-1)
 game._check(fishing.elapsed==0,"negative fishing time is ignored")
 fishing.cancel()
 game._check(not fishing.active,"fishing cancellation clears transient state")
 var production=Progression.new()
 var ingredients: Dictionary={"ore":2,"wood":4,"ingot":0}
 game._check(not production.start_recipe("ingot",ingredients) and ingredients.wood==4,"smelting cannot partially charge missing ore")
 ingredients.ore=3
 game._check(production.start_recipe("ingot",ingredients) and ingredients.ore==0 and ingredients.wood==3,"smelting charges three ore and one wood")
 production.advance(45)
 game._check(production.collect(ingredients)==1 and ingredients.ingot==1,"smelting completes and collects a copper ingot")
 var old: Dictionary=production.state();old.products.erase("ingot")
 game._check(production.restore(old) and production.products.ingot==0,"old workshop products gain copper default")
 game.modal.hide();game.fishing.cancel();game.frontier=Frontier.new()
 game.player=Vector2(48*24+12,8*24+12);game.selected=0;game.energy=60
 game.action_cooldown=0
 game._check(game._act(bush) and game.bag.berry>=2,"world hand action gathers nearby berries")
 var amount: int=game.bag.berry
 game._check(game._eat_berry() and game.energy==68 and game.bag.berry==amount-1,"edible berries restore eight energy and consume one")
 game.energy=100
 amount=game.bag.berry
 game._check(not game._eat_berry() and game.bag.berry==amount,"full stamina does not waste food")
 game.player=Vector2(456,336);game.bag.berry=6
 game._check(not game._complete_villager("lina") and game.bag.berry==6,"villager cannot be paid remotely")
 game.player=Vector2(49*24+12,12*24+12)
 var coins: int=game.coins
 game._check(game._complete_villager("lina") and game.coins==coins+160 and game.bag.berry==0,"nearby villager accepts goods through world transaction")
 game.modal.hide()
 game.resources.erase(Vector2i(58,19))
 game.player=Vector2(58*24+12,19*24+12);game.energy=60;game.action_cooldown=0
 # Arrange a dry bank position, with reachable water two cells away.
 var lake:=Vector2i(60,19)
 game._check(game.water.has(lake) and game._test_action(lake,7) and game.energy==56,"rod casts only at nearby water with exact stamina cost")
 game.hud.show_map()
 var elapsed: float=game.fishing.elapsed
 game._process(0.5)
 game._check(game.fishing.elapsed==elapsed,"map pauses fishing reaction timer")
 game.modal.hide()
 game.fishing.advance(game.fishing.bite_at)
 var fish_before: int=game.bag.fish
 game._check(game._reel_fish() and game.bag.fish==fish_before+1 and game.frontier.catches==1,"world fishing gives persistent fish and catch statistic")
 game._check(not game._reel_fish() and game.bag.fish==fish_before+1,"world catch cannot be duplicated")
 game.energy=3;game.action_cooldown=0
 game._check(not game._test_action(lake,7) and not game.fishing.active,"exhaustion prevents casting")
 game.player=Vector2(57*24+12,37*24+12)
 var ore_cell:=Vector2i(58,37)
 game.resources[ore_cell]={"kind":"rock","hp":1};game.energy=60
 var ore_before: int=game.bag.ore
 game._check(game._test_action(ore_cell,5) and game.bag.ore==ore_before+2,"quarry rock yields copper ore as well as stone")
 # Frontier regeneration must protect tilled land and existing buildings.
 game.plots[ore_cell]={"stage":-1,"wet":false,"crop":""}
 game._seed_frontier_resources()
 game._check(not game.resources.has(ore_cell),"frontier regeneration never overwrites a plot")
 var reachable: Dictionary=game._reachable_cells(Vector2i(19,14))
 for id in Frontier.NPCS:
  game._check(game._near_reachable(Frontier.NPCS[id].cell,reachable),"walkable routes reach villager "+id)
 game.frontier.visited=["farm","forest","lake","ridge"]
 game.day=maxi(game.day,3)
 game._save_game()
 game.frontier=Frontier.new()
 game._check(game._load_game() and game.frontier.completed.has("lina") and game.frontier.catches==1 and game.frontier.visited.size()==4,"farm reload preserves exploration, quests, fish and visited regions")
 game._save_game()
 var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
 game._check(game._valid_save(saved),"expanded coordinates and adventure state validate after JSON conversion")
 saved.frontier.picked=[[49,8,game.day+1]]
 game._check(not game._valid_save(saved),"future berry cooldown rejects corrupted save")
 game.frontier=Frontier.new()
 game.day=6;game.modal.hide();game.fishing.cancel()
 var plot:=Vector2i(19,20)
 game.plots[plot]={"stage":0,"wet":false,"crop":"turnip"}
 game._sleep()
 game._check(game.plots[plot].stage==1 and not game.plots[plot].wet,"rain grows planted crops overnight then resets daily water")
 game._check(not Frontier.rainy(1) and Frontier.rainy(6) and Frontier.rainy(12),"weather follows reproducible six-day cycle")
 game.hud.show_map()
 game._check(game.hud.view=="map" and game.modal.visible,"map window opens with actual world and villager journal")
 game.modal.hide()

 game.muted=false
 game._toggle_sound()
 game._check(game.muted,"sound toggle works through shared keyboard and touch action")
 game.muted=false
 game._check(game._load_game() and game.muted,"audio preference survives validated farm reload")

 var broken: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
 broken.workshop=null
 broken.progression.jobs=[]
 broken.progression.products={"planks":0,"crate":0,"ingot":1}
 game._check(not game._valid_save(broken),"uncollected copper cannot exist without its workshop in a validated save")

 game.modal.hide()
 game.player=Vector2(252,252)
 game._check(game._test_action(Vector2i(10,9),7) and game.modal.visible and game.hud.view=="home","equipped fishing rod does not block normal home interaction")
 game.modal.hide()
