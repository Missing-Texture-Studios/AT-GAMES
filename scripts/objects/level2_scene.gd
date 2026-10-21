extends Node2D

var _player: CharacterBody2D


func _ready() -> void:
	var puzzle = _get_level2_puzzle()
	if puzzle != null:
		puzzle.reset_progress()


func _get_level2_puzzle() -> Node:
	if has_node("/root/Level2Puzzle"):
		return get_node("/root/Level2Puzzle")
	return null
