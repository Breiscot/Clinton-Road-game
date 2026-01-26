extends Node3D

enum Phase { DRIVE, SEE_CREATURE, CRASH, BLACK_TEXT, REVEAL, POST }

@export var drive_speed := 12.0
@export var brake_time := 0.7
@export var crash_move_time := 0.35
@export var black_text_time := 2.5
@export var fade_in_time := 2.0
