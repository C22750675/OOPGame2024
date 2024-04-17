extends Area3D

var base_damage_amount = 10
var base_knockback_amount = 15
var max_charge_time = 2.0
var charge_rate = 1.5
var max_area_scale = 2.0
var min_area_scale = 1.0

var attack_visual: Sprite3D
var attack_cooldown: float = 0.75
var time_since_last_attack: float = 0
var charge_time: float = 0
var charging: bool = false
var enemies_in_zone: Array = []
var base_scale: Vector3 = Vector3(1, 1, 1) # Initialize base_scale
var queued_damage_and_knockback: Array = [] # Store damage and knockback for queued enemies

func _ready():
	attack_visual = $AttackAreaPoints/Sprite3D
	attack_visual.hide()

func apply_damage_and_knockback(charge_factor: float):
	var damage = base_damage_amount * charge_factor
	var knockback = base_knockback_amount * charge_factor
	for damage_knockback in queued_damage_and_knockback:
		var enemy = damage_knockback["enemy"]
		if enemy.has_method("take_damage"):
			enemy.take_damage(damage)
		if enemy.has_method("take_knockback"):
			var knockback_direction = (enemy.global_transform.origin - global_transform.origin).normalized()
			enemy.take_knockback(knockback_direction * knockback)
	queued_damage_and_knockback.clear() # Clear the queued damage and knockback after applying

func are_enemies_in_zone():
	return enemies_in_zone.size() > 0

func _process(delta):
	time_since_last_attack += delta
	if charging:
		charge_time += delta * charge_rate
		# Clamp charge time
		charge_time = clamp(charge_time, 0, max_charge_time)
		# Calculate scale factor based on charge time
		var scale_factor = lerp(min_area_scale, max_area_scale, charge_time / max_charge_time)
		# Apply scale to the area
		scale = base_scale * scale_factor

func _input(event):
	if event.is_action_pressed("attack"):
		charging = true
		attack_visual.show() # Display attack area
	elif event.is_action_released("attack"):
		charging = false
		attack_visual.hide()
		if are_enemies_in_zone():
			apply_damage_and_knockback(charge_time / max_charge_time)
		charge_time = 0

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		enemies_in_zone.append(body)
		if attack_visual.visible:
			queued_damage_and_knockback.append({"enemy": body})

func _on_body_exited(body):
	if body.is_in_group("enemies"):
		enemies_in_zone.erase(body)
		for i in range(queued_damage_and_knockback.size()):
			var damage_knockback = queued_damage_and_knockback[i]
			if damage_knockback["enemy"] == body:
				queued_damage_and_knockback.erase(i)
				break
