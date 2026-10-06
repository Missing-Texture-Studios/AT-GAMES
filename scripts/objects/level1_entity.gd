extends "res://scripts/objects/object_interaction.gd"


enum Kind {
	DIARY,
	BOOK,
	BOOKSHELF,
	CROWBAR,
	BARRED_DOOR
}

@export var kind: Kind = Kind.DIARY
@export_range(1, 3) var book_number: int = 1

@onready var entity_sprite: Sprite2D = $Sprite2D
@onready var blocking_shape: CollisionShape2D = $CollisionShape2D

var ENTITY_TEXTURES: Array[Texture2D] = [
	preload("res://sprites/objects/diary.png"),
	preload("res://sprites/objects/book.png"),
	preload("res://sprites/tiles/bookshelf1.png"),
	preload("res://sprites/objects/crowbar.png"),
	preload("res://sprites/tiles/barred_door.png")
]
var BOOKSHELF_SOLVED_TEXTURE := preload("res://sprites/tiles/bookshelf2.png")

func _ready() -> void:
	super._ready()
	entity_sprite.texture = ENTITY_TEXTURES[kind]
	match kind:
		Kind.DIARY:
			if Level1Puzzle.diary_collected:
				set_available(false)
		Kind.BOOK:
			if Level1Puzzle.puzzle_solved:
				set_available(false)
		Kind.CROWBAR:
			if Level1Puzzle.crowbar_collected:
				set_available(false)


func interact() -> void:
	if player == null or player.dialog_box.dialog_enabled:
		return

	match kind:
		Kind.DIARY:
			await _show_dialog(Level1Puzzle.read_diary(player, self), DialogLine.Presentation.QUOTE)
		Kind.BOOK:
			await _pick_up_book()
		Kind.BOOKSHELF:
			if Level1Puzzle.puzzle_solved:
				await _claim_shelf_key()
			else:
				await _show_book_choice()
		Kind.CROWBAR:
			await _pick_up_crowbar()
		Kind.BARRED_DOOR:
			await _use_crowbar()


func set_available(available: bool) -> void:
	visible = available
	blocking_shape.set_deferred("disabled", true)
	interaction_area.set_deferred("monitoring", available)

	if is_instance_valid(player):
		player.remove_interaction(self)
		if available:
			call_deferred("_restore_nearby_interaction")


func _restore_nearby_interaction() -> void:
	if is_instance_valid(player) and interaction_area.overlaps_body(player):
		player.add_interaction(self)


func _show_dialog(message: String, presentation: DialogLine.Presentation = DialogLine.Presentation.PLAIN) -> void:
	var line := DialogLine.new()
	line.dialog_text = message
	line.presentation = presentation
	var lines: Array[DialogLine] = [line]
	player.dialog_box.open(lines, self)
	await player.dialog_box.dialog_closed


func _pick_up_book() -> void:
	var item_id := 4 + book_number
	var book_title := _book_title(book_number)
	player.addItem(item_id, 1)
	set_available(false)
	await _show_dialog("Você pega \"%s\"." % book_title, DialogLine.Presentation.ACTION)


func _show_book_choice() -> void:
	# Sem nenhum livro no inventário: filler, sem opções.
	if not _has_any_book():
		await _show_dialog(
			"Oh, parece que faltam alguns livros aqui...",
			DialogLine.Presentation.THOUGHT
		)
		return

	_book_opening_line = DialogLine.new()
	_book_opening_line.index = 0
	_book_opening_line.dialog_text = Level1Puzzle.bookshelf_hint()
	_book_opening_line.presentation = DialogLine.Presentation.THOUGHT
	_book_opening_line.has_responses = true
	_book_opening_line.next_index = -1
	_refresh_book_options()

	_book_result_line = DialogLine.new()
	_book_result_line.index = 5
	_book_result_line.dialog_text = ""
	# Após mostrar o resultado, volta para a escolha (sem fechar o dialog).
	_book_result_line.next_index = 0

	var lines: Array[DialogLine] = [_book_opening_line, _book_result_line]
	player.dialog_box.open(lines, self)
	await player.dialog_box.dialog_closed

	_book_opening_line = null
	_book_result_line = null



