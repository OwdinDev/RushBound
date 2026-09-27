extends CharacterBody2D

var speed: float = 150.0
var dash_speed: float = 600.0
var accel: float = 10.0
var jumpforce: float = -400
var health: float = speed
var gravity: float = 20.0
var wall_gravity: float = 2.0

var on_wall: bool = false
var dashing: bool = false

@onready var wall_checker: RayCast2D = $WallChecker

var state = STATES.AIR
enum STATES {AIR=1, FLOOR, WALL}

func _physics_process(_delta: float) -> void:
	
	var direction = Input.get_axis("Left", "Right")
	
	if wall_checker.is_colliding():
		on_wall = true
	else:
		on_wall = false
	
	if direction < 0:
		wall_checker.target_position.x = -15
	elif direction > 0:
		wall_checker.target_position.x = 15
	
	match state:
		
		STATES.AIR:
			
			if is_on_floor():
				state = STATES.FLOOR
			
			if on_wall:
				state = STATES.WALL
			
			velocity.y += gravity
			
			if direction:
				if dashing:
					velocity.x = direction * dash_speed
				else:
					velocity.x = direction * speed
			else:
				velocity.x = move_toward(velocity.x, 0, accel)
			
			if Input.is_action_just_pressed("Dash"):
				dashing = true
				$DashTimer.start()
			
		STATES.FLOOR:
			
			if !is_on_floor():
				state = STATES.AIR
			
			
			if direction:
				if dashing:
					velocity.x = direction * dash_speed
				else:
					velocity.x = direction * speed
			else:
				velocity.x = move_toward(velocity.x, 0, accel)
			
			if Input.is_action_just_pressed("Dash"):
				dashing = true
				$DashTimer.start()
			
			if Input.is_action_just_pressed("Jump"):
				velocity.y = jumpforce
			
		STATES.WALL:
			
			if !on_wall:
				state = STATES.AIR
			
			velocity.y += wall_gravity
	
	
	move_and_slide()
	print(state)


func _on_dash_timer_timeout() -> void:
	dashing = false
