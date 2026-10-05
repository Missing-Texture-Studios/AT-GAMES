extends "res://scripts/objects/object_interaction.gd"

@export_category("Lock")
@export var locked: bool = true
@export var required_item_id: int = 1
@export var required_item_name: String = "Coin"
@export var consume_required_item: bool = true
@export var persistent_id: String = ""

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var blocking_collision: CollisionShape2D = $CollisionShape2D

var is_open: bool = false


func _ready() -> void:
	super._ready()
	if persistent_id == "pantry" and Level1Puzzle.pantry_unlocked:
		locked = false
		_open_door()
		return
	animated_sprite.play("closed")


func interact() -> void:
	if player == null or player.dialog_box.dialog_enabled:
		return

	if is_open:
		return

	if locked:
		if persistent_id == "pantry":
			Level1Puzzle.note_pantry_interaction()
		var required_item := _find_required_item()
		if required_item == null:
			if persistent_id == "pantry" and Level1Puzzle.bookshelf_examined:
				_show_dialog("A porta da despensa está trancada. Talvez a estante esconda uma chave.", DialogLine.Presentation.THOUGHT)
			else:
				_show_dialog("A porta está trancada. A fechadura parece precisar de uma chave.", DialogLine.Presentation.THOUGHT)
			return

		if consume_required_item:
			required_item.item_amount -= 1
			if required_item.item_amount <= 0:
				player.inventory.erase(required_item)

		locked = false
		if persistent_id == "pantry":
			Level1Puzzle.unlock_pantry()
		_open_door()
		_show_dialog("A chave gira na fechadura. A porta da despensa está destrancada.", DialogLine.Presentation.ACTION)
		return

	_open_door()


func _find_required_item() -> InvItem:
	for item: InvItem in player.inventory:
		if item.ItemID == required_item_id and item.item_amount > 0:
			return item
	return null


func _open_door() -> void:
	is_open = true
	animated_sprite.play("open")
	blocking_collision.set_deferred("disabled", true)
	_fade_and_remove()


func _fade_and_remove() -> void:
	var tween := create_tween()
	tween.tween_property(animated_sprite, "modulate:a", 0.0, 0.8)
	await tween.finished
	queue_free()


func _show_dialog(
	message: String,
	presentation: DialogLine.Presentation = DialogLine.Presentation.PLAIN
) -> void:
	var line := DialogLine.new()
	line.dialog_text = message
	line.presentation = presentation
	var door_dialog: Array[DialogLine] = [line]
	player.dialog_box.open(door_dialog, self)
