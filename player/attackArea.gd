extends Area3D

var damage_amount = 10
var knockback_amount = 12
var attack_visual: MeshInstance3D
var attack_cooldown: float = 0.75
var time_since_last_attack: float = 0

func _ready():
	collision_mask = 1
	attack_visual = $attackArea/attackArea_debug
	attack_visual.hide()

func apply_damage(enemy : CharacterBody3D):
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage_amount)

func apply_knockback(enemy : CharacterBody3D):
	if enemy.has_method("take_knockback"):
		var knockback_direction = (enemy.global_transform.origin - global_transform.origin).normalized()
		enemy.take_knockback(knockback_direction * knockback_amount)

func check_enemies_in_zone():
	for body in get_overlapping_bodies():
		if body.is_in_group("Enemies"):
			return true
	return false

func _process(delta):
	time_since_last_attack += delta

func _input(event):
	if event.is_action_pressed("attack"):
		if time_since_last_attack > attack_cooldown:
			attack_visual.show()
			if check_enemies_in_zone():
				for body in get_overlapping_bodies():
					if body.is_in_group("Enemies"):
						apply_damage(body)
						apply_knockback(body)
			time_since_last_attack = 0
	else:
		attack_visual.hide()

func _on_body_entered(body):
	if body.is_in_group("Enemies"):
		check_enemies_in_zone()

func _on_body_exited(body):
	if body.is_in_group("Enemies"):
		check_enemies_in_zone()
