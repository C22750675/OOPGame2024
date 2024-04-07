extends Node

@export var mob_scene: PackedScene

# Preload the mob script to read its global variables
var Mob = preload("res://mob/Mob.gd")
var HealthPowerUpScene = preload("res://powerUp/HealthPowerUp.tscn")

func _ready():

	# Start the round timer
	$roundTimer.start()
	
	# Start the HealthPowerUpTimer
	$healthPowerUpTimer.start()
	
func _on_healthPowerUpTimer_timeout():
	
	var healthPowerUp = HealthPowerUpScene.instantiate()
	var player_position = $Player.position

	# Add the power-up to the scene
	add_child(healthPowerUp)
	
	# Calculate a random position on top of the ground
	var ground_radius = 25
	var angle = randf_range(0, 2 * PI)
	var radius = sqrt(randf()) * ground_radius
	var x = radius * cos(angle)
	var z = radius * sin(angle)
	var y = player_position.y + 1
	var position = Vector3(x, y, z)
	
	# Set the power-up's position
	healthPowerUp.global_transform.origin = position


func _on_mobSpawnTimer_timeout():

	# Create a new instance of the Mob scene.
	var mob = mob_scene.instantiate()
	

	# Choose a random location on the SpawnPath.
	# We store the reference to the SpawnLocation node.
	var mob_spawn_location = get_node("SpawnPath/SpawnLocation")
	# And give it a random offset
	mob_spawn_location.progress_ratio = randf()

	var player_position = $Player.position
	mob.initialize(mob_spawn_location.position, player_position)

	# Spawn the mob by adding it to the Main scene.
	add_child(mob)


func _process(_delta):

	$killCounter.text = "Mobs Killed: " + str(GlobalVars.mobsKilled)
	$roundTimerDisplay.text = "Time Left: " + str(GlobalVars.roundTimer) + " seconds"


func _on_roundTimer_timeout():
	
	if GlobalVars.roundTimer > 0:

		GlobalVars.roundTimer -= 1
		
