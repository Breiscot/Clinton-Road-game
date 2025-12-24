extends CharacterBody3D

enum State {
	IDLE,
	PATROL,
	CHASE,
	SEARCH,
	ATTACK,
	STUNNED,
	FLEE_ROAD
}

@export var patrol_speed := 3.0
@export var chase_speed := 6.0
@export var attack_damage := 100.0
@export var attack_cooldown := 0.8
@export var detection_range := 20.0
@export var attack_range := 2.5
@export var lose_interest_time := 15.0

@onready var nav_agent := $NavigationAgent3D
@onready var attack_area := $AttackArea
@onready var detection_area := $DetectionArea
@onready var raycast := $RayCast3D
#@onready var audio := $AudioStreamPlayer3D
#@onready var anim_player := $AnimationPlayer

var current_state: State = State.PATROL
var player: CharacterBody3D = null
var last_known_player_position: Vector3
var patrol_points: Array[Vector3] = []
var current_patrol_index := 0
var search_timer := 0.0
var attack_timer := 0.0
var gravity := 9.8

# Audio
var footstep_player: AudioStreamPlayer3D = null
var growl_player: AudioStreamPlayer3D = null
var chase_player: AudioStreamPlayer3D = null
var footstep_timer := 0.0

# Suoni
@export var sound_idle: AudioStream
@export var sound_chase: AudioStream
@export var sound_attack: AudioStream
@export var sound_ambient: AudioStream

# Evita Strada
var avoidance_area: Area3D = null
var is_fleeing_road := false
var flee_direction := Vector3.ZERO
var flee_timer := 0.0

func _ready():
	add_to_group("enemies")
	setup_patrol_points()
	setup_audio()
	setup_avoidance()
#	play_ambient_sound()
	
	await get_tree().physics_frame
	
	var fences = get_tree().get_nodes_in_group("road_fence")
	print("ALL FENCES IN GROUP")
	print("Total fences: ", fences.size())
	find_player()

func setup_audio():
	# Footsteps Enemy
	footstep_player = AudioStreamPlayer3D.new()
	footstep_player.name = "EnemyFootsteps"
	footstep_player.max_distance = 30
	footstep_player.volume_db = -5
	add_child(footstep_player)
	
	var footstep_stream = load("res://audio/sfx/footstep.ogg")
	if footstep_stream:
		footstep_player.stream = footstep_stream
		
	# Growl
	growl_player = AudioStreamPlayer3D.new()
	growl_player.name = "EnemyGrowl"
	growl_player.max_distance = 40
	growl_player.volume_db = 0
	add_child(growl_player)
	
	var growl_stream = load("res://audio/enemy/growl.ogg")
	if growl_stream == null:
		growl_stream = load("res://audio/enemy/growl.ogg")
	if growl_stream:
		growl_player.stream = growl_stream
		
	# Suono inseguimento
	chase_player = AudioStreamPlayer3D.new()
	chase_player.name = "EnemyChase"
	chase_player.max_distance = 50
	chase_player.volume_db = -10
	add_child(chase_player)
	
	var chase_stream = load("res://audio/enemy/enemy_chase.ogg")
	if chase_stream:
		chase_player.stream = chase_stream
		
func setup_avoidance():
	if has_node("AvoidanceArea"):
		avoidance_area = $AvoidanceArea
	else:
		avoidance_area = Area3D.new()
		avoidance_area.name = "AvoidanceArea"
		
		var collision = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = 2.0
		collision.shape = shape
		avoidance_area.add_child(collision)
		
		add_child(avoidance_area)
		
	# Connetti segnali
	avoidance_area.body_entered.connect(_on_avoidance_body_entered)
	avoidance_area.area_entered.connect(_on_avoidance_area_entered)
	
func _on_avoidance_body_entered(body: Node3D):
	if body.is_in_group("road_fence"):
		start_fleeing_road(body)
		
func _on_avoidance_area_entered(area: Area3D):
	if area.is_in_group("road_fence") or area.get_parent().is_in_group("road_fence"):
		start_fleeing_road(area)
		
var road_center_x := 0.0

func start_fleeing_road(obstacle: Node3D):
	print("START FLEEING FROM ROAD")
	print("Enemy position: ", global_position)
	print("Enemy X: ", global_position.x)
	print("Obstacle position: ", obstacle.global_position)
	
	if is_fleeing_road:
		print("Already fleeing, skip")
		return
		
	is_fleeing_road = true
	flee_timer = 3.0 # Fugge per 3 secondi
		
	if global_position.x > road_center_x:
		# Zona B - Fuggi verso destra
		flee_direction = Vector3(1, 0, 0)
	else:
		# Zona A - Fuggi verso sinistra
		flee_direction = Vector3(-1, 0, 0)
		
	flee_direction.z = randf_range(-0.3, 0.3)
	flee_direction = flee_direction.normalized()
	
	print("Final flee direction: ", flee_direction)
	
	change_state(State.FLEE_ROAD)
	
