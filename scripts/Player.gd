extends CharacterBody3D

# ~+'^'+~ CONTROLS ~+'^'+~ #
const IN_JUMP = "move_jump"
const IN_BACKWARD = "move_backward"
const IN_FORWARD = "move_forward"
const IN_LEFT = "move_left"
const IN_RIGHT = "move_right"
const IN_LEAN_LEFT = "lean_left"
const IN_LEAN_RIGHT = "lean_right"

const IN_FIRE = "primary_fire"
const IN_ALT_FIRE = "alternate_fire"

const MOUSE_SENS_MOD: float = 0.005

var mouse_sens: float = 1.0

var speed: float = 5.0
const JUMP_VELOCITY: float = 4.5

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var cam = $PlayerCamera

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	controls(delta)
	move_and_slide()

func _input(event):
	if cam.current and event is InputEventMouseMotion and\
	Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sens * MOUSE_SENS_MOD)
		cam.rotate_x(-event.relative.y * mouse_sens * MOUSE_SENS_MOD)
		cam.rotation.x = clamp(cam.rotation.x, -PI*0.45, PI*0.45)

func controls(delta):
	if Input.is_action_just_pressed(IN_ALT_FIRE):
		pass # TODO
	
	# jump
	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed(IN_JUMP) and is_on_floor():
		velocity.y = JUMP_VELOCITY
	# walk
	var input_dir = Input.get_vector(IN_LEFT, IN_RIGHT, IN_FORWARD, IN_BACKWARD)
	var dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if dir:
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
