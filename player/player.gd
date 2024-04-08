extends CharacterBody3D

# Define Sprite nodes for each direction
@onready var playerForward = $playerForward
@onready var playerBack = $playerBack
@onready var playerLeft = $playerLeft
@onready var playerRight = $playerRight
@onready var playerForwardLeft = $playerForwardLeft
@onready var playerForwardRight = $playerForwardRight
@onready var playerBackLeft = $playerBackLeft
@onready var playerBackRight = $playerBackRight

@onready var damageTimer = $damageTimer # Timer for taking damage

@onready var attackArea = $Pivot/AttackArea/AttackAreaPoints/AttackAreaDebug

# Player health
var health = 100

# Store the player's last position
var last_position = Vector3.ZERO

var is_colliding_with_mob = false

var colliding_mobs = [] # List of mobs the player is currently colliding with

# How fast the player moves in meters per second.
@export var speed = 14
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75

# The direction the player will fallback to when there is no input
var fallback_direction = Vector3(0, 0, 1)	

var target_velocity = Vector3.ZERO
var target_pos = Vector3.ZERO
var target_enemy = null
var min_distance = 7

var camera : Camera3D = null

# Called when the node enters the scene tree for the first time.
func _ready():

	playerBack.show()
	var cameras = get_tree().get_nodes_in_group("camera")
	if cameras.size() > 0:
		camera = cameras[0] # Now you have the reference to the camera


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):

	var direction = Vector3.ZERO
	
	# Move the character depending on the input
	if Input.is_action_pressed("move_right"):

		direction.x += 1

	if Input.is_action_pressed("move_left"):

		direction.x -= 1

	if Input.is_action_pressed("move_back"):

		direction.z += 1

	if Input.is_action_pressed("move_forward"):

		direction.z -= 1

	# Normalize the direction vector to ensure constant movement speed in all directions
	if direction != Vector3.ZERO:

		direction = direction.normalized()

	# Calculate the players next position
	var new_position = position + direction * speed * delta

	# If the next position is outside the floor radius, stop the character
	if new_position.distance_to(Vector3.ZERO) > 25:

		direction = Vector3.ZERO
	
	# Ground Velocity
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed

	# Vertical Velocity
	if not is_on_floor(): # If in the air, fall towards the floor. Literally gravity

		target_velocity.y = target_velocity.y - (fall_acceleration * delta)

	# Moving the Character
	velocity = target_velocity

	move_and_slide()

	direction_management()
	update_sprite_direction()
	

	# If player's y is less than -2, reset player to starting position
	if global_transform.origin.y < -2:

		global_transform.origin = Vector3(0, 0, 0) # reset player to starting position

		velocity = Vector3.ZERO # stop player from moving
		
		target_velocity = Vector3.ZERO # set target velocity to zero

		direction = Vector3.ZERO # set direction to zero

		target_pos = Vector3.ZERO # set target direction to zero

		target_enemy = null # set target enemy to null

		hide_sprites() # hide all sprites

		# reset player's rotation
		$Pivot.basis = Basis.IDENTITY
		$Pivot.look_at(global_transform.origin + fallback_direction, Vector3.UP)

func take_damage(damage):
	
	if $SubViewport/HealthBar3D.value < damage:
		
		damage = $SubViewport/HealthBar3D.value
		
	$SubViewport/HealthBar3D.value -= damage

	if $SubViewport/HealthBar3D.value == 0:
		
		gameOver()
	
	damageTimer.start()
	
# Take damage on collision with mob
func _on_Mob_body_entered(body):

	if body.is_in_group("enemies"):
		# Add the mob to the array when the player collides with it
		colliding_mobs.append(body)

		take_damage(5)

		damageTimer.start()

func _on_HealthPowerUp_body_entered(body):

	if body.is_in_group("powerUp"):
		
		apply_HealthPowerUp(body)

func _on_Mob_body_exited(body):

	if body.is_in_group("enemies"):

		# Remove the mob from the array when the player stops colliding with it
		colliding_mobs.erase(body)

	if colliding_mobs.size() == 0:
		
		damageTimer.stop() # Stop the timer when the player is no longer colliding with any mob

