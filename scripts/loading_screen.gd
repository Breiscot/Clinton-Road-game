extends Control

@onready var progress_bar := $VBoxContainer/ProgressBar
@onready var title_label := $VBoxContainer/Title
@onready var tip_label := $VBoxContainer/TipLabel

var scene_to_load: String = ""
var loader: ResourceLoader
var load_progress: Array = []
var scene_load_status := 0
var scene_loaded := false

func _ready():
	animate_title()
	style_progress_bar()
	
func style_progress_bar():
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1)
	bg_style.set_corner_radius_all(5)
	progress_bar.add_theme_stylebox_override("background", bg_style)
	
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = Color(0.8, 0.2, 0.2)
	fill_style.set_corner_radius_all(5)
	progress_bar.add_theme_stylebox_override("fill", fill_style)
	
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
		
	if scene_loaded:
		return
		
	var status = ResourceLoader.load_threaded_get_status(scene_to_load, load_progress)
	
	# ProgressBar
	if load_progress.size() > 0 and progress_bar:
		progress_bar.value = load_progress[0] * 100
		
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		scene_loaded = true
		finish_loading()
		
func finish_loading():
	if progress_bar:
		progress_bar.value = 100
	if title_label:
		title_label.text = "Compleated.."
		
	queue_free()
	get_tree().change_scene_to_file("res://scene/ui/intro_screen.tscn")
