extends Node

@export var mob_scene: PackedScene

# Preload the mob script to read its global variables
var Mob = preload("res://mob/Mob.gd")

func _ready():

	# Start the round timer
	$roundTimer.start()


func _on_mob_timer_timeout():
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


func _on_round_timer_timeout():
	
	if GlobalVars.roundTimer > 0:

		GlobalVars.roundTimer -= 1
		
