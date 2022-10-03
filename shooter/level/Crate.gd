extends Area2D

export var damage = 0
export var explosion_timer = 0
export var dot = 0
export var explosion_type = 0

func _on_Crate_area_entered(area):
	if area.get_class() == "Projectile":
		EntityManager.create_explosion(self, damage, explosion_timer, dot, explosion_type)
		queue_free()

func get_class():
	return "Crate"
