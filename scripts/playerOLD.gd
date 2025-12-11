extends CharacterBody3D

# Movimento

@export var walk_speed := 3.0
@export var run_speed := 5.5
@export var crouch_speed := 1.5
@export var jump_force := 4.5
@export var mouse_sensitivity := 0.002

# Stamina

@export var max_stamina := 100.0
var stamina := max_stamina
var stamina_regen := 15.0
var stamina_drain := 25.0

# Riferimenti
@onready var head: Node3D = $Head
@onready var camera : Camera3D = $Head/Camera3D
@onready var flashlight := $Head/Flashlight
@onready var footstep_audio := $FootstepAudio
@onready var breathing_audio := $BreathingAudio

# Stati

var current_speed := walk_speed
var is_running := false
var is_crouching := false
var gravity := 9.8
var health := 100.0

# Paura
var fear_level := 0.0

func _ready():
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	flashlight.light_energy = 1.0

func _input(event):
	# La posizione della camera con il mouse
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, -PI / 2, PI / 2)

	# Torcia
	if Input.is_action_just_pressed("flashlight"):
		if has_node("Head/Flashlight"):
			$Head/Flashlight.visible = !$Head/Flashlight.visible
			print("Flashlight toggled")
		flashlight.visible = not flashlight.visible
		
	# Uscire dal gioco
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	handle_movement(delta)
	handle_stamina(delta)
	handle_fear_effects(delta)
	update_footsteps()

func handle_movement(delta):
	# Gravità
	if not is_on_floor():
		velocity.y -= gravity * delta
	# Input di movimento
	var input_dir := Vector2.ZERO
	
	if Input.is_action_pressed("move_forward"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_backward"):
		input_dir.y += 1
	if Input.is_action_pressed("move_left"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.y += 1
		
	input_dir = input_dir.normalized()
	
	var direction := Vector3.ZERO
	direction += transform.basis.z * input_dir.y #Avanti/Indietro
	direction += transform.basis.x * input_dir.x #Sinistra/Destra
	direction = direction.normalized()
	
	# Inserisce il movimento
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	# Corsa
	if Input.is_action_pressed("run") and stamina > 0:
		current_speed = run_speed
		stamina -= 20 * delta
	else:
		current_speed = walk_speed
		stamina = min(stamina + 10 * delta, max_stamina)

	# Accovacciamento
	if Input.is_action_pressed("crouch"):
		is_crouching = true
		current_speed = crouch_speed
	elif is_crouching:
		is_crouching = false
		current_speed = run_speed
	else:
		is_crouching = false
		current_speed = walk_speed
	
	# Salto
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force

		move_and_slide()

func handle_stamina(delta):
	if is_running:
		stamina -= stamina_drain * delta
		stamina = max(stamina, 0)
		if stamina <= 20:
			breathing_audio.volume_db = lerp(breathing_audio.volume_db, 0.0, delta * 2)
	else:
		stamina += stamina_regen * delta
		stamina = min(stamina, max_stamina)
		breathing_audio.volume_db = lerp(breathing_audio.volume_db, -40.0, delta)

func handle_fear_effects(delta):
	# Effetti visivi sul livello di paura
	if fear_level > 0.5:
		var shake = randf_range(-0.002, 0.002) * fear_level
		camera.rotation.z = lerp(camera.rotation.z, shake, delta * 10)
	
	# Diminuzione della paura nel tempo
	fear_level = lerp(fear_level, 0.0, delta * 0.1)

func update_footsteps():
	var is_moving = velocity.length() > 0.5 and is_on_floor()
	if is_moving and not footstep_audio.playing:
		footstep_audio.pitch_scale = randf_range(0.9, 1.1)
		if is_running:
			footstep_audio.playback_speed *= 1.3
		footstep_audio.play()

func add_fear(amount):
	fear_level = clamp(fear_level + amount, 0.0, 1.0)

func take_damage(amount: float):
	add_fear(0.3)
	
func die():
	print("Player died")
	EventBus.emit_signal("player_died")
	# Momentaneamente ricarica la scena
	get_tree().reload_current_scene()
	
func get_health() -> float:
	return health
