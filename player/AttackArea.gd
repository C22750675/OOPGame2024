extends Area3D

@onready var mobKnockback = $"../../MobKnockback"

var playerNode: CharacterBody3D
var baseDamageAmount = 10
var baseKnockbackAmount = 15
var maxChargeTime = 2.0
var chargeRate = 1.0
var maxAreaScale = 2.0
var minAreaScale = 1.0

var attackVisual: Sprite3D
var sheildVisual: MeshInstance3D
var attackCooldown: float = 0.75
var timeSinceLastAttack: float = 0
var chargeTime: float = 0
var charging: bool = false
var enemiesInZone: Array = []
var baseScale: Vector3 = Vector3(1, 1, 1) # Initialize baseScale
var queuedDamageAndKnockback: Array = [] # Store damage and knockback for queued enemies

var maxSweetSpotBonus: float = 1.5
var sweetSpotRange: float = 0.05
var sweetSpotBonus: float = 1.0 #initialize
var sweetSpotWindowSize: float = 0.4

var maxChargeReached: bool = false

func _ready():

	var parentNode = find_character_body(get_parent())
	
	
	print(parentNode.get_class()) # Output the class name of the parent node
	
	if parentNode and parentNode is CharacterBody3D:
		playerNode = parentNode
	else : 
		print("error")
		
	attackVisual = $AttackAreaPoints/Aoe
	sheildVisual = $Shield
	sheildVisual.hide()
	attackVisual.hide()

func applyDamageAndKnockback(chargeFactor: float, sweetSpotBonusFactor: float):

	var damage = baseDamageAmount * chargeFactor * sweetSpotBonusFactor
	var knockback = baseKnockbackAmount * chargeFactor * sweetSpotBonusFactor

	for damageKnockback in queuedDamageAndKnockback:

		var enemy = damageKnockback["enemy"]

		if enemy.has_method("takeDamage"):
			enemy.takeDamage(damage)
			
		if enemy.has_method("takeKnockback"):
			var knockbackDirection = (enemy.global_transform.origin - global_transform.origin).normalized()
			enemy.takeKnockback(knockbackDirection * knockback)
			
	mobKnockback.play()
	await mobKnockback.finished
			

	queuedDamageAndKnockback.clear() # Clear the queued damage and knockback after applying

func areEnemiesInZone():

	return enemiesInZone.size() > 0

func calculateSweetSpotBonus(chargeTimeValue: float):
	var randomOffset = randf_range(-sweetSpotRange, sweetSpotRange)
	var sweetSpotTime = maxChargeTime / 2.0 + randomOffset
	var sweetSpotStart = sweetSpotTime - sweetSpotWindowSize / 2.0
	var sweetSpotEnd = sweetSpotTime + sweetSpotWindowSize / 2.0
	
	if chargeTimeValue < sweetSpotStart or chargeTimeValue > sweetSpotEnd:
		return 1.0 # No bonus if not within the sweet spot window
		
	else:
		return lerp(1.0, maxSweetSpotBonus, abs((chargeTime - sweetSpotTime) / sweetSpotRange))

func _process(delta):

	timeSinceLastAttack += delta

	if charging:

		chargeTime += delta * chargeRate
		# Clamp charge time
		chargeTime = clamp(chargeTime, 0, maxChargeTime)
		# Calculate scale factor based on charge time
		var scaleFactor = lerp(minAreaScale, maxAreaScale, chargeTime / maxChargeTime)
		
		if chargeTime >= maxChargeTime:
			maxChargeReached = true
			if playerNode:
				playerNode.stopMovement(maxChargeReached)
				sheildVisual.show()
		# Apply scale to the area
		scale = baseScale * scaleFactor
		sweetSpotBonus = calculateSweetSpotBonus(chargeTime)
		# Check if we are in the sweet spot
		if sweetSpotBonus > 1.0:
			attackVisual.modulate = Color(1,0,0)
		else:
			attackVisual.modulate = Color(1,1,1)
		
func _input(event):

	if event.is_action_pressed("attack"):
		charging = true
		attackVisual.show() # Display attack area

	elif event.is_action_released("attack"):

		charging = false
		maxChargeReached = false
		attackVisual.hide()
		sheildVisual.hide()
		if playerNode:
				playerNode.stopMovement(maxChargeReached)
		

		if areEnemiesInZone():
			applyDamageAndKnockback(chargeTime / maxChargeTime, sweetSpotBonus)

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

# Recursively find the CharacterBody3D parent
func find_character_body(node):
	
	if not node:
		return null
		
	elif node is CharacterBody3D:
		return node
		
	else:
		return find_character_body(node.get_parent())
