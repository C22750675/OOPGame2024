extends Sprite3D


# Called when the node enters the scene tree for the first time.
func _ready():
	
	texture = $SubViewport.get_texture()
	
func update_health(health):
	
	$SubViewport/HealthBar2D.update_health(health)
