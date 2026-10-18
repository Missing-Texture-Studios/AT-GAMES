extends Node

const PROGRESS_PATH := "user://mara.json"
const SAVE_FORMAT := "mara-save-v1"
const SAVE_OBFUSCATION_KEY := "rising-sorrow/mara/level-v1"
const DEFAULT_LEVEL := "res://scenes/maps/level_1.tscn"
const ALLOWED_LEVELS := [
	"res://scenes/maps/level_1.tscn",
	"res://scenes/maps/basement.tscn"
]

var level: String = DEFAULT_LEVEL

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	load_progress()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func save_progress() -> void:
	level = _validated_level(level)
	var payload := JSON.stringify({"level": level})
	var data := {
		"format": SAVE_FORMAT,
		"checksum": payload.sha256_text(),
		"payload": _obfuscate(payload)
	}
	var file := FileAccess.open(PROGRESS_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Could not write save data: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data))


func load_progress() -> void:
	if not FileAccess.file_exists(PROGRESS_PATH):
		return

	var file := FileAccess.open(PROGRESS_PATH, FileAccess.READ)
	if file == null:
		return

	var save_json := JSON.new()
	if save_json.parse(file.get_as_text()) != OK or not save_json.data is Dictionary:
		return

	var save_data: Dictionary = save_json.data
	var payload := ""
	var needs_migration := false
	if save_data.get("format", "") == SAVE_FORMAT:
		var encoded_payload: Variant = save_data.get("payload", "")
		var checksum: Variant = save_data.get("checksum", "")
		if not encoded_payload is String or not checksum is String:
			return
		payload = _deobfuscate(encoded_payload)
		if payload.is_empty() or payload.sha256_text() != checksum:
			push_warning("Save data integrity check failed; progress was not loaded.")
			return
	else:
		payload = JSON.stringify(save_data)
		needs_migration = true

	var payload_json := JSON.new()
	if payload_json.parse(payload) != OK or not payload_json.data is Dictionary:
		return
	var progress: Dictionary = payload_json.data
	level = _validated_level(progress.get("level", DEFAULT_LEVEL))
	if needs_migration:
		save_progress()


func _obfuscate(value: String) -> String:
	var bytes := value.to_utf8_buffer()
	var key_bytes := SAVE_OBFUSCATION_KEY.to_utf8_buffer()
	for index in range(bytes.size()):
		bytes[index] = bytes[index] ^ key_bytes[index % key_bytes.size()]
	return Marshalls.raw_to_base64(bytes)


func _deobfuscate(value: String) -> String:
	var bytes := Marshalls.base64_to_raw(value)
	if bytes.is_empty():
		return ""
	var key_bytes := SAVE_OBFUSCATION_KEY.to_utf8_buffer()
	for index in range(bytes.size()):
		bytes[index] = bytes[index] ^ key_bytes[index % key_bytes.size()]
	return bytes.get_string_from_utf8()


func _validated_level(value: Variant) -> String:
	if value is String and value in ALLOWED_LEVELS:
		return value
	return DEFAULT_LEVEL
