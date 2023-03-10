extends Node

# preload all needed entity scenes
const projectile_scene = preload("res://shooter/projectile/Projectile.tscn")
const explosion_scene = preload("res://shooter/projectile/Explosion.tscn")
const turret_scene = preload("res://shooter/entity/Turret.tscn")
const soldier_scene = preload("res://shooter/entity/Soldier.tscn")
const general_scene = preload("res://shooter/entity/General.tscn")
const chem_thrower_scene = preload("res://shooter/entity/ChemThrower.tscn")
const drone_scene = preload("res://shooter/entity/Drone.tscn")
const spider_boss_scene = preload("res://shooter/entity/SpiderBoss.tscn")
const big_shot_scene = preload("res://shooter/projectile/BigShot.tscn")

# keep track of the scene that things should be added to
var shooter_game: Node

# needed to track which nodes to buff every ten seconds
var enemy_percent = [1.0, 0.0, 0.0, 0.0]
var enemy_percent_increase = [-0.17, 0.1, 0.05, 0.02]
var enemy_percent_min = [0.4, 0.0, 0.0, 0.0]
var enemy_percent_max = [1.0, 0.3, 0.2, 0.1]
var difficulty_modifier = 2
var level_modifier = 0
var enemies = []
var player = null
var keypads = []
var keypad
var goblin

# the enemy spawners of the level
var spawners = []
var turret_spawners = []
var goblin_spawners = []
var spider_boss_spawners = []

# current buffs that the enemies have
# := means that the variable cannot change types
const buff_names = []
var buff_cards = []

const min_health = 0
const min_speed = 0
const min_damage = 0
const min_amount = 0
const min_dot = 0
const min_proj_range = 0
const min_attack_speed = 0.0

const max_health = 1000
const max_speed = 1000
const max_damage = 1000
const max_amount = 1000
const max_dot = 1000
const max_proj_range = 1000
const max_attack_speed = 100.0

var current_health := 0
var current_speed := 0
var current_damage := 0
var current_amount := 0
var current_dot := 0
var current_proj_range := 0
var current_attack_speed := 0.0

const health = 1
const speed = 25
const damage = 1
const amount = 1
const dot = 1
const proj_range = 25
const attack_speed = 0.05

# current buffs for the player
var player_health = 0
var player_grenades = 0
var player_speed = 0
var player_damage = 0
var player_amount = 0
var player_dot = 0
var player_range = 0
var player_attack_speed = 0
var player_pierce = 0

var random = RandomNumberGenerator.new()

# sizes of the enemies for spawning purposes
const drone_size = Vector2(16.0, 16.0)
const soldier_size = Vector2(16.0, 16.0)
const general_size = Vector2(16.0, 16.0)
const chem_thrower_size = Vector2(16.0, 16.0)

func _ready():
	buff_names.append("health")
	buff_names.append("speed")
	buff_names.append("damage")
	buff_names.append("amount")
	buff_names.append("dot")
	buff_names.append("range")
	buff_names.append("attack-speed")
	buff_names.append("spawn")
	
	random.randomize()

func reset_enemy_percent():
	enemy_percent[0] = 1.0
	for i in range(1, enemy_percent.size()):
		enemy_percent[i] = 0.0

# restarts a level, removing some buffs
func new_level(remove_amount):
	difficulty_modifier += 2
	
	for i in range(0, enemy_percent.size()):
		enemy_percent[i] += enemy_percent_increase[i]
		if enemy_percent[i] >= enemy_percent_max[i]:
			enemy_percent[i] = enemy_percent_max[i]
		if enemy_percent[i] <= enemy_percent_min[i]:
			enemy_percent[i] = enemy_percent_min[i]
	
	for enemy in enemies:
		enemy.queue_free()
	enemies.clear()
	#player.queue_free()
	keypads.clear()
	keypad = null
	
	if goblin != null:
		goblin.queue_free()
	goblin = null
	
	spawners.clear()
	turret_spawners.clear()
	goblin_spawners.clear()
	spider_boss_spawners.clear()
	
	remove_buffs(remove_amount)

