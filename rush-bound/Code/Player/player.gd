extends CharacterBody2D

var speed: float = 150.0
var accel: float = 200.0
var jumpforce: float = -300
var health: float = speed

func _physics_process(delta: float) -> void:
	
	var direction = Input.get_axis("Left", "Right")
	
	if direction:
		velocity.x = direction * speed
	
	
	
	move_and_slide()
