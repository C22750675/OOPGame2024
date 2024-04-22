extends Node

signal start_game()

@onready var main_menu = %MainMenu


# Preload the mob script to read its global variables
var mobScene = preload("res://mob/Mob.tscn")
var healthPowerUpScene = preload("res://powerUp/HealthPowerUp.tscn")

func _on_main_menu_start_game() -> void:
	start_game.emit()

func _ready():

	# Start the round timer
	$RoundTimer.start()
	
	# Start the HealthPowerUpTimer
	$HealthPowerUpTimer.start()
	
func _onHealthPowerUpTimerTimeout():
	
	var healthPowerUp = healthPowerUpScene.instantiate()
	var playerPosition = $Player.position

	# Add the power-up to the scene
	add_child(healthPowerUp)
	
	# Calculate a random position on top of the ground
	var groundRadius = 25
	var angle = randf_range(0, 2 * PI)
	var radius = sqrt(randf()) * groundRadius
	var x = radius * cos(angle)
	var z = radius * sin(angle)
	var y = playerPosition.y + 1
	var position = Vector3(x, y, z)
	
	# Set the power-up's position
	healthPowerUp.global_transform.origin = position


func _onMobSpawnTimerTimeout():

	# Create a new instance of the Mob scene.
	var mob = mobScene.instantiate()
	

	# Choose a random location on the SpawnPath.
	# We store the reference to the SpawnLocation node.
	var mobSpawnLocation = get_node("SpawnPath/SpawnLocation")
	# And give it a random offset
	mobSpawnLocation.progress_ratio = randf()

	var playerPosition = $Player.position
	mob.initialize(mobSpawnLocation.position, playerPosition)

	# Spawn the mob by adding it to the Main scene.
	add_child(mob)


func _process(_delta):

	$KillCounter.text = "Mobs Killed: " + str(GlobalVars.mobsKilled)
	$RoundTimerDisplay.text = "Time Left: " + str(GlobalVars.roundTimer) + " seconds"


func _onRoundTimerTimeout():
	
	if GlobalVars.roundTimer > 0:

		GlobalVars.roundTimer -= 1
		
