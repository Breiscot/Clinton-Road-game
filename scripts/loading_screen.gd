extends Control

@onready var progress_bar := $VBoxContainer/ProgressBar
@onready var title_label := $VBoxContainer/Title
@onready var tip_label := $VBoxContainer/TipLabel
@onready var background := $ColorRect

var scene_to_load: String = ""
var load_progress: Array = []
var scene_loaded := false

func _ready():
	print("LoadingScreen: Ready")
	
	if background:
		background.color = Color(0, 0, 0, 1)
		
	visible = true
	modulate.a = 1.0
	
	animate_title()
	style_progress_bar()
	
func style_progress_bar():
	if not progress_bar:
		return
	
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1)
	bg_style.set_corner_radius_all(5)
	progress_bar.add_theme_stylebox_override("background", bg_style)
	
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.8, 0.2, 0.2)
	fill_style.set_corner_radius_all(5)
	progress_bar.add_theme_stylebox_override("fill", fill_style)
	
func animate_title():
	if not title_label:
		return
	
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(title_label, "modulate:a", 0.5, 0.5)
	tween.tween_property(title_label, "modulate:a", 1.0, 0.5)
	
func load_scene(scene_path: String):
	scene_to_load = scene_path
	scene_loaded = false
	
	print("LoadingScreen: Starting to load: ", scene_path)
	
	if not FileAccess.file_exists(scene_path):
		print("LoadingScreen: ERROR - File not found : ", scene_path)
		get_tree().change_scene_to_file(scene_path)
		return
	
	# Inizia caricamento in background
	var error = ResourceLoader.load_threaded_request(scene_path)
	
	if error != OK:
		print("Error starting load: ", error)
		# Fallback (caricamento diretto)
		get_tree().change_scene_to_file(scene_path)
		return
		
	print("LoadingScreen: Threaded Loading started: ")
	
func _process(delta):
	if scene_to_load == "":
		return
		
	if scene_loaded:
		return
		
	var status = ResourceLoader.load_threaded_get_status(scene_to_load, load_progress)
	
	# ProgressBar
	if load_progress.size() > 0 and progress_bar:
		var progress_value = load_progress[0] * 100
		progress_bar.value = progress_value
		
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			pass
			
		ResourceLoader.THREAD_LOAD_LOADED:
			print("LoadingScreen: Scene loaded.")
			scene_loaded = true
			finish_loading()
			
		ResourceLoader.THREAD_LOAD_FAILED:
			print("LoadingScreen: Load failed.")
			scene_loaded = true
			get_tree().change_scene_to_file(scene_to_load)
		
func finish_loading():
	print("LoadingScreen: Finishing...")
	if progress_bar:
		progress_bar.value = 100
	if title_label:
		title_label.text = "Compleated.."
		
	queue_free()
	get_tree().change_scene_to_file("res://scene/ui/intro_screen.tscn")
