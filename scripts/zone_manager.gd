extends Node3D

@export var road_x_min := -3.0 # Bordo sinistro road
@export var road_x_max := 3.0 # Bordo destro strada
@export var spawn_distance_from_player := 20.0 # Distanza minima spawn enemy
@export var spawn_distance_max := 35.0 # Distanza massima spawn enemy
@export var teleport_cooldown := 5.0 # secondi di teleport

var player: CharacterBody3D = null
var enemy: CharacterBody3D = null

# Stato
enum Zone { ROAD, ZONE_A, ZONE_B }
var player_current_zone: Zone = Zone.ZONE_B
var player_previous_zone: Zone = Zone.ZONE_B
var teleport_timer := 0.0
var can_teleport := true

func _ready():
	print("Zone Manager READY")
	await get_tree().physics_frame
	
	find_player()
	find_enemy()
	
	# Determina Zona iniziale del player
	if player:
		player_current_zone = get_zone(player.global_position)
		player_previous_zone = player_current_zone
		print("Player starting in zone: ", Zone.keys()[player_current_zone])
		
func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		print("ZoneManager: Player found in ZONE")
	else:
		print("ZoneManager: No Player found in ZONE")
		
func find_enemy():
	var enemies = get_tree().get_nodes_in_group("enemies")
	if enemies.size() > 0:
		enemy = enemies[0]
		print("ZoneManager: Enemy found at: ", enemy.global_position)
	else:
		print("ZoneManager: No Enemy found")
		
func _process(delta):
	if player == null:
		find_player()
		return
		
	if enemy == null:
		find_enemy()
		return
		
	# Aggiorna timer cooldown
	if not can_teleport:
		teleport_timer -= delta
		if teleport_timer <= 0:
			can_teleport = true
			
	# Controlla la zona del player
	check_player_zone()
	
func check_player_zone():
	var new_zone = get_zone(player.global_position)
	
	# Ignora se é sulla strada
	if new_zone == Zone.ROAD:
		return
		
	# Il player ha cambiato zona?
	if new_zone != player_current_zone:
		player_previous_zone = player_current_zone
		player_current_zone = new_zone
		
		print("PLAYER CHANGED ZONE!")
		print("From: ", Zone.keys()[player_previous_zone])
		print("To: ", Zone.keys()[player_current_zone])
		
		# Teletrasporta l'enemy
		if can_teleport:
			teleport_enemy_to_player_zone()
			
func get_zone(position: Vector3) -> Zone:
	if position.x >= road_x_min and position.x <= road_x_max:
		return Zone.ROAD
	elif position.x < road_x_min:
		return Zone.ZONE_A
	else:
		return Zone.ZONE_B
		
func teleport_enemy_to_player_zone():
	if enemy == null or player == null:
		return
	print("TELEPORTING ENEMY")
	
	# Calcola  posizione di spawn
	var spawn_pos = calculate_spawn_position()
	
	if spawn_pos == Vector3.ZERO:
		print("Could not find valid spawn position")
		return
		
	# Salva stato precedente
	var was_chasing = false
	if "current_state" in enemy:
		was_chasing = enemy.current_state == enemy.State.CHASE
		
	# Teletrasporta
	enemy.global_position = spawn_pos
	enemy.velocity = Vector3.ZERO
	
	# Reset stato enemy
	if enemy.has_method("change_state"):
		enemy.change_state(enemy.State.PATROL)
		
	# Se stava inseguendo, riprendi dopo un attimo
	if was_chasing:
		await get_tree().create_timer(2.0).timeout
		if enemy.has_method("change_state") and player:
			enemy.player = player
			enemy.change_state(enemy.State.CHASE)
			
	# Cooldown
	can_teleport = false
	teleport_timer = teleport_cooldown
	
	print("Enemy teleported to ", spawn_pos)
	print("Teleport on cooldown for ", teleport_cooldown, " seconds")
	
func calculate_spawn_position() -> Vector3:
	var spawn_pos := Vector3.ZERO
	var attempts := 0
	var max_attempts := 20
	
	while attempts < max_attempts:
		attempts += 1
		
		# Genera posizione casuale nella stessa zona del player
		var angle = randf() * TAU
		var distance = randf_range(spawn_distance_from_player, spawn_distance_max)
		
		var offset = Vector3(
			cos(angle) * distance,
			0,
			sin(angle) * distance
		)

		spawn_pos = player.global_position + offset
		
		# Deve essere zona corretta
		if get_zone(spawn_pos) != player_current_zone:
			# Sposta verso la zona corretta
			if player_current_zone == Zone.ZONE_A:
				spawn_pos.x = min(spawn_pos.x, road_x_min - 5)
			else:
				spawn_pos.x = max(spawn_pos.x, road_x_max + 5)
				
		# Verifica che non sia troppo vicino al player
		if spawn_pos.distance_to(player.global_position) < spawn_distance_from_player:
			continue
			
		# Verifica che non sia sulla strada
		if get_zone(spawn_pos) == Zone.ROAD:
			continue
			
		# Verifica che non sia visibile dal player
		if not is_position_visible_to_player(spawn_pos):
			return spawn_pos
			
	# Fallback: posizione lontana nella zona corretta
	if player_current_zone == Zone.ZONE_A:
		spawn_pos = Vector3(road_x_min - 20, 1, player.global_position.z + randf_range(-15, 15))
	else:
		spawn_pos = Vector3(road_x_max + 20, 1, player.global_position.z + randf_range(-15, 15))
		
	print("Using fallback spawn position after ", attempts, " attempts")
	return spawn_pos
	
func is_position_visible_to_player(pos: Vector3) -> bool:
	if player == null:
		return true
		
	var space_state = get_world_3d().direct_space_state
	var from = player.global_position + Vector3(0, 1.5, 0) # Altezza occhi
	var to = pos + Vector3(0, 1, 0)
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [player]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		return false
		
	return true
