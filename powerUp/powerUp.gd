extends CharacterBody3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called when a body enters the area.
func _on_Area_body_entered(body):
	# Check if the body entering the area is the player character
	if body.has_method("apply_health_power_up"):
		# Call the function to apply health increase
		body.apply_health_power_up(20)  # Increase health 
		
