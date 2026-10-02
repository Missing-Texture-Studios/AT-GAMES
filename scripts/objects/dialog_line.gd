# Representa uma única linha de dialog.
# Cada recurso DialogLine corresponde a uma fala exibida pelo sistema.

class_name DialogLine
extends Resource


@export_category("Dialog")

# Índice único usado para identificar esta linha.
# Outros elementos do sistema podem usar este índice
# para pular diretamente para esta linha.
@export var index: int = 0

# Nome do personagem que está falando.
@export var dialog_name: String = ""

# Retrato do personagem que será exibido na caixa de dialog.
@export var dialog_portrait: Texture2D

# Texto da fala.
# @export_multiline permite escrever textos maiores
# diretamente no Inspector.
@export_multiline var dialog_text: String = ""

# Índice da próxima linha quando o dialog avança normalmente.
# -1 significa que não existe próxima linha e o dialog será fechado.
@export var next_index: int = -1


@export_category("Responses")

# Define se esta linha possui opções de resposta.
@export var has_responses: bool = false

# Primeira opção de resposta.
@export var response_1: DialogResponse

# Segunda opção de resposta.
@export var response_2: DialogResponse
