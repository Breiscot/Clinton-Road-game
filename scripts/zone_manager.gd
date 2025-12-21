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
	
