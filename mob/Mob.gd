extends CharacterBody3D

# Define Sprite nodes for each direction
@onready var mobForward = $mobForward
@onready var mobBack = $mobBack
@onready var mobLeft = $mobLeft
@onready var mobRight = $mobRight
@onready var mobForwardLeft = $mobForwardLeft
@onready var mobForwardRight = $mobForwardRight
@onready var mobBackLeft = $mobBackLeft
@onready var mobBackRight = $mobBackRight

# Minimum speed of the mob in meters per second.
@export var min_speed = 3

# Maximum speed of the mob in meters per second.
@export var max_speed = 5

# Random speed of the mob in meters per second.
var random_speed

# Acceleration of the mob in meters per second squared.
@export var fall_acceleration = 75

var target_player = null
var targetDistance = 50
@export var health = 20

# Add a timer for the knockback effect
var knockback_timer = 0.2 # Mob will be knocked back for x seconds
var knockback_time = 0

var knockback_force = Vector3.ZERO

var movementState = "normal"

# Called when the node enters the scene tree for the first time.
func _ready():
	if GlobalVars.currentRound == 1:
		min_speed = 3
		max_speed = 5
	elif GlobalVars.currentRound == 2:
		min_speed = 4
		max_speed = 6
	elif GlobalVars.currentRound == 3:
		min_speed = 5
		max_speed = 7
	elif GlobalVars.currentRound == 4:
		min_speed = 6
		max_speed = 8

func _physics_process(delta):
	move_and_slide()
	find_player()
	var direction = Vector3.ZERO
	if movementState == "normal":
		if not is_on_floor():
			velocity.y -= fall_acceleration * delta
		if target_player != null and global_transform.origin.distance_to(target_player.global_transform.origin) < targetDistance:
			direction = (target_player.global_transform.origin - global_transform.origin).normalized()
			velocity = direction
			velocity = velocity.normalized() * random_speed
		else:
			velocity = velocity.normalized() * random_speed
		if direction != Vector3.ZERO:
			direction = direction.normalized()
		direction_management()
		var new_position = position + direction * random_speed * delta
		if new_position.distance_to(Vector3.ZERO) > 25:
			queue_free()
	elif movementState == "knockback":
		velocity += knockback_force
		var damping_factor = 0.3
		knockback_force *= damping_factor
		knockback_time += delta
		if knockback_time >= knockback_timer:
			movementState = "normal"
			knockback_force = Vector3.ZERO
			knockback_time = 0

func initialize(start_position, player_position):
	var player_position_xz = Vector3(player_position.x, start_position.y, player_position.z)
	look_at_from_position(start_position, player_position_xz)
	random_speed = randi_range(min_speed, max_speed)
	velocity = Vector3.FORWARD * random_speed
	velocity = velocity.rotated(Vector3.UP, rotation.y)

func _on_visible_on_screen_notifier_3d_screen_exited():
	queue_free()

func take_damage(damage_amount):
	if damage_amount <= 0:
		return
	if health <= 0:
		return
	health -= damage_amount
	if health <= 0:
		queue_free()
		GlobalVars.mobsKilled += 1

func take_knockback(force : Vector3):
	knockback_force = force
	velocity += knockback_force
	movementState = "knockback"

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	var player = players[0]
	var distance_to_player = global_transform.origin.distance_to(player.global_transform.origin)
	if distance_to_player < targetDistance:
		target_player = player
	else:
		target_player = null

func direction_management():
	if target_player != null:
		look_at(target_player.global_transform.origin, Vector3.UP)
		var direction_to_player = (target_player.global_transform.origin - global_transform.origin).normalized()
		update_sprite_direction(direction_to_player)

func update_sprite_direction(new_target_direction):

	var angle_degrees

	if new_target_direction != Vector3.ZERO:

		angle_degrees = rad_to_deg(atan2(new_target_direction.z, new_target_direction.x))
		
		hide_sprites()
		sprite_direction(angle_degrees)

func sprite_direction(angle_degrees):
	if angle_degrees < 0:
		angle_degrees += 360
	if angle_degrees > 22.5 and angle_degrees <= 67.5:
		mobBackRight.show()
	elif angle_degrees > 67.5 and angle_degrees <= 112.5:
		mobBack.show()
	elif angle_degrees > 112.5 and angle_degrees <= 157.5:
		mobBackLeft.show()
	elif angle_degrees > 157.5 and angle_degrees <= 202.5:
		mobLeft.show()
	elif angle_degrees > 202.5 and angle_degrees <= 247.5:
		mobForwardLeft.show()
	elif angle_degrees > 247.5 and angle_degrees <= 292.5:
		mobForward.show()
	elif angle_degrees > 292.5 and angle_degrees <= 337.5:
		mobForwardRight.show()
	elif (angle_degrees > 337.5 or angle_degrees <= 22.5) or angle_degrees == 360:
		mobRight.show()

func hide_sprites():
	mobForward.hide()
	mobBack.hide()
	mobBackLeft.hide()
	mobBackRight.hide()
	mobForwardLeft.hide()
	mobForwardRight.hide()
	mobRight.hide()
	mobLeft.hide()
