class_name DialogResponse
extends Resource

@export var text: String = ""

@export_category("Actions")
@export var actions: Array[DialogAction] = []

@export_category("Dialog Flow")
@export var target_index: int = -1
@export var close_after_action: bool = true
