class_name SpiderBoss extends "Enemy.gd"

onready var collision_shape = $CollisionShape2D
onready var big_shot_timer = $BigShotTimer
onready var spawn_drone_timer = $SpawnDroneTimer
onready var burst_timer = $BurstTimer
onready var ray_cast = $RayCast2D
onready var end_of_drone_timer = $EndOfDroneAttackTimer

var use_main_attack := false
var use_big_shot_attack := false
var use_spawn_drone := false

var can_use_big_shot := true
var can_spawn_drone := true

var show_death_anim := false

var next_burst := false
var using_burst := 0

export var burst_freeze = 1
export var grenade_freeze = 1
export var big_shot_freeze = 1
export var spawn_drone_freeze = 1

var rotating = false
export(float) var rotation_speed := 90.0

var temp_range = 0

func _ready():
	rotation_speed = deg2rad(rotation_speed)

func _physics_process(delta):
	if state == STATE.MOVE:
		var move_direction = position.direction_to(nav_agent.get_next_location())
		velocity = move_direction * speed
		velocity = move_and_slide(velocity)
		if velocity.length() > 0:
			sprite.play("default")
		else:
			sprite.stop()
	
	velocity = Vector2.ZERO
	
	if rotating:
		var player_position = EntityManager.player.global_position
		var player_angle = (player_position - global_position).angle() + deg2rad(90.0)
		var angle = lerp_angle(global_rotation, player_angle, 1.0)
		var rotate_delta = rotation_speed * delta
		angle = clamp(angle, global_rotation - rotate_delta, global_rotation + rotate_delta)
		global_rotation = angle
		
		if ray_cast.is_colliding():
			target = player_position
			rotating = false
			animation.stop()
			pick_attack()
			just_attacked = true

func _process(delta):
	if use_main_attack and can_use_attack:
		can_use_attack = false
		
		var rng = randi() % 2
		if rng == 0:
			burst_shot()
		else:
			grenade()
		
		attack.start()
	elif use_big_shot_attack and can_use_big_shot:
		can_use_big_shot = false
		big_shot()
		big_shot_timer.start()
		attack.start()
	elif use_spawn_drone and can_spawn_drone:
		can_spawn_drone = false
		spawn_drone()
		spawn_drone_timer.start()
		attack.start()
		
	if next_burst && using_burst > 0:
		next_burst = false
		using_burst -= 1
		EntityManager.create_projectile(self, target, projectile_speed, projectile_accuracy, projectile_range, projectile_damage, projectile_pierce, projectile_dot_tick, projectile_explode, projectile_explode_type, projectile_shielding)
		
		for i in range(1, projectile_amount):
			EntityManager.create_projectile(self, target, projectile_speed, projectile_accuracy - 0.1, projectile_range, projectile_damage, projectile_pierce, projectile_dot_tick, projectile_explode, projectile_explode_type, projectile_shielding)
		burst_timer.start()

func burst_shot():
	if using_burst <= 0:
		next_burst = true
		using_burst = 3
		
		freezeCD.start(burst_freeze)
		
		use_main_attack = false
		use_big_shot_attack = false
		use_spawn_drone = false
	
func grenade():
	EntityManager.create_projectile(self, target, projectile_speed / 3, projectile_accuracy, projectile_range, projectile_damage, 1, projectile_dot_tick, 0.3, 2, false)
	
	for i in range(1, projectile_amount):
		EntityManager.create_projectile(self, target, projectile_speed / 3, projectile_accuracy - 0.2, projectile_range, projectile_damage, 1, projectile_dot_tick, 0.3, 2, false)
	
	freezeCD.start(grenade_freeze)	
	
	use_main_attack = false
	use_big_shot_attack = false
	use_spawn_drone = false
		
func big_shot():
	animation.play("big_shot")
	EntityManager.create_big_shot(self, target, 0, projectile_accuracy, projectile_range * 2, projectile_damage * 2, projectile_pierce * 2, projectile_dot_tick, projectile_explode, projectile_explode_type, true)
	freezeCD.start(big_shot_freeze)
	
	use_main_attack = false
	use_big_shot_attack = false
	use_spawn_drone = false

func spawn_drone():
	animation.play("spawn_drone")
	end_of_drone_timer.start(spawn_drone_freeze)
	
	use_main_attack = false
	use_big_shot_attack = false
	use_spawn_drone = false
	
func process_ai(player):
	if show_death_anim:
		return
	
	if just_attacked:
		state = STATE.IDLE
	else:
		if can_use_attack && player_in_attack(player.position):
			state = STATE.ATTACK
		elif !player_in_attack(player.position) && player_in_sight(player.position):
			state = STATE.MOVE
		
	if state == STATE.MOVE:
		if next_path_find:
			next_path_find = false
			nav_agent.set_target_location(player.position)
		target = player.global_position
		look_at_target = true
	elif state == STATE.ATTACK:
		animation.play("default")
		rotating = true
		look_at_target = false

func pick_attack():
	if can_use_big_shot:
		use_big_shot_attack = true
	elif can_spawn_drone:
		use_spawn_drone = true
	else:
		use_main_attack = true

func take_damage(damage):
	health -= damage
	if !show_death_anim && health <= 0:
		show_death_anim = true
		animation.play("death")
		collision_shape.set_deferred("disabled", true)

func add_sight_range(amount):
	.add_sight_range(amount)
	ray_cast.cast_to.y -= amount
		
func _on_NavigationAgent2D_velocity_computed(safe_velocity):
	if show_death_anim:
		return
	
	if !arrived_at_location():
		if safe_velocity.length() > 0:
			sprite.play("default")
		else:
			sprite.stop()
		velocity = move_and_slide(safe_velocity)
	else:
		sprite.stop()

func _on_BigShotTimer_timeout():
	can_use_big_shot = true

func _on_SpawnDroneTimer_timeout():
	can_spawn_drone = true

func _on_BurstTimer_timeout():
	next_burst = true

func _on_EndOfDroneAttackTimer_timeout():
	if health <= 0:
		return
	
	EntityManager.create_enemy("roomba", position.x + 25, position.y)
	EntityManager.create_enemy("roomba", position.x - 25, position.y)
	freezeCD.start(spawn_drone_freeze)
	
	animation.play("default")
	animation.stop()

func _on_RealHitBox_area_entered(area):
	if area.is_in_group("Projectile"):
		take_damage(area.damage)
		
		if area.dot > 0:
			add_dot(area.dot)
		if area.explode > 0:
				EntityManager.create_explosion(area, area.damage, area.explode, area.dot, area.explode_type)
		
		area.queue_free()