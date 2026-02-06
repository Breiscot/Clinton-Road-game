extends Area3D

@export var flicker_count := 5
@export var flicker_speed := 0.1
@export var scare_sound: AudioStream

@onready var rake_model: Node3D = $RakeAppearTrigger/TheRakeModel
@onready var trigger_light: Light3D = $RakeAppearTrigger/TriggerLight
@onready var audio_player: AudioStreamPlayer3D = $Audio

var triggered := false
var original_light_energy: float

func _ready():
	body_entered.connect(_on_body_entered)
	monitoring = true
	monitorable = true
	
	if trigger_light:
		original_light_energy = trigger_light.light_energy
		
	if audio_player and scare_sound:
		audio_player.stream = scare_sound
		
func _on_body_entered(body):
	if triggered:
		return
		
	if not body.is_in_group("player"):
		return
		
	if rake_model and not rake_model.visible:
		return
		
	triggered = true
	
	start_disappear_sequence()
	
func start_disappear_sequence():
	if audio_player and audio_player.stream:
		audio_player.play()
		
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("add_fear"):
		player.add_fear(30.0)
		
	# Sfarfalla la luce
	await flicker_light()
	
	if rake_model:
		rake_model.visible = false
		
	if trigger_light:
		trigger_light.light_energy = original_light_energy
		
func flicker_light():
	if not trigger_light:
		await get_tree().create_timer(0.5).timeout
		return
		
	for i in range(flicker_count):
		# Luce spenta
		trigger_light.light_energy = 0
		await get_tree().create_timer(flicker_speed).timeout
		
		# Luce accesa
		trigger_light.light_energy = original_light_energy * randf_range(0.3, 1.2)
		await get_tree().create_timer(flicker_speed).timeout
		
	# Spegne mentre The Rake scompare
	trigger_light.light_energy = 0
	await get_tree().create_timer(flicker_speed * 2).timeout
