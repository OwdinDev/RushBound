extends CharacterBody2D

var speed: float = 150.0
var accel: float = 10.0
var jumpforce: float = -300
var health: float = speed

func _physics_process(delta: float) -> void:
	
	var direction = Input.get_axis("Left", "Right")
	
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, accel)
	
	
	move_and_slide()
