extends CharacterBody2D

enum State { AIR, FLOOR, WALL }

const WALK_SPEED: float = 120.0
const MAX_SPEED: float = 600.0
const DASH_SPEED: float = 550.0

const FLOOR_ACCEL: float = 900.0
const AIR_ACCEL: float = 450.0
const GROUND_FRICTION: float = 700.0
const AIR_FRICTION: float = 20.0
const TURN_BRAKE: float = 1400.0

const MOMENTUM_GAIN: float = 150.0
const MOMENTUM_DECAY: float = 300.0


const GRAVITY: float = 1200.0
const WALL_SLIDE_GRAVITY: float = 120.0
const WALL_SLIDE_MAX: float = 150.0
const JUMP_VELOCITY: float = -400.0
const JUMP_CUT: float = 0.5
const WALL_JUMP_MIN_PUSH: float = 400.0

const BOUNCE_MIN_SPEED: float = 400.0

const BOUNCE_RETENTION_MIN: float = 0.70
const BOUNCE_RETENTION_MAX: float = 0.95
const BOUNCE_POP_MIN: float = -100.0
const BOUNCE_POP_MAX: float = -250.0
const BOUNCE_LOCK_MIN: float = 0.10
const BOUNCE_LOCK_MAX: float = 0.30

@onready var wall_checker: RayCast2D = $WallChecker
@onready var dash_timer: Timer = $DashTimer

var state: State = State.AIR
var top_speed: float = WALK_SPEED
var facing: float = 1.0
var on_wall: bool = false
var dashing: bool = false
var can_dash: bool = true
var bounce_lock: float = 0.0


func _physics_process(delta: float) -> void:
	var direction: float = Input.get_axis("Left", "Right")
	
	if direction != 0.0:
		facing = sign(direction)
		wall_checker.target_position.x = 15.0 * facing
		wall_checker.force_raycast_update()
	on_wall = wall_checker.is_colliding()
	bounce_lock = max(bounce_lock - delta, 0.0)
	
	if dashing:
		move_and_bounce()
		return
	
	match state:
		State.AIR:
			air_state(direction, delta)
		State.FLOOR:
			floor_state(direction, delta)
		State.WALL:
			wall_state(delta)
	
	velocity.x = clamp(velocity.x, -MAX_SPEED, MAX_SPEED)
	move_and_bounce()


func air_state(direction: float, delta: float) -> void:
	if is_on_floor():
		state = State.FLOOR
		can_dash = true
		return
	
	if on_wall and velocity.y > 0.0 and direction == facing \
			and abs(velocity.x) < BOUNCE_MIN_SPEED and bounce_lock <= 0.0:
		state = State.WALL
		can_dash = true
		return
	
	velocity.y += GRAVITY * delta
	
	if Input.is_action_just_released("Jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT
	
	apply_horizontal(direction, AIR_ACCEL, AIR_FRICTION, delta)
	dash(direction)


func floor_state(direction: float, delta: float) -> void:
	if not is_on_floor():
		state = State.AIR
		return
	
	velocity.y += GRAVITY * delta
	update_top_speed(direction, delta)
	apply_horizontal(direction, FLOOR_ACCEL, GROUND_FRICTION, delta)
	
	if Input.is_action_just_pressed("Jump"):
		velocity.y = JUMP_VELOCITY
		state = State.AIR
		return
	
	dash(direction)


func wall_state(delta: float) -> void:
	if is_on_floor():
		state = State.FLOOR
		return
	if not on_wall:
		state = State.AIR
		return
	
	velocity.y = min(velocity.y + WALL_SLIDE_GRAVITY * delta, WALL_SLIDE_MAX)
	
	if Input.is_action_just_pressed("Jump"):
		var push_dir: float = sign(wall_checker.get_collision_normal().x)
		velocity.y = JUMP_VELOCITY
		velocity.x = push_dir * max(top_speed, WALL_JUMP_MIN_PUSH)
		facing = push_dir
		state = State.AIR


func update_top_speed(direction: float, delta: float) -> void:
	var running_forward: bool = direction != 0.0 and (velocity.x == 0.0 or sign(velocity.x) == direction)
	if running_forward:
		top_speed = move_toward(top_speed, MAX_SPEED, MOMENTUM_GAIN * delta)
	else:
		top_speed = move_toward(top_speed, WALK_SPEED, MOMENTUM_DECAY * delta)


func apply_horizontal(direction: float, accel: float, friction: float, delta: float) -> void:
	if bounce_lock > 0.0:
		return
	
	if direction == 0.0:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)
	elif sign(velocity.x) == -direction:
		velocity.x = move_toward(velocity.x, direction * top_speed, TURN_BRAKE * delta)
	elif abs(velocity.x) < top_speed:
		velocity.x = move_toward(velocity.x, direction * top_speed, accel * delta)


func dash(direction: float) -> void:
	if Input.is_action_just_pressed("Dash") and can_dash:
		dashing = true
		can_dash = false
		var dash_dir: float = direction if direction != 0.0 else facing
		velocity = Vector2(dash_dir * DASH_SPEED, 0.0)
		top_speed = max(top_speed, DASH_SPEED * 0.75)
		dash_timer.start()


func move_and_bounce() -> void:
	var pre_vx: float = velocity.x
	move_and_slide()
	
	if not is_on_wall() or abs(pre_vx) < BOUNCE_MIN_SPEED:
		return
	
	var normal_x: float = get_wall_normal().x
	if sign(pre_vx) != -sign(normal_x):
		return
	
	var t: float = clamp(inverse_lerp(BOUNCE_MIN_SPEED, MAX_SPEED, abs(pre_vx)), 0.0, 1.0)
	var retention: float = lerp(BOUNCE_RETENTION_MIN, BOUNCE_RETENTION_MAX, t)
	var pop: float = lerp(BOUNCE_POP_MIN, BOUNCE_POP_MAX, t)
	
	velocity.x = sign(normal_x) * abs(pre_vx) * retention
	velocity.y = min(velocity.y, pop)
	facing = sign(normal_x)
	wall_checker.target_position.x = 15.0 * facing
	bounce_lock = lerp(BOUNCE_LOCK_MIN, BOUNCE_LOCK_MAX, t)
	state = State.AIR
	can_dash = true
	dashing = false
	dash_timer.stop()


func _on_dash_timer_timeout() -> void:
	dashing = false
