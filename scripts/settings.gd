extends Node

const SETTINGS_PATH := "user://settings.cfg"
const DEFAULT_VOLUME := 100.0
const MIN_VOLUME_DB := -80.0

var music_volume: float = DEFAULT_VOLUME
var sfx_volume: float = DEFAULT_VOLUME
var vsync_enabled: bool = true
var fullscreen_enabled: bool = false

func _ready() -> void:
	_load_settings()
	_apply_volume("Mus", music_volume)
	_apply_volume("SFX", sfx_volume)
	_apply_vsync()
	_apply_fullscreen()

func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 100.0)
	_apply_volume("Mus", music_volume)
	_save_settings()

func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 100.0)
	_apply_volume("SFX", sfx_volume)
	_save_settings()

func set_vsync_enabled(enabled: bool) -> void:
	vsync_enabled = enabled
	_apply_vsync()
	_save_settings()

func set_fullscreen_enabled(enabled: bool) -> void:
	fullscreen_enabled = enabled
	_apply_fullscreen()
	_save_settings()

func _apply_vsync() -> void:
	var mode := DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(mode)

func _apply_fullscreen() -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen_enabled else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

func _apply_volume(bus_name: String, volume: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		push_warning("Audio bus '%s' was not found." % bus_name)
		return
	var volume_db := MIN_VOLUME_DB if volume <= 0.0 else linear_to_db(volume / 100.0)
	AudioServer.set_bus_volume_db(bus_index, volume_db)

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	music_volume = clampf(config.get_value("audio", "music", DEFAULT_VOLUME), 0.0, 100.0)
	sfx_volume = clampf(config.get_value("audio", "sfx", DEFAULT_VOLUME), 0.0, 100.0)
	vsync_enabled = config.get_value("display", "vsync", true)
	fullscreen_enabled = config.get_value("display", "fullscreen", false)

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("display", "vsync", vsync_enabled)
	config.set_value("display", "fullscreen", fullscreen_enabled)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_error("Could not save settings: %s" % error_string(error))