func _has_any_book() -> bool:
	for book_number in [1, 2, 3]:
		if _find_item(4 + book_number) != null:
			return true
	return false


func _refresh_book_options() -> void:
	if _book_opening_line == null:
		return
	var options: Array[DialogResponse] = []
	for book_number in [1, 2, 3]:
		# Só mostra os livros que o jogador tem no inventário.
		if _find_item(4 + book_number) == null:
			continue
		options.append(_book_choice_response(book_number, _book_option_text(book_number)))
	# "Nenhum" para sair sem colocar livro.
	var none_response := DialogResponse.new()
	none_response.text = "Nenhum"
	none_response.close_after_action = true
	options.append(none_response)
	_book_opening_line.responses = options


func _book_option_text(book_number_to_place: int) -> String:
	match book_number_to_place:
		1:
			return "Livro I: O Solar das Cinzas"
		2:
			return "Livro II: O Retrato Velado"
		_:
			return "Livro III: A Última Chave"


var _book_opening_line: DialogLine
var _book_result_line: DialogLine


func _book_choice_response(book_number_to_place: int, choice_text: String) -> DialogResponse:
	var response := DialogResponse.new()
	response.text = choice_text
	response.target_index = 5
	response.close_after_action = false
	var action := DialogAction.new()
	action.action_method = &"select_book_for_shelf"
	action.action_parameters = [book_number_to_place]
	response.actions.append(action)
	return response


func select_book_for_shelf(book_number_to_place: int) -> void:
	if _book_result_line == null:
		return

	var result := Level1Puzzle.choose_book(player, book_number_to_place)
	_book_result_line.dialog_text = result.message
	_book_result_line.presentation = (
		DialogLine.Presentation.ACTION if result.correct else DialogLine.Presentation.THOUGHT
	)

	# O livro usado já foi removido do inventário pelo choose_book.
	# Se o puzzle foi resolvido, troca a aparência da estante.
	if Level1Puzzle.puzzle_solved:
		entity_sprite.texture = BOOKSHELF_SOLVED_TEXTURE
		_book_result_line.next_index = -1
		return

	# Senão, atualiza as opções (sem o livro usado) para o próximo loop.
	_refresh_book_options()


func _book_title(title_number: int) -> String:
	match title_number:
		1:
			return "O Solar das Cinzas"
		2:
			return "O Retrato Velado"
		_:
			return "A Última Chave"


func _claim_shelf_key() -> void:
	var was_claimed := Level1Puzzle.key_claimed
	var hint := Level1Puzzle.claim_key(player)
	if was_claimed:
		await _show_dialog(hint)
		return
	await _show_dialog("Você encontra uma chave antiga atrás dos livros.", DialogLine.Presentation.ACTION)
	await _show_dialog(hint, DialogLine.Presentation.THOUGHT)


func _pick_up_crowbar() -> void:
	if Level1Puzzle.crowbar_collected:
		await _show_dialog("Não há mais nada aqui.")
		return
	var hint := Level1Puzzle.claim_crowbar(player, self)
	await _show_dialog("Você pega o pé de cabra.", DialogLine.Presentation.ACTION)
	await _show_dialog(hint, DialogLine.Presentation.THOUGHT)


func _use_crowbar() -> void:
	Level1Puzzle.barred_door_examined = true
	var crowbar := _find_item(3)
	if crowbar == null:
		if Level1Puzzle.crowbar_collected:
			await _show_dialog("As barras continuam firmes.", DialogLine.Presentation.THOUGHT)
		else:
			await _show_dialog("As barras parecem presas. Um pé de cabra talvez ajude.", DialogLine.Presentation.THOUGHT)
		return

	crowbar.item_amount -= 1
	if crowbar.item_amount <= 0:
		player.inventory.erase(crowbar)

	await _show_dialog("Com esforço, você afasta as barras e desce ao porão.", DialogLine.Presentation.ACTION)
	Level1Puzzle.save_player_inventory(player)
	get_tree().change_scene_to_file("res://scenes/maps/basement.tscn")


func _find_item(item_id: int) -> InvItem:
	for item: InvItem in player.inventory:
		if item.ItemID == item_id and item.item_amount > 0:
			return item
	return null
