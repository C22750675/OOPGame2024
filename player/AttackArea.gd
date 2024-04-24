extends Area3D

@onready var mobKnockback = $"../../MobKnockback"

var playerNode: CharacterBody3D

const BASE_DAMAGE = 10
const BASE_KNOCKBACK_AMOUNT = 50
const MAX_CHARGE_TIME = 1.5

# Charge attack variables
var chargeRate = 1.0
var chargeTime: float = 0
var charging: bool = false
var sweetSpotTime: float = 0

# Area scaling variables
var maxAreaScale = 2.0
var minAreaScale = 1.0

# Attack variables
var attackVisual: Sprite3D
var attackCooldown: float = 0.75
var enemiesInZone: Array = []
var baseScale: Vector3 = Vector3(1, 1, 1) # Initialize baseScale
var queuedDamageAndKnockback: Array = [] # Store damage and knockback for queued enemies

# Sweet spot variables
var maxSweetSpotBonus: float = 1.5
var sweetSpotRange: float = 0.05
var sweetSpotBonus: float = 1.0
var sweetSpotWindowSize: float = 0.4

func _ready():

	var parentNode = findCharacterBody(get_parent())
	
		
	if parentNode and parentNode is CharacterBody3D:
		playerNode = parentNode
	else : 
		print("error")
		
	attackVisual = $AttackAreaPoints/Aoe
	attackVisual.hide()

func _process(delta):

	if charging:

		updateCharging(delta)

	else:
		
		attackRelease()


# Updates charging status and calculates scale based on charge time
func updateCharging(delta):

	if charging:

		chargeTime += delta

		chargeTime = min(chargeTime, MAX_CHARGE_TIME)  # Clamps the charge time to maximum

		updateAttackAreaScale()

	else:

		attackRelease()

# Handles releasing the attack and applying damage
func attackRelease():

	if playerNode and chargeTime > 0:

		applyDamageKnockback()

		resetAttack()

# Updates the visual and actual scale of the attack area based on charge time
func updateAttackAreaScale():

	var scaleFactor = lerp(minAreaScale, maxAreaScale, chargeTime / MAX_CHARGE_TIME)


	scale = baseScale * scaleFactor

	sweetSpotBonus = calculateSweetSpotBonus(chargeTime)


	if sweetSpotBonus > 1.0 :

		attackVisual.modulate = Color(1, 0, 0)
		
	else:
		
		attackVisual.modulate = Color(1, 1, 1)


# Applies damage to all enemies currently in the zone
func applyDamageKnockback():

	sweetSpotBonus = calculateSweetSpotBonus(chargeTime)

	var damage = calculateDamage(sweetSpotBonus)
	var knockback = BASE_KNOCKBACK_AMOUNT


	for enemy in enemiesInZone:

		if validateEnemy(enemy):

			enemy.takeDamage(damage)
			push_error("Damage: " + str(damage))

			var knockbackDirection = (enemy.global_transform.origin - global_transform.origin).normalized()

			enemy.takeKnockback(knockbackDirection * knockback)
			
			mobKnockback.play()  # Play knockback sound


# Calculates damage based on charge time
func calculateDamage(sweetSpotBonusFactor):

	return (BASE_DAMAGE * (chargeTime / MAX_CHARGE_TIME) * sweetSpotBonusFactor)


# Calculates sweet spot bonus based on timing precision
func calculateSweetSpotBonus(chargeTimeValue: float):

	var sweetSpotStart = sweetSpotTime - sweetSpotWindowSize / 2.0
	var sweetSpotEnd = sweetSpotTime + sweetSpotWindowSize / 2.0
	
	if chargeTimeValue < sweetSpotStart or chargeTimeValue > sweetSpotEnd:

		return 1.0 # No bonus if not within the sweet spot window
		
	else:

		return lerp(1.0, maxSweetSpotBonus, abs((chargeTime - sweetSpotTime) / sweetSpotRange))


# Checks if an enemy is still valid for interaction
func validateEnemy(enemy):

	return enemy and enemy.is_inside_tree()

# Resets attack parameters after release
func resetAttack():

	chargeTime = 0

	attackVisual.hide()

	charging = false

# Utility function to find the CharacterBody3D parent
func findCharacterBody(node):

	if node is CharacterBody3D:

		return node

	elif node:

		return findCharacterBody(node.get_parent())
		
	return null


func areEnemiesInZone():

	return enemiesInZone.size() > 0


func _input(event):

	if event.is_action_pressed("attack"):

		charging = true
		attackVisual.show() # Display attack area

		var randomOffset = randf_range(-sweetSpotRange, sweetSpotRange)
		sweetSpotTime = MAX_CHARGE_TIME / 2.0 + randomOffset

	elif event.is_action_released("attack"):

		charging = false

		attackVisual.hide()
		
		if areEnemiesInZone():
			
			applyDamageKnockback()

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
