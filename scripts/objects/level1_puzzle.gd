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
var boss_defeated: bool = false
var inventory_snapshot: Array[InvItem] = []
var restore_inventory_pending: bool = false


func _ready() -> void:
	randomize()
	book_order.shuffle()
	get_tree().scene_changed.connect(_on_scene_changed)


func reset_progress() -> void:
	book_order = [1, 2, 3]
	book_order.shuffle()
	book_progress = 0
	diary_collected = false
	puzzle_solved = false
	key_claimed = false
	crowbar_collected = false
	pantry_unlocked = false
	pantry_examined = false
	bookshelf_examined = false
	barred_door_examined = false
	boss_defeated = false
	inventory_snapshot.clear()
	restore_inventory_pending = false


func save_player_inventory(player: Node) -> void:
	inventory_snapshot.clear()
	for item: InvItem in player.inventory:
		inventory_snapshot.append(item.duplicate() as InvItem)
	restore_inventory_pending = true


func _on_scene_changed() -> void:
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


func mark_boss_defeated() -> void:
	boss_defeated = true


func note_pantry_interaction() -> void:
	pantry_examined = true


func bookshelf_hint() -> String:
	bookshelf_examined = true
	if puzzle_solved:
		return "A estante se move com um clique seco. Há uma chave escondida atrás dos livros, como se Mara tivesse planejado isso antes mesmo de acordar."
	if diary_collected:
		return "O diário menciona uma ordem de livros e a chave escondida atrás da estante. Mara começa a achar que não foi só memória. Qual volume encaixa agora?"
	if pantry_examined:
		return "Os livros da estante parecem estar em desordem por causa de alguém. Talvez a ordem deles tenha a ver com a chave da despensa."
	return "Há marcas nos livros, como se alguém tivesse tentado deixar uma pista. Talvez a ordem deles signifique alguma coisa."


func read_diary(player: Node, diary: Node) -> String:
	if not diary_collected:
		diary_collected = true
		player.addItem(2, 1)
		diary.set_available(false)
	if pantry_examined:
		return "No diário, a caligrafia de Mara está quase apagada: 'Se o porão me assustar, siga os livros. A chave da despensa tá escondida atrás da estante e a ordem tem de estar certa.'"
	return "No diário, uma anotação quase apagada diz: 'Se eu esquecer, os livros vão lembrar por mim. A chave da despensa fica atrás da estante; a ordem importa.'"


func choose_book(player: Node, book_number: int) -> Dictionary:
	if puzzle_solved:
		return {"correct": false, "message": "Os livros já estão na ordem certa. A chave está no compartimento escondido da estante."}

	var book_item_id := 4 + book_number
	var book_item := _find_item(player, book_item_id)
	if book_item == null:
		return {"correct": false, "message": "Mara não está carregando esse volume agora. Ela se apressa e só o vê perdido no meio da bagunça."}

	if book_number != book_order[book_progress]:
		return {"correct": false, "message": "Esse não é o próximo livro. O relógio da manhã parece bater mais forte e a ordem continua confusa."}

	book_item.item_amount -= 1
	if book_item.item_amount <= 0:
		player.inventory.erase(book_item)
	book_progress += 1
	if book_progress == book_order.size():
		puzzle_solved = true
		if not key_claimed:
			key_claimed = true
			player.addItem(4, 1)
		return {"correct": true, "message": "O último livro encaixa com um clique seco. Um compartimento se abre na estante e uma chave antiga cai em suas mãos."}

	return {"correct": true, "message": "O livro entra no lugar. Mara tenta lembrar a ordem correta antes que o relógio a deixe mais atrasada."}


func claim_key(player: Node) -> String:
	if not puzzle_solved:
		return "A estante não se move. Os livros continuam fora de ordem e Mara não tem tempo para isso."

	if key_claimed:
		return "A chave já está em mãos. O compartimento da estante ficou vazio." 

	key_claimed = true
	player.addItem(4, 1)
	if pantry_examined:
		return "A chave da despensa. Finalmente, ela tem o que precisava para abrir a porta da cozinha."
	return "A chave da despensa. Mara sente que a resposta estava na estante o tempo todo."


func claim_crowbar(player: Node, crowbar: Node) -> String:
	if crowbar_collected:
		return "Mara já pegou o pé de cabra."

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
