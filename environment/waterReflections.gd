extends SpotLight3D

var images = []
var currentImageIndex = 0
var numImages = 10


# Called when the node enters the scene tree for the first time.
func _ready():

	loadImages()
	

func loadImages():
	
	for i in range(numImages):

		var imagePath = "res://environment/environmentArt/waterFrames/water" + str(i) + ".png"
		
		var image = load(imagePath)

		if image:

			images.append(image)

func _OnWaterFramechangeTimeout():
	
	currentImageIndex = (currentImageIndex + 1) % images.size()
	
	light_projector = images[currentImageIndex]
