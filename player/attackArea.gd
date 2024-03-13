extends Area3D

var damage_amount = 10
var knockback_amount = 12
var attack_visual: MeshInstance3D
var attack_cooldown: float = 0.75
var time_since_last_attack: float = 0

func _ready():
	collision_mask = 1
	attack_visual = $AttackAreaPoints/AttackAreaDebug
	

	attack_visual.hide()

func apply_damage(enemy : CharacterBody3D):
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage_amount)

func check_enemies_in_zone():
	for body in get_overlapping_bodies(): #goes through every body that is in the zone
		if body.is_in_group("enemies"):
			return true
	return false

func _process(delta):
	time_since_last_attack += delta

func _input(event):
	if event.is_action_pressed("attack"):
		attack_visual.show() # display attack area
		if check_enemies_in_zone(): #calls func returns true or false
			for body in get_overlapping_bodies(): 
				if body.is_in_group("enemies"):
					apply_damage(body)#calls func to do damage
					apply_knockback(body)
	else:
		attack_visual.hide()

func _on_body_entered(body): # func is called when zone detects a body enetering it
	if body.is_in_group("enemies"):
		check_enemies_in_zone()

func _on_body_exited(body): #func is called when zone detects a body exits it
	if body.is_in_group("enemies"):
		check_enemies_in_zone() # checks if there are no bodies in the zone

func apply_knockback(enemy : CharacterBody3D):

	#Check if enemy has knockback method
	if enemy.has_method("take_knockback"):

		# Calculate knockback direction
		var knockback_direction = (enemy.global_transform.origin - global_transform.origin).normalized()
		
		enemy.take_knockback(knockback_direction * knockback_amount)
		
