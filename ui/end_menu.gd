extends Control

func _on_new_game_pressed() -> void:
	
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func _on_quit_button_pressed() -> void:
	
	get_tree().quit()
