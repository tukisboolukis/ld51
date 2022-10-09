extends Control

export (AnimatedTexture) var health_texture
const health_y_offset = 32
const health_x = 99
var health_y = 0
const health_size = 32

var player_health = 10

func _ready():
	health_y = get_viewport_rect().size.y - health_size - 180
	
func _draw():
	var temp_health_y = health_y
	for i in player_health:
		draw_texture_rect(health_texture, Rect2(health_x, health_y, health_size, health_size), false)
		health_y -= health_y_offset
	health_y = temp_health_y
	
func update_player_health(health):
	if health > 40:
		health = 40
	player_health = health
	update()
