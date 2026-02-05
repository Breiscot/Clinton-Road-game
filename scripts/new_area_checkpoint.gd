extends Node3D

@export var enemy_scene: PackedScene
@export var the_rake_scene: PackedScene
@export var the_rake_chase_scene: PackedScene
@export var enemy_visible_time := 0.5

var enemy_spawned := false
var the_rake_spawned := false
var chase_rake_spawned := false
var current_chase_rake: Node3D = null
var current_enemy: Node3D = null
var current_the_rake: Node3D = null

var enemy_spawn_position := Vector3(3.3, 0.2, -60.0)
var the_rake_spawn_position := Vector3(0, 0, 10.0)


@onready var player := $Player
@onready var black_overlay :=$CanvasLayer/BlackOverlay
@onready var intro_text := $CanvasLayer/IntroText
@onready var intro_text_2 := $CanvasLayer/IntroText2
@onready var message_label := $CanvasLayer/MessageLabel
@onready var bridge_trigger := $BridgeTrigger
@onready var the_rake_trigger := $TheRakeTrigger
@onready var the_rake_end_trigger := $TheRakeEndTrigger
@onready var tunnel_door := $TunnelDoor/Area3D
@onready var chase_trigger := $ChaseTrigger

func _ready():
	
	chase_trigger.body_entered.connect(_on_chase_trigger_entered)
	
func show_subtitle(text: String, duration := 3.5):
	message_label.text = text
	message_label.visible = true
	
	var tween = create_tween()
	tween.tween_property(message_label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(duration)
	tween.tween_property(message_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): message_label.visible = false)

	
# Trigger spawn The Rake
func _on_the_rake_trigger_entered(body: Node3D):
	if body.is_in_group("player") and not the_rake_spawned:
		spawn_the_rake()
		
func spawn_the_rake():
	the_rake_spawned = true
	
	if the_rake_scene == null:
		return
		
	# Spawna dietro al player
	the_rake_spawn_position = Vector3(
		player.global_position.x,
		0,
		player.global_position.z + 15
	)
	
	current_the_rake = the_rake_scene.instantiate()
	current_the_rake.global_position = the_rake_spawn_position
	current_the_rake.scale = Vector3(1.0, 1.0, 1.0)
	
	add_child(current_the_rake)
	
	
	await get_tree().physics_frame
	
	# Attiva The Rake
	if current_the_rake.has_method("activate"):
		current_the_rake.activate()
		
# Despawn il The Rake
func _on_the_rake_end_trigger_entered(body: Node3D):
	if body.is_in_group("player") and current_the_rake != null:
		despawn_the_rake()
		
func _on_chase_trigger_entered(body: Node3D):
	if body.is_in_group("player") and not chase_rake_spawned:
		spawn_chase_rake()
		
func spawn_chase_rake():
	chase_rake_spawned = true
	
	if the_rake_chase_scene == null:
		the_rake_chase_scene = the_rake_scene
		
	if the_rake_chase_scene == null:
		return
		
	# Abilita la porta
	if tunnel_door and tunnel_door.has_method("enable_entry"):
		tunnel_door.enable_entry()
		
	var player_forward = -player.global_transform.basis.z
	var spawn_pos = player.global_position + player_forward * 25.0
	spawn_pos.y = 0
	
	current_chase_rake = the_rake_chase_scene.instantiate()
	current_chase_rake.global_position = spawn_pos
	current_chase_rake.scale = Vector3(1.0, 1.0, 1.0)
	
	add_child(current_chase_rake)
	
	show_subtitle("NO FUCK! I NEED TO GET OUT OF HERE!")
	
	await get_tree().physics_frame
	
	# Attiva in chase mode
	if current_chase_rake.has_method("activate_chase"):
		current_chase_rake.activate_chase()
		
func despawn_the_rake():
	if current_the_rake != null:
		if current_the_rake.has_method("deactivate"):
			current_the_rake.deactivate()
		else:
			current_the_rake.queue_free()
		current_the_rake = null
		
	the_rake_spawned = false
		
