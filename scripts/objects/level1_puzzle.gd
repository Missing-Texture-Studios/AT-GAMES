extends Node

var book_order: Array[int] = [1, 2, 3]
var book_progress: int = 0
var diary_collected: bool = false
var puzzle_solved: bool = false
var key_claimed: bool = false
var crowbar_collected: bool = false
var pantry_unlocked: bool = false
var pantry_examined: bool = false
var bookshelf_examined: bool = false
var barred_door_examined: bool = false
var inventory_snapshot: Array[InvItem] = []
var restore_inventory_pending: bool = false


func _ready() -> void:
	randomize()
	book_order.shuffle()
	get_tree().scene_changed.connect(_on_scene_changed)


func save_player_inventory(player: Node) -> void:
	inventory_snapshot.clear()
	for item: InvItem in player.inventory:
		inventory_snapshot.append(item.duplicate() as InvItem)
	restore_inventory_pending = true


func _on_scene_changed(_scene_root: Node) -> void:
	call_deferred("_restore_player_inventory")


func _restore_player_inventory() -> void:
	if not restore_inventory_pending:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	player.inventory.clear()
	for item: InvItem in inventory_snapshot:
		player.inventory.append(item.duplicate() as InvItem)
	restore_inventory_pending = false


func unlock_pantry() -> void:
	pantry_unlocked = true


func note_pantry_interaction() -> void:
	pantry_examined = true


func bookshelf_hint() -> String:
	bookshelf_examined = true
	if puzzle_solved:
		return "A estante está destrancada. Há um compartimento atrás dos livros."
	if diary_collected:
		return "A anotação do diário talvez indique a ordem destes livros. Qual volume deseja colocar?"
	if pantry_examined:
		return "Há marcas de uso nos livros. Talvez a ordem deles revele algo útil para a despensa."
	return "Três livros têm marcas de uso. Talvez exista uma ordem para colocá-los."


func read_diary(player: Node, diary: Node) -> String:
	if not diary_collected:
		diary_collected = true
		player.addItem(2, 1)
		diary.set_available(false)
	if pantry_examined:
		return "No diário, uma anotação quase apagada lista os volumes: %s." % _format_order()
	return "No diário, uma anotação quase apagada menciona uma sequência de volumes: %s." % _format_order()


func choose_book(player: Node, book_number: int) -> Dictionary:
	if puzzle_solved:
		return {"correct": false, "message": "Os livros já estão na ordem certa."}

	var book_item_id := 4 + book_number
	var book_item := _find_item(player, book_item_id)
	if book_item == null:
		return {"correct": false, "message": "Você não está carregando esse volume."}

	if book_number != book_order[book_progress]:
		return {"correct": false, "message": "Esse não é o próximo livro da sequência. A estante continua à espera."}

	book_item.item_amount -= 1
	if book_item.item_amount <= 0:
		player.inventory.erase(book_item)
	book_progress += 1
	if book_progress == book_order.size():
		puzzle_solved = true
		return {"correct": true, "message": "O último livro se encaixa. Um compartimento se abre atrás da estante."}

	return {"correct": true, "message": "O livro se encaixa. Falta encontrar o próximo da sequência."}


func claim_key(player: Node) -> String:
	if not puzzle_solved:
		return "A estante não se move. Os livros ainda parecem fora de ordem."

	if key_claimed:
		return "O compartimento atrás dos livros está vazio."

	key_claimed = true
	player.addItem(4, 1)
	if pantry_examined:
		return "Talvez esta chave abra a porta da despensa."
	return "Onde será que esta chave se encaixa?"


func claim_crowbar(player: Node, crowbar: Node) -> String:
	if crowbar_collected:
		return "Você já pegou o pé de cabra."

	crowbar_collected = true
	player.addItem(3, 1)
	crowbar.set_available(false)
	if barred_door_examined:
		return "Talvez o pé de cabra sirva para afastar aquelas barras."
	return "Talvez seja útil para soltar algo preso."


func _find_item(player: Node, item_id: int) -> InvItem:
	for item: InvItem in player.inventory:
		if item.ItemID == item_id and item.item_amount > 0:
			return item
	return null


func _format_order() -> String:
	var formatted: Array[String] = []
	for book_number in book_order:
		formatted.append(str(book_number))
	return ", depois ".join(formatted)
