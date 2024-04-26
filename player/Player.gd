extends CharacterBody3D

# Define sprite nodes for each direction
@onready var sprites = {

	"pForward": $PlayerForward,
	"pBack": $PlayerBack,
	"pLeft": $PlayerLeft,
	"pRight": $PlayerRight,
	"pForwardLeft": $PlayerForwardLeft,
	"pForwardRight": $PlayerForwardRight,
	"pBackLeft": $PlayerBackLeft,
	"pBackRight": $PlayerBackRight

}

@onready var damageTimer = $DamageTimer # Timer for taking damage
@onready var player_takes_damage = $PlayerTakesDamage
@onready var health_power_up = $HealthPowerUp



# Player health
var health = 75
var canMove: bool = false

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
var minDistance = 7

var camera : Camera3D = null

# Called when the node enters the scene tree for the first time.
func _ready():

	sprites["pBack"].show()

	var cameras = get_tree().get_nodes_in_group("camera")


	if cameras.size() > 0:
		camera = cameras[0] # Now you have the reference to the camera

func getInputDirection() -> Vector3:
	
	var direction = Vector3.ZERO
	
	if canMove == true:
		# Move the character depending on the input
		if Input.is_action_pressed("move_right"):
			direction.x += 1
		if Input.is_action_pressed("move_left"):
			direction.x -= 1
		if Input.is_action_pressed("move_back"):
			direction.z += 1
		if Input.is_action_pressed("move_forward"):
			direction.z -= 1

	if direction != Vector3.ZERO:
		return direction.normalized() # Normalize the direction vector to ensure constant movement speed in all directions
	else:
		return direction


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):

	# Return early if the player can't move
	if canMove == false:
		return

	# Set default animation speed
	for sprite in sprites.values():

		sprite.speed_scale = 2

	var direction = getInputDirection()  # Get the movement direction based on player input

	var currentSpeed = speed  # Set the current speed to the default speed


	if Input.is_action_pressed("boost"):

		currentSpeed *= 1.5  # Double the speed

		# Increase the animation speed
		for sprite in sprites.values():

			sprite.speed_scale = 3



	# Calculate the players next position
	var newPosition = position + direction * currentSpeed * delta

	# If the next position is outside the floor radius, stop the character
	if newPosition.distance_to(Vector3.ZERO) > 25:

		direction = Vector3.ZERO
	
	# Ground Velocity
	targetVelocity.x = direction.x * currentSpeed
	targetVelocity.z = direction.z * currentSpeed

	# Vertical Velocity
	if not is_on_floor(): # If in the air, fall towards the floor

		targetVelocity.y = targetVelocity.y - (fallAcceleration * delta)

	# Moving the Character
	velocity = targetVelocity

	move_and_slide()

	directionManagement()
	updateSpriteDirection()


	if direction == Vector3.ZERO:
		
		for sprite in sprites.values():

			sprite.stop()
			
	else:

		for sprite in sprites.values():

			sprite.play("Walk")


	# If player's y is less than -2, reset player to starting position
	if global_transform.origin.y < -2:

		global_transform.origin = Vector3(0, 0, 0) # reset player to starting position

		velocity = Vector3.ZERO # stop player from moving
		
		targetVelocity = Vector3.ZERO # set target velocity to zero

		direction = Vector3.ZERO # set direction to zero

		targetPos = Vector3.ZERO # set target direction to zero

		hideSprites() # hide all sprites

		# reset player's rotation
		$Pivot.basis = Basis.IDENTITY
		$Pivot.look_at(global_transform.origin + fallbackDirection, Vector3.UP)

func takeDamage(damage):
	
	if $SubViewport/HealthBar3D.value < damage:
		
		damage = $SubViewport/HealthBar3D.value
		
	$SubViewport/HealthBar3D.value -= damage

	if $SubViewport/HealthBar3D.value == 0:
		
		playerReset()

		return
	
	damageTimer.start()
	
# Take damage on collision with mob
func _onMobBodyEntered(body):

	if body.is_in_group("enemies"):
		# Add the mob to the array when the player collides with it
		collidingMobs.append(body)

		takeDamage(10)
		player_takes_damage.play()

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
	
	
	var baseDamage = 5  # Define a base damage amount
	var scalingFactor = 1.0  # Default scaling factor

	# Adjust scaling factor based on the current round
	match GlobalVars.currentRound:
		1:
			scalingFactor = 1.0
		2:
			scalingFactor = 1.5
		3:
			scalingFactor = 2.0
		4:
			scalingFactor = 2.5
		_:
			scalingFactor = 3.0

	var scaledDamage = baseDamage * scalingFactor  # Calculate scaled damage

	for mob in collidingMobs:
		player_takes_damage.play()
		takeDamage(scaledDamage)

# Function to apply health increase from power up
func applyHealthPowerUp(body):
	
	var givenHealth = 0

	if $SubViewport/HealthBar3D.value > 65:
		
		givenHealth = 75 - $SubViewport/HealthBar3D.value

	elif $SubViewport/HealthBar3D.value <= 65:
		
		givenHealth = 10

	$SubViewport/HealthBar3D.value += givenHealth
	
	health_power_up.play()
   
	# Remove the power-up from the scene
	body.queue_free()

# Game over function called when player's health is 0
func playerReset():
	
	$SubViewport/HealthBar3D.value = 75

	velocity = Vector3.ZERO # stop player from moving
	
	targetVelocity = Vector3.ZERO # set target velocity to zero

	targetPos = Vector3.ZERO # set target direction to zero

	# reset player's rotation
	$Pivot.basis = Basis.IDENTITY # reset player's rotation
	$Pivot.look_at(global_transform.origin + fallbackDirection, Vector3.UP)

	#get_tree().change_scene_to_file("res://ui/end_menu.tscn")
	# Call gameOver in the main script
	get_tree().get_root().get_node("Main").gameOver()

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
			
			targetPos = Vector3(intersection.position.x, global_transform.origin.y, intersection.position.z)
			
			$Pivot.look_at(targetPos, Vector3.UP)
	

func updateSpriteDirection():

	var globalFacingDirection = -$Pivot.global_transform.basis.z.normalized()
	var angleDegrees = rad_to_deg(atan2(globalFacingDirection.x, globalFacingDirection.z))
	
	angleDegrees = fmod(angleDegrees, 360)

	if angleDegrees < 0:
		angleDegrees += 360
		
	hideSprites()

	spriteDirection(angleDegrees)

func spriteDirection(angleDegrees):

	# List of direction ranges
	var directions = [

		{"range": [337.5, 360], "sprite": "pBack"},
		{"range": [0, 22.5], "sprite": "pBack"},
		{"range": [22.5, 67.5], "sprite": "pBackRight"},
		{"range": [67.5, 112.5], "sprite": "pRight"},
		{"range": [112.5, 157.5], "sprite": "pForwardRight"},
		{"range": [157.5, 202.5], "sprite": "pForward"},
		{"range": [202.5, 247.5], "sprite": "pForwardLeft"},
		{"range": [247.5, 292.5], "sprite": "pLeft"},
		{"range": [292.5, 337.5], "sprite": "pBackLeft"}
	]


	# Adjust angle to be in range 0-360
	if angleDegrees < 0:
		angleDegrees += 360

	# Determine which sprite to show based on angle
	for direction in directions:

		var angleRange = direction["range"]


		if (angleDegrees >= angleRange[0]) and (angleDegrees <= angleRange[1]):
	
			sprites[direction["sprite"]].show()


func hideSprites():

	# Hide all sprites
	for sprite in sprites.values():
		sprite.hide()
	
	
