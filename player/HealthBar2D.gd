extends TextureProgressBar

var bar_red = preload("res://player/playerHealthBar/bar_red.png")
var bar_green = preload("res://player/playerHealthBar/bar_green.png")
var bar_yellow = preload("res://player/playerHealthBar/bar_yellow.png")


func update_health(health):

	if health < 100:

		show()

	texture_progress = bar_green

	if health < 75:

		texture_progress = bar_yellow

	if health < 45:

		texture_progress = bar_red
