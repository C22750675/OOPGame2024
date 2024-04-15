extends Control



func _onPlayPressed():
	get_tree().change_scene_to_file("res://Main.tscn")


func _onOptionsPressed():
	get_tree().change_scene_to_file("res://OptionsMenu.tscn")


func _onQuitPressed():
	get_tree().quit()