func _on_damageTimer_timeout():
	
	for mob in colliding_mobs:

		take_damage(5)
		
		
# Function to apply health increase from power up
func apply_HealthPowerUp(body):
	
	var givenHealth = 0

	if $SubViewport/HealthBar3D.value > 80:
		
		givenHealth = 100 - $SubViewport/HealthBar3D.value

	elif $SubViewport/HealthBar3D.value <= 80:
		
		givenHealth = 20

	$SubViewport/HealthBar3D.value += givenHealth
   
	# Remove the power-up from the scene
	body.queue_free()

# Game over function called when player's health is 0
func gameOver():
	
	$SubViewport/HealthBar3D.value = 100
		
	global_transform.origin = Vector3(0, 0, 0) # reset player to starting position

	velocity = Vector3.ZERO # stop player from moving
	
	target_velocity = Vector3.ZERO # set target velocity to zero

	target_pos = Vector3.ZERO # set target direction to zero

	target_enemy = null # set target enemy to null

	var mobsToFree = get_tree().get_nodes_in_group("enemies")

	# Append power ups on screen to enemiesToFree
	var healthPowerUpsToFree = get_tree().get_nodes_in_group("powerUp")


	for mob in mobsToFree:
		
		mob.queue_free()

	for powerUp in healthPowerUpsToFree:
		
		powerUp.queue_free()

	# reset player's rotation
	$Pivot.basis = Basis.IDENTITY # reset player's rotation
	$Pivot.look_at(global_transform.origin + fallback_direction, Vector3.UP)

func direction_management():
	
	var mouse_pos = get_viewport().get_mouse_position()
	if camera:
		var ray_origin = camera.project_ray_origin(mouse_pos)
		var ray_end = ray_origin + camera.project_ray_normal(mouse_pos) * 1000
		
		var space_state = get_world_3d().direct_space_state
		var ray_query = PhysicsRayQueryParameters3D.new()
		ray_query.from = ray_origin
		ray_query.to = ray_end
		ray_query.exclude = [self]
		ray_query.collision_mask = 0xFFFFFFFF 
		
		var intersection = space_state.intersect_ray(ray_query)
		if intersection:
			target_pos = intersection.position
			
			$Pivot.look_at(target_pos, Vector3.UP)
	

func update_sprite_direction():

	var global_facing_direction = -$Pivot.global_transform.basis.z.normalized()
	var angle_degrees = rad_to_deg(atan2(global_facing_direction.x, global_facing_direction.z))
	
	angle_degrees = fmod(angle_degrees, 360)
	if angle_degrees < 0:
		angle_degrees += 360
		
	hide_sprites()
	#print_debug(angle_degrees)
	sprite_direction(angle_degrees)

func sprite_direction(angle_degrees):

  # Adjust angle to be in range 0-360
	if angle_degrees < 0:
    angle_degrees += 360
	
	# Show the sprite corresponding to the current direction
	if angle_degrees > 22.5 and angle_degrees <= 67.5:
		playerBackRight.show()
	elif angle_degrees > 67.5 and angle_degrees <= 112.5:
		playerBack.show()
	elif angle_degrees > 112.5 and angle_degrees <= 157.5:
		playerBackLeft.show()
	elif angle_degrees > 157.5 and angle_degrees <= 202.5:
		playerLeft.show()
	elif angle_degrees > 202.5 and angle_degrees <= 247.5:
		playerForwardLeft.show()
	elif angle_degrees > 247.5 and angle_degrees <= 292.5:
		playerForward.show()
	elif angle_degrees > 292.5 and angle_degrees <= 337.5:
		playerForwardRight.show()
	elif (angle_degrees > 337.5 or angle_degrees <= 22.5) or angle_degrees == 360:
		playerRight.show()

	
func hide_sprites():
	# Hide all sprites
	playerForward.hide()
	playerBack.hide()
	playerBackLeft.hide()
	playerBackRight.hide()
	playerForwardLeft.hide()
	playerForwardRight.hide()
	playerRight.hide()
	playerLeft.hide()
	
	
