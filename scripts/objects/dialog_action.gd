class_name DialogAction
extends Resource

@export_category("Action")

# Node que receberá o método.
# O caminho é relativo ao objeto que abriu o dialog.
@export var action_node: NodePath

# Nome do método que será executado.
@export var action_method: StringName = &""

# Parâmetros que serão enviados para o método.
@export var action_parameters: Array[Variant] = []
