extends Control

@onready var stamina_bar := $StaminaContainer/StaminaBar
@onready var stamina_label := $StaminaContainer/StaminaLabel

@onready var flash_bar := $FlashContainer/FlashBar
@onready var flash_label := $FlashContainer/FlashLabel

@onready var fear_container := $FearContainer
@onready var fear_bar := $FearContainer/FearBar
@onready var fear_label := $FearContainer/FearLabel

@onready var damage_overlay := $DamageOverlay

@onready var parts_container := $PartsContainer
@onready var battery_label := $PartsContainer/BatteryLabel
@onready var fuel_label := $PartsContainer/FuelLabel
@onready var spark_plug_label := $PartsContainer/SparkPlugLabel

var car: Node3D = null

var player: CharacterBody3D = null

# Colori
var stamina_full_color := Color(0.2, 0.8, 0.2)
var stamina_low_color := Color(0.8, 0.2, 0.2)
var flash_ready_color := Color(0.2, 0.6, 1.0)
var flash_charging_color := Color(0.3, 0.3, 0.3)
var fear_color := Color(0.6, 0.0, 0.0)

func _ready():
	# Trova il player
	await get_tree().physics_frame
	find_player()
	
	# Applica stili iniziali
	setup_bar_styles()
	
	# Nasconde paura inizialmente
	fear_container.visible = false
	
	# Overlay invisibile
	damage_overlay.modulate.a = 0
	
	find_car()
	
	print("HUD ready")
	
func find_car():
	car = get_tree().get_first_node_in_group("crashed_car")
	if car:
		if car.has_signal("part_collected"):
			car.part_collected.connect(_on_part_collected)
		print("HUD: Car found")
	
func _on_part_collected(part_name: String, total: int, required: int):
	print("HUD: Collected ", part_name)
	update_parts_display()
	
func update_parts_display():
	if car == null:
		return
		
	if not "parts_collected" in car:
		return
		
	var parts = car.parts_collected
	
	if battery_label:
		if parts.get("battery", false):
			battery_label.text = "[X] Battery"
			battery_label.modulate = Color(0.2, 1.0, 0.2)
		else:
			battery_label.text = "[ ] Battery"
			battery_label.modulate = Color(1.0, 1.0, 1.0)
			
	if fuel_label:
		if parts.get("fuel", false):
			fuel_label.text = "[X] Fuel Can"
			fuel_label.modulate = Color(0.2, 1.0, 0.2)
		else:
			fuel_label.text = "[ ] Fuel Can"
			fuel_label.modulate = Color(1.0, 1.0, 1.0)
			
	if spark_plug_label:
		if parts.get("spark_plug", false):
			spark_plug_label.text = "[X] Spark Plug"
			spark_plug_label.modulate = Color(0.2, 1.0, 0.2)
		else:
			spark_plug_label.text = "[ ] Spark Plug"
			spark_plug_label.modulate = Color(1.0, 1.0, 1.0)

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
	
func setup_bar_styles():
	# Stile Stamina
	var stamina_fill := StyleBoxFlat.new()
	stamina_fill.bg_color = stamina_full_color
	stamina_fill.set_corner_radius_all(3)
	stamina_bar.add_theme_stylebox_override("fill", stamina_fill)
	
	var stamina_bg := StyleBoxFlat.new()
	stamina_bg.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	stamina_bg.set_corner_radius_all(3)
	stamina_bar.add_theme_stylebox_override("background", stamina_bg)
	
	# Stile Flash
	var flash_fill := StyleBoxFlat.new()
	flash_fill.bg_color = flash_ready_color
	flash_fill.set_corner_radius_all(3)
	flash_bar.add_theme_stylebox_override("fill", flash_fill)
	
	var flash_bg := StyleBoxFlat.new()
	flash_bg.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	flash_bg.set_corner_radius_all(3)
	flash_bar.add_theme_stylebox_override("background", flash_bg)
	
	# Stile Fear
	var fear_fill := StyleBoxFlat.new()
	fear_fill.bg_color = fear_color
	fear_fill.set_corner_radius_all(3)
	fear_bar.add_theme_stylebox_override("fill", fear_fill)
	
	var fear_bg := StyleBoxFlat.new()
	fear_bg.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	fear_bg.set_corner_radius_all(3)
	fear_bar.add_theme_stylebox_override("background", fear_bg)
	
