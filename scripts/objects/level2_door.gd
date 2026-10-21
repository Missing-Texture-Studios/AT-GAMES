extends Area2D

var player: CharacterBody2D


func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if player == null:
		return

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	if body != player:
		return
	player.add_interaction(self)


func _on_body_exited(body: Node2D) -> void:
	if body != player:
		return
	player.remove_interaction(self)


func interact() -> void:
	if player == null or player.dialog_box.dialog_enabled:
		return

	var puzzle = _get_level2_puzzle()
	if puzzle == null:
		return

	if not puzzle.ticket_purchased:
		_show_dialog("A porta do metrô continua fechada. Mara precisa da passagem antes que o trem saia sem ela.", DialogLine.Presentation.THOUGHT)
		return
	player.fadein()
	await player.fade_anim.animation_finished
	get_tree().change_scene_to_file("res://scenes/maps/metro.tscn")


func _show_dialog(message: String, presentation: DialogLine.Presentation = DialogLine.Presentation.PLAIN) -> void:
	var line := DialogLine.new()
	line.dialog_name = "Mara"
	line.dialog_text = message
	line.presentation = presentation
	var lines: Array[DialogLine] = [line]
	player.dialog_box.open(lines, self)
	await player.dialog_box.dialog_closed


func _get_level2_puzzle() -> Node:
	if has_node("/root/Level2Puzzle"):
		return get_node("/root/Level2Puzzle")
	return null
