extends Node

func complete_chapter(chapter_num: int):
	var config = ConfigFile.new()
	config.load("user://progress.cfg")
	config.set_value("progress", "chapter_" + str(chapter_num) + "_completed", true)
	config.save("user://progress.cfg")
	print("GameProgress: Chapter ", chapter_num, " completed!")
	
func is_chapter_unlocked(chapter_num: int) -> bool:
	if chapter_num == 1:
		return true
		
	var config = ConfigFile.new()
	var err = config.load("user://progress.cfg")
	
	if err != OK:
		return false
		
	var prev_chapter = chapter_num - 1
	return config.get_value("progress", "chapter_" + str(prev_chapter) + "_completed", false)
	
func reset_progress():
	var config = ConfigFile.new()
	config.set_value("progress", "chapter_1_completed", false)
	config.set_value("progress", "chapter_2_completed", false)
	config.set_value("progress", "chapter_3_completed", false)
	config.save("user://progress.cfg")
