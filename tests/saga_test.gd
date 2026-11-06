extends RefCounted
const Combat=preload("res://game/combat.gd")
const Homestead=preload("res://game/homestead.gd")
const Inventory=preload("res://game/inventory_layout.gd")
func clear_area(game: Node2D,c: Vector2i) -> void:
 for y in range(c.y-1,c.y+4):
  for x in range(c.x-1,c.x+5):game.resources.erase(Vector2i(x,y));game.plots.erase(Vector2i(x,y))
func run(game: Node2D) -> void:
 var inv=Inventory.new();var old: Array=[];old.resize(24);old.fill("");old[2]="hoe";old[23]="wood"
 game._check(inv.restore(old) and inv.slots.size()==36 and inv.slots[23]=="wood" and inv.slots[2]=="hoe","24-cell inventory migrates to 36 without moving saved stacks")
 inv.reconcile({"wood":5})
 game._check(inv.slots.has("sword") and inv.slots.has("sling") and inv.slots.count("wood")==1,"new weapons fit permanent inventory without duplicate resources")
 var home=Homestead.new();var bag: Dictionary={"wheat":6,"bread":0,"iron":6,"wood":4,"ironbar":0}
 game._check(not home.start("bread",bag) and bag.wheat==6,"bread requires an actual bakery before charging grain")
 home.place("bakery",Vector2i(19,18));home.place("forge",Vector2i(24,22))
 game._check(not home.place("bakery",Vector2i(30,18)),"unique facilities cannot be duplicated")
 game._check(home.start("bread",bag) and home.start("ironbar",bag) and home.start("bread",bag),"bakery and forge share an ordered production queue")
 game._check(not home.start("ironbar",bag) and bag.iron==3,"full new production queue does not partially charge materials")
 game._check(home.advance(34)==0 and home.advance(1)==1 and home.products.bread==1,"bread completes at exact recipe boundary")
 game._check(not home.removable("bakery") and not home.removable("forge"),"active tasks and goods protect their production building")
 home.advance(95)
 game._check(home.jobs.is_empty() and home.collect(bag)==3 and bag.bread==2 and bag.ironbar==1,"night-length budget finishes bakery and forge in order")
 game._check(home.collect(bag)==0,"new production collection cannot duplicate goods")
 game._check(home.restore(home.state()) and home.has("forge"),"facility positions, jobs and goods serialize together")
 var corrupt: Dictionary=home.state();corrupt.structures=[];corrupt.products.ironbar=1
 game._check(not home.restore(corrupt) and home.has("forge"),"invalid missing-facility goods cannot mutate homestead")
 var model=Combat.new();model.initialize(1)
 var free:=func(_p: Vector2) -> bool: return true
 var wall:=func(_p: Vector2) -> bool: return false
 var moss: Dictionary=model.mobs[0];var attacker: Vector2=moss.pos+Vector2(0,36)
 game._check(not Combat.dangerous(Vector2(456,336)) and Combat.dangerous(attacker),"enemy aggression is confined to wilds and never the original farm")
 game._check(model.strike(attacker,moss.pos,1,free) and moss.hp==14,"starter blade damages a nearby creature in its attack arc")
 game._check(not model.strike(attacker,moss.pos,1,free) and moss.hp==14,"attack recovery prevents click-spam damage")
 for i in range(5):model.step(0.1,Vector2(456,336),free,free,1)
 model.strike(attacker,moss.pos,1,free)
 game._check(moss.hp==0 and model.defeated==1 and model.events.size()==1,"defeated mob emits exactly one loot event")
 var dead_state: Dictionary=model.state()
 game._check(model.restore(dead_state,1) and not model.mobs.any(func(m: Dictionary) -> bool: return m.id==0),"reloading cannot immediately respawn a killed creature")
 game._check(model.restore(dead_state,3) and model.mobs.any(func(m: Dictionary) -> bool: return m.id==0),"wild creatures return after two game days")
 moss=model.mobs[0];attacker=moss.pos+Vector2(0,36)
 model.strike(attacker,attacker+Vector2.DOWN*24,3,free)
 game._check(moss.hp==28,"melee cannot damage targets behind the character")
 model.attack_left=0;model.strike(attacker,moss.pos,3,wall)
 game._check(moss.hp==28,"terrain blocks melee attacks through obstacles")
 var ammo: Dictionary={"stone":0};model.attack_left=0
 game._check(not model.shoot(attacker,moss.pos,ammo) and model.shots.is_empty(),"sling needs stone ammunition")
 ammo.stone=1;attacker=moss.pos+Vector2(0,80)
 game._check(model.shoot(attacker,moss.pos,ammo) and ammo.stone==0,"sling launches one projectile for one stone")
 for i in range(6):model.step(0.1,attacker,free,free,3)
 game._check(moss.hp<28 and model.shots.is_empty(),"swept projectile hits a moving creature once")
 model=Combat.new();model.initialize(1);moss=model.mobs[0];attacker=moss.pos+Vector2(0,28)
 for i in range(8):model.step(0.1,attacker,free,free,1)
 game._check(model.health==100 and moss.windup>0,"creature telegraphs attack before dealing damage")
 for i in range(7):model.step(0.1,attacker,free,free,1)
 game._check(model.health==92 and model.immunity>0,"enemy hit deals exact damage and grants brief protection")
 var health: int=model.health
 model.step(0.1,attacker,free,free,1)
 game._check(model.health==health,"contact cannot repeatedly damage every animation frame")
 model=Combat.new();model.initialize(1);moss=model.mobs[0];attacker=moss.pos+Vector2(0,28)
 for i in range(8):model.step(0.1,attacker,free,free,1)
 for i in range(7):model.step(0.1,attacker+Vector2(0,90),free,free,1)
 game._check(model.health==100,"moving out of a telegraphed strike avoids damage")
 corrupt=model.state();corrupt.killed=[[0,2]]
 game._check(not model.valid(corrupt,1),"future enemy death timestamps reject damaged saves")
 game.modal.hide();game.day=3;game.frontier=load("res://game/frontier.gd").new();game.homestead=Homestead.new();game.combat=Combat.new();game.combat.initialize(game.day)
 game.orders=load("res://game/orders.gd").new()
 game.progression=load("res://game/progression.gd").new();game.workshop=Vector2i(-1,-1);game.buildings.clear()
 game.bag.wood=200;game.bag.stone=200;game.bag.planks=50;game.bag.ingot=20;game.coins=2000
 for kind in ["bakery","well","forge"]:
  var cell:=Vector2i(19,18) if kind=="bakery" else Vector2i(24,18) if kind=="well" else Vector2i(24,22)
  clear_area(game,cell);game.player=Vector2((cell+Vector2i(1,-1))*24+Vector2i(12,12));game.build_kind=kind
  game._check(game._test_build(cell) and game.homestead.has(kind),"dedicated construction places "+kind)
 game._check(game.coins==1600 and game.bag.planks==34 and game.bag.ingot==14,"new facilities charge their complete multi-material costs")
 var planted:=Vector2i(26,20);game.resources.erase(planted);game.plots.erase(planted)
 game.player=Vector2(25*24+12,20*24+12);game.energy=100;game.bag.wheat_seeds=1
 game._check(game._test_action(planted,1) and game._test_action(planted,9) and game.bag.wheat_seeds==0,"wheat can be prepared and planted through its assigned action")
 var dry:=Vector2i(32,18);game.resources.erase(dry);game.plots[dry]={"stage":0,"wet":false,"crop":"wheat"}
 game._sleep();game._sleep()
 game._check(game.plots[planted].stage==2 and game.plots[dry].stage==0,"well grows nearby crops automatically without watering distant fields")
 var grain: int=game.bag.wheat
 game._check(game._test_action(planted,0) and game.bag.wheat==grain+2,"mature wheat gives two grain and resets its plot")
 game.bag.wheat=3;game.player=Vector2(19*24+12,20*24+12)
 game._check(game._start_facility_recipe("bread") and game.bag.wheat==0,"bakery interaction charges exact grain")
 game.modal.hide();game._sleep();game._collect_facility("bakery");game.modal.hide()
 game._check(game.bag.bread==1,"world overnight production delivers bread")
 game.energy=20;game.combat.health=30
 game._check(game._eat_bread() and game.energy==45 and game.combat.health==65 and game.bag.bread==0,"bread restores health and stamina while consuming one item")
 game.energy=100;game.combat.health=100;game.bag.bread=1
 game._check(not game._eat_bread() and game.bag.bread==1,"full character cannot accidentally waste healing food")
 game.bag.ironbar=3;game.player=Vector2(252,252)
 game._check(not game._upgrade_weapon() and game.bag.ironbar==3,"weapon upgrades require being at the forge")
 game.player=Vector2(25*24+12,24*24+12);var money: int=game.coins
 game._check(game._upgrade_weapon() and game.combat.weapon_level==2 and game.bag.ironbar==0 and game.coins==money-100,"forge upgrades blade and sling with exact cost")
 game.modal.hide();game.bag.ironbar=6;game.bag.essence=5
 game._check(not game._upgrade_weapon() and game.bag.ironbar==6,"missing essence cannot partially charge final weapon upgrade")
 game.bag.essence=6
 game._check(game._upgrade_weapon() and game.combat.weapon_level==3 and game.bag.ironbar==0 and game.bag.essence==0,"final weapon tier consumes iron and wild loot")
 game.modal.hide();game.progression.tool_level=3;game.bag.ironbar=5;game.coins=300
 game._check(game._forge_tools() and game.progression.tool_level==4 and game.bag.ironbar==0 and game.coins==0,"forge unlocks mountain tools after workshop tier III")
 game.modal.hide();game.player=Vector2(83*24+12,20*24+12);var ore:=Vector2i(84,20);game.resources[ore]={"kind":"rock","hp":3};game.energy=100
 var iron: int=game.bag.iron;var stone: int=game.bag.stone
 game._check(game._test_action(ore,5) and game.bag.iron==iron+4 and game.bag.stone==stone+8,"mountain pick mines wild iron with improved yields")
 game.combat.health=70;game._save_game();game.combat=Combat.new();game.homestead=Homestead.new()
 game._check(game._load_game() and game.combat.health==70 and game.combat.weapon_level==3 and game.homestead.structures.size()==3 and game.progression.tool_level==4,"save reload preserves health, gear, all facilities and new tools")
 var state: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(game.save_path))
 game._check(game._valid_save(state),"entire expansion validates after JSON numeric conversion")
 state.homestead.structures[1][1]=19;state.homestead.structures[1][2]=18
 game._check(not game._valid_save(state),"overlapping new buildings reject damaged save data")
 game.coins=1000;var cargo: Dictionary=game.bag.duplicate();game.combat.health=0;game.combat.events=[{"kind":"hurt","damage":18,"pos":game.player}]
 game._combat_events()
 game._check(game.player==Vector2(252,252) and game.combat.health==60 and game.coins==900 and game.bag==cargo and game.hud.view=="rescue","defeat returns home with bounded coin penalty and no inventory loss")
 game.modal.hide()

 var guard=Combat.new();guard.initialize(1)
 var boss: Dictionary=guard.mobs[5];boss.windup=0.8
 guard.strike(boss.pos+Vector2(0,36),boss.pos,1,free)
 game._check(boss.hp==126 and boss.windup==0.8,"armored guardian keeps its warning attack when hit and cannot be stunlocked")
 guard=Combat.new();guard.initialize(1);var target: Dictionary=guard.mobs[0]
 guard.shoot(target.pos+Vector2(0,80),target.pos,{"stone":1})
 guard.step(0.1,target.pos+Vector2(0,80),free,wall,1)
 game._check(target.hp==28 and guard.shots.is_empty(),"obstacle blocks a sling projectile before it can hit an enemy")

 var legacy: Dictionary={"version":2,"player":[456,336],"day":3,"minutes":360,"energy":100,"coins":123,"bag":{"wood":12,"stone":0,"seeds":8,"turnip":2},"quest":0,"plots":[[18,18,1,true,"turnip"]],"resources":[],"buildings":[],"frontier":{}}
 var out:=FileAccess.open(game.save_path,FileAccess.WRITE);out.store_string(JSON.stringify(legacy));out.close()
 var loaded: bool=game._load_game()
 game._check(loaded and game.coins==123 and game.bag.turnip==2 and game.plots[Vector2i(18,18)].stage==1 and not game.resources.is_empty() and game.resources.keys().all(func(c: Vector2i) -> bool: return c.x>=80 or c.y>=56),"RC1 migration seeds only expanded land and preserves cleared original districts")

 game._check(game._can_stand(Vector2((Combat.RUIN.position+Vector2i(2,1))*24+Vector2i(12,12))) and game._solid(Combat.RUIN.position),"ruin gate has a walkable center and solid visible stone pillars")
 var master=Combat.new();master.weapon_level=3;master.initialize(1);var prey: Dictionary=master.mobs[0]
 var shot_bag: Dictionary={"stone":1}
 master.shoot(prey.pos+Vector2(0,80),prey.pos,shot_bag)
 for i in range(6):master.step(0.1,prey.pos+Vector2(0,80),free,free,1)
 game._check(prey.hp==0 and master.defeated==1 and shot_bag.stone==0,"master sling defeats a moss creature with one stone and one loot event")
