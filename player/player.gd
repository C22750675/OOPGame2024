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

@onready var damage_timer = $damageTimer # Timer for taking damage

@onready var attackArea = $Pivot/attackArea/attackArea/attackArea_debug

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
var target_direction = Vector3.ZERO
var target_enemy = null
var min_distance = 7

# Called when the node enters the scene tree for the first time.
func _ready():

	sprite_backward.show()


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
	
	# Find nearest enemy
	find_nearest_enemy()

	# Ground Velocity
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed

	# Vertical Velocity
	if not is_on_floor(): # If in the air, fall towards the floor. Literally gravity

		target_velocity.y = target_velocity.y - (fall_acceleration * delta)

	# Moving the Character
	velocity = target_velocity

	move_and_slide()

	direction_management(direction)

	# If player's y is less than -2, reset player to starting position
	if global_transform.origin.y < -2:

		global_transform.origin = Vector3(0, 0, 0) # reset player to starting position

		velocity = Vector3.ZERO # stop player from moving
		
		target_velocity = Vector3.ZERO # set target velocity to zero

		direction = Vector3.ZERO # set direction to zero

		target_direction = Vector3.ZERO # set target direction to zero

		target_enemy = null # set target enemy to null

		hide_sprites() # hide all sprites

		# reset player's rotation
		$Pivot.basis = Basis.IDENTITY
		$Pivot.look_at(global_transform.origin + fallback_direction, Vector3.UP)
		update_sprite_direction(fallback_direction)

func take_damage(damage):
	
	if $SubViewport/HealthBar3D.value < damage:
		
		damage = $SubViewport/HealthBar3D.value
		
	$SubViewport/HealthBar3D.value -= damage

	if $SubViewport/HealthBar3D.value == 0:
		
		gameOver()
	
	damage_timer.start()
	
# Take damage on collision with mob
func _on_Mob_body_entered(body):

	if body.is_in_group("Enemies"):
		# Add the mob to the array when the player collides with it
		colliding_mobs.append(body)

		take_damage(5)

		damage_timer.start() # Start the timer when the player collides with a mob

func _on_Mob_body_exited(body):

	if body.is_in_group("Enemies"):

		# Remove the mob from the array when the player stops colliding with it
		colliding_mobs.erase(body)

	if colliding_mobs.size() == 0:
		
		damage_timer.stop() # Stop the timer when the player is no longer colliding with any mob

func _on_damage_timer_timeout():
	
	for mob in colliding_mobs:

		take_damage(5)

# Game over function called when player's health is 0
func gameOver():
	
	$SubViewport/HealthBar3D.value = 100
		
	global_transform.origin = Vector3(0, 0, 0) # reset player to starting position

	velocity = Vector3.ZERO # stop player from moving
	
	target_velocity = Vector3.ZERO # set target velocity to zero

	target_direction = Vector3.ZERO # set target direction to zero

	target_enemy = null # set target enemy to null

	var mobs = get_tree().get_nodes_in_group("Enemies")

	for mob in mobs:
		
		mob.queue_free()

	# reset player's rotation
	$Pivot.basis = Basis.IDENTITY # reset player's rotation
	$Pivot.look_at(global_transform.origin + fallback_direction, Vector3.UP)
	update_sprite_direction(fallback_direction)

func direction_management(direction):

	var look_direction = direction

	if look_direction == Vector3.ZERO and target_enemy != null:
		look_direction = (target_enemy.global_transform.origin - global_transform.origin).normalized()

	if look_direction != Vector3.ZERO:
		$Pivot.basis = Basis.looking_at(look_direction, Vector3.UP)
		update_sprite_direction(look_direction)

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
	
func update_sprite_direction(new_target_direction):

	var angle_degrees

	if new_target_direction != Vector3.ZERO:

		angle_degrees = rad_to_deg(atan2(new_target_direction.z, new_target_direction.x))

		hide_sprites()

		# Show the sprite corresponding to the current direction
		sprite_direction(angle_degrees)
	
func sprite_direction(angle_degrees):

	# Adjust angle to be in range 0-360
	if angle_degrees < 0:

		angle_degrees += 360
	
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

	elif (angle_degrees > 337.5 or angle_degrees <= 22.5) or angle_degrees == 360:
		
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
