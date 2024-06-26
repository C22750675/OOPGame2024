extends Node

signal start_game()
signal menu_opened()
signal menu_closed()
signal quit_to_menu()


@onready var main_menu = %MainMenu
@onready var Music_Bus_ID = AudioServer.get_bus_index("Music")
@onready var MobDies_Bus_ID = AudioServer.get_bus_index("MobDies")
@onready var MobKnockback_Bus_ID = AudioServer.get_bus_index("MobKnockback")
@onready var HealthPowerUp_Bus_ID = AudioServer.get_bus_index("HealthPowerUp")
@onready var PlayerDamage_Bus_ID = AudioServer.get_bus_index("PlayerDamage")
@onready var gameOverSound = $GameOverSound
@onready var in_game_menu = $InGameMenu

var countdownValue = 3
var killRecord = 0
var saveFile = ConfigFile.new()




# Preload the mob script to read its global variables
var mobScene = preload("res://mob/Mob.tscn")
var healthPowerUpScene = preload("res://powerUp/HealthPowerUp.tscn")

func _on_main_menu_start_game() -> void:
	
	start_game.emit()
	
func _ready():

	var err = saveFile.load("user://killRecord.ini")

	if err == OK:

		killRecord = saveFile.get_value("records", "killRecord", 0)
		print("Just read the kill record as " + str(killRecord))

	# Call the updateKillRecord function in the main menu script
	$MainMenu.updateKillRecord(killRecord)

	

func _onCountdownTimerTimeout():

	if countdownValue > 0:

		countdownValue -= 1
		$Countdown.text = str(countdownValue)

	else:

		$CountdownTimer.stop()

		$Countdown.hide()
		countdownValue = 3  # Reset for next use

		gameStart()

func startCountdown():

	# Position player at the center of the scene
	$Player.position = Vector3(0, 1, 0)


	# Set global variables
	GlobalVars.currentRound = 1
	GlobalVars.roundTimer = 60
	GlobalVars.mobsKilled = 0

	# Update the UI labels at start
	$KillCounter.text = "Mobs Killed: " + str(GlobalVars.mobsKilled)

	$RoundTimerDisplay.text = "Time Left: " + str(GlobalVars.roundTimer)

	$RoundNumber.text = "Round: " + str(GlobalVars.currentRound)

	# Pause game
	get_tree().paused = true

	countdownValue = 3

	$Countdown.text = str(countdownValue)
	$Countdown.show()
	$CountdownTimer.start()


func gameStart():

	# Unpause game
	get_tree().paused = false


	# Start timers
	$MobSpawnTimer.start()
	$OneSecond.start()
	$HealthPowerUpTimer.start()

	# Allow player to move
	$Player.canMove = true

func gameOver():

	# Stop timers
	$MobSpawnTimer.stop()
	$OneSecond.stop()
	$HealthPowerUpTimer.stop()

	# Clear all mobs and power-ups from the scene
	var mobsToFree = get_tree().get_nodes_in_group("enemies")
	var healthPowerUpsToFree = get_tree().get_nodes_in_group("powerUp")


	for mob in mobsToFree:
		
		mob.queue_free()

	for powerUp in healthPowerUpsToFree:
		
		powerUp.queue_free()

	# Play game over sound
	gameOverSound.play()

	# Check if the player has a new kill record
	if GlobalVars.mobsKilled > killRecord:
		# Save the new kill record
		saveFile.set_value("records", "killRecord", GlobalVars.mobsKilled)
		print("Just set the kill record as " + str(killRecord))
		saveFile.save("user://killRecord.ini")

	# Call the updateKillRecord function in the main menu script
	$MainMenu.updateKillRecord(GlobalVars.mobsKilled)

	# Show the main menu
	$MainMenu.show()

	
func _input(event):
	
	if !main_menu.visible and event.is_action_pressed("ui_cancel"):
		in_game_menu.visible = !in_game_menu.visible
		if in_game_menu.visible:
			menu_opened.emit()
		else:
			menu_closed.emit()
	
	
