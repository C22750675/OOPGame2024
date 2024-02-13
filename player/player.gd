extends CharacterBody3D

# How fast the player moves in meters per second.
@export var speed = 14
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75

var fallback_direction = Vector3(0, 0, 270)	

var target_velocity = Vector3.ZERO
var target_enemy = null
var min_distance = 7

func _physics_process(delta):
	var direction = Vector3.ZERO

	# Find nearest enemy
	find_nearest_enemy()

	if target_enemy != null:
		var target_direction = (target_enemy.global_transform.origin - global_transform.origin).normalized()
		$Pivot.basis = Basis.looking_at(target_direction, Vector3.UP)
		
	if target_enemy == null:
		$Pivot.look_at(global_transform.origin + fallback_direction, Vector3.UP)
		

	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_back"):
		direction.z += 1
	if Input.is_action_pressed("move_forward"):
		direction.z -= 1

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
	
