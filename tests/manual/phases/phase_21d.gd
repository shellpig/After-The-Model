extends "res://tests/manual/phases/phase_21e.gd"

func _run_phase_21d() -> void:
	# ===================== Phase 21-D: 女聲主題歌掛載 =====================
	print("--- Phase 21-D: 女聲主題歌掛載 ---")

	# 1. 驗證資料庫設定的路徑
	var song_path_21d = GameState.get_echo_audio_path("echo_linfei")
	if song_path_21d != "res://assets/audio/echoes/echo_linfei_song.mp3":
		printerr("FAIL 21-D: echo_linfei audio path incorrect, got: ", song_path_21d)
		get_tree().quit(1)
		return

	# 2. 驗證資產存在且為有效 AudioStream
	var song_stream_21d = load(song_path_21d)
	if song_stream_21d == null or not song_stream_21d is AudioStream:
		printerr("FAIL 21-D: Failed to load Lin Fei song asset as AudioStream!")
		get_tree().quit(1)
		return

	# 3. 驗證門檻值設定為 3 (半收集)
	var echo_data_21d = EchoDB.get_echo("echo_linfei")
	if echo_data_21d.get("media_slots", {}).get("audio", {}).get("threshold", 0) != 3:
		printerr("FAIL 21-D: Lin Fei audio unlock threshold is not 3!")
		get_tree().quit(1)
		return

	print("PASS: Phase 21-D linfei vocal theme song mount verified.")

