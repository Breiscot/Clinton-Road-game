extends Node3D

# Particelle
var smoke_particles: GPUParticles3D = null
var glass_particles: GPUParticles3D = null

# Luci
@onready var headlight_left := $Headlights/HeadlightLeft if has_node("Headlights/HeadlightLeft") else null
@onready var hazard_left := $Hazardlights/HazardLeft if has_node("Hazardlights/HazardLeft") else null
@onready var hazard_right := $Hazardlights/HazardRight if has_node("Hazardlights/HazardRight") else null

# Fumo
@onready var smoke := $SmokeParticles

# Interazione
var interaction_area: Area3D = null
var interaction_prompt: Node3D = null
var prompt_label: Label3D = null
var player_in_range := false
var player_ref: CharacterBody3D = null

# Sistema Riparazione
var required_parts := 3
var collected_parts := 0
var part_names := ["Battery", "Fuel Can", "Spark Plug"]
var parts_collected := {
	"battery":  false,
	"fuel": false,
	"spark plug": false
}
var car_repaired := false

# Timer luci
var hazard_timer := 0.0
var hazard_on := false
var headlight_flicker_timer := 0.0

# Segnali
signal car_repaired_signal
signal part_collected(part_name: String, total: int, required: int)
signal interaction_availble(availble: bool)

func _ready():
	add_to_group("crashed_car")
	
	setup_car_damage()
	setup_smoke_particles()
	setup_interaction_area()
	setup_interaction_prompt()
	start_effects()
	
	print("Crashed car ready")
	print("Parts needed: ", required_parts)
	
func setup_car_damage():
	# Posiziona la testa fuori strada
	position.x += 2.5
	
func setup_smoke_particles():
	smoke_particles = GPUParticles3D.new()
	smoke_particles.name = "SmokeParticles"
	smoke_particles.amount = 50
	smoke_particles.lifetime = 3.0
	smoke_particles.emitting = true
	smoke_particles.position = Vector3(0, 1.2, 0.8)
	
	var smoke_mat := ParticleProcessMaterial.new()
	smoke_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	smoke_mat.emission_box_extents = Vector3(0.3, 0.1, 0.3)
	smoke_mat.direction = Vector3(0, 1, 0)
	smoke_mat.spread = 15.0
	smoke_mat.initial_velocity_min = 0.5
	smoke_mat.initial_velocity_max = 1.5
	smoke_mat.gravity = Vector3(0, -0.2, 0)
	smoke_mat.scale_min = 0.5
	smoke_mat.scale_max = 2.0
	
	var gradient := Gradient.new()
	gradient.add_point(0.0, Color(0.4, 0.4, 0.4, 0.6))
	gradient.add_point(1.0, Color(0.2, 0.2, 0.2, 0.0))
	var gradient_tex := GradientTexture1D.new()
	gradient_tex.gradient = gradient
	smoke_mat.color_ramp = gradient_tex
	
	smoke_particles.process_material = smoke_mat
	
	var quad := QuadMesh.new()
	quad.size = Vector2(1, 1)
	smoke_particles.draw_pass_1 = quad
	
	var visual_mat := StandardMaterial3D.new()
	visual_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	visual_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	visual_mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	visual_mat.vertex_color_use_as_albedo = true
	visual_mat.albedo_color = Color(0.5, 0.5, 0.5, 1.0)
	smoke_particles.material_override = visual_mat
	
	add_child(smoke_particles)
	
func setup_interaction_area():
	if has_node("InteractionArea"):
		interaction_area = $InteractionArea
	else:
		interaction_area = Area3D.new()
		interaction_area.name = "InteractionArea"
		
		var collision = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(3, 2, 3)
		collision.shape = shape
		collision.position = Vector3(0, 1, 2.5)
		
		interaction_area.add_child(collision)
		add_child(interaction_area)
		
	# Connetti segnali
	interaction_area.body_entered.connect(_on_interaction_area_entered)
	interaction_area.body_exited.connect(_on_interaction_area_exited)
	
	print("Interaction area setup.")
	
func setup_interaction_prompt():
	interaction_prompt = Node3D.new()
	interaction_prompt.name = "InteractionPrompt"
	interaction_prompt.position = Vector3(0, 2.5, 2.5)
	
	prompt_label = Label3D.new()
	prompt_label.text = get_prompt_text()
	prompt_label.font_size = 32
	prompt_label.modulate = Color(1, 1, 1, 1)
	prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	prompt_label.no_depth_test = true
	prompt_label.outline_size = 8
	prompt_label.outline_modulate = Color(0, 0, 0, 1)
	
	interaction_prompt.add_child(prompt_label)
	add_child(interaction_prompt)
	
	# Nascondi all'inizio
	interaction_prompt.visible = false
		
