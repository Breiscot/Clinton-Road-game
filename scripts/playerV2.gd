extends CharacterBody3D

@export var walk_speed := 3.0
@export var run_speed := 5.5
@export var mouse_sensitivity := 0.002
@export var jump_force := 4.5

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

var gravity := 9.8
var current_speed := 3.0

func _ready():
	# Aggiungi al gruppo player
	add_to_group("player")
	# Cattura il mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Debug
	print("Player ready")
	print("Player position: ", global_position)

func _input(event):
	# Rotazione della visuale con il mouse
	if event is InputEventMouseMotion:
		# Rotazione del corpo del player a sinistra/destra
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Rotazione della testa su/giù
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, -1.5, 1.5)

	# Toggle torcia
	if event.is_action_pressed("flashlight"):
		if has_node("Head/Flashlight"):
			$Head/Flashlight.visible = !$Head/Flashlight.visible
			print("Flashlight toggled")

	# Sblocca/Blocca il mouse con ESC (menu di pausa)
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	# Applica la gravità
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Salto
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force
		print("Jump")

	# Corsa
	if Input.is_action_pressed("run"):
		current_speed = run_speed
	else:
		current_speed = walk_speed

	# Movimento
	var input_dir := Vector2.ZERO

	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
		
	var w = Input.is_key_pressed(KEY_W)
	var s = Input.is_key_pressed(KEY_S)
	var a = Input.is_key_pressed(KEY_A)
	var d = Input.is_key_pressed(KEY_D)
	
	if w or s or a or d:
		print("Keys: W=", w, " S=", s, " A=", a, " D=", d)
		print("On floor: ", is_on_floor)
		print("Velocity before: ", velocity)

	input_dir = input_dir.normalized()

	# Direzione 3D del player
	var direction := Vector3.ZERO
	direction += transform.basis.z * input_dir.y # Forward/Backward
	direction += transform.basis.x * input_dir.x # Left/Right
	direction = direction.normalized()

	# Applica il movimento
	if direction != Vector3.ZERO:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed * 0.5)
		velocity.z = move_toward(velocity.z, 0, current_speed * 0.5)
		
	if w or s or a or d:
		print("Velocity after: ", velocity)
		print("---")

		move_and_slide()

func take_damage(amount: float):
	print("Player took ", amount, " damage")

func add_fear(amount: float):
	print("Fear added: ", amount)
