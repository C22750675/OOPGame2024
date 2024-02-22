extends CharacterBody3D

# Minimum speed of the mob in meters per second.
@export var min_speed = 5
# Maximum speed of the mob in meters per second.
@export var max_speed = 6

# Acceleration of the mob in meters per second squared.
@export var fall_acceleration = 75


var health = 10

func _physics_process(delta):

	move_and_slide()

	# If the mob is not on the floor, apply gravity
	if not is_on_floor():
		velocity.y -= fall_acceleration * delta

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
	var random_speed = randi_range(min_speed, max_speed)

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

	#print("health", health)
	if health <= 0:

		queue_free() # kills mob

		# increment the number of mobs killed
		GlobalVars.mobsKilled += 1