func get_prompt_text():
	if car_repaired:
		return "[E] Escape!"
	elif collected_parts >= required_parts:
		return "[E] Repair Car"
	else:
		return"[E] Repair Car\n" + str(collected_parts) + "/" + str(required_parts) + " parts"

func start_effects():
	# Fumo che esce dal motore
	if smoke_particles:
		smoke_particles.emitting = true

func _process(delta):
	update_hazard_lights(delta)
	update_headlight_flicker(delta)
	update_prompt()

func update_hazard_lights(delta):
	hazard_timer += delta
	if hazard_timer >= 0.8:
		hazard_timer = 0.0
		hazard_on = !hazard_on
		hazard_left.visible = hazard_on
		hazard_right.visible = hazard_on

		# Luce delle frecce
		if hazard_on:
			hazard_left.light_color = Color(1.0, 0.5, 0.0)
			hazard_right.light_color = Color(1.0, 0.5, 0.0)

func update_headlight_flicker(delta):
	headlight_flicker_timer += delta

	# Faro sinistro danneggiato che lampeggia
	if headlight_flicker_timer >= randf_range(0.1, 0.5):
		headlight_flicker_timer = 0.0
		if randf() > 0.3:
			headlight_left.light_energy = randf_range(0.3, 1.0)
		else:
			headlight_left.light_energy = 0.0
			
func update_prompt():
	if interaction_prompt == null:
		return
		
	# Mostra/Nascondi prompt
	interaction_prompt.visible = player_in_range
	
	# Aggiorna testo
	if prompt_label:
		prompt_label.text = get_prompt_text()
		
		# Colore in base allo stato
		if collected_parts >= required_parts:
			prompt_label.modulate = Color(0.2, 1.0, 0.2)
		else:
			prompt_label.modulate = Color(1.0, 0.5, 0.2)
			
func _input(event):
	if not player_in_range:
		return
		
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		try_interact()
		
func try_interact():
	print("Parts: ", collected_parts, "/", required_parts)
	
	if car_repaired:
		escape_victory()
	elif collected_parts >= required_parts:
		repair_car()
	else:
		show_missing_parts_message()
		
func show_missing_parts_message():
	var missing := required_parts - collected_parts
	print("Need ", missing, " more parts")
	
	var missing_parts := []
	if not parts_collected["battery"]:
		missing_parts.append("Battery")
	if not parts_collected["fuel"]:
		missing_parts.append("Fuel Can")
	if not parts_collected["spark_plug"]:
		missing_parts.append("Spark Plug")
		
	print("Missing: ", missing_parts)
	
	# Aggiungi paura per frustazione
	if player_ref and player_ref.has_method("add_fear"):
		player_ref.add_fear(5.0)
		
func repair_car():
	car_repaired = true
	
	# Ferma il fumo
	if smoke_particles:
		smoke.emitting = false
		
	# Emetti segnale
	car_repaired_signal.emit()
	
	# Aggiorna prompt
	if prompt_label:
		prompt_label.text = "[E] ESCAPE!"
		prompt_label.modulate = Color(0.2, 1.0, 0.2)
		
	print("Car repaired! Press E to escape!")
	
func escape_victory():
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file("res://scene/ui/main_menu.tscn")
	
# Raccolta parti
func add_part(part_id: String):
	if parts_collected.has(part_id) and not parts_collected[part_id]:
		parts_collected[part_id] = true
		collected_parts += 1
		
		var part_name = part_id.replace("_", " ").capitalize()
		print("Collected: ", part_name, " (", collected_parts, "/", required_parts, ")")
		
		part_collected.emit(part_name, collected_parts, required_parts)
		
		return true
	return false
	
func has_all_parts() -> bool:
	return collected_parts >= required_parts
	
# Segnali

func _on_interaction_area_entered(body: Node3D):
	if body.is_in_group("player"):
		print("Player entered car interaction area")
		player_in_range = true
		player_ref = body
		interaction_availble.emit(true)
		
func _on_interaction_area_exited(body: Node3D):
	if body.is_in_group("player"):
		print("Player left car interaction area")
		player_in_range = false
		player_ref = null
		interaction_availble.emit(false)
