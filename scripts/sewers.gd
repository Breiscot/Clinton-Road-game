extends Node3D

@export var the_rake_scene: PackedScene
@export var spawn_sound: AudioStream
@export var despawn_sound: AudioStream

@onready var player := $Player
@onready var rake_spawn_trigger := $RakeSpawnTrigger
@onready var rake_despawn_trigger := $RakeDespawnTrigger
@onready var spawn_audio := $SpawnSound
@onready var despawn_audio := $DespawnSound
@onready var rake_spawn_point := $RakeSpawnPoint
@onready var audio_close := $AudioClose

var intro_shown := false
var rake_spawned := false
var current_rake: Node3D = null
var rake_spawn_position := Vector3.ZERO

func _ready():
	setup_environment()
	setup_audio()
	connect_triggers()
	
	if audio_close:
		audio_close.play()
	
	await get_tree().create_timer(2.0).timeout
	show_intro_messages()
	
func setup_environment():
	var world_env = WorldEnvironment.new()
	var env = Environment.new()
	
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#050505")
	
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#0a0a0a")
	env.ambient_light_energy = 0.02
	
	env.fog_enabled = true
	env.fog_light_color = Color("#0a0a0a")
	env.fog_density = 0.02
	
	world_env.environment = env
	add_child(world_env)
	
func setup_audio():
	if spawn_audio and spawn_sound:
		spawn_audio.stream = spawn_sound
		
	if despawn_audio and despawn_sound:
		despawn_audio.stream = despawn_sound
		
func connect_triggers():
	if rake_spawn_trigger:
		rake_spawn_trigger.body_entered.connect(_on_rake_spawn_trigger_entered)
		
	if rake_despawn_trigger:
		rake_despawn_trigger.body_entered.connect(_on_rake_despawn_trigger_entered)
	
func show_intro_messages():
	if intro_shown:
		return
	intro_shown = true
	
	show_message("I don't think I want to go back out on the street with that thing waiting for me.")
	
	await get_tree().create_timer(5.0).timeout
	show_message("These sewers... There must be a way out of here.")
	
func _on_rake_spawn_trigger_entered(body: Node3D):
	if body.is_in_group("player") and not rake_spawned:
		spawn_the_rake()
		
func _on_rake_despawn_trigger_entered(body: Node3D):
	if body.is_in_group("player") and rake_spawned:
		despawn_the_rake()
		
func spawn_the_rake():
	rake_spawned = true
	print("Sewers: Spawning The Rake..")
	
	if the_rake_scene == null:
		return
		
	# Spawn sound
	if spawn_audio and spawn_audio.stream:
		spawn_audio.play()
		
	# Message
	show_message("I hear bad things..")
	
	# Paura iniziale
	if player.has_method("add_fear"):
		player.add_fear(30.0)
		
	current_rake = the_rake_scene.instantiate()
	current_rake.global_position = rake_spawn_point.global_position
	current_rake.scale = Vector3(0.8, 0.8, 0.8)
	
	add_child(current_rake)
	
	await get_tree().physics_frame
	
	if "can_teleport" in current_rake:
		current_rake.can_teleport = false
	
	if current_rake.has_method("activate"):
		current_rake.activate()
		
func despawn_the_rake():
	print("Sewers: Despawning The Rake..")
	
	# Despawn sound
	if despawn_audio and despawn_audio.stream:
		despawn_audio.play()
		
	# Message
	show_message("It's gone...")
	
	if current_rake != null:
		if current_rake.has_method("deactivate"):
			current_rake.deactivate()
		else:
			current_rake.queue_free()
		current_rake = null
		
	rake_spawned = false
	
func show_message(text: String):
	if player and player.has_node("MessageUI"):
		player.get_node("MessageUI").show_message(text, 3.5)
