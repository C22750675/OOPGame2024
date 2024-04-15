extends Area3D

var baseDamageAmount = 10
var baseKnockbackAmount = 15
var maxChargeTime = 2.0
var chargeRate = 1.5
var maxAreaScale = 2.0
var minAreaScale = 1.0

var attackVisual: Sprite3D
var attackCooldown: float = 0.75
var timeSinceLastAttack: float = 0
var chargeTime: float = 0
var charging: bool = false
var enemiesInZone: Array = []
var baseScale: Vector3 = Vector3(1, 1, 1) # Initialize baseScale
var queuedDamageAndKnockback: Array = [] # Store damage and knockback for queued enemies

func _ready():

	attackVisual = $AttackAreaPoints/Sprite3D
	attackVisual.hide()

func applyDamageAndKnockback(chargeFactor: float):

	var damage = baseDamageAmount * chargeFactor
	var knockback = baseKnockbackAmount * chargeFactor


	for damageKnockback in queuedDamageAndKnockback:

		var enemy = damageKnockback["enemy"]


		if enemy.has_method("takeDamage"):
			enemy.takeDamage(damage)

		if enemy.has_method("takeKnockback"):
			var knockbackDirection = (enemy.global_transform.origin - global_transform.origin).normalized()
			enemy.takeKnockback(knockbackDirection * knockback)

	queuedDamageAndKnockback.clear() # Clear the queued damage and knockback after applying

func areEnemiesInZone():

	return enemiesInZone.size() > 0

func _process(delta):

	timeSinceLastAttack += delta

	if charging:

		chargeTime += delta * chargeRate
		# Clamp charge time
		chargeTime = clamp(chargeTime, 0, maxChargeTime)
		# Calculate scale factor based on charge time
		var scaleFactor = lerp(minAreaScale, maxAreaScale, chargeTime / maxChargeTime)

		# Apply scale to the area
		scale = baseScale * scaleFactor

func _input(event):

	if event.is_action_pressed("attack"):
		charging = true
		attackVisual.show() # Display attack area

	elif event.is_action_released("attack"):

		charging = false
		attackVisual.hide()

		if areEnemiesInZone():
			applyDamageAndKnockback(chargeTime / maxChargeTime)

		chargeTime = 0

func _onBodyEntered(body):

	if body.is_in_group("enemies"):
		enemiesInZone.append(body)

		if attackVisual.visible:
			queuedDamageAndKnockback.append({"enemy": body})

func _onBodyExited(body):

	if body.is_in_group("enemies"):
		enemiesInZone.erase(body)

		for i in range(queuedDamageAndKnockback.size()):

			var damageKnockback = queuedDamageAndKnockback[i]


			if damageKnockback["enemy"] == body:

				queuedDamageAndKnockback.erase(i)

				break
