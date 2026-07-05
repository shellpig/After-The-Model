extends "res://tests/manual/phases/phase_m2e.gd"

func _run_phase_m2d() -> void:
	# ===================== Phase M2-D: 對話樹與資料 i18n =====================
	print("--- Phase M2-D: 對話樹與資料 i18n ---")

	var dlg_db = load("res://data/dialogue/dialogue_db.gd")
	var shop_db = load("res://data/shops/shop_db.gd")
	var quest_db = load("res://data/quests/quest_db.gd")

	# (1) 品質 lint — dialogue.csv / data.csv
	for csv_domain in ["dialogue", "data"]:
		var csv_path := "res://locale/%s.csv" % csv_domain
		var recs := _m2b_parse_csv(csv_path)
		if recs.size() < 2:
			printerr("FAIL M2-D: cannot parse %s (records=%d)" % [csv_path, recs.size()])
			get_tree().quit(1)
			return
		var hdr: Array = recs[0]
		if hdr.size() < 4 or hdr[0] != "keys" or hdr[1] != "zh_TW" or hdr[2] != "zh_CN" or hdr[3] != "en":
			printerr("FAIL M2-D: unexpected %s header: %s" % [csv_path, str(hdr)])
			get_tree().quit(1)
			return
		var t_tw := load("res://locale/%s.zh_TW.translation" % csv_domain) as Translation
		var t_cn := load("res://locale/%s.zh_CN.translation" % csv_domain) as Translation
		var t_en := load("res://locale/%s.en.translation" % csv_domain) as Translation
		if t_tw == null or t_cn == null or t_en == null:
			printerr("FAIL M2-D: %s.*.translation artifacts missing (run --import)." % csv_domain)
			get_tree().quit(1)
			return

		var c_fail := false
		var c_checked := 0
		for ri3 in range(1, recs.size()):
			var rr: Array = recs[ri3]
			if rr.size() == 1 and str(rr[0]).strip_edges() == "":
				continue
			if rr.size() < 4:
				printerr("FAIL M2-D: %s row %d has < 4 columns: %s" % [csv_domain, ri3, str(rr)])
				c_fail = true
				continue
			var kk: String = rr[0]
			if kk.strip_edges() == "":
				continue
			c_checked += 1
			# (a) 三語非空
			for ci2 in range(1, 4):
				if str(rr[ci2]).strip_edges() == "":
					printerr("FAIL M2-D: %s key '%s' has empty column %d." % [csv_domain, kk, ci2])
					c_fail = true
			# (b) import 與 CSV 同步
			if t_tw.get_message(kk) != rr[1]:
				printerr("FAIL M2-D: %s key '%s' zh_TW out of sync (reimport?)." % [csv_domain, kk])
				c_fail = true
			if t_cn.get_message(kk) != rr[2]:
				printerr("FAIL M2-D: %s key '%s' zh_CN out of sync (reimport?)." % [csv_domain, kk])
				c_fail = true
			if t_en.get_message(kk) != rr[3]:
				printerr("FAIL M2-D: %s key '%s' en out of sync (reimport?)." % [csv_domain, kk])
				c_fail = true
			# (c) zh_CN 無繁體字洩漏
			for ch in rr[2]:
				if trad_blocklist_c.contains(ch):
					printerr("FAIL M2-D: %s key '%s' zh_CN contains traditional char '%s'." % [csv_domain, kk, ch])
					c_fail = true
					break
		if c_fail:
			get_tree().quit(1)
			return
		print("PASS M2-D: %s.csv lint over %d keys (3-locale non-empty, import in sync, zh_CN no traditional leak)." % [csv_domain, c_checked])

	# (2) 資料驅動覆蓋：走訪資料字典，斷言 CSV 有對應列
	var dialogue_keyset := {}
	var dialogue_recs := _m2b_parse_csv("res://locale/dialogue.csv")
	for ri4 in range(1, dialogue_recs.size()):
		var rr4: Array = dialogue_recs[ri4]
		if rr4.size() >= 1 and str(rr4[0]).strip_edges() != "":
			dialogue_keyset[rr4[0]] = true

	var data_keyset := {}
	var data_recs := _m2b_parse_csv("res://locale/data.csv")
	for ri5 in range(1, data_recs.size()):
		var rr5: Array = data_recs[ri5]
		if rr5.size() >= 1 and str(rr5[0]).strip_edges() != "":
			data_keyset[rr5[0]] = true

	var m2d_coverage_fail := false

	# 1. 9 棵對話 TREE
	for tree_id in dlg_db.TREES:
		var dlg_tree: Dictionary = dlg_db.TREES[tree_id]
		for node_id in dlg_tree:
			var node: Dictionary = dlg_tree[node_id]

			# Check speaker
			if node.has("speaker"):
				var sp: String = str(node["speaker"])
				if not sp.is_empty():
					if not _m2c_is_translation_key(sp):
						printerr("FAIL M2-D: Dialogue tree '%s' node '%s' speaker is not a translation key: %s" % [tree_id, node_id, sp])
						m2d_coverage_fail = true
					elif not dialogue_keyset.has(sp):
						printerr("FAIL M2-D: Dialogue tree '%s' node '%s' speaker key '%s' missing from dialogue.csv." % [tree_id, node_id, sp])
						m2d_coverage_fail = true

			# Check text
			if node.has("text"):
				var txt: String = str(node["text"])
				if not _m2c_is_translation_key(txt):
					printerr("FAIL M2-D: Dialogue tree '%s' node '%s' text is not a translation key: %s" % [tree_id, node_id, txt])
					m2d_coverage_fail = true
				elif not dialogue_keyset.has(txt):
					printerr("FAIL M2-D: Dialogue tree '%s' node '%s' text key '%s' missing from dialogue.csv." % [tree_id, node_id, txt])
					m2d_coverage_fail = true

			# Check choices
			if node.has("choices"):
				var node_choices = node["choices"]
				if node_choices is Array:
					for choice in node_choices:
						if choice is Dictionary and choice.has("label"):
							var lbl: String = str(choice["label"])
							if not _m2c_is_translation_key(lbl):
								printerr("FAIL M2-D: Dialogue tree '%s' node '%s' choice label is not a translation key: %s" % [tree_id, node_id, lbl])
								m2d_coverage_fail = true
							elif not dialogue_keyset.has(lbl):
								printerr("FAIL M2-D: Dialogue tree '%s' node '%s' choice label key '%s' missing from dialogue.csv." % [tree_id, node_id, lbl])
								m2d_coverage_fail = true

	# 2. echoes (EchoDB.ECHOES)
	for echo_id in EchoDB.ECHOES:
		var echo: Dictionary = EchoDB.ECHOES[echo_id]

		# Check title
		var title: String = str(echo.get("title", ""))
		if not _m2c_is_translation_key(title):
			printerr("FAIL M2-D: Echo '%s' title is not a translation key: %s" % [echo_id, title])
			m2d_coverage_fail = true
		elif not data_keyset.has(title):
			printerr("FAIL M2-D: Echo '%s' title key '%s' missing from data.csv." % [echo_id, title])
			m2d_coverage_fail = true

		# Check comment
		if echo.has("comment"):
			var comment: String = str(echo["comment"])
			if not _m2c_is_translation_key(comment):
				printerr("FAIL M2-D: Echo '%s' comment is not a translation key: %s" % [echo_id, comment])
				m2d_coverage_fail = true
			elif not data_keyset.has(comment):
				printerr("FAIL M2-D: Echo '%s' comment key '%s' missing from data.csv." % [echo_id, comment])
				m2d_coverage_fail = true

		# Check segments
		if echo.has("segments"):
			var segments = echo["segments"]
			if segments is Array:
				for seg in segments:
					if seg is Dictionary and seg.has("text"):
						var seg_txt: String = str(seg["text"])
						if not _m2c_is_translation_key(seg_txt):
							printerr("FAIL M2-D: Echo '%s' segment '%s' text is not a translation key: %s" % [echo_id, str(seg.get("id")), seg_txt])
							m2d_coverage_fail = true
						elif not data_keyset.has(seg_txt):
							printerr("FAIL M2-D: Echo '%s' segment '%s' text key '%s' missing from data.csv." % [echo_id, str(seg.get("id")), seg_txt])
							m2d_coverage_fail = true

	# 3. shops (ShopDB.SHOPS)
	for shop_id in shop_db.SHOPS:
		var shop: Dictionary = shop_db.SHOPS[shop_id]
		var shop_name: String = str(shop.get("name", ""))
		if not _m2c_is_translation_key(shop_name):
			printerr("FAIL M2-D: Shop '%s' name is not a translation key: %s" % [shop_id, shop_name])
			m2d_coverage_fail = true
		elif not data_keyset.has(shop_name):
			printerr("FAIL M2-D: Shop '%s' name key '%s' missing from data.csv." % [shop_id, shop_name])
			m2d_coverage_fail = true

	# 4. quests (QuestDB.QUESTS)
	for quest_id in quest_db.QUESTS:
		var quest_data = quest_db.QUESTS[quest_id]

		# WORK_NOTES_BY_STEP
		if "WORK_NOTES_BY_STEP" in quest_data:
			var steps: Dictionary = quest_data.WORK_NOTES_BY_STEP
			for step_id in steps:
				var note: Dictionary = steps[step_id]
				var q_title: String = str(note.get("title", ""))
				var q_body: String = str(note.get("body", ""))

				if not _m2c_is_translation_key(q_title):
					printerr("FAIL M2-D: Quest '%s' step '%s' note title is not a translation key: %s" % [quest_id, step_id, q_title])
					m2d_coverage_fail = true
				elif not data_keyset.has(q_title):
					printerr("FAIL M2-D: Quest '%s' step '%s' note title key '%s' missing from data.csv." % [quest_id, step_id, q_title])
					m2d_coverage_fail = true

				if not _m2c_is_translation_key(q_body):
					printerr("FAIL M2-D: Quest '%s' step '%s' note body is not a translation key: %s" % [quest_id, step_id, q_body])
					m2d_coverage_fail = true
				elif not data_keyset.has(q_body):
					printerr("FAIL M2-D: Quest '%s' step '%s' note body key '%s' missing from data.csv." % [quest_id, step_id, q_body])
					m2d_coverage_fail = true

		# WORK_NOTES_BY_STATUS
		if "WORK_NOTES_BY_STATUS" in quest_data:
			var statuses: Dictionary = quest_data.WORK_NOTES_BY_STATUS
			for status_id in statuses:
				var note: Dictionary = statuses[status_id]
				var q_title: String = str(note.get("title", ""))
				var q_body: String = str(note.get("body", ""))

				if not _m2c_is_translation_key(q_title):
					printerr("FAIL M2-D: Quest '%s' status '%s' note title is not a translation key: %s" % [quest_id, status_id, q_title])
					m2d_coverage_fail = true
				elif not data_keyset.has(q_title):
					printerr("FAIL M2-D: Quest '%s' status '%s' note title key '%s' missing from data.csv." % [quest_id, status_id, q_title])
					m2d_coverage_fail = true

				if not _m2c_is_translation_key(q_body):
					printerr("FAIL M2-D: Quest '%s' status '%s' note body is not a translation key: %s" % [quest_id, status_id, q_body])
					m2d_coverage_fail = true
				elif not data_keyset.has(q_body):
					printerr("FAIL M2-D: Quest '%s' status '%s' note body key '%s' missing from data.csv." % [quest_id, status_id, q_body])
					m2d_coverage_fail = true

		# WORK_NOTES_COMPLETED
		if "WORK_NOTES_COMPLETED" in quest_data:
			var completed: Dictionary = quest_data.WORK_NOTES_COMPLETED
			for comp_id in completed:
				var note: Dictionary = completed[comp_id]
				var q_title: String = str(note.get("title", ""))
				var q_body: String = str(note.get("body", ""))

				if not _m2c_is_translation_key(q_title):
					printerr("FAIL M2-D: Quest '%s' completed variant '%s' note title is not a translation key: %s" % [quest_id, comp_id, q_title])
					m2d_coverage_fail = true
				elif not data_keyset.has(q_title):
					printerr("FAIL M2-D: Quest '%s' completed variant '%s' note title key '%s' missing from data.csv." % [quest_id, comp_id, q_title])
					m2d_coverage_fail = true

				if not _m2c_is_translation_key(q_body):
					printerr("FAIL M2-D: Quest '%s' completed variant '%s' note body is not a translation key: %s" % [quest_id, comp_id, q_body])
					m2d_coverage_fail = true
				elif not data_keyset.has(q_body):
					printerr("FAIL M2-D: Quest '%s' completed variant '%s' note body key '%s' missing from data.csv." % [quest_id, comp_id, q_body])
					m2d_coverage_fail = true

	if m2d_coverage_fail:
		get_tree().quit(1)
		return
	print("PASS M2-D: data-driven coverage (9 dialogue TREES + EchoDB + ShopDB + QuestDB) all keys present in CSV.")

	# (3) 抽樣 tr() 真實命中三語
	var m2d_sample_cases := [
		{"key": "DLG_CEN_FIRST_MEET_TEXT", "zh_TW_substr": "地盤", "zh_CN_substr": "地盘", "en_substr": "turf"},
		{"key": "DLG_LU_QICHEN_EXIT_TEXT", "zh_TW_substr": "記得戴好手套", "zh_CN_substr": "记得戴好手套", "en_substr": "Remember to wear your gloves"},
		{"key": "ECHO_CLERK_TITLE", "zh_TW_substr": "店員的殘響", "zh_CN_substr": "店员的残响", "en_substr": "Clerk's Echo"},
		{"key": "QUEST_REPAIR_VENDOR_BOT_STEP_STARTED_TITLE", "zh_TW_substr": "故障機器人", "zh_CN_substr": "故障机器人", "en_substr": "Glitched Bot"},
	]
	var m2d_sample_pass := true
	for case in m2d_sample_cases:
		for loc in ["zh_TW", "zh_CN", "en"]:
			LocaleManager.set_locale(loc)
			var got_text := tr(case["key"])
			var expect_sub: String = case["%s_substr" % loc]
			if got_text == case["key"]:
				printerr("FAIL M2-D: tr('%s') in %s returned key itself (translation missing)." % [case["key"], loc])
				m2d_sample_pass = false
			elif not expect_sub in got_text:
				printerr("FAIL M2-D: tr('%s') in %s = '%s' missing expected substr '%s'." % [case["key"], loc, got_text, expect_sub])
				m2d_sample_pass = false
	if not m2d_sample_pass:
		get_tree().quit(1)
		return
	print("PASS M2-D: sample tr() across 3 locales for 4 keys (DLG / ECHO / QUEST).")

	# (4) 禁字檢查（跨三語）：全文不得含「林霏」或 English transliterations like "Lin Fei" / "Linfei"
	var forbidden_fail_d := false
	for loc2 in ["zh_TW", "zh_CN", "en"]:
		LocaleManager.set_locale(loc2)

		# Check dialogue.csv keys
		for key_f in dialogue_keyset:
			var txt := tr(key_f)
			if "林霏" in txt:
				printerr("FAIL M2-D: forbidden word '林霏' appears in tr('%s') under locale %s: '%s'" % [key_f, loc2, txt])
				forbidden_fail_d = true
			var lower_txt = txt.to_lower()
			if "lin fei" in lower_txt or "linfei" in lower_txt:
				printerr("FAIL M2-D: forbidden word 'Lin Fei/Linfei' appears in tr('%s') under locale %s: '%s'" % [key_f, loc2, txt])
				forbidden_fail_d = true

		# Check data.csv keys
		for key_f in data_keyset:
			var txt := tr(key_f)
			if "林霏" in txt:
				printerr("FAIL M2-D: forbidden word '林霏' appears in tr('%s') under locale %s: '%s'" % [key_f, loc2, txt])
				forbidden_fail_d = true
			var lower_txt = txt.to_lower()
			if "lin fei" in lower_txt or "linfei" in lower_txt:
				printerr("FAIL M2-D: forbidden word 'Lin Fei/Linfei' appears in tr('%s') under locale %s: '%s'" % [key_f, loc2, txt])
				forbidden_fail_d = true

	if forbidden_fail_d:
		get_tree().quit(1)
		return
	print("PASS M2-D: forbidden words absent from dialogue & data translations across 3 locales.")

	# (5) 英文人名音譯一致性檢查
	var name_translations := [
		{"key": "SPEAKER_WAN", "zh_TW": "晚", "zh_CN": "晚", "en": "Wan"},
		{"key": "SPEAKER_LU_QICHEN", "zh_TW": "鹿其琛", "zh_CN": "鹿其琛", "en": "Lu Qichen"},
		{"key": "SPEAKER_CEN", "zh_TW": "小岑", "zh_CN": "小岑", "en": "Cen"},
		{"key": "SPEAKER_WU", "zh_TW": "伍姐", "zh_CN": "伍姐", "en": "Wu"},
		{"key": "SPEAKER_SEVEN", "zh_TW": "七號", "zh_CN": "七号", "en": "Seven"},
	]
	var names_pass := true
	for entry in name_translations:
		for loc in ["zh_TW", "zh_CN", "en"]:
			LocaleManager.set_locale(loc)
			var got_val := tr(entry["key"])
			var expected_val: String = entry[loc]
			if got_val != expected_val:
				printerr("FAIL M2-D: name transliteration mismatch for '%s' under locale %s. Expected: '%s', Got: '%s'" % [entry["key"], loc, expected_val, got_val])
				names_pass = false
	if not names_pass:
		get_tree().quit(1)
		return
	print("PASS M2-D: name transliterations verified consistently (Wan, Lu Qichen, Cen, Wu, Seven).")

