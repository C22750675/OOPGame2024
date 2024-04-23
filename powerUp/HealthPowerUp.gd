extends CharacterBody3D

# Called when the node enters the scene tree for the first time
func _ready():

	pass

# Called every frame
func _physics_process(delta):

	# Rotate the power up
	rotate_y(delta)
	


