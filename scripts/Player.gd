extends CharacterBody3D

# ~+'^'+~ CONTROLS ~+'^'+~ #
const IN_JUMP: String = "move_jump"
const IN_BACKWARD: String = "move_backward"
const IN_FORWARD: String = "move_forward"
const IN_LEFT: String = "move_left"
const IN_RIGHT: String = "move_right"
const IN_LEAN_LEFT: String = "lean_left"
const IN_LEAN_RIGHT: String = "lean_right"

const IN_FIRE: String = "primary_fire"
const IN_ALT_FIRE: String = "alternate_fire"

const SPEED: float = 5.0
const JUMP_VELOCITY: float = 4.5

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta):
	process_input(delta)
	move_and_slide()

func process_input(delta):
	if Input.is_action_just_pressed(IN_ALT_FIRE):
		var ray = RayCast3D.new()
		
	# whatever
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed(IN_JUMP) and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir = Input.get_vector(IN_LEFT, IN_RIGHT, IN_FORWARD, IN_BACKWARD)
	var dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if dir:
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
