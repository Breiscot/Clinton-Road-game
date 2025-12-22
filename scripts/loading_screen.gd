extends Control

@onready var progress_bar := $VBoxContainer/ProgressBar
@onready var title_label := $VBoxContainer/Title
@onready var tip_label := $VBoxContainer/TipLabel

var scene_to_load: String = ""
var loader: ResourceLoader
var load_progress: Array = []
var scene_load_status := 0

func _ready():
	animate_title()
	
func animate_title():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(title_label, "modulate:a", 0.5, 0.5)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.5)
	
func load_scene(scene_path: String):
	scene_to_load = scene_path
	
	# Inizia caricamento in background
	var error = ResourceLoader.load_threaded_request(scene_path)
	
	if error != OK:
		print("Error starting load: ", error)
		# Fallback (caricamento diretto)
		get_tree().change_scene_to_file(scene_path)
		return
		
	print("Loading scene: ", scene_path)
	
func _process(delta):
	if scene_to_load == "":
		return
		
	# Controlla progresso caricamento
	scene_load_status = ResourceLoader.load_threaded_get_status(scene_to_load, load_progress)
	
	# ProgressBar
	if load_progress.size() > 0:
		var progress = load_progress[0] * 100
		progress_bar.value = lerp(progress_bar.value, progress, delta * 10)
		
	match scene_load_status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			pass
		ResourceLoader.THREAD_LOAD_LOADED:
			progress_bar.value = 100
			title_label.text = "Compleated.."
			
			await get_tree().create_timer(0.5).timeout
			
			var loaded_scene = ResourceLoader.load_threaded_get(scene_to_load)
			get_tree().change_scene_to_packed(loaded_scene)
			
		ResourceLoader.THREAD_LOAD_FAILED:
			print("Failed to load")
