extends CanvasLayer

var dialog_box: Control
@onready var white_background: ColorRect = $WhiteBackground
@onready var fade_overlay: ColorRect = $Fade
@onready var fade_anim: AnimationPlayer = $Fade/fadeAnim



func _ready() -> void:
	_dialog_setup()
	_start_dialog()


func _dialog_setup() -> void:
	var dialog_scene := preload("res://scenes/UI/dialog_box.tscn")
	dialog_box = dialog_scene.instantiate()
	add_child(dialog_box)
	dialog_box.z_index = 10
	dialog_box.visible = false


func _start_dialog() -> void:
	var lines: Array[DialogLine] = []
	for text in [
		"O-O QUE ERA AQUILO?!",
		"SOCORRO!!!",
		"ALGUÉM ME AJUDA!!!",
		"A-alg-guém...",
		"Mara de repente desmaia"
	]:
		var line := DialogLine.new()
		line.dialog_name = "Mara"
		line.dialog_portrait = preload("res://sprites/player/portrait_static.png")
		line.hide_portrait = false
		line.hide_name = false
		line.dialog_text = text
		line.presentation = DialogLine.Presentation.PLAIN if text.contains("!") or text.contains("...") else DialogLine.Presentation.ACTION
		lines.append(line)

	for i in range(lines.size()):
		lines[i].index = i
		if i < lines.size() - 1:
			lines[i].next_index = i + 1
		else:
			lines[i].next_index = -1

	dialog_box.open(lines, self)
	await dialog_box.dialog_closed
	await get_tree().create_timer(0.25).timeout
	await _fade_out_and_continue()


func _fade_out_and_continue() -> void:
	fade_anim.play("fade")
	await fade_anim.animation_finished
	await get_tree().process_frame
	Loading.load_scene("res://scenes/maps/level_2.tscn")
