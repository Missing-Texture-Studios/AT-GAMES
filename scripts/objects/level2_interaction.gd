extends "res://scripts/objects/object_interaction.gd"

@export var interaction_kind: String = "trash"


func interact() -> void:
	if player == null or player.dialog_box.dialog_enabled:
		return

	match interaction_kind:
		"trash":
			_handle_trash()
		"ticket_booth":
			_handle_ticket_booth()
		_:
			return


func _handle_trash() -> void:
	var puzzle = _get_level2_puzzle()
	if puzzle == null:
		return

	if puzzle.found_coin:
		_show_dialog("Mara revira a lixeira mais uma vez e só encontra sujeira, grude e um medo doentio de estar atrasada.", DialogLine.Presentation.THOUGHT)
		return

	_show_dialog("Mara revira a lixeira com nojo, e encontra uma moeda.", DialogLine.Presentation.ACTION)
	_show_dialog(puzzle.find_change(player), DialogLine.Presentation.ACTION)


func _handle_ticket_booth() -> void:
	var puzzle = _get_level2_puzzle()
	if puzzle == null:
		return

	if puzzle.ticket_purchased:
		_show_dialog("Mara guarda a passagem no bolso e sente, pela primeira vez, que consegue respirar sem pressa.", DialogLine.Presentation.THOUGHT)
		return

	if not puzzle.has_coin(player):
		_show_dialog("A máquina exige uma moeda antes de liberar a passagem. Mara precisa de troco, e rápido.", DialogLine.Presentation.THOUGHT)
		return

	_show_dialog("Mara enfia a moeda na máquina e observa, com o coração acelerado, a passagem sair com um chiado baixo.", DialogLine.Presentation.ACTION)
	_show_dialog(puzzle.buy_ticket(player), DialogLine.Presentation.ACTION)


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
