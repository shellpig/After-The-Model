extends "res://tests/manual/phases/phase_m2c.gd"

func _run_phase_m2b() -> void:
	# ===================== Phase M2-B: UI Chrome i18n coverage lint =====================
	# 對 ui.csv 做機械化把關，補上 GUI 走查抓不到的失譯：
	#   (a) 每個 key 三語欄皆非空
	#   (b) .translation 與 CSV 同步（揪出「改了 CSV 忘了 reimport」）
	#   (c) zh_CN 欄不得殘留繁體字（封鎖集由 zh_TW 欄實際用字推導）
	print("--- Phase M2-B: ui.csv coverage lint ---")
	var csv_records := _m2b_parse_csv("res://locale/ui.csv")
	if csv_records.size() < 2:
		printerr("FAIL M2-B: cannot parse locale/ui.csv (records=%d)" % csv_records.size())
		get_tree().quit(1)
		return
	var header: Array = csv_records[0]
	if header.size() < 4 or header[0] != "keys" or header[1] != "zh_TW" or header[2] != "zh_CN" or header[3] != "en":
		printerr("FAIL M2-B: unexpected ui.csv header: %s" % str(header))
		get_tree().quit(1)
		return

	var tr_tw := load("res://locale/ui.zh_TW.translation") as Translation
	var tr_cn := load("res://locale/ui.zh_CN.translation") as Translation
	var tr_en := load("res://locale/ui.en.translation") as Translation
	if tr_tw == null or tr_cn == null or tr_en == null:
		printerr("FAIL M2-B: ui.*.translation artifacts missing (run --import).")
		get_tree().quit(1)
		return

	# zh_CN 禁用的繁體字（取自 zh_TW 欄實際出現、且簡繁不同形的字）
	trad_blocklist = "丟佈來個們備儲內劇動務勞區員啟單囈圓報場塊墊夢夾寫將尋對層屬帳帶庫張後從徹憑憶應戲拋掙採換損撥擇據敗數斷時暢暫會棄標樣機檔檢櫃櫥欄權殘殺毀沒淨準溫滅滿潤無燈牆獲現產畫發確禮筆紅細組結絕給統絲經維綻緒緻總繼續聲聽與舊蓋蕩處號螢裝裡見視覺觀觸託記訝設診詳誌認語說談請謝證讓貝貨販買賣贅跡載輕轉這連進遊運過達選遺還銘錄鍵鎖鐘鐵門閃閉開間閘關陳隱雜離靜響頁順領頭題願類驚體鳴麼點"

	var lint_fail := false
	var lint_checked := 0
	for ri in range(1, csv_records.size()):
		var rec: Array = csv_records[ri]
		if rec.size() == 1 and str(rec[0]).strip_edges() == "":
			continue  # 空行
		if rec.size() < 4:
			printerr("FAIL M2-B: row %d has < 4 columns: %s" % [ri, str(rec)])
			lint_fail = true
			continue
		var key: String = rec[0]
		if key.strip_edges() == "":
			continue
		lint_checked += 1
		# (a) 三語皆非空
		for ci in range(1, 4):
			if str(rec[ci]).strip_edges() == "":
				printerr("FAIL M2-B: key '%s' has empty column %d." % [key, ci])
				lint_fail = true
		# (b) import 同步：.translation 查得到且與 CSV 一致
		if tr_tw.get_message(key) != rec[1]:
			printerr("FAIL M2-B: key '%s' zh_TW out of sync with CSV (reimport?)." % key)
			lint_fail = true
		if tr_cn.get_message(key) != rec[2]:
			printerr("FAIL M2-B: key '%s' zh_CN out of sync with CSV (reimport?)." % key)
			lint_fail = true
		if tr_en.get_message(key) != rec[3]:
			printerr("FAIL M2-B: key '%s' en out of sync with CSV (reimport?)." % key)
			lint_fail = true
		# (c) zh_CN 不得殘留繁體字（語言名稱標籤除外）
		if not key.begins_with("UI_SETTINGS_LANG_"):
			for ch in rec[2]:
				if trad_blocklist.contains(ch):
					printerr("FAIL M2-B: key '%s' zh_CN contains traditional char '%s'." % [key, ch])
					lint_fail = true
					break
	if lint_fail:
		get_tree().quit(1)
		return
	print("PASS M2-B: ui.csv lint over %d keys (3-locale non-empty, import in sync, zh_CN no traditional leak)." % lint_checked)

	# --- M2-B-2: 反向靜態掃描（程式碼/場景字面量 → CSV）---
	# 揪「程式裡 tr("KEY") / set_hints([...]) / hints.append|insert / .tscn prompt_text 用了某字面量 key，
	# 但 ui.csv 沒有該列」——這是 CSV→譯文方向 lint 蓋不到的型（M2-B 漏 key 即此型）。
	# 限制：只認直接字面量；動態 key（tr(var) / 三元 / 串接）不在範圍，由各 domain 資料驅動檢查負責。
	var csv_keyset := {}
	for ri2 in range(1, csv_records.size()):
		var rec2: Array = csv_records[ri2]
		if rec2.size() >= 1 and str(rec2[0]).strip_edges() != "":
			csv_keyset[rec2[0]] = true

	var gd_files: Array = []
	for src_root in ["res://scenes", "res://scripts", "res://data"]:
		_m2b_list_files(src_root, ".gd", gd_files)
	var tscn_files: Array = []
	_m2b_list_files("res://scenes", ".tscn", tscn_files)

	var re_tr := RegEx.new();   re_tr.compile('\\btr\\(\\s*"([^"]*)"\\s*\\)')
	var re_hint := RegEx.new(); re_hint.compile('\\bhints\\.(?:append|insert)\\([^"\\n]*"([^"]*)"')
	var re_seth := RegEx.new(); re_seth.compile('set_hints\\([^\\]\\n]*\\[([^\\]]*)\\]')
	var re_str := RegEx.new();  re_str.compile('"([^"]*)"')
	var re_pmt := RegEx.new();  re_pmt.compile('prompt_text = "([^"]*)"')
	# emit 內嵌的 toast 標題：note_title 的字面量值最終會被 game_ui tr()，
	# 所以「直接給字面量」必須是 ui.csv 的 key，否則英文/簡中不會翻譯。
	# （動態值如 note_title": _pending_toast_title 無引號，不被此 regex 匹配。）
	var re_note := RegEx.new(); re_note.compile('"note_title"\\s*:\\s*"([^"]*)"')

	var scan_refs := 0
	var scan_missing := {}
	var note_refs := 0
	var note_missing := {}
	for f in gd_files:
		var fa2 := FileAccess.open(f, FileAccess.READ)
		if fa2 == null:
			continue
		var txt := fa2.get_as_text(); fa2.close()
		for m in re_tr.search_all(txt):
			scan_refs += 1
			_m2b_check_ref(m.get_string(1), f, csv_keyset, scan_missing)
		for m in re_hint.search_all(txt):
			scan_refs += 1
			_m2b_check_ref(m.get_string(1), f, csv_keyset, scan_missing)
		for m in re_seth.search_all(txt):
			for sm in re_str.search_all(m.get_string(1)):
				scan_refs += 1
				_m2b_check_ref(sm.get_string(1), f, csv_keyset, scan_missing)
		for m in re_note.search_all(txt):
			note_refs += 1
			_m2b_check_ref(m.get_string(1), f, csv_keyset, note_missing)
	for f in tscn_files:
		var fa3 := FileAccess.open(f, FileAccess.READ)
		if fa3 == null:
			continue
		var txt2 := fa3.get_as_text(); fa3.close()
		for m in re_pmt.search_all(txt2):
			scan_refs += 1
			_m2b_check_ref(m.get_string(1), f, csv_keyset, scan_missing)
	if not scan_missing.is_empty():
		for k in scan_missing:
			printerr("FAIL M2-B-2: code/scene references key '%s' missing from ui.csv (e.g. %s)" % [k, scan_missing[k]])
		get_tree().quit(1)
		return
	print("PASS M2-B-2: %d literal key refs (tr/set_hints/hints/prompt_text) all present in ui.csv." % scan_refs)

	# M2-B-3: 內嵌 note_title 字面量必須是 ui.csv key（攔截硬編繁中 toast 標題）。
	if not note_missing.is_empty():
		for k in note_missing:
			printerr("FAIL M2-B-3: literal note_title '%s' is not a ui.csv key (e.g. %s) — toast 標題不會被翻譯。" % [k, note_missing[k]])
		get_tree().quit(1)
		return
	print("PASS M2-B-3: %d literal note_title refs all resolve to ui.csv keys." % note_refs)
	print("--- Phase M2-B: ALL CHECKS PASSED ---")

