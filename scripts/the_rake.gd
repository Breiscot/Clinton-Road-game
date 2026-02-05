extends CharacterBody3D

enum State {
	INACTIVE,
	IDLE,
	WALKING,
	RETREATING,
	SCREAMING,
	CHASING,
	ATTACKING
}

# Parametri
@export var walk_speed := 6.0
@export var retreat_speed := 8.0
@export var chase_speed := 7.0
@export var retreat_duration := 4.0
@export var min_distance_behind := 2.0
@export var attack_range := 2.5
@export var can_teleport := true
@export var respawn_scene_path := "res://scene/new_area_checkpoint.tscn"

# Animazioni
@export var anim_idle := "the_rake/metarig|idle"
@export var anim_walk := "the_rake/metarig|walk"
@export var anim_run := "the_rake/metarig|run"
@export var anim_screech := "the_rake/metarig|screech"
@export var anim_getup := "the_rake/metarig|getup1"

# Audio
@export var footstep_sound: AudioStream
@export var screech_sound: AudioStream
@export var ambient_sound: AudioStream
@export var jumpscare_sound: AudioStream

var player: Node3D = null
var flashlight: SpotLight3D = null
var camera: Camera3D = null

# Stati
var current_state: State = State.INACTIVE
var retreat_timer := 0.0
var is_active := false
var gravity := 9.8
var is_chase_mode := false
var has_attacked := false
var stare_timer := 0.0
var stare_duration := 3.0
var teleport_distance := 20.0
var is_respawning := false

# Fear
var fear_timer := 0.0
var fear_internal := 0.5

# Audio Timing
var footstep_timer := 0.0
var footstep_interval := 0.4

# Nodi
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var footstep_player: AudioStreamPlayer3D = $FootstepPlayer
@onready var screech_player: AudioStreamPlayer3D = $ScreechPlayer
@onready var ambient_player: AudioStreamPlayer3D = $AmbientPlayer
@onready var jumpscare_player: AudioStreamPlayer3D = $JumpscarePlayer
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func _ready():
	add_to_group("the_rake")
	print("TheRake: _ready() called")
	
	if nav_agent:
		print("TheRake: NavigationAgent exists")
		await get_tree().physics_frame
		await get_tree().physics_frame
		print("TheRake: Position = ", global_position)
		print("TheRake: is on navigation mesh = ", nav_agent.is_target_reachable())
	else:
		print("TheRake: No NavigationAgent")
		
	if nav_agent:
		nav_agent.path_desired_distance = 0.5
		nav_agent.target_desired_distance = 0.5
	
	if anim_player:
		print("Animazioni disponibili:")
		var animations = anim_player.get_animation_list()
		for anim in animations:
			print(" - ", anim)
		print("===========================")
		
	setup_audio()
	find_player()
	
func setup_audio():
	# Footsteps
	if footstep_player and footstep_sound:
		footstep_player.stream = screech_sound
		footstep_player.max_distance = 30
		footstep_player.volume_db = -5
		
	# Screech
	if screech_player and screech_sound:
		screech_player.stream = screech_sound
		screech_player.max_distance = 50
		screech_player.volume_db = 0
		
	# Ambient
	if ambient_player and ambient_sound:
		ambient_player.stream = ambient_sound
		ambient_player.max_distance = 20
		ambient_player.volume_db = -20
		
	# Jumpscare
	if jumpscare_player and jumpscare_sound:
		jumpscare_player.stream = jumpscare_sound
		jumpscare_player.max_distance = 30
		jumpscare_player.volume_db = 0

func find_player():
	await get_tree().physics_frame
	
	var players = get_tree().get_nodes_in_group("player")
	print("TheRake: Found ", players.size(), " players")
	
	if players.size() > 0:
		player = players[0]
		print("TheRake: Player = ", player.name)
		
		# Trova la torcia
		if player.has_node("Head/Flashlight"):
			flashlight = player.get_node("Head/Flashlight")
			print("TheRake: Flashlight found")
		else:
			print("TheRake: Error, No Flashlight found")
	else:
		print("TheRake: Error, No player found")
		
		# Trova la camera
		if player.has_node("Head/Camera3D"):
			camera = player.get_node("Head/Camera3D")
			