func remove_spider_boss():
	shooter_game.spider_boss_killed()
	kill_all_enemies()
	remove_buffs(6)
	shooter_game.remove_enemy_buff_from_hud(6)

func remove_buffs(remove_amount):
	for i in range(0, remove_amount):
		if buff_cards.size() == 0:
			return
			
		var buff_name = buff_cards.pop_back()
		match buff_name:
			"health":
				current_health -= health
				if current_health < min_health:
					current_health = min_health
			"speed":
				current_speed -= speed
				if current_speed < min_speed:
					current_speed = min_speed
			"damage":
				current_damage -= damage
				if current_damage < min_damage:
					current_damage = min_damage
			"amount":
				current_amount -= amount
				if current_amount < min_amount:
					current_amount = min_amount
			"dot":
				current_dot -= dot
				if current_dot < min_dot:
					current_dot = min_dot
			"range":
				current_proj_range -= proj_range
				if current_proj_range < min_proj_range:
					current_proj_range = min_proj_range
			"attack-speed":
				current_attack_speed -= attack_speed
				if current_attack_speed < min_attack_speed:
					current_attack_speed = min_attack_speed
			"spawn":
				difficulty_modifier -= 1
				if difficulty_modifier < 2:
					difficulty_modifier = 2

# this function might cause the game to crash
# will have to try and see if it is overloading
# queue free
func kill_all_enemies():
	for enemy in enemies:
		if !enemy.is_in_group("SpiderBoss"):
			enemy.queue_free()
		else:
			enemy.disable_player_interaction()
	enemies.clear()

func restart():
	difficulty_modifier = 2
	
	enemy_percent[0] = 1.0
	for i in range(1, enemy_percent.size()):
		enemy_percent[i] = 0.0
	
	for enemy in enemies:
		enemy.queue_free()
	enemies.clear()
	#player.queue_free()
	keypads.clear()
	keypad = null
	
	if goblin != null:
		goblin.queue_free()
	goblin = null
	
	spawners.clear()
	turret_spawners.clear()
	goblin_spawners.clear()
	spider_boss_spawners.clear()
	
	current_health = 0
	current_speed = 0
	current_damage = 0
	current_amount = 0
	current_dot = 0
	current_proj_range = 0
	current_attack_speed = 0.0
	
	player_health = 0
	player_grenades = 0
	player_speed = 0
	player_damage = 0
	player_amount = 0
	player_dot = 0
	player_range = 0
	player_attack_speed = 0
	player_pierce = 0
	
	random.randomize()

func find_closest_enemy(position):
	var distance = 1000000.0
	var closest = null
	
	for enemy in enemies:
		var dist = enemy.position.distance_to(position)
		if dist < distance:
			distance = dist
			closest = enemy
	return closest

func randomize_keypad():
	for kp in keypads:
		kp.visible = false
	
	var rng = randi() % keypads.size()
	keypad = keypads[rng]
	keypad.visible = true

