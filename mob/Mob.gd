extends CharacterBody3D

# Define Sprite nodes for each direction
@onready var mobForward = $MobForward
@onready var mobBack = $MobBack
@onready var mobLeft = $MobLeft
@onready var mobRight = $MobRight
@onready var mobForwardLeft = $MobForwardLeft
@onready var mobForwardRight = $MobForwardRight
@onready var mobBackLeft = $MobBackLeft
@onready var mobBackRight = $MobBackRight

@onready var mobDies = $MobDies

@onready var deathAnimation = $DeathAnimation


# Minimum speed of the mob in meters per second.
@export var minSpeed = 3

# Maximum speed of the mob in meters per second.
@export var maxSpeed = 5

# Random speed of the mob in meters per second.
var randomSpeed

# Acceleration of the mob in meters per second squared.
@export var fallAcceleration = 75

var targetPlayer = null

@export var health = 20

var knockbackForce = Vector3.ZERO

var movementState


# Called when the node enters the scene tree for the first time.
func _ready():

	movementState = "normal"

	var speedRanges = {
		
		1: [3, 5],
		2: [4, 6],
		3: [5, 7],
		4: [6, 8]
	}
	if GlobalVars.currentRound in speedRanges:
		minSpeed = speedRanges[GlobalVars.currentRound][0]
		maxSpeed = speedRanges[GlobalVars.currentRound][1]
	else:
		# Default speed range for rounds beyond 4
		minSpeed = 9
		maxSpeed = 10

	mobForward.play("Walk")
	mobBack.play("Walk")
	mobLeft.play("Walk")
	mobRight.play("Walk")
	mobForwardLeft.play("Walk")
	mobForwardRight.play("Walk")
	mobBackLeft.play("Walk")
	mobBackRight.play("Walk")

		
func _physics_process(delta):

	move_and_slide()
	findPlayer()

	var direction = Vector3.ZERO


	if movementState == "normal":

		if not is_on_floor():

			velocity.y -= fallAcceleration * delta

		if targetPlayer != null:

			direction = (targetPlayer.global_transform.origin - global_transform.origin).normalized()
			velocity = direction
			velocity = velocity.normalized() * randomSpeed

		else:

			velocity = velocity.normalized() * randomSpeed

		if direction != Vector3.ZERO:

			direction = direction.normalized()

		directionManagement()

		var newPosition = position + direction * randomSpeed * delta

		# If the mob is too far from the player, kill it
		if newPosition.distance_to(Vector3.ZERO) > 25:

			queue_free()

	elif movementState == "knockback":

		velocity = velocity.lerp(Vector3.ZERO, 0.1)  # Dampen the knockback force

	elif movementState == "dead":

		# Mob faces forward and doesn't move
		
		velocity = Vector3.ZERO

		hideSprites()

		# Animate the death of the mob and pass current position to the function
		animateDeath()


func initialize(startPosition, playerPosition):
	
	var playerPositionXZ = Vector3(playerPosition.x, startPosition.y, playerPosition.z)


	look_at_from_position(startPosition, playerPositionXZ)

	randomSpeed = randi_range(minSpeed, maxSpeed)

	velocity = Vector3.FORWARD * randomSpeed
	velocity = velocity.rotated(Vector3.UP, rotation.y)


func _onVisibleOnScreenNotifier3DScreenExited():

	queue_free()


func takeDamage(damageAmount):

	if damageAmount <= 0:
		
		return

		
	health -= damageAmount

	if health <= 0:

		# Set the movement state to dead
		movementState = "dead"
		
		mobDies.play()

	 	# Increment the number of mobs killed
		GlobalVars.mobsKilled += 1


func takeKnockback(force : Vector3):
	
	# If health is less than or equal to 0, don't apply knockback
	if health <= 0:
		
		return


	knockbackForce = force

	# Apply the knockback force to the mob
	velocity += knockbackForce

	
	movementState = "knockback"
	$KnockbackTimer.start()  # Start knockback timer


func findPlayer():

	var players = get_tree().get_nodes_in_group("player")
	var player = players[0]

	targetPlayer = player


func directionManagement():

	if targetPlayer != null:

		look_at(targetPlayer.global_transform.origin, Vector3.UP)

		var directionToPlayer = (targetPlayer.global_transform.origin - global_transform.origin).normalized()


		updateSpriteDirection(directionToPlayer)
	
	else:

		push_error("No player found")

func updateSpriteDirection(newTargetDirection):

	var angleDegrees

	if newTargetDirection != Vector3.ZERO:

		angleDegrees = rad_to_deg(atan2(newTargetDirection.z, newTargetDirection.x))
		
		hideSprites()
		spriteDirection(angleDegrees)

func spriteDirection(angleDegrees):

	if angleDegrees < 0:
		angleDegrees += 360

	if angleDegrees > 22.5 and angleDegrees <= 67.5:
		mobBackRight.show()

	elif angleDegrees > 67.5 and angleDegrees <= 112.5:
		mobBack.show()

	elif angleDegrees > 112.5 and angleDegrees <= 157.5:
		mobBackLeft.show()

	elif angleDegrees > 157.5 and angleDegrees <= 202.5:
		mobLeft.show()

	elif angleDegrees > 202.5 and angleDegrees <= 247.5:
		mobForwardLeft.show()

	elif angleDegrees > 247.5 and angleDegrees <= 292.5:
		mobForward.show()

	elif angleDegrees > 292.5 and angleDegrees <= 337.5:
		mobForwardRight.show()
		
	elif (angleDegrees > 337.5 or angleDegrees <= 22.5) or angleDegrees == 360:
		mobRight.show()

func hideSprites():

	mobForward.hide()
	mobBack.hide()
	mobBackLeft.hide()
	mobBackRight.hide()
	mobForwardLeft.hide()
	mobForwardRight.hide()
	mobRight.hide()
	mobLeft.hide()

func animateDeath():

	# Show the death sprite
	deathAnimation.show()

	# Play the death animation
	deathAnimation.play("Smoke")

func killMob():

	queue_free()

func _onKnockbackTimerTimeout():

	movementState = "normal"  # Set the movement state back to normal
	velocity = Vector3.ZERO  # Reset velocity after knockback
