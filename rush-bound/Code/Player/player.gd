extends CharacterBody2D

var speed: float = 150.0
var accel: float = 10.0
var jumpforce: float = -400
var health: float = speed
var gravity: float = 20

func _physics_process(_delta: float) -> void:
	
	if !is_on_floor():
		velocity.y += gravity
	else:
		pass
	
	var direction = Input.get_axis("Left", "Right")
	
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, accel)
	
	if Input.is_action_just_pressed("Jump"):
		velocity.y = jumpforce
	
	move_and_slide()