func _physics_process(delta):
	# Gravità
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	if Engine.get_physics_frames() % 60 == 0:
		print("TheRake: is_active=", is_active, " state=", State.keys()[current_state])
		print("TheRake: position=", global_position)
		if player:
			print("TheRake: player position=", player.global_position)
	
	if not is_active or player == null:
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return
		
	match current_state:
		State.INACTIVE:
			velocity.x = 0
			velocity.z = 0
		State.IDLE:
			process_idle(delta)
		State.WALKING:
			process_walking(delta)
		State.RETREATING:
			process_retreating(delta)
		State.SCREAMING:
			process_screaming(delta)
		State.CHASING:
			process_chasing(delta)
		State.ATTACKING:
			velocity.x = 0
			velocity.z = 0
			
	move_and_slide()
		
func process_idle(delta):
	velocity.x = 0
	velocity.z = 0
	
	play_animation("idle")
	
	footstep_timer = 0
	
	start_ambient()
	
	# Timer per teletrasporto se guardato troppo a lungo
	if is_flashlight_pointing_at_me():
		if can_teleport:
			stare_timer += delta
		
		if stare_timer >= stare_duration:
			teleport_behind_player()
			return
	else:
		stare_timer = 0.0
		change_state(State.WALKING)
	
	# Se non puntato dalla torcia, inizia a camminare
	if not is_flashlight_pointing_at_me():
		change_state(State.WALKING)
		
func teleport_behind_player():
	print("TheRake: Teleporting..")
	stare_timer = 0.0
	
	var player_back = player.global_transform.basis.z
	var new_position = player.global_position + player_back * teleport_distance
	
	new_position.x = player.global_position.x
	new_position.y = 0
	
	visible = false
	
	await get_tree().create_timer(0.3).timeout
	
	# Teleport
	global_position = new_position
	visible = true
	
	change_state(State.WALKING)
	
func process_walking(delta):
	play_animation("walk")
	
	# Passi
	update_footsteps(delta, 0.5)
	
	# Se viene puntato dalla torcia, si ferma
	if is_flashlight_pointing_at_me():
		change_state(State.IDLE)
		return
		
	if nav_agent:
		print("TheRake: nav target = ", nav_agent.target_position)
		print("TheRake: nav finished = ", nav_agent.is_navigation_finished())
		print("TheRake: velocity = ", velocity)
		
	move_behind_player(delta)
	
	# Aggiungi paura in base alla distanza
	add_fear_by_distance(delta)
	
	# Controlla se può attaccare
	var distance = global_position.distance_to(player.global_position)
	if distance <= attack_range and not has_attacked:
		attack_player()
		
func add_fear_by_distance(delta: float, multiplier := 1.0):
	if player == null:
		return
		
	fear_timer += delta
	if fear_timer < fear_internal:
		return
		
	fear_timer = 0.0
	
	var distance = global_position.distance_to(player.global_position)
	var fear_amount := 0.0

	if distance < 5.0:
		fear_amount = 15.0 * multiplier
	elif distance < 10.0:
		fear_amount = 8.0 * multiplier
	elif distance < 20.0:
		fear_amount = 3.0 * multiplier
		
	fear_amount = fear_amount * multiplier
		
	if fear_amount > 0 and player.has_method("add_fear"):
		player.add_fear(fear_amount)
	
