extends ColorRect

# the lower and upper ranges for the spawn
var lx = 0
var ly = 0
var ux = 0
var uy = 0

func _ready():
	EntityManager.register_spawner(self)
	
	visible = false
	lx = rect_global_position.x
	ly = rect_global_position.y
	ux = lx + rect_size.x
	uy = ly + rect_size.y
		
func spawn_one(type):
	EntityManager.create_enemy(type, rand_range(lx, ux), rand_range(ly, uy))