func _process(delta):
	if player == null:
		find_player()
		return
		
	if car == null:
		find_car()
		
	update_stamina_bar()
	update_flash_bar()
	update_fear_bar()
	
func update_stamina_bar():
	if not player.has_method("get_stamina_percent"):
		return
		
	var stamina_percent = player.get_stamina_percent() * 100
	stamina_bar.value = stamina_percent
	
	# Cambia colore quando bassa
	var fill_style = stamina_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill_style:
		if stamina_percent < 30:
			fill_style.bg_color = stamina_low_color
			# Effetto pulsante quando si abbassa
			var pulse = abs(sin(Time.get_ticks_msec() / 150.0))
			stamina_bar.modulate = Color(1, 1, 1, 0.7 + pulse * 0.3)
		else:
			fill_style.bg_color = stamina_full_color
			stamina_bar.modulate = Color.WHITE
			
func update_flash_bar():
	if not player.has_method("get_flash_cooldown_percent"):
		return
		
	var flash_percent = player.get_flash_cooldown_percent() * 100
	flash_bar.value = flash_percent
	
	var fill_style = flash_bar.get_theme_stylebox("fill") as StyleBoxFlat
	
	# Controlla se può usare il Flash
	var can_flash = true
	if "can_flash" in player:
		can_flash = player.can_flash
		
	if can_flash:
		if fill_style:
			fill_style.bg_color = flash_ready_color
		flash_label.modulate = Color.WHITE
		
		# Effetto glow del pulsante
		var glow = abs(sin(Time.get_ticks_msec() / 300.0))
		flash_bar.modulate = Color(1, 1, 1, 0.8 + glow * 0.2)
	else:
		# In ricarica
		if fill_style:
			fill_style.bg_color = flash_charging_color
			
		# Mostra il tempo rimanente alla ricarica
		if "flash_timer" in player:
			flash_label.text = "FLASH [Q] - %.1fs" % player.flash_timer
		else:
			flash_label.text = "FLASH [Q] - CHARGING..."
			
		flash_label.modulate = Color(0.5, 0.5, 0.5)
		flash_bar.modulate = Color.WHITE
	
func update_fear_bar():
	if not player.has_method("get_fear_percent"):
		return
		
	var fear_percent = player.get_fear_percent() * 100
	
	# Mostra/Nascondi container Fear
	if fear_percent > 0:
		fear_container.visible = true
		fear_bar.value = fear_percent
		
		# Effetto pulsante quando alta
		if fear_percent > 50:
			var pulse = abs(sin(Time.get_ticks_msec() / 100.0))
			fear_container.modulate = Color(1 ,1 ,1 , 0.7 + pulse * 0.3)
			
			# Testo che cambia
			if fear_percent > 80:
				fear_label.text = "FEAR - PANIC"
			else:
				fear_label.text = "FEAR - HIGH"
		else:
			fear_container.modulate = Color.WHITE
			fear_label.text = "FEAR"
	else:
		fear_container.visible = false
		
func show_damage_flash():
	# Rosso quando il player muore
	damage_overlay.modulate.a = 0.5
	var tween = create_tween()
	tween.tween_property(damage_overlay, "modulate:a", 0.0, 0.3)
	
func pulse_fear():
	var tween = create_tween()
	fear_container.scale = Vector2(1.2, 1.2)
	tween.tween_property(fear_container, "scale", Vector2.ONE, 0.2)
