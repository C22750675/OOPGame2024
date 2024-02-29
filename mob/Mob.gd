extends CharacterBody3D

# Minimum speed of the mob in meters per second.
@export var min_speed = 4
# Maximum speed of the mob in meters per second.
@export var max_speed = 6

var random_speed = 5

# Acceleration of the mob in meters per second squared.
@export var fall_acceleration = 75

var target_player = null
var min_distance = 15
var health = 10

func _physics_process(delta):

	var direction = Vector3.ZERO

	move_and_slide()

	# If the mob is not on the floor, apply gravity
	if not is_on_floor():

		velocity.y -= fall_acceleration * delta

	# If the mob is within minimum distance of the player, change its movement direction
	if target_player != null and global_transform.origin.distance_to(target_player.global_transform.origin) < min_distance:
		
		direction = (target_player.global_transform.origin - global_transform.origin).normalized()
		
		
		velocity = direction * random_speed
	else:
		
		velocity = velocity.normalized() * random_speed

	# Calculate the players next position to anticipate their movement
	var new_position = position + direction * random_speed * delta

	# Despawn the mob if the next position reaches edge of the map
	if new_position.distance_to(Vector3.ZERO) > 25:

		queue_free()
		
	find_player()

	direction_management()
	

# This function will be called from the Main scene.
func initialize(start_position, player_position):

	# var for players x and z position only
	var player_position_xz = Vector3(player_position.x, start_position.y, player_position.z)

	#position the mob at the start position and rotate it to face the players x and z position only
	look_at_from_position(start_position, player_position_xz)

	# Rotate this mob randomly within range of -90 and +90 degrees,
	#so that it doesn't move directly towards the player.
	rotate_y(randf_range(-PI / 4, PI / 4))

	# We calculate a random speed (integer)
	random_speed = randi_range(min_speed, max_speed)

	# We calculate a forward velocity that represents the speed.
	velocity = Vector3.FORWARD * random_speed

	# We then rotate the velocity vector based on the mob's Y rotation
	# in order to move in the direction the mob is looking.
	velocity = velocity.rotated(Vector3.UP, rotation.y)

func _on_visible_on_screen_notifier_3d_screen_exited():

	queue_free()
	
func take_damage(damage_amount):

	# if the damage is 0 or less, don't do anything
	if damage_amount <= 0:
		
		return
	
	# if the mob is already dead, don't do anything
	if health <= 0:

		return

	# subtract the damage from the health
	health -= damage_amount

	if health <= 0:

		queue_free() # kills mob

		# increment the number of mobs killed
		GlobalVars.mobsKilled += 1

func take_knockback(knockback_amount : float):

	var knockback_direction = (target_player.global_transform.origin - global_transform.origin).normalized()
	var knockback_force = knockback_direction * knockback_amount

	# Apply the knockback force to the mob's velocity
	velocity += knockback_force
	
func find_player():

	# Retrieve player node
	var players = get_tree().get_nodes_in_group("player")

	# Get the first player in the list
	var player = players[0]
	
	var distance_to_player = global_transform.origin.distance_to(player.global_transform.origin)

	# If the current enemy is closer than the previously closest one, update the closest enemy
	if distance_to_player < min_distance:

		target_player = player

	else:
		
		target_player = null
	

func direction_management():

	if target_player != null:

		var look_direction = (target_player.global_transform.origin - global_transform.origin).normalized()
		
		
		if look_direction != Vector3.ZERO:

			var look_rotation = Basis().looking_at(look_direction, Vector3.UP)


			$Pivot.global_transform.basis = look_rotation
