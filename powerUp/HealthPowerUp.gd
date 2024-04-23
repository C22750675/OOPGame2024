extends CharacterBody3D


# Acceleration of the mob in meters per second squared.
@export var fallAcceleration = 500

# Called when the node enters the scene tree for the first time
func _ready():

	pass

# Called every frame
func _physics_process(delta):
	
	velocity = Vector3.ZERO

	# The power up falls to the ground
	velocity.y -= fallAcceleration * delta

	# Rotate the power up
	rotate_y(delta)
	