func process_flee_road(delta: float):
	flee_timer -= delta
	
	var flee_speed = chase_speed * 1.5
	velocity.x = flee_direction.x * flee_speed
	velocity.z = flee_direction.z * flee_speed
	
	if flee_direction.length() > 0.1:
		var look_target = global_position + flee_direction
		look_at(Vector3(look_target.x, global_position.y, look_target.z))
		
	if int(flee_timer * 2) % 1 == 0:
		print("Fleeing.. Pos: ", global_position, " Dir: ", flee_direction, " Timer. ", flee_timer)
		
	# Controlla se siamo abbastanza lontani dalla strada
	var distance_from_road = abs(global_position.x - road_center_x)
	if distance_from_road > 10.0 and flee_timer < 2.0:
		flee_timer = 0
		
	if flee_timer <= 0:
		is_fleeing_road = false
		flee_timer = 0
		change_state(State.PATROL)
	
func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		print("Player found: ", player.name)
	else:
		print("No player found")

func setup_patrol_points():
	# Genera i punti di pattuglia casuali intorno alla posizione iniziale
	for i in range(4):
		var angle = (TAU / 4) * i
		var point = global_position + Vector3(
			cos(angle) * randf_range(5, 15),
			0,
			sin(angle) * randf_range(5, 15)
		)
		patrol_points.append(point)

func _physics_process(delta):
	# Gravità
	if not is_on_floor():
		velocity.y -= gravity * delta
		
	update_enemy_footsteps(delta)

	match current_state:
		State.IDLE:
			process_idle(delta)
		State.PATROL:
			process_patrol(delta)
		State.CHASE:
			process_chase(delta)
		State.SEARCH:
			process_search(delta)
		State.ATTACK:
			attack_timer = attack_cooldown
			perform_attack()
			process_attack(delta)
		State.FLEE_ROAD:
			process_flee_road(delta)

	move_and_slide()
	
func update_enemy_footsteps(delta: float):
	if footstep_player == null or footstep_player.stream == null:
		return
		
	var speed = Vector2(velocity.x, velocity.z).length()
	if speed < 0.5:
		return
		
	var interval = 0.6
	if current_state == State.CHASE:
		interval = 0.35
		
	footstep_timer += delta
	
	if footstep_timer >= interval:
		footstep_timer = 0
		footstep_player.pitch_scale = randf_range(0.7, 0.9)
		footstep_player.play()

func process_idle(delta):
	#anim_player.play("idle")
	
	# Riprende pattuglia
	if randf() < 0.01:
		change_state(State.PATROL)

func process_patrol(delta):
	#anim_player.play("walk")
	if player and can_see_player():
		change_state(State.CHASE)
		return
	
	if patrol_points.is_empty():
		return

	var target = patrol_points[current_patrol_index]
	nav_agent.target_position = target

	var next_position = nav_agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()
	direction.y = 0

	velocity.x = direction.x * patrol_speed
	velocity.z = direction.z * patrol_speed

	# Ruota verso la direzione del movimento
	if direction.length() > 0.1:
		look_at(global_position + direction, Vector3.UP)

	# Controlla se ha raggiunto il punto
	if global_position.distance_to(target) < 2.0:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()

		# Pausa momentanea
		if randf() > 0.7:
			change_state(State.IDLE)
			await get_tree().create_timer(randf_range(2.0, 5.0)).timeout
			if current_state == State.IDLE:
				change_state(State.PATROL)

func process_chase(delta):
	#anim_player.play("run")
	var distance = global_position.distance_to(player.global_position)
	
	if distance < attack_range:
		change_state(State.ATTACK)
		return
	# Se può vedere il player, lo insegue
	if can_see_player():
		last_known_player_position = player.global_position
		search_timer = 0.0
	else:
		search_timer += delta
		if search_timer > lose_interest_time:
			last_known_player_position = player.global_position
			search_timer = 0
			return

	# Se abbastanza vicino per attaccare
	if global_position.distance_to(player.global_position) < attack_range:
		change_state(State.ATTACK)
		return
	else:
		search_timer += delta
		if search_timer > lose_interest_time:
			change_state(State.SEARCH)
			return

	# Insegue il giocatore
	nav_agent.target_position = last_known_player_position
	var next_position = nav_agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()
	direction.y = 0

	velocity.x = direction.x * chase_speed
	velocity.z = direction.z * chase_speed

	if direction.length() > 0.1:
		look_at(global_position + direction, Vector3.UP)
		
	# Paura durante l'inseguimento
	if player and player.has_method("add_fear"):
		var fear_amount = 0.0
		
		if distance < 5:
			fear_amount = 15.0 * delta
		elif distance < 10:
			fear_amount = 8.0 * delta
		else:
			fear_amount = 3.0 * delta
			
		player.add_fear(fear_amount)

