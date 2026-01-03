extends Node3D

@export var enemy_scene: PackedScene
@export var enemy_visible_time := 0.5

var enemy_spawned := false
var enemy_spawn_position := Vector3(3.3, 0.2, -60.0)
var current_enemy: Node3D = null

@onready var player := $Player
@onready var black_overlay :=$CanvasLayer/BlackOverlay
@onready var intro_text := $CanvasLayer/IntroText
@onready var bridge_trigger := $BridgeTrigger

func _ready():
	# Fade In della schermata nera
	black_overlay.color = Color(0, 0, 0, 1)
	black_overlay.visible = true
	
	# Testo introduttivo
	intro_text.text = "Hours later..."
	intro_text.modulate.a = 0
	
	# Disablita player temporaneamente
	player.set_physics_process(false)
	
	await get_tree().create_timer(1.0).timeout
	
	var tween = create_tween()
	tween.tween_property(intro_text, "modulate:a", 1.0, 1.0)
	tween.tween_interval(2.0)
	tween.tween_property(intro_text, "modulate:a", 0.0, 1.0)
	tween.tween_property(black_overlay, "color:a", 0.0, 1.5)
	tween.tween_callback(start_gameplay)
	
	bridge_trigger.body_entered.connect(_on_bridge_trigger_entered)
	
func start_gameplay():
	player.set_physics_process(true)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _on_bridge_trigger_entered(body: Node3D):
	if body.is_in_group("player") and not enemy_spawned:
		spawn_enemy()
		
func spawn_enemy():
	enemy_spawned = true
	print("Player crossed the bridge, spawning enemy...")
	
	if enemy_scene == null:
		return
		
	# Crea il nemico
	current_enemy = enemy_scene.instantiate()
	current_enemy.global_position = enemy_spawn_position
	current_enemy.scale = Vector3(6.0, 6.0, 6.0)
	
	add_child(current_enemy)
	
	# Despawn dopo qualche secondo
	await get_tree().create_timer(enemy_visible_time).timeout
	despawn_enemy()
	
func despawn_enemy():
	if current_enemy == null:
		return
		
	print("Enemy despawning.")
	
	current_enemy.queue_free()
	current_enemy = null