func process_retreating(delta):
	retreat_timer -= delta
	
	play_animation("run")
	
	# Passi veloci
	update_footsteps(delta, 0.25)
	
	if player == null:
		return
		
	var away_direction = (global_position - player.global_position).normalized()
	var retreat_target = global_position + away_direction * 10.0
	
	# Usa Navigation per scappare
	if nav_agent:
		nav_agent.target_position = retreat_target
		
		if not nav_agent.is_navigation_finished():
			var next_pos = nav_agent.get_next_path_position()
			var direction = global_position.direction_to(next_pos)
			direction.y = 0
			direction = direction.normalized()
	
			velocity.x = direction.x * retreat_speed
			velocity.z = direction.z * retreat_speed
			
			if direction.length() > 0.1:
				var look_pos = Vector3(next_pos.x, global_position.y, next_pos.z)
				look_at(look_pos)
	else:
		velocity.x = away_direction.x * retreat_speed
		velocity.z = away_direction.z * retreat_speed
		
	if retreat_timer <= 0:
		if is_chase_mode:
			change_state(State.CHASING)
		else:
			change_state(State.WALKING)
		
func process_screaming(delta):
	velocity.x = 0
	velocity.z = 0
	look_at_player()
	
func process_chasing(delta):
	play_animation("run")
	update_footsteps(delta, 0.2)
	
	if player == null or nav_agent == null: return
	
	nav_agent.target_position = player.global_position
	
	if not nav_agent.is_navigation_finished():
		_navigate_to_next_point()
	
	add_fear_by_distance(delta, 2.0)
	
	# Controlla se può attaccare
	var distance = global_position.distance_to(player.global_position)
	if distance <= attack_range and not has_attacked:
		attack_player()
		
	if not is_chase_mode and is_flashlight_pointing_at_me():
		change_state(State.IDLE)
		return
	
func attack_player():
	if has_attacked:
		return
		
	has_attacked = true
	
	print("TheRake: Attacking player!")
	change_state(State.ATTACKING)
	is_active = false
	velocity = Vector3.ZERO
	
	if player and player.has_method("add_fear"):
		player.add_fear(100.0)
	
	look_at_player()
	
	show_jumpscare_only()
	
	await get_tree().create_timer(1.0).timeout
	
	handle_player_death()
	
func show_jumpscare_only():
	if player:
		player.set_physics_process(false)
		player.set_process_input(false)
		
	play_jumpscare()
	
	var jumpscare_layer = CanvasLayer.new()
	jumpscare_layer.layer = 50
	jumpscare_layer.name = "JumpscareLayer"
	get_tree().current_scene.add_child(jumpscare_layer)
	
	# Sfondo nero
	var black_bg = ColorRect.new()
	black_bg.color = Color(0, 0, 0, 1)
	black_bg.anchor_right = 1.0
	black_bg.anchor_bottom = 1.0
	jumpscare_layer.add_child(black_bg)
	
	# Immagine jumpscare
	var jumpscare_image = TextureRect.new()
	var texture = load("res://images/jumpscare_the_rake.png")
	if texture:
		jumpscare_image.texture = texture
	jumpscare_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	jumpscare_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	jumpscare_image.anchor_right = 1.0
	jumpscare_image.anchor_bottom = 1.0
	jumpscare_layer.add_child(jumpscare_image)
		
func handle_player_death():
	print("TheRake: Handling player death")
	
	if CheckpointManager.has_checkpoint():
		var respawn_scene = CheckpointManager.get_checkpoint_scene()
		load_respawn_scene(respawn_scene)
	else:
		print("TheRake: No checkpoint, showing death screen...")
		await get_tree().create_timer(1.5).timeout
		get_tree().reload_current_scene()
		
func load_respawn_scene(scene_path: String):
	var transition_layer = CanvasLayer.new()
	transition_layer.layer = 100
	transition_layer.name = "TransitionLayer"
	get_tree().current_scene.add_child(transition_layer)
	
	var black_screen = ColorRect.new()
	black_screen.color = Color(0, 0, 0, 1)
	black_screen.anchor_right = 1.0
	black_screen.anchor_bottom = 1.0
	transition_layer.add_child(black_screen)
	
	await get_tree().create_timer(1.0).timeout
	
	var jumpscare_layer = get_tree().current_scene.get_node_or_null("JumpscareLayer")
	if jumpscare_layer:
		jumpscare_layer.queue_free()
		
	get_tree().change_scene_to_file(scene_path)
	
