extends "res://tests/manual/phases/phase_10b.gd"

func _run_phase_10a() -> void:
	# 10-A. Verify street ambience nodes (rain bed + subway rumble + Ambient bus)
	print("Verifying Phase 10-A street ambience...")
	if AudioServer.get_bus_index("Ambient") == -1:
		printerr("FAIL 10-A: 'Ambient' audio bus not found!")
		get_tree().quit(1)
		return
	if street_instance.get_node_or_null("BGMPlayer") != null:
		printerr("FAIL 10-A: apartment_entrance still has a dangling scene-local BGMPlayer node!")
		get_tree().quit(1)
		return
	var ambient_rain = street_instance.get_node_or_null("AmbientRain")
	if not ambient_rain or ambient_rain.stream == null or ambient_rain.bus != "Ambient" or not ambient_rain.playing:
		printerr("FAIL 10-A: AmbientRain missing, not on Ambient bus, or not playing!")
		get_tree().quit(1)
		return
	var ambient_subway = street_instance.get_node_or_null("AmbientSubway")
	if not ambient_subway or ambient_subway.bus != "Ambient":
		printerr("FAIL 10-A: AmbientSubway missing or not on Ambient bus!")
		get_tree().quit(1)
		return
	var subway_timer = street_instance.get_node_or_null("SubwayTimer")
	if not subway_timer or not subway_timer.one_shot or subway_timer.time_left <= 0.0:
		printerr("FAIL 10-A: SubwayTimer missing, not one_shot, or not armed after _ready!")
		get_tree().quit(1)
		return
	print("PASS: Phase 10-A street ambience nodes and Ambient bus verified.")