func spawn_full_enemies():
	# spawn a spider boss if there is one
	if spider_boss_spawners.size() > 0:
		var rng = randi() % spider_boss_spawners.size()
		spider_boss_spawners[rng].spawn_boss()
	
	# spawn a goblin if there is one
	if goblin_spawners.size() > 0:
		var rng = randi() % goblin_spawners.size()
		goblin = goblin_spawners[rng].spawn_goblin()
		shooter_game.add_child(goblin)
	
	# amount of enemies to spawn
	var enemy_amount = 0
	var enemy_amount_left = difficulty_modifier + level_modifier
	
	if spawners.size() > 0:
		# drone amount
		enemy_amount = get_roomba_amount(enemy_amount_left)
		enemy_amount_left -= enemy_amount
		for i in range(0, enemy_amount):
			var spawner = spawners[randi() % spawners.size()]
			spawner.spawn_one("roomba", drone_size)
		
		# soldiers
		enemy_amount = get_soldier_amount(enemy_amount_left)
		enemy_amount_left -= enemy_amount
		for i in range(0, enemy_amount):
			var spawner = spawners[randi() % spawners.size()]
			spawner.spawn_one("soldier", soldier_size)
		
		# generals
		enemy_amount = get_general_amount(enemy_amount_left)
		enemy_amount_left -= enemy_amount
		for i in range(0, enemy_amount):
			var spawner = spawners[randi() % spawners.size()]
			spawner.spawn_one("general", general_size)
			
		# chem throwers
		enemy_amount = get_chem_thrower_amount(enemy_amount_left)
		enemy_amount_left -= enemy_amount
		for i in range(0, enemy_amount):
			var spawner = spawners[randi() % spawners.size()]
			spawner.spawn_one("chem-thrower", chem_thrower_size)
		
	# turret amount
	if turret_spawners.size() > 0:
		enemy_amount = floor(get_turret_amount(difficulty_modifier + level_modifier))
		for i in range(0, enemy_amount):
			var turret_spawner = turret_spawners[randi() % turret_spawners.size()]
			turret_spawner.spawn_one()

func add_single_stat_to_player(stat):
	match stat:
		"health":
			player_health += health
		"speed":
			player_speed += speed
		"damage":
			player_damage += damage
		"amount":
			player_amount += amount
		"dot":
			player_dot += dot
		"range":
			player_range += proj_range
		"grenade":
			player_grenades += 1
		"debuff":
			remove_buffs(2)
		"attack-speed":
			player_attack_speed -= attack_speed
		"pierce":
			player_pierce += 1

# adds the stats to the player
func add_stats_to_player():
	player.max_health += player_health
	player.health += player_health
	player.grenades += player_grenades
	player.speed += player_speed
	player.projectile_damage += player_damage
	player.projectile_amount += player_amount
	player.projectile_dot_tick += player_dot
	player.projectile_range += player_range
	player.projectile_attack_speed += player_attack_speed
	player.change_attack_speed()
	player.projectile_pierce += player_pierce

# adds the entity to the main node
# so it shows up on screen
func add_node_to_root(node):
	#shooter_game.call_deferred("add_child", node)
	shooter_game.add_child(node)

func add_enemy(enemy):
	enemies.append(enemy)
	add_node_to_root(enemy)
	
	enemy.max_health += current_health
	enemy.health += current_health
	enemy.speed += current_speed
	enemy.projectile_damage += current_damage
	enemy.projectile_amount += current_amount
	enemy.projectile_dot_tick += current_dot
	
	enemy.projectile_range += current_proj_range
	if enemy.is_in_group("Enemy"):
		enemy.add_sight_range(current_proj_range)
		
	enemy.projectile_attack_speed -= current_attack_speed
	enemy.change_attack_speed()

func create_multi_enemy(type, x, y, amount):
	for i in amount:
		create_enemy(type, x, y)

func create_enemy(type, x, y):
	var enemy = null
	
	match type:
		"random":
			var rng = randi() % 4
			match rng:
				0:
					create_enemy("roomba", x, y)
				1:
					create_enemy("soldier", x, y)
				2:
					create_enemy("general", x, y)
				3:
					create_enemy("chem-thrower", x, y)
		"turret":
			enemy = turret_scene.instance()
		"roomba":
			enemy = drone_scene.instance()
		"soldier":
			enemy = soldier_scene.instance()
		"general":
			enemy = general_scene.instance()
		"chem-thrower":
			enemy = chem_thrower_scene.instance()
		"spider-boss":
			enemy = spider_boss_scene.instance()
		
	if enemy != null:
		enemy.create(x, y)
		add_enemy(enemy)

func create_projectile(owner, start_position, target, speed, accuracy, distance, damage, pierce, dot, explode, explode_type, shielding):
	var projectile = projectile_scene.instance()
	add_node_to_root(projectile)
	projectile.create(owner, start_position, target, speed, accuracy, distance, damage, pierce, dot, explode, explode_type, shielding)
	
