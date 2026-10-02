extends Node

const LOADING_SCENE_PATH := "res://scenes/UI/loading.tscn"
const MIN_LOADING_VISIBLE_TIME := 0.2

func load_scene(target_scene: String) -> void:
	if target_scene.is_empty():
		push_error("No target scene provided for loading.")
		return

	var load_error = ResourceLoader.load_threaded_request(target_scene)
	if load_error != OK:
		push_error("Failed to queue scene for loading: %s" % target_scene)
		return

	var start_time := Time.get_ticks_msec()
	var loading_started := false

	while true:
		var status = ResourceLoader.load_threaded_get_status(target_scene)

		if status == ResourceLoader.THREAD_LOAD_LOADED:
			var packed_scene = ResourceLoader.load_threaded_get(target_scene)
			if packed_scene == null:
				push_error("Loaded scene is null: %s" % target_scene)
				return

			if not loading_started:
				get_tree().change_scene_to_packed(packed_scene)
				return

			get_tree().change_scene_to_packed(packed_scene)
			return

		if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("Failed to load scene: %s" % target_scene)
			return

		var elapsed := (Time.get_ticks_msec() - start_time) / 1000.0
		if not loading_started and elapsed >= MIN_LOADING_VISIBLE_TIME:
			get_tree().change_scene_to_file(LOADING_SCENE_PATH)
			loading_started = true

		await get_tree().process_frame
