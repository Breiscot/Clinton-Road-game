extends CharacterBody3D

# Movimento
@export var walk_speed := 3.0
@export var run_speed := 5.5
@export var mouse_sensitivity := 0.002
@export var jump_force := 4.5

# Stamina
@export var max_stamina := 100.0
@export var stamina_drain := 20.0 # Consumo della stamina
@export var stamina_regen := 15.0 # Rigenerazione della stamina
var stamina: float = 100.0
var can_run := true

# Fear
@export var max_fear := 100.0
@export var fear_decay := 5.0 # Diminuzione nel tempo
var fear: float = 0.0

# Stordimento con la torcia
@export var flash_cooldown := 10.0
@export var flash_range := 12.0
@export var flash_angle := 30.0
@export var stun_duration := 3.0
var flash_timer := 0.0
var can_flash := true

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var flashlight: SpotLight3D = $Head/Flashlight

var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_speed := 3.0
var is_dead := false
var move_direction := Vector3.ZERO

# Effetti Fear
var base_fov := 75.0
var fear_shake_intensity := 0.0
var shake_time := 0.0

func _ready():
	# Aggiungi al gruppo player
	add_to_group("player")
	# Cattura il mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Debug
	print("Player ready")
	
	if camera:
		base_fov = camera.fov
	
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
	
	# Flash stordimento
	if event is InputEventKey and event.pressed and event.keycode == KEY_Q:
		use_flash_stun()

	# Sblocca/Blocca il mouse con ESC (menu di pausa)
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	if is_dead:
		return
		
	# Aggiorna i sistemi
	update_stamina(delta)
	update_fear(delta)
	update_flash_cooldown(delta)
	apply_fear_effects(delta)
	
	# Applica la gravità
	velocity.y -= gravity * delta

	# Salto
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_force
		print("Jump")

	# Corsa
	var wants_to_run = Input.is_key_pressed(KEY_SHIFT) or Input.is_action_pressed("run")
	if wants_to_run and can_run and stamina > 0:
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
		
func update_stamina(delta: float):
	var is_moving = velocity.length() > 0.5
	var is_running = current_speed == run_speed and is_moving
	
	if is_running:
		# Consuma stamina
		stamina -= stamina_drain * delta
		stamina = max(stamina, 0)
		
		# Quando finisce aspetti per correre
		if stamina <= 0:
			can_run = false
	else:
		# Rigenera la stamina
		stamina += stamina_regen * delta
		stamina = min(stamina, max_stamina)
		# Può correre di nuovo quando ha almeno il 20% di stamina
		if stamina >= max_stamina * 0.2:
			can_run = true
func get_stamina_percent() -> float:
	return stamina / max_stamina
	
func update_fear(delta: float):
	# La paura diminuisce nel tempo
	if fear > 0:
		fear -= fear_decay * delta
		fear = max(fear, 0)

func add_fear(amount: float):
	fear += amount
	fear = min(fear, max_fear)
	print("Fear: ", int(fear), "%")

func get_fear_percent() -> float:
	return fear / max_fear
	
func apply_fear_effects(delta: float):
	var fear_percent = get_fear_percent()
	
	if fear_percent <= 0:
		# Il reset dei effetti
		camera.fov = base_fov
		camera.rotation.z = 0
		return
	
	# Tremolio Camera
	shake_time += delta * (5 + fear_percent * 10)
	fear_shake_intensity = fear_percent * 0.02
	
	camera.rotation.z = sin(shake_time) * fear_shake_intensity
	camera.rotation.x += cos(shake_time * 1.3) * fear_shake_intensity * 0.5
	
	# Fov Distorto
	var target_fov = base_fov - (fear_percent * 10)
	camera.fov = lerp(camera.fov, target_fov, delta * 2)
	# Effetto respiro pesante
	if fear_percent > 0.5:
		var breath = sin(shake_time * 2) * 0.01 * fear_percent
		head.position.y = 0.8 + breath
		
func update_flash_cooldown(delta: float):
	if flash_timer > 0:
		flash_timer -= delta
		if flash_timer <= 0:
			flash_timer = 0
			can_flash = true
			print("Flash READY")
			
func use_flash_stun():
	if not can_flash:
		print("Flash not ready, wait ", "%.1f" % flash_timer, "s")
		return
	if not flashlight or not flashlight.visible:
		print("Turn on flashlight first")
		return
		
	# Imposta cooldown
	can_flash = false
	flash_timer = flash_cooldown
	
	# Altri sistemi
	perform_flash_effect()
	stun_enemies_in_cone()
	
func perform_flash_effect():
	# Aumenta temporaneamente la luce
	var original_energy = flashlight.light_energy
	var original_range = flashlight.spot_range
	
	flashlight.light_energy = 5.0
	flashlight.spot_range = flash_range
	
	var tween = create_tween()
	tween.tween_property(flashlight, "light_energy", original_energy, 0.3)
	tween.parallel().tween_property(flashlight, "spot_range", original_range, 0.3)
	
func stun_enemies_in_cone():
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	for enemy in enemies:
		if is_enemy_in_flash_cone(enemy):
			print("Enemy stunned: ", enemy.name)
			if enemy.has_method("stun"):
				enemy.stun(stun_duration)
				
func is_enemy_in_flash_cone(enemy: Node3D) -> bool:
	var to_enemy = enemy.global_position - camera.global_position
	var distance = to_enemy.length()
	
	if distance > flash_range:
		return false
		
	# Angolo tra direzione camera e enemy
	var forward = -camera.global_transform.basis.z
	var angle = rad_to_deg(forward.angle_to(to_enemy.normalized()))
	
	if angle > flash_angle:
		return false
	
	# Raycast per vedere che non ci siano ostacoli
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		camera.global_position,
		enemy.global_position + Vector3(0, 1, 0)
	)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	if result:
		if result.collider == enemy or result.collider.get_parent() == enemy:
			return true
		# Se c'è un ostacolo
		return false
	
	return true
	
func get_flash_cooldown_percent() -> float:
	if can_flash:
		return 1.0
	return 1.0 - (flash_timer / flash_cooldown)
	
func toggle_flashlight():
	if flashlight:
		flashlight.visible = !flashlight.visible

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