func _onHealthPowerUpTimerTimeout():
	
	# Calculate a random position on top of the ground
	var groundRadius = 25
	var angle = randf_range(0, 2 * PI)
	var radius = sqrt(randf()) * groundRadius

	#Calculate the x, y and z coordinates of the power-up
	var x = radius * cos(angle)
	var y = 1
	var z = radius * sin(angle)

	# Create a position Vector3 with the x, y and z coordinates
	var spawnPosition = Vector3(x, y, z)

	# Create a new instance of the HealthPowerUp scene
	var healthPowerUp = healthPowerUpScene.instantiate()

	# Add the power-up to the scene
	add_child(healthPowerUp)

	# Set the power-up's position to the calculated position
	healthPowerUp.global_transform.origin = spawnPosition
	

func _onMobSpawnTimerTimeout():

	var playerPosition = $Player.position

	# Create a new instance of the Mob scene.
	var mob = mobScene.instantiate()
	

	mob.initialize(calculateMobSpawn(), playerPosition)

	# Spawn the mob by adding it to the Main scene.
	add_child(mob)

func calculateMobSpawn():

	var playerPosition = $Player.position

	# Calculate a random position on top of the ground
	var groundRadius = 25
	var spawnPosition = Vector3.ZERO

	while true:

		var angle = randf_range(0, 2 * PI)
		var radius = sqrt(randf()) * groundRadius

		# Calculate the x, y and z coordinates of the power-up
		var x = radius * cos(angle)
		var y = $Player.position.y
		var z = radius * sin(angle)

		spawnPosition = Vector3(x, y, z)

		# If the spawn position is not too close to the player, break the loop
		if spawnPosition.distance_to(playerPosition) >= 10:
			
			break

	return spawnPosition

func _onOneSecondTimout():
	
	if GlobalVars.roundTimer > 0:

		GlobalVars.roundTimer -= 1

	else:
		# Increment currentRound
		GlobalVars.currentRound += 1

		GlobalVars.roundTimer = 60

	# Update the UI labels once per second
	$KillCounter.text = "Mobs Killed: " + str(GlobalVars.mobsKilled)

	$RoundTimerDisplay.text = "Time Left: " + str(GlobalVars.roundTimer)

	$RoundNumber.text = "Round: " + str(GlobalVars.currentRound)


# Function to operate the slider vlaues for Music
func _on_music_slider_value_changed(value):
	
	AudioServer.set_bus_volume_db(Music_Bus_ID, linear_to_db(value))
	AudioServer.set_bus_mute(Music_Bus_ID, value < 0.05)

# Function to operate the slider vlaues for SFX
func _on_sfx_slider_value_changed(value):
	
	AudioServer.set_bus_volume_db(MobDies_Bus_ID, linear_to_db(value))
	AudioServer.set_bus_volume_db(MobKnockback_Bus_ID, linear_to_db(value))
	AudioServer.set_bus_volume_db(HealthPowerUp_Bus_ID, linear_to_db(value))
	AudioServer.set_bus_volume_db(PlayerDamage_Bus_ID, linear_to_db(value))
	AudioServer.set_bus_mute(MobDies_Bus_ID, value < 0.05)
	AudioServer.set_bus_mute(MobKnockback_Bus_ID, value < 0.05)
	AudioServer.set_bus_mute(HealthPowerUp_Bus_ID, value < 0.05)
	AudioServer.set_bus_mute(PlayerDamage_Bus_ID, value < 0.05)
	

func _on_in_game_menu_main_menu():
	
	in_game_menu.hide()

	main_menu.show()


func _on_in_game_menu_return_to_game():
	
	in_game_menu.hide()
	menu_closed.emit()
	

func _on_menu_closed():
	get_tree().paused = false


func _on_menu_opened():
	
	get_tree().paused = true
