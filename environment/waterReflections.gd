extends SpotLight3D

var images = []
var currentImageIndex = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# Load all the images
	for i in range(0, 10):  # Assuming the images are named water1.png, water2.png, ..., water10.png
		
		var image = load("res://environment/environmentArt/waterFrames/water" + str(i) + ".png")
		
		images.append(image)

func _OnWaterFramechangeTimeout():
	
	currentImageIndex = (currentImageIndex + 1) % images.size()
	
	light_projector = images[currentImageIndex]
