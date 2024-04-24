extends Control

signal return_to_game()
signal main_menu()


@onready var musicBusID = AudioServer.get_bus_index("Music")
@onready var SFXBusID = AudioServer.get_bus_index("SFX")

@onready var buttons_v_box = %ButtonsVBox

# Function to operate the slider vlaues for Music
func _on_music_slider_value_changed(value):
	
	AudioServer.set_bus_volume_db(musicBusID, linear_to_db(value))
	AudioServer.set_bus_mute(musicBusID, value < 0.05)

# Function to operate the slider vlaues for SFX
func _on_sfx_slider_value_changed(value):
	
	AudioServer.set_bus_volume_db(SFXBusID, linear_to_db(value))
	AudioServer.set_bus_mute(SFXBusID, value < 0.05)
	
func focus_button() -> void:
	
	if buttons_v_box:
		var button: Button = buttons_v_box.get_child(0)
		if button is Button:
			button.grab_focus()


func _on_visibility_changed():
	
	if visible:
		focus_button()


func _on_return_to_game_button_pressed():

	return_to_game.emit()


func _on_main_menu_button_pressed():
	

	# Call playerReset in Player script
	get_tree().get_root().get_node("Main/Player").playerReset()

	# Show the main menu
	main_menu.emit()

	
func _on_quit_button_pressed():
	
	get_tree().quit()