func reset_rake():
	has_attacked = false
	is_active = false
	stare_timer = 0.0
	current_state = State.INACTIVE
	velocity = Vector3.ZERO
	
	var spawn_points = get_tree().get_nodes_in_group("rake_spawn_point")
	
	if spawn_points.size() > 0:
		var spawn_point = spawn_points[randi() % spawn_points.size()]
		global_position = spawn_point.global_position
	else:
		if CheckpointManager.has_checkpoint:
			var random_offset = Vector3(
				randf_range(-1, 1),
				0,
				randf_range(-1, 1)
			).normalized() * 25.0
			global_position = CheckpointManager.checkpoint_position + random_offset
	
	visible = false
	
	await get_tree().create_timer(3.0).timeout
	
	visible = true
	activate()
		
func show_jumpscare():
	if player:
		player.set_physics_process(false)
		player.set_process_input(false)
		
	# Audio
	play_jumpscare()
		
	var jumpscare_layer = CanvasLayer.new()
	jumpscare_layer.layer = 50
	jumpscare_layer.name = "JumpscareLayer"
	get_tree().current_scene.add_child(jumpscare_layer)
	
	# Sfondo nero
	var black_bg = ColorRect.new()
	black_bg.color = Color(0, 0, 0, 1)
	black_bg.anchor_right = 1.0
	black_bg.anchor_bottom = 1.0
	jumpscare_layer.add_child(black_bg)
	
	# Immagine jumpscare
	var jumpscare_image = TextureRect.new()
	var texture = load("res://images/jumpscare_the_rake.png")
	if texture:
		jumpscare_image.texture = texture
	jumpscare_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	jumpscare_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	jumpscare_image.anchor_right = 1.0
	jumpscare_image.anchor_bottom = 1.0
	jumpscare_layer.add_child(jumpscare_image)
	
	await get_tree().create_timer(0.8).timeout
	
	if player and player.has_method("take_damage"):
		player.take_damage(100)
		
func update_footsteps(delta: float, interval: float):
	footstep_timer += delta
	
	if footstep_timer >= interval:
		footstep_timer = 0
		play_footstep()
		
func play_footstep():
	if footstep_player and footstep_player.stream:
		footstep_player.pitch_scale = randf_range(0.8, 1.2)
		footstep_player.play()
		
func play_screech():
	if screech_player and screech_player.stream:
		screech_player.pitch_scale = randf_range(0.9, 1.1)
		screech_player.play()
		
func play_jumpscare():
	if jumpscare_player and jumpscare_player.stream:
		jumpscare_player.pitch_scale = randf_range(0.9, 1.1)
		jumpscare_player.play()
		
func start_ambient():
	if ambient_player and ambient_player.stream:
		if not ambient_player.playing:
			ambient_player.play()
			
func stop_ambient():
	if ambient_player and ambient_player.playing:
		ambient_player.stop()
		
func move_behind_player(delta):
	if player == null or nav_agent == null: return
		
	# Calcola posizione dietro al player
	var player_forward = -player.global_transform.basis.z
	var target_pos = player.global_position - player_forward * min_distance_behind
	
	var map = get_world_3d().navigation_map
	target_pos = NavigationServer3D.map_get_closest_point(map, target_pos)
	
	nav_agent.target_position = target_pos
	
	if nav_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		look_at_player()
		return
		
	_navigate_to_next_point()
		
func _navigate_to_next_point():
	var next_path_pos = nav_agent.get_next_path_position()
	var direction = (next_path_pos - global_position)
	direction.y = 0
	
	if direction.length() > 0.1:
		direction = direction.normalized()
		velocity.x = direction.x * walk_speed if current_state == State.WALKING else direction.x * chase_speed
		velocity.z = direction.z * walk_speed if current_state == State.WALKING else direction.z * chase_speed
		
		var look_target = global_position + direction
		look_at(Vector3(look_target.x, global_position.y, look_target.z), Vector3.UP)
	
