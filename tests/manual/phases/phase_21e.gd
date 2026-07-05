extends "res://tests/manual/phases/phase_21f.gd"

func _run_phase_21e() -> void:
	# ===================== Phase 21-E: 《雨還沒停》環境母題 =====================
	print("--- Phase 21-E: 《雨還沒停》環境母題 ---")

	# 1. 驗證地鐵月台與地下道聚落中均存在環境播放點
	var platform_scene = load("res://scenes/levels/subway_station/subway_station_platform.tscn").instantiate()
	var plat_motif = platform_scene.get_node_or_null("ThemeMotifPlayer")
	if plat_motif == null or not plat_motif is AudioStreamPlayer:
		printerr("FAIL 21-E: ThemeMotifPlayer not found in subway_station_platform!")
		get_tree().quit(1)
		return
	if plat_motif.stream == null or plat_motif.stream.resource_path != "res://assets/audio/echoes/echo_song_rain_doesnt_stop.mp3":
		printerr("FAIL 21-E: Subway platform ThemeMotifPlayer has wrong stream path: ", plat_motif.stream.resource_path if plat_motif.stream else "null")
		get_tree().quit(1)
		return
	if plat_motif.bus != &"Ambient":
		printerr("FAIL 21-E: Subway platform ThemeMotifPlayer should play on Ambient bus, got: ", plat_motif.bus)
		get_tree().quit(1)
		return
	platform_scene.free()

	var settlement_scene_21e = load("res://scenes/levels/underground_settlement/underground_settlement.tscn").instantiate()
	var set_motif = settlement_scene_21e.get_node_or_null("ThemeMotifPlayer")
	if set_motif == null or not set_motif is AudioStreamPlayer:
		printerr("FAIL 21-E: ThemeMotifPlayer not found in underground_settlement!")
		get_tree().quit(1)
		return
	if set_motif.stream == null or set_motif.stream.resource_path != "res://assets/audio/echoes/echo_song_rain_doesnt_stop.mp3":
		printerr("FAIL 21-E: Underground settlement ThemeMotifPlayer has wrong stream path: ", set_motif.stream.resource_path if set_motif.stream else "null")
		get_tree().quit(1)
		return
	if set_motif.bus != &"Ambient":
		printerr("FAIL 21-E: Underground settlement ThemeMotifPlayer should play on Ambient bus, got: ", set_motif.bus)
		get_tree().quit(1)
		return
	settlement_scene_21e.free()

	print("PASS: Phase 21-E ambient play points verified.")

