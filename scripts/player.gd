extends CharacterBody3D

# Movimento
@export var walk_speed := 3.0
@export var run_speed := 5.5
@export var mouse_sensitivity := 0.002
@export var jump_force := 4.5
@export var crouch_speed := 1.5
var is_crouching := false
var default_height := 1.8
var crouch_height := 0.9
var default_head_y := 0.8
var crouch_head_y := 0.3

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
@onready var collision_shape := $CollisionShape3D
@onready var fear_effects := $FearEffects
@onready var death_screen := $DeathScreen

var gravity : float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_speed := 3.0
var is_dead := false
var move_direction := Vector3.ZERO

# Effetti Fear
var base_fov := 75.0
var fear_shake_intensity := 0.0
var shake_time := 0.0

# Audio
var footstep_player: AudioStreamPlayer3D = null
var breath_player: AudioStreamPlayer3D = null
var footstep_timer := 0.0
var footstep_interval := 0.5 	# Tempo tra passi

func _ready():
	# Aggiungi al gruppo player
	add_to_group("player")
	# Cattura il mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	# Debug
	print("Player ready")
	
	if camera:
		base_fov = camera.fov
	
	# Se non é ancora morto
	if is_dead:
		return
		
	if CheckpointManager.has_checkpoint:
		CheckpointManager.apply_checkpoint_position()
		
	setup_audio()
	
func setup_audio():
	# Footsteps
	footstep_player = AudioStreamPlayer3D.new()
	footstep_player.name = "FootstepPlayer"
	footstep_player.max_distance = 2
	footstep_player.volume_db = -5
	add_child(footstep_player)
	
	var footstep_stream = load("res://audio/sfx/footstep.ogg")
	if footstep_stream == null:
		footstep_stream = load("res://audio/sfx/footstep.wav")
	if footstep_stream:
		footstep_player.stream = footstep_stream
	else:
		print("Footstep audio not found")
		
	breath_player = AudioStreamPlayer3D.new()
	breath_player.name = "BreathPlayer"
	breath_player.max_distance = 10
	breath_player.volume_db = -20 # Inizia basso
	add_child(breath_player)
	
	var breath_stream = load("res://audio/sfx/breathing.ogg")
	if breath_stream == null:
		breath_stream = load("res://audio/sfx/breath_heavy.ogg")
	if breath_stream:
		breath_player.stream = breath_stream

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

func _physics_process(delta):
	if is_dead:
		return
		
	# Aggiorna i sistemi
	update_stamina(delta)
	update_fear(delta)
	update_flash_cooldown(delta)
	apply_fear_effects(delta)
	update_footsteps(delta)
	update_breathing(delta)
	
	# Applica la gravità
	velocity.y -= gravity * delta

	# Salto
	if is_on_floor() and Input.is_action_just_pressed("jump"):
		velocity.y = jump_force
		print("Jump")

	# Accovacciamento
	var wants_to_crouch = Input.is_key_pressed(KEY_CTRL) or Input.is_action_pressed("crouch")
	
	if wants_to_crouch:
		start_crouch()
	else:
		stop_crouch()
		
	# Velocità in base allo stato
	var wants_to_run = Input.is_key_pressed(KEY_SHIFT) or Input.is_action_pressed("run")
	
	if is_crouching:
		current_speed = crouch_speed
	elif wants_to_run and can_run and stamina > 0:
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
		update_fear_effects()
		
func update_fear_effects():
	var fear_percent = fear / max_fear
	if fear_effects == null:
		print("WARNING: fear_effects is null.")
		return
		
	if fear_effects.has_method("set_fear_level"):
		fear_effects.set_fear_level(fear_percent)
	else:
		print("WARNING: set_fear_level method not found.")

func add_fear(amount: float):
	fear += amount
	fear = min(fear, max_fear)
	print("Fear: ", int(fear), "%")
	update_fear_effects()

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
		
func start_crouch():
	if is_crouching:
		return
		
	is_crouching = true
	
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		collision_shape.shape.height = crouch_height
		collision_shape.position.y = crouch_height / 2
		
	# Abbassa la testa
	if head:
		var tween = create_tween()
		tween.tween_property(head, "position:y", crouch_head_y, 0.15)
		
func stop_crouch():
	if not is_crouching:
		return
		
	# Controlla se può alzarsi
	if not can_stand_up():
		return
		
	is_crouching = false
	
	# Ripristina altezza collisione
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		collision_shape.shape.height = default_height
		collision_shape.position.y = default_height / 2
		
	# Alza testa
	if head:
		var tween = create_tween()
		tween.tween_property(head, "position:y", default_head_y, 0.15)
		
func can_stand_up() -> bool:
	# Raycast verso l'alto
	var space_state = get_world_3d().direct_space_state
	var from = global_position + Vector3(0, crouch_height, 0)
	var to = global_position + Vector3(0, default_height, 0)
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	
	return result.is_empty()
		
func update_flash_cooldown(delta: float):
	if flash_timer > 0:
		flash_timer -= delta
		if flash_timer <= 0:
			flash_timer = 0
			can_flash = true
			print("Flash READY")
			
func update_footsteps(delta: float):
	var horizontal_speed = Vector2(velocity.x, velocity.z).length()
	var is_moving = horizontal_speed > 0.5 and is_on_floor()
	
	if not is_moving:
		footstep_timer = 0
		return
		
	# Intervallo dipende dalla velocità
	if current_speed == run_speed:
		footstep_interval = 0.3 # Passi Veloci
	else:
		footstep_interval = 0.5 # Passi Normali
		
		footstep_timer += delta
		
		if footstep_timer >= footstep_interval:
			footstep_timer = 0
			play_footstep()
			
func play_footstep():
	if footstep_player and footstep_player.stream:
		footstep_player.pitch_scale = randf_range(0.9, 1.1)
		
		if current_speed == run_speed:
			footstep_player.volume_db = -3
		else:
			footstep_player.volume_db = -8
			
		footstep_player.play()
		
func update_breathing(delta: float):
	if breath_player == null or breath_player.stream == null:
		return
		
	var fear_percent = get_fear_percent()
	var stamina_percent = get_stamina_percent()
	
	# Respiro
	var should_breathe_heavy = fear_percent > 0.5 or stamina_percent < 0.3
	
	if should_breathe_heavy:
		# Aumenta il volume gradualmente
		var target_volume = -5.0
		if fear_percent > 0.8:
			target_volume = 0.0 # Forte quando c'è il panico
			
		breath_player.volume_db = lerp(breath_player.volume_db, target_volume, delta * 2)
		
		if not breath_player.playing:
			breath_player.play()
	else:
		# Diminuisci volume
		breath_player.volume_db = lerp(breath_player.volume_db, -40.0, delta * 3)
		
		if breath_player.volume_db < -35:
			breath_player.stop()
	
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
				
	# Respingi TheRake
	var rakes = get_tree().get_nodes_in_group("the_rake")
	for rake in rakes:
		if is_enemy_in_flash_cone(rake):
			print("The Rake hit by flash.")
			if rake.has_method("flash_hit"):
				rake.flash_hit()
				
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
	set_process_unhandled_input(false)
	
	# Jumpscare HUD
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_jumpscare"):
		hud.show_jumpscare()
		await get_tree().create_timer(1.5).timeout
	
	print("Showing death screen...")
	print("death_screen is: ", death_screen)
	
	if death_screen:
		death_screen.show_death_screen()
	else:
		print("ERROR: death_screen is null.")
	
func die():
	take_damage(100)