func look_at_player():
	if player == null:
		return
	var look_pos = Vector3(player.global_position.x, global_position.y, player.global_position.z)
	look_at(look_pos)
	
func is_flashlight_pointing_at_me() -> bool:
	if is_chase_mode:
		return false
	
	# Se la torcia é spenta non conta
	if flashlight == null or not flashlight.visible:
		return false
		
	# Distanza dal player
	var distance = global_position.distance_to(player.global_position)
	
	if distance > flashlight.spot_range:
		return false
		
	var to_enemy = (global_position + Vector3(0, 1, 0) - flashlight.global_position).normalized()
	
	var flashlight_direction = -flashlight.global_transform.basis.z
	
	var angle = rad_to_deg(flashlight_direction.angle_to(to_enemy))
	
	var is_lit = angle < flashlight.spot_angle / 2.0
		
	return is_lit
	
func flash_hit():
	if is_chase_mode:
		return
	
	if not is_active:
		return
		
	is_active = false
	velocity = Vector3.ZERO
	
	# Screech
	play_screech()
	
	var screech_anim = "the_rake/metarig|screech"
	if anim_player and anim_player.has_animation(screech_anim):
		print("TheRake: Playing screech")
		anim_player.play(screech_anim)
		anim_player.animation_finished.connect(_on_screech_finished, CONNECT_ONE_SHOT)
	else:
		print("TheRake: No screech animation")
		_on_screech_finished("")
		
func _on_screech_finished(anim_name: String):
	is_active = true
	
	change_state(State.RETREATING)
	retreat_timer = retreat_duration
	
func change_state(new_state: State):
	current_state = new_state
	
	if new_state != State.IDLE:
		stare_timer = 0.0
	
	if new_state in [State.IDLE, State.WALKING, State.RETREATING, State.CHASING]:
		start_ambient()
	else:
		stop_ambient()
	
func play_animation(anim_name: String):
	if anim_player == null:
		return
	
	var real_name = anim_name
	match anim_name:
		"idle":
			real_name = anim_idle
		"walk":
			real_name = anim_walk
		"run":
			real_name = anim_run
			
	if anim_player.has_animation(real_name):
		if anim_player.current_animation != real_name:
			anim_player.play(real_name)
	else:
		print("TheRake: Animation not found: ", real_name)
			
# Chiamato dal trigger per attivare il nemico
func activate():
	print("TheRake: Spawned")
	is_active = false
	is_chase_mode = false
	
	var getup_anim = "the_rake/metarig|getup1"
	if anim_player and anim_player.has_animation(getup_anim):
		print("TheRake: Playing getup animation...")
		anim_player.play(getup_anim)
		anim_player.animation_finished.connect(_on_getup_finished, CONNECT_ONE_SHOT)
	else:
		print("TheRake: No getup animation")
		_on_getup_finished("")
		
func _on_getup_finished(anim_name: String):
	is_active = true
	start_ambient()
	
	if is_chase_mode:
		change_state(State.CHASING)
	else:
		change_state(State.WALKING)
	
func activate_chase():
	print("TheRake: Chase mode activated")
	is_chase_mode = true
	is_active = false
	has_attacked = false
	
	# Fear
	if player and player.has_method("add_fear"):
		player.add_fear(50.0)
	
	# Urlo
	change_state(State.SCREAMING)
	play_screech()
	
	if anim_player and anim_player.has_animation(anim_screech):
		anim_player.play(anim_screech)
		anim_player.animation_finished.connect(_on_chase_scream_finished, CONNECT_ONE_SHOT)
	else:
		await get_tree().create_timer(1.0).timeout
		_on_chase_scream_finished("")
		
func _on_chase_scream_finished(anim_name: String):
	is_active = true
	start_ambient()
	change_state(State.CHASING)


# Chiamato dal trigger per disattivare il nemico
func deactivate():
	print("TheRake: Despawned")
	is_active = false
	is_chase_mode = false
	stop_ambient()
	change_state(State.INACTIVE)
	queue_free()
