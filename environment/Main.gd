extends Node

signal start_game()


@onready var main_menu = %MainMenu
@onready var Music_Bus_ID = AudioServer.get_bus_index("Music")
@onready var MobDies_Bus_ID = AudioServer.get_bus_index("MobDies")
@onready var MobKnockback_Bus_ID = AudioServer.get_bus_index("MobKnockback")
@onready var HealthPowerUp_Bus_ID = AudioServer.get_bus_index("HealthPowerUp")
@onready var PlayerDamage_Bus_ID = AudioServer.get_bus_index("PlayerDamage")
@onready var in_game_menu = $InGameMenu


# Preload the mob script to read its global variables
var mobScene = preload("res://mob/Mob.tscn")
var healthPowerUpScene = preload("res://powerUp/HealthPowerUp.tscn")

func _on_main_menu_start_game() -> void:
	start_game.emit()

func _ready():

	# Start the round timer
	$OneSecond.start()
	
	# Start the HealthPowerUpTimer
	$HealthPowerUpTimer.start()
	

func _input(event):
	
	if event.is_action_pressed("ui_cancel"):
		in_game_menu.visible = !in_game_menu.visible
	
	
func _onHealthPowerUpTimerTimeout():
	
	# Calculate a random position on top of the ground
	var groundRadius = 25
	var angle = randf_range(0, 2 * PI)
	var radius = sqrt(randf()) * groundRadius

	#Calculate the x, y and z coordinates of the power-up
	var x = radius * cos(angle)
	var y = $Player.position.y + 1  # Add 1 to the player's y position
	var z = radius * sin(angle)

	# Create a position Vector3 with the x, y and z coordinates
	var position = Vector3(x, y, z)

	# Create a new instance of the HealthPowerUp scene
	var healthPowerUp = healthPowerUpScene.instantiate()

	# Add the power-up to the scene
	add_child(healthPowerUp)

	# Set the power-up's position to the calculated position
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

func _onOneSecondTimout():
	
	if GlobalVars.roundTimer > 0:

		GlobalVars.roundTimer -= 1

	else:
		# Increment currentRound
		GlobalVars.currentRound += 1

		GlobalVars.roundTimer = 60

	# Update the UI labels once per second
	$KillCounter.text = "Mobs Killed: " + str(GlobalVars.mobsKilled)
	$RoundTimerDisplay.text = "Time Left: " + str(GlobalVars.roundTimer) + " seconds"
	$RoundNumber.text = "Round: " + str(GlobalVars.currentRound)


func _on_music_slider_value_changed(value):

	AudioServer.set_bus_volume_db(Music_Bus_ID, linear_to_db(value))
	AudioServer.set_bus_mute(Music_Bus_ID, value < 0.05)


func _on_sfx_slider_value_changed(value):
	
	AudioServer.set_bus_volume_db(MobDies_Bus_ID, linear_to_db(value))
	AudioServer.set_bus_volume_db(MobKnockback_Bus_ID, linear_to_db(value))
	AudioServer.set_bus_volume_db(HealthPowerUp_Bus_ID, linear_to_db(value))
	AudioServer.set_bus_volume_db(PlayerDamage_Bus_ID, linear_to_db(value))
	AudioServer.set_bus_mute(MobDies_Bus_ID, value < 0.05)
	AudioServer.set_bus_mute(MobKnockback_Bus_ID, value < 0.05)
	AudioServer.set_bus_mute(HealthPowerUp_Bus_ID, value < 0.05)
	AudioServer.set_bus_mute(PlayerDamage_Bus_ID, value < 0.05)
	
	
