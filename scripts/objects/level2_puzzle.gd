extends Node

var found_coin: bool = false
var ticket_purchased: bool = false
var boarded: bool = false


func reset_progress() -> void:
	found_coin = false
	ticket_purchased = false
	boarded = false


func has_coin(player: Node) -> bool:
	return _find_item(player, 1) != null


func has_ticket(player: Node) -> bool:
	return _find_item(player, 8) != null


func find_change(player: Node) -> String:
	if found_coin:
		return "Mara revira o lixo novamente e só encontra mais sujeira."

	found_coin = true
	player.addItem(1, 1)
	return "Mara encontra uma moeda no fundo do lixo."


func buy_ticket(player: Node) -> String:
	if ticket_purchased:
		return "Mara já guardou a passagem no bolso."

	var coin := _find_item(player, 1)
	if coin == null:
		return "A máquina exige uma moeda antes de emitir a passagem."

	coin.item_amount -= 1
	if coin.item_amount <= 0:
		player.inventory.erase(coin)

	player.addItem(8, 1)
	ticket_purchased = true
	return "A máquina emite a passagem com um chiado baixo."


func board_metro() -> String:
	if not ticket_purchased:
		return "A porta do metrô não abre sem a passagem."

	boarded = true
	return "A porta se abre e Mara entra no trem."


func _find_item(player: Node, item_id: int) -> InvItem:
	if player == null:
		return null
	for item: InvItem in player.inventory:
		if item.ItemID == item_id and item.item_amount > 0:
			return item
	return null