func process_search(delta):
	#anim_player.play("search")

	search_timer += delta

	# Cerca nell'ultima posizione conosciuta
	nav_agent.target_position = last_known_player_position
	var next_position = nav_agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()
	direction.y = 0

	velocity.x = direction.x * patrol_speed * 0.7
	velocity.z = direction.z * patrol_speed * 0.7

	# Guarda intorno
	rotation.y += sin(search_timer * 2.0) * delta * 0.5

	# Finisce la ricerca
	if search_timer > lose_interest_time * 1.5:
		change_state(State.PATROL)

func process_attack(delta):
	velocity.x = 0
	velocity.z = 0

	if player == null:
		change_state(State.PATROL)
		return
	# Guarda il player
	var look_pos = Vector3(player.global_position.x, global_position.y, player.global_position.z)
	look_at(look_pos)
	
	var distance = global_position.distance_to(player.global_position)
	# Se il player e' nel range ATTACK
	if distance <= attack_range:
		attack_timer += delta
		if attack_timer >= attack_cooldown:
			attack_timer = 0.0
			perform_attack()
	else:
		change_state(State.CHASE)

func perform_attack():
	#anim_player.play("attack")
#	audio.stream = sound_attack
#	audio.play()

	# Controlla se il giocatore è ancora nell'area
	if player == null:
		return
		
	var distance = global_position.distance_to(player.global_position)
	if distance <= attack_range:
		if player.has_method("take_damage"):
			player.take_damage(attack_damage)
			print("ENEMY HIT PLAYER")

func can_see_player() -> bool:
	if player == null:
		return false
	# Calcola la distanza
	var distance = global_position.distance_to(player.global_position)
	# Range ridotto se il player é accovacciato
	var effective_range = detection_range
	if player.has_method("is_crouching") or "is_crouching" in player:
		if player.is_crouching:
			effective_range = detection_range * 0.5
	if distance > effective_range:
		return false
	# Raycast per vedere ostacoli
	var space_state = get_world_3d().direct_space_state
	var from = global_position + Vector3(0, 1, 0)
	var to = player.global_position + Vector3(0, 1, 0)

	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]

	var result = space_state.intersect_ray(query)

	if result:
		if result.collider.is_in_group("player"):
			print("Enemy can see player!")
			return true
			
	return false

func change_state(new_state: State):

#	match current_state:
#		State.CHASE:
#			audio.stop()
	var old_state = current_state
	current_state = new_state

	match new_state:
		State.FLEE_ROAD:
			print("FLEEING from road!")
			if chase_player:
				chase_player.stop()
		State.CHASE:
			# Growl
			if old_state != State.CHASE:
				if growl_player and growl_player.stream:
					growl_player.pitch_scale = randf_range(0.8, 1.0)
					growl_player.play()
					
			# Suono Inseguimento
			if chase_player and chase_player.stream:
				if not chase_player.playing:
					chase_player.play()
#			audio.stream = sound_chase
#			audio.play()
			if player and player.has_method("add_fear"):
				player.add_fear(40.0) # Paura iniziale
		State.SEARCH:
			search_timer = 0.0
		State.ATTACK:
			attack_timer = attack_cooldown * 0.8  # Attacca immediatamente
			# Growl durante attacco
			if growl_player and growl_player.stream:
				growl_player.pitch_scale = randf_range(0.6, 0.8)
				growl_player.play()
				
			if player and player.has_method("add_fear"):
				player.add_fear(40.0)

#func play_ambient_sound():
	# Suono ambientale
#	var timer = Timer.new()
#	timer.wait_time = randf_range(5.0, 15.0)
#	timer.one_shot = false
#	timer.timeout.connect(func():
#		if current_state in [State.IDLE, State.PATROL]:
#			if sound_ambient and randf() > 0.5:
#				audio.stream = sound_ambient
#				audio.play()
#	)
#	add_child(timer)
#	timer.start()

func _on_detection_area_body_entered(body):
	if body.is_in_group("player"):
		player = body
		change_state(State.SEARCH)

# Nemico stordito
func stun(duration: float):
	print("Enemy STUNNED for: ", duration, " seconds.")
	# Ferma il movimento
	velocity = Vector3.ZERO
	# Cambia stato
	var previous_state = current_state
	current_state = State.STUNNED
	# Aspetta la durata
	await get_tree().create_timer(duration).timeout
	# Riprende
	print("Enemy not stunned anymore")
	# Torna a cercare
	current_state = State.SEARCH
	search_timer = 0.0
	
func process_stunned(delta):
	velocity.x = 0
	velocity.z = 0
	rotation.y += delta * 2

func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		last_known_player_position = body.global_position
		if current_state == State.CHASE:
			current_state = State.SEARCH
