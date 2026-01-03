extends CharacterBody3D

enum State {
	INACTIVE,
	IDLE,
	WALKING,
	RETREATING
}

# Parametri
@export var walk_speed := 3.5
@export var retreat_speed := 8.0
@export var retreat_duration := 8.0
@export var min_distance_behind := 2.0

var player: Node3D = null
var flashlight: SpotLight3D = null
var camera: Camera3D = null

# Stati
var current_state: State = State.INACTIVE
var retreat_timer := 0.0
var is_active := false
var gravity := 9.8

# Animazioni
@onready var anim_player: AnimationPlayer = $AnimationPlayer

func _ready():
	add_to_group("the_rake")
	find_player()
	
func find_player():
	await get_tree().physics_frame
	
	var players = get_tree().get_nodes_in_group("player")
	if player.size() > 0:
		player = players[0]
		print("TheRake: Player found!")
		
		# Trova la torcia
		if player.has_node("Head/Flashlight"):
			flashlight = player.get_node("Head/Flashlight")
		
		# Trova la camera
		if player.has_node("Head/Camera3D"):
			camera = player.get_node("Head/Camera3D")
			
func _physics_process(delta):
	# Gravità
	if not is_on_floor():
		velocity.y -= gravity * delta
		
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
				
		move_and_slide()
		
func process_idle(delta):
	velocity.x = 0
	velocity.z = 0
	
	play_animation("idle")
	
	# Guarda sempre il player
	look_at_player()
	
	# Se non puntato dalla torcia, inizia a camminare
	if not is_flashlight_pointing_at_me():
		change_state(State.WALKING)
		
func process_walking(delta):
	play_animation("walk")
	
	# Se viene puntato dalla torcia, si ferma
	if is_flashlight_pointing_at_me():
		change_state(State.IDLE)
		return
		
	move_behind_player(delta)
	
func process_retreating(delta):
	retreat_timer -= delta
	
	play_animation("walk")
	
	# Si allontana dal player
	var direction = (global_position - player.global_position).normalized()
	direction.y = 0
	
	velocity.x = direction.x * retreat_speed
	velocity.z = direction.z * retreat_speed
	
	# Guarda dove va indietro
	if direction.length() > 0.1:
		var look_pos = global_position + direction
		look_at(Vector3(look_pos.x, global_position.y, look_pos.z))
		
	if retreat_timer <= 0:
		print("TheRake: Retreat finished, back to the player")
		change_state(State.WALKING)
		
func move_behind_player(delta):
	if player == null:
		return
		
	# Calcola posizione dietro al player
	var player_forward = -player.global_transform.basis.z
	var behind_position = player.global_position - player_forward * min_distance_behind
	behind_position.y = global_position.y
	
	# Direzione verso posizione
	var direction = (behind_position - global_position).normalized()
	direction.y = 0
	
	velocity.x = direction.x * walk_speed
	velocity.z = direction.z * walk_speed
	
	look_at_player()
	
func look_at_player():
	if player == null:
		return
	var look_pos = Vector3(player.global_position.x, global_position.y, player.global_position.z)
	look_at(look_pos)
	
func is_flashlight_pointing_at_me() -> bool:
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
	if is_lit:
		print("TheRake: Flashlight, freezing..")
		
		
	
	
