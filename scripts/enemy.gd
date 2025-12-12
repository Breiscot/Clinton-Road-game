extends CharacterBody3D

enum State {
	IDLE,
	PATROL,
	CHASE,
	SEARCH,
	ATTACK,
	STUNNED
}

@export var patrol_speed := 2.0
@export var chase_speed := 4.5
@export var attack_damage := 100.0
@export var attack_cooldown := 0.5
@export var detection_range := 15.0
@export var attack_range := 2.5
@export var lose_interest_time := 5.0

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

# Suoni
@export var sound_idle: AudioStream
@export var sound_chase: AudioStream
@export var sound_attack: AudioStream
@export var sound_ambient: AudioStream

func _ready():
	add_to_group("enemies")
	setup_patrol_points()
#	play_ambient_sound()
	
	await get_tree().physics_frame
	find_player()
	
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

	move_and_slide()

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
		# Se é lontano non lo vede
		if search_timer > lose_interest_time and distance > detection_range:
			change_state(State.SEARCH)
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
	# Se troppo lontano non vede
	if distance > detection_range:
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

	current_state = new_state

	match new_state:
		State.CHASE:
#			audio.stream = sound_chase
#			audio.play()
			if player:
				player.add_fear(0.4)
		State.SEARCH:
			search_timer = 0.0
		State.ATTACK:
			attack_timer = attack_cooldown * 0.8  # Attacca immediatamente

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
		if current_state == State.CHASE:
			last_known_player_position = player.global_position
			change_state(State.SEARCH)

# Nemico stordito
func stun(duration: float):
	change_state(State.STUNNED)
	await get_tree().create_timer(duration).timeout
	change_state(State.SEARCH)


func _on_detection_area_body_exited(body):
	if body.is_in_group("player"):
		last_known_player_position = body.global_position
		if current_state == State.CHASE:
			current_state = State.SEARCH
