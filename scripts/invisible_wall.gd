extends Area3D

enum WallType {
	ROAD,
	FOREST,
	ROAD_NEW_AREA_BACK,
	FOREST_NEW_AREA
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

var messages_road_new_area_back := [
	"I don't want turn back, I need to go ahead.",
]

var messages_forest_new_area := [
	"I don't want turn back to the forest.",
	"The road is my only way out of here."
]

var can_show_message := true
var cooldown := 3.0

func _ready():
	print("InvisibleWall ready, type: ", WallType.keys()[wall_type])
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node3D): 
	
	if body.is_in_group("player") and can_show_message:
		print("showing message")
		show_message()
		
func show_message():
	can_show_message = false
	
	var message := ""
	match wall_type:
		WallType.ROAD:
			message = messages_road[randi() % messages_road.size()]
		WallType.FOREST:
			message = messages_forest[randi() % messages_forest.size()]
		WallType.ROAD_NEW_AREA_BACK:
			message = messages_road_new_area_back[randi() % messages_road_new_area_back.size()]
		WallType.FOREST_NEW_AREA:
			message = messages_forest_new_area[randi() % messages_forest_new_area.size()]
			
	print("message to show: ", message)
	
	var player = get_tree().get_first_node_in_group("player")
	print("Player: ", player)
	
	if player:
		print("Has MessageUI: ", player.has_node("MessageUI"))
		
		if player.has_node("MessageUI"):
			print("Calling MessageUI.show_message()")
			player.get_node("MessageUI").show_message(message)
		elif player.has_method("show_message"):
			print("Calling player.show_message()")
			player.show_message(message)
		else:
			print("No MessageUI found, message: ", message)
	else:
		print("no player found")
			
	await get_tree().create_timer(cooldown).timeout
	can_show_message = true
	
