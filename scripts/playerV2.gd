extends CharacterBody3D

@export var walk_speed := 3.0
@export var run_speed := 5.5
@export var mouse_sensitivity := 0.002
@export var jump_force := 4.5

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D

var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_speed := 3.0
var is_dead := false
var move_direction := Vector3.ZERO

func _ready():
	# Aggiungi al gruppo player
	add_to_group("player")
	# Cattura il mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Debug
	print("Player ready")
	
func _unhandled_input(event: InputEvent):
	# Se non é ancora morto
	if is_dead:
		return

func _input(event):
	# Rotazione della visuale con il mouse
	if event is InputEventMouseMotion:
		# Rotazione del corpo del player a sinistra/destra
		rotate_y(-event.relative.x * mouse_sensitivity)
		# Rotazione della testa su/giù
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))

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
	if is_dead:
		return
	# Applica la gravità
		velocity.y -= gravity * delta

	# Salto
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_force
		print("Jump")

	# Corsa
	if Input.is_action_pressed("run"):
		current_speed = run_speed
	else:
		current_speed = walk_speed

	# Movimento
	var input_x := 0.0
	var input_z := 0.0

	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("move_forward"):
		input_z -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("move_backward"):
		input_z += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("move_left"):
		input_x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("move_right"):
		input_x += 1.0
	
	var input_vector := Vector2(input_x, input_z).normalized()
	
	# Calcola la direzione alla rotazione del player
	var forward := -transform.basis.z
	var right := transform.basis.x
	
	move_direction = (forward * -input_vector.y + right * input_vector.x).normalized()
	
	# Velocità orizzontale
	if input_vector.length() > 0:
		velocity.x = move_direction.x * current_speed
		velocity.z = move_direction.z * current_speed
	else:
		velocity.x = lerp(velocity.x, 0.0, 10.0 * delta)
		velocity.z = lerp(velocity.x, 0.0, 10.0 * delta)
		
	move_and_slide()
		
func add_fear(amount: float):
	print("Fear added: ", amount)
		
func take_damage(amount: float):
	print("Player took ", amount, " damage")
	if is_dead:
		return
		
	print("!!! PLAYER DIED !!!")
	is_dead = true
	# Blocca il player
	set_physics_process(false)
	# Aspetta un momento e ricarica
	await get_tree().create_timer(1.5).timeout
	# Ricarica la scena
	get_tree().reload_current_scene()
	
func die():
	take_damage(100)
