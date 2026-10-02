# Representa um objeto do cenário que pode ser interagido pelo jogador.
class_name ObjectInteraction
extends StaticBody2D


@export_category("Interaction")

# Lista de linhas de dialog que este objeto irá abrir.
# As linhas podem ser configuradas diretamente no Inspector.
@export var dialog: Array[DialogLine]


# Área usada para detectar quando o jogador está próximo do objeto.
@onready var interaction_area: Area2D = $Area2D

# Referência ao jogador atualmente utilizado pela cena.
var player: CharacterBody2D


func _ready() -> void:
	# Procura o primeiro node que pertence ao grupo "player".
	player = get_tree().get_first_node_in_group("player")

	# Caso nenhum jogador seja encontrado, mostra um erro
	# e interrompe a configuração deste objeto.
	if player == null:
		push_error(
			"%s could not find a player in the 'player' group."
			% name
		)
		return

	# Conecta os sinais da Area2D para detectar
	# quando o jogador entra ou sai da área de interação.
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node2D) -> void:
	# Ignora qualquer corpo que não seja o jogador.
	if body != player:
		return

	# Adiciona este objeto à lista de objetos
	# que o jogador pode interagir.
	player.add_interaction(self)


func _on_body_exited(body: Node2D) -> void:
	# Ignora qualquer corpo que não seja o jogador.
	if body != player:
		return

	# Remove este objeto da lista de interações disponíveis.
	player.remove_interaction(self)


func interact() -> void:
	# Não faz nada caso este objeto não tenha nenhum dialog configurado.
	if dialog.is_empty():
		return

	# Impede que o objeto abra outro dialog enquanto
	# já existe um dialog ativo.
	if player.dialog_box.dialog_enabled:
		return

	# Abre o dialog no Dialog Box do jogador.
	# "self" é enviado como a origem do dialog,
	# permitindo que respostas executem métodos neste objeto.
	player.dialog_box.open(dialog, self)
