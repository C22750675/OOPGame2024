extends CharacterBody3D

# Define Sprite nodes for each direction
@onready var playerForward = $PlayerForward
@onready var playerBack = $PlayerBack
@onready var playerLeft = $PlayerLeft
@onready var playerRight = $PlayerRight
@onready var playerForwardLeft = $PlayerForwardLeft
@onready var playerForwardRight = $PlayerForwardRight
@onready var playerBackLeft = $PlayerBackLeft
@onready var playerBackRight = $PlayerBackRight

@onready var damageTimer = $DamageTimer # Timer for taking damage


# Player health
var health = 100

# Store the player's last position
var lastPosition = Vector3.ZERO

var isCollidingWithMob = false

var collidingMobs = [] # List of mobs the player is currently colliding with

# How fast the player moves in meters per second.
@export var speed = 14
# The downward acceleration when in the air, in meters per second squared.
@export var fallAcceleration = 75

# The direction the player will fallback to when there is no input
var fallbackDirection = Vector3(0, 0, 1)	

var targetVelocity = Vector3.ZERO
var targetPos = Vector3.ZERO
var targetEnemy = null
var minDistance = 7

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
	var newPosition = position + direction * speed * delta

	# If the next position is outside the floor radius, stop the character
	if newPosition.distance_to(Vector3.ZERO) > 25:

		direction = Vector3.ZERO
	
	# Ground Velocity
	targetVelocity.x = direction.x * speed
	targetVelocity.z = direction.z * speed

	# Vertical Velocity
	if not is_on_floor(): # If in the air, fall towards the floor. Literally gravity

		targetVelocity.y = targetVelocity.y - (fallAcceleration * delta)

	# Moving the Character
	velocity = targetVelocity

	move_and_slide()

	directionManagement()
	updateSpriteDirection()
	

	# If player's y is less than -2, reset player to starting position
	if global_transform.origin.y < -2:

		global_transform.origin = Vector3(0, 0, 0) # reset player to starting position

		velocity = Vector3.ZERO # stop player from moving
		
		targetVelocity = Vector3.ZERO # set target velocity to zero

		direction = Vector3.ZERO # set direction to zero

		targetPos = Vector3.ZERO # set target direction to zero

		targetEnemy = null # set target enemy to null

		hideSprites() # hide all sprites

		# reset player's rotation
		$Pivot.basis = Basis.IDENTITY
		$Pivot.look_at(global_transform.origin + fallbackDirection, Vector3.UP)

func takeDamage(damage):
	
	if $SubViewport/HealthBar3D.value < damage:
		
		damage = $SubViewport/HealthBar3D.value
		
	$SubViewport/HealthBar3D.value -= damage

	if $SubViewport/HealthBar3D.value == 0:
		
		gameOver()
	
	damageTimer.start()
	
# Take damage on collision with mob
func _onMobBodyEntered(body):

	if body.is_in_group("enemies"):
		# Add the mob to the array when the player collides with it
		collidingMobs.append(body)

		takeDamage(5)

		damageTimer.start()

func _onHealthPowerUpBodyEntered(body):

	if body.is_in_group("powerUp"):
		
		applyHealthPowerUp(body)

func _onMobBodyExited(body):

	if body.is_in_group("enemies"):

		# Remove the mob from the array when the player stops colliding with it
		collidingMobs.erase(body)

	if collidingMobs.size() == 0:
		
		damageTimer.stop() # Stop the timer when the player is no longer colliding with any mob

func _onDamageTimerTimeout():
	
	for mob in collidingMobs:

		takeDamage(5)
		
		
# Function to apply health increase from power up
func applyHealthPowerUp(body):
	
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
	
	targetVelocity = Vector3.ZERO # set target velocity to zero

	targetPos = Vector3.ZERO # set target direction to zero

	targetEnemy = null # set target enemy to null

	var mobsToFree = get_tree().get_nodes_in_group("enemies")

	# Append power ups on screen to enemiesToFree
	var healthPowerUpsToFree = get_tree().get_nodes_in_group("powerUp")


	for mob in mobsToFree:
		
		mob.queue_free()

	for powerUp in healthPowerUpsToFree:
		
		powerUp.queue_free()

	# reset player's rotation
	$Pivot.basis = Basis.IDENTITY # reset player's rotation
	$Pivot.look_at(global_transform.origin + fallbackDirection, Vector3.UP)

func directionManagement():
	
	var mousePos = get_viewport().get_mouse_position()
	if camera:
		var rayOrigin = camera.project_ray_origin(mousePos)
		var rayEnd = rayOrigin + camera.project_ray_normal(mousePos) * 1000
		
		var spaceState = get_world_3d().direct_space_state
		var rayQuery = PhysicsRayQueryParameters3D.new()
		rayQuery.from = rayOrigin
		rayQuery.to = rayEnd
		rayQuery.exclude = [self]
		rayQuery.collision_mask = 0xFFFFFFFF 
		
		var intersection = spaceState.intersect_ray(rayQuery)
		if intersection:
			targetPos = intersection.position
			
			$Pivot.look_at(targetPos, Vector3.UP)
	

func updateSpriteDirection():

	var globalFacingDirection = -$Pivot.global_transform.basis.z.normalized()
	var angleDegrees = rad_to_deg(atan2(globalFacingDirection.x, globalFacingDirection.z))
	
	angleDegrees = fmod(angleDegrees, 360)

	if angleDegrees < 0:
		angleDegrees += 360
		
	hideSprites()
	#print_debug(angle_degrees)
	spriteDirection(angleDegrees)

func spriteDirection(angleDegrees):

  # Adjust angle to be in range 0-360
	if angleDegrees < 0:
		angleDegrees += 360
	
	# Determine which sprite to show based on angle
	if angleDegrees >= 337.5 or angleDegrees < 22.5:
		playerBack.show()
	elif angleDegrees >= 22.5 and angleDegrees < 67.5:
		playerBackRight.show()
	elif angleDegrees >= 67.5 and angleDegrees < 112.5:
		playerRight.show()
	elif angleDegrees >= 112.5 and angleDegrees < 157.5:
		playerForwardRight.show()
	elif angleDegrees >= 157.5 and angleDegrees < 202.5:
		playerForward.show()
	elif angleDegrees >= 202.5 and angleDegrees < 247.5:
		playerForwardLeft.show()
	elif angleDegrees >= 247.5 and angleDegrees < 292.5:
		playerLeft.show() 
	elif angleDegrees >= 292.5 and angleDegrees < 337.5:
		playerBackLeft.show()

	
func hideSprites():
	# Hide all sprites
	playerForward.hide()
	playerBack.hide()
	playerBackLeft.hide()
	playerBackRight.hide()
	playerForwardLeft.hide()
	playerForwardRight.hide()
	playerRight.hide()
	playerLeft.hide()
	
	
