extends Node3D

@onready var player := get_tree().get_first_node_in_group("player")
@onready var entry_trigger := $EntryTrigger
@onready var dialogue_trigger := $DialogueTrigger
@onready var girl_face_target := $Girl/FaceTarget
@onready var dialogue_label := $CanvasLayer/DialogueLabel
@onready var black_screen := $CanvasLayer/BlackOverlay

var entry_triggered := false
var dialogue_started := false
var dialogue_index := 0

# Colore del testo della ragazza (Rosa/Viola)
var girl_text_color := Color("#d67fff")

# Dialogo Finale
var dialogue_lines: Array[String] = [
	"..."
]

func _ready():
	setup_environment()
	
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
