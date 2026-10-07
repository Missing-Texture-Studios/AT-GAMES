extends Node
const PROGRESS_PATH := "user://mara.json"
var level = "res://scenes/maps/level_1.tscn"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_progress()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func save_progress():
	var data := {
		"level": level
	}

	var file := FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))


func load_progress():
	if !FileAccess.file_exists(PROGRESS_PATH):
		return

	var file := FileAccess.open(PROGRESS_PATH, FileAccess.READ)

	var json := JSON.new()

	if json.parse(file.get_as_text()) != OK:
		return

	var data: Dictionary = json.data

	level = data.get("level","res://scenes/maps/level_1.tscn")
