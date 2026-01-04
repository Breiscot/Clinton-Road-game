extends Area3D

enum WallType {
	ROAD,
	FOREST
}

@export var wall_type: WallType = WallType.FOREST

var messages_road := [
	"I can't go any further. I should find a way to fix the car.",
	"I think that I can't find something on this way."
]

var messages_forest := [
	"I think I'm going too far from the road.",
	"I'm straying too far, I need to turn back."
]

var can_show_message := true
var cooldown := 3.0

func _ready():
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node3D):
	if body.is_in_group("player") and can_show_message:
		show_message()
		
func show_message():
	can_show_message = false
	
	var message := ""
	match wall_type:
		WallType.ROAD:
			message = messages_road[randi() % messages_road.size()]
		WallType.FOREST:
			message = messages_forest[randi() % messages_forest.size()]
			
	# Hud e mostra messaggio
	var hud = get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_message"):
		hud.show_message(message)
	else:
		# Fallback
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_node("MessageUI"):
			player.get_node("MessageUI").show_message(message)
		else:
			print("Message: ", message)
			
	await get_tree().create_timer(cooldown).timeout
	can_show_message = true
	
