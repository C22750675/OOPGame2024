extends CharacterBody3D

# Define Sprite nodes for each direction
@onready var sprite_forward = $crabUp
@onready var sprite_backward = $crabDown
@onready var sprite_left = $crabLeft
@onready var sprite_right = $crabRight
@onready var sprite_up_left = $crabUpLeft
@onready var sprite_up_right = $crabUpRight
@onready var sprite_down_left = $crabDownLeft
@onready var sprite_down_right = $crabDownRight


# How fast the player moves in meters per second.
@export var speed = 14
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75

var fallback_direction = Vector3(0, 0, 1)	

var target_velocity = Vector3.ZERO
var target_direction = Vector3.ZERO
var target_enemy = null
var min_distance = 7

func _physics_process(delta):
	var direction = Vector3.ZERO

	# Find nearest enemy
	find_nearest_enemy()
		
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_back"):
		direction.z += 1
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1
		
	print_debug(direction)
		
	if direction != Vector3.ZERO:
		direction = direction.normalized()

	# Ground Velocity
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed

	# Vertical Velocity
	if not is_on_floor(): # If in the air, fall towards the floor. Literally gravity
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)

	# Moving the Character
	velocity = target_velocity
	move_and_slide()
	
	if target_enemy != null:
		target_direction = (target_enemy.global_transform.origin - global_transform.origin).normalized()
		$Pivot.basis = Basis.looking_at(target_direction, Vector3.UP)
		update_sprite_direction(target_direction)
		
	else:
		$Pivot.look_at(global_transform.origin + fallback_direction, Vector3.UP)
		target_direction = Vector3.ZERO
		hide_sprites()
		sprite_backward.show()
		
	

func find_nearest_enemy():
	# Retrieve all nodes tagged as enemies in the scene
	var enemies = get_tree().get_nodes_in_group("Enemies")
	
	# If there are no enemies, return early
	if enemies.size() == 0:
		target_enemy = null
		return
		
	var closest_distance = float(min_distance)
	var closest_enemy = null
	
	# Iterate through each enemy and calculate the distance to the character
	for enemy in enemies:
		var distance_to_enemy = global_transform.origin.distance_to(enemy.global_transform.origin)
	
		# If the current enemy is closer than the previously closest one, update the closest enemy
		if distance_to_enemy < closest_distance:
			closest_distance = distance_to_enemy
			closest_enemy = enemy
			
	# Update the target_enemy variable with the closest enemy found
	target_enemy = closest_enemy
	
func update_sprite_direction(target_direction):
	#print("Direction:", direction)
	var angle_degrees
	if target_direction != Vector3.ZERO:
		angle_degrees = rad_to_deg(atan2(target_direction.z, target_direction.x))
		hide_sprites()
		spite_direction(angle_degrees)
		
	
func spite_direction(angle_degrees):
	# Adjust angle to be in range 0-360
	if angle_degrees < 0:
		angle_degrees += 360
	
	print("angleDegrees:", angle_degrees)
	
	# Show the sprite corresponding to the current direction
	if angle_degrees > 22.5 and angle_degrees <= 67.5:
		sprite_down_right.show()
	elif angle_degrees > 67.5 and angle_degrees <= 112.5:
		sprite_backward.show()
	elif angle_degrees > 112.5 and angle_degrees <= 157.5:
		sprite_down_left.show()
	elif angle_degrees > 157.5 and angle_degrees <= 202.5:
		sprite_left.show()
	elif angle_degrees > 202.5 and angle_degrees <= 247.5:
		sprite_up_left.show()
	elif angle_degrees > 247.5 and angle_degrees <= 292.5:
		sprite_forward.show()
	elif angle_degrees > 292.5 and angle_degrees <= 337.5:
		sprite_up_right.show()
	elif (angle_degrees > 337.5 or angle_degrees <= 22.5) and (angle_degrees != 0) or angle_degrees == Vector3(1, 0, 0):
		sprite_right.show()
	
func hide_sprites():
	# Hide all sprites
	sprite_forward.hide()
	sprite_backward.hide()
	sprite_left.hide()
	sprite_right.hide()
	sprite_up_left.hide()
	sprite_up_right.hide()
	sprite_down_left.hide()
	sprite_down_right.hide()
	