func create_big_shot(owner, start_position, target, speed, accuracy, distance, damage, pierce, dot, explode, explode_type, shielding):
	var big_shot = big_shot_scene.instance()
	add_node_to_root(big_shot)
	big_shot.create(owner, start_position, target, speed, accuracy, distance, damage, pierce, dot, explode, explode_type, shielding)
	big_shot.offset_big_shot()
	
func create_explosion(owner, damage, dot, type, loops):
	var explosion = explosion_scene.instance()
	explosion.create(owner, damage, dot, type, loops)
	add_node_to_root(explosion)

func register_spawner(spawner):
	spawners.append(spawner)	
	
func register_turret_spawner(spawner):
	turret_spawners.append(spawner)

func register_goblin(goblin):
	goblin_spawners.append(goblin)
	
func register_spider_boss_spawner(boss_spawner):
	spider_boss_spawners.append(boss_spawner)
	
func add_buff_to_enemies():
	# randomize the next enemy buff card
	# if all enemies are dead, no more can spawn
	# this level, but other cards can work
	var rng = 0
	if enemies.size() == 0:
		rng = randi() % (buff_names.size() - 1)
	elif spider_boss_spawners.size() == 1:
		if enemies.size() > 1:
			rng = randi() % buff_names.size()
		else:
			rng = randi() % (buff_names.size() - 1)
	else:
		rng = randi() % buff_names.size()
	var buff = buff_names[rng]
	buff_cards.append(buff)
	
	if buff != "spawn":
		match buff:
			"health":
				current_health += health
				if current_health > max_health:
					current_health = max_health
			"speed":
				current_speed += speed
				if current_speed > max_speed:
					current_speed = max_speed
			"damage":
				current_damage += damage
				if current_damage > max_damage:
					current_damage = max_damage
			"amount":
				current_amount += amount
				if current_amount > max_amount:
					current_amount = max_amount
			"dot":
				current_dot += dot
				if current_dot > max_dot:
					current_dot = max_dot
			"range":
				current_proj_range += proj_range
				if current_proj_range > max_proj_range:
					current_proj_range = max_proj_range
			"attack-speed":
				current_attack_speed += attack_speed
				if current_attack_speed > max_attack_speed:
					current_attack_speed = max_attack_speed
	else:
		var enemy = enemies[randi() % enemies.size()]
		create_enemy(enemy.enemy_name, enemy.position.x + 10, enemy.position.y)

	for enemy in enemies:
		add_buff_to_enemy(enemy, buff)
		
	return buff
	
func add_buff_to_enemy(enemy, buff):
	match buff:
		"health":
			enemy.max_health += health
			enemy.health += health
		"speed":
			enemy.speed += speed
		"damage":
			enemy.projectile_damage += damage
		"amount":
			enemy.projectile_amount += amount
		"dot":
			enemy.projectile_dot_tick += dot
		"range":
			enemy.projectile_range += proj_range
			if enemy.get_class() == "Enemy":
				enemy.add_sight_range(proj_range)
			pass
		"attack-speed":
			enemy.projectile_attack_speed -= attack_speed
			enemy.change_attack_speed()
	
func process_enemies():
	for enemy in enemies:
		enemy.process_ai(player)
	
# iterates through the enemy array
# if they are !alive
# then removes them from the scene and array
func remove_dead_enemies():
	for i in range(enemies.size() - 1, -1, -1):
		if !enemies[i].alive:
			enemies[i].queue_free()
			enemies.remove(i)
	
# math functions to find how many enemies to spawn
func get_roomba_amount(x):
	return ceil(enemy_percent[0] * x)
	
func get_turret_amount(x):
	return x
	
func get_soldier_amount(x):
	return ceil(enemy_percent[1] * x)
	
func get_general_amount(x):
	return ceil(enemy_percent[2] * x)
	
func get_chem_thrower_amount(x):
	return ceil(enemy_percent[3] * x)
