extends Control

@onready var stamina_bar := $StaminaContainer/StaminaBar
@onready var stamina_label := $StaminaContainer/StaminaLabel

@onready var flash_bar := $FlashContainer/FlashBar
@onready var flash_label := $FlashContainer/FlashLabel

@onready var fear_container := $FearContainer
@onready var fear_bar := $FearContainer/FearBar
@onready var fear_label := $FearContainer/FearLabel

@onready var damage_overlay := $DamageOverlay

var player: CharacterBody3D = null

# Colori
var stamina_full_color := Color(0.2, 0.8, 0.2)
var stamina_low_color := Color(0.8, 0.2, 0.2)
var flash_ready_color := Color(0.2, 0.6, 1.0)
var flash_charging_color := Color(0.3, 0.3, 0,3)
var fear_color := Color(0.6, 0.0, 0.0)
