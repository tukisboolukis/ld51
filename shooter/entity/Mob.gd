class_name Mob extends KinematicBody2D

# child nodes
onready var attack = $AttackCD
onready var animation = $AnimatedSprite
onready var attack_cd = $AttackCD
onready var acid_overlay = $AcidOverlay
onready var muzzle_flash = $MuzzleFlash
onready var bullet_spawn = $BulletSpawn
onready var bullet_impact = $BulletImpact
onready var random_bullet_impact = $RandomBulletImpact
onready var collision_shape = $CollisionShape2D
onready var dot_timer = $DotTimer
onready var attack_windup_timer = $AttackWindupTimer

var radius = 0

export var max_health = 1
var health = 1
var alive = true

export var speed = 300
var velocity = Vector2.ZERO

# current projectile information
# would like to learn how to do this more oop
var target = Vector2.ZERO
var can_use_attack = true
var use_attack = false
export var projectile_speed = 1000
export var projectile_range = 25
export var projectile_damage = 1
export var projectile_pierce = 1
export var projectile_amount = 1
export var projectile_accuracy = 1.0
export var projectile_dot_tick = 0
export var projectile_explode_damage = 0
export(int, "Shock", "Slime", "Normal") var projectile_explode_type = 0
export var projectile_shielding = false
export var projectile_attack_speed = 1.0

var dot_amount = 0
var look_at_target = true
var use_attack_wind_up := true

func _ready():
	radius = collision_shape.shape.radius
	
	health = max_health
	change_attack_speed()
	
	dot_timer.paused = true

func _physics_process(delta):
	if velocity.length() > 0:
		velocity = move_and_slide(velocity)

func _process(delta):
	if use_attack and can_use_attack:
		can_use_attack = false
		
		if use_attack_wind_up:
			attack_windup_timer.start()
		else:
			basic_attack()
		
	if look_at_target:	
		look_at(target)
		rotation_degrees += 90.0
	
	if dot_amount > 0:
		acid_overlay.visible = true
	else:
		acid_overlay.visible = false
		
	bullet_impact.global_rotation = 0
	random_bullet_impact.global_rotation = 0

func change_attack_speed():
	attack_cd.wait_time = projectile_attack_speed
	if attack_cd.wait_time <= 0.05:
		attack_cd.wait_time = 0.05

func take_damage(damage, location):
	if location != null:
		var direction = global_position.direction_to(location)
		bullet_impact.global_position = global_position + direction * radius
		bullet_impact.direction = direction
		bullet_impact.emitting = true
		random_bullet_impact.emitting = true
	
	health -= damage
	if health <= 0:
		alive = false

func basic_attack():
	#if !self.is_in_group("Player"):
	#	print("not player")
	#	target = EntityManager.player.global_position
	EntityManager.create_projectile(self, bullet_spawn.global_position, target, projectile_speed, projectile_accuracy, projectile_range, projectile_damage, projectile_pierce, projectile_dot_tick, projectile_explode_damage, projectile_explode_type, projectile_shielding)
		
	for i in range(1, projectile_amount):
		EntityManager.create_projectile(self, bullet_spawn.global_position, target, projectile_speed, projectile_accuracy - 0.1, projectile_range, projectile_damage, projectile_pierce, projectile_dot_tick, projectile_explode_damage, projectile_explode_type, projectile_shielding)
		
	muzzle_flash.visible = true
	muzzle_flash.frame = 0
	muzzle_flash.play("default")
	attack.start()
		
func add_dot(ticks):
	dot_timer.paused = false
	if ticks >= dot_amount:
		dot_amount = ticks

func _on_AttackCD_timeout():
	can_use_attack = true

func _on_DotTimer_timeout():
	if dot_amount > 0:
		take_damage(1, null)
		dot_amount -= 1
		
		if dot_amount == 0:
			dot_timer.paused = true

func _on_MuzzleFlash_animation_finished():
	muzzle_flash.stop()
	muzzle_flash.visible = false

func _on_AttackWindupTimer_timeout():
	basic_attack()
