extends "res://tests/manual/phases/phase_m2d.gd"

func _run_phase_m2c() -> void:
	# ===================== Phase M2-C: 敘事資料 i18n =====================
	# 動機：M2-C 把 STORY_NOTES (title/body) / STORY_MESSAGES / ITEMS_DB (name/desc) 改存翻譯 key。
	# 兩道閘：
	#   (1) 品質 lint (a/b/c) — 對 story.csv / items.csv 套用同 M2-B 的三項；
	#   (2) 資料驅動覆蓋（即 spec 的 ii）— 走訪資料字典，每個顯示欄位的 key 都必須在 CSV 有列。
	#       這抓得到「整欄忘了 key 化」、新增 dict 條目漏補 CSV、key 拼錯。
	print("--- Phase M2-C: 敘事資料 i18n ---")

	# zh_CN 禁用的繁體字（沿用 M2-B 同一封鎖集）
	trad_blocklist_c = trad_blocklist

	# (1) 品質 lint — story.csv / items.csv
	for csv_domain in ["story", "items"]:
		var csv_path := "res://locale/%s.csv" % csv_domain
		var recs := _m2b_parse_csv(csv_path)
		if recs.size() < 2:
			printerr("FAIL M2-C: cannot parse %s (records=%d)" % [csv_path, recs.size()])
			get_tree().quit(1)
			return
		var hdr: Array = recs[0]
		if hdr.size() < 4 or hdr[0] != "keys" or hdr[1] != "zh_TW" or hdr[2] != "zh_CN" or hdr[3] != "en":
			printerr("FAIL M2-C: unexpected %s header: %s" % [csv_path, str(hdr)])
			get_tree().quit(1)
			return
		var t_tw := load("res://locale/%s.zh_TW.translation" % csv_domain) as Translation
		var t_cn := load("res://locale/%s.zh_CN.translation" % csv_domain) as Translation
		var t_en := load("res://locale/%s.en.translation" % csv_domain) as Translation
		if t_tw == null or t_cn == null or t_en == null:
			printerr("FAIL M2-C: %s.*.translation artifacts missing (run --import)." % csv_domain)
			get_tree().quit(1)
			return

		var c_fail := false
		var c_checked := 0
		for ri3 in range(1, recs.size()):
			var rr: Array = recs[ri3]
			if rr.size() == 1 and str(rr[0]).strip_edges() == "":
				continue
			if rr.size() < 4:
				printerr("FAIL M2-C: %s row %d has < 4 columns: %s" % [csv_domain, ri3, str(rr)])
				c_fail = true
				continue
			var kk: String = rr[0]
			if kk.strip_edges() == "":
				continue
			c_checked += 1
			# (a) 三語非空
			for ci2 in range(1, 4):
				if str(rr[ci2]).strip_edges() == "":
					printerr("FAIL M2-C: %s key '%s' has empty column %d." % [csv_domain, kk, ci2])
					c_fail = true
			# (b) import 與 CSV 同步
			if t_tw.get_message(kk) != rr[1]:
				printerr("FAIL M2-C: %s key '%s' zh_TW out of sync (reimport?)." % [csv_domain, kk])
				c_fail = true
			if t_cn.get_message(kk) != rr[2]:
				printerr("FAIL M2-C: %s key '%s' zh_CN out of sync (reimport?)." % [csv_domain, kk])
				c_fail = true
			if t_en.get_message(kk) != rr[3]:
				printerr("FAIL M2-C: %s key '%s' en out of sync (reimport?)." % [csv_domain, kk])
				c_fail = true
			# (c) zh_CN 無繁體字洩漏
			for ch in rr[2]:
				if trad_blocklist_c.contains(ch):
					printerr("FAIL M2-C: %s key '%s' zh_CN contains traditional char '%s'." % [csv_domain, kk, ch])
					c_fail = true
					break
		if c_fail:
			get_tree().quit(1)
			return
		print("PASS M2-C: %s.csv lint over %d keys (3-locale non-empty, import in sync, zh_CN no traditional leak)." % [csv_domain, c_checked])

	# (2) 資料驅動覆蓋：走訪資料字典，斷言 CSV 有對應列
	# 顯示欄位契約（M2-C 範圍）：
	#   - STORY_NOTES[*].title / .body  → story.csv
	#   - STORY_MESSAGES[*]              → story.csv（其值就是 MSG_* key）
	#   - ITEMS_DB[*].name / .description → items.csv
	# 邏輯欄位（不准 key 化、不入 CSV）：id / category / status / icon_path / stackable / value / etc.
	var story_keyset := {}
	var story_recs := _m2b_parse_csv("res://locale/story.csv")
	for ri4 in range(1, story_recs.size()):
		var rr4: Array = story_recs[ri4]
		if rr4.size() >= 1 and str(rr4[0]).strip_edges() != "":
			story_keyset[rr4[0]] = true
	var items_keyset := {}
	var items_recs := _m2b_parse_csv("res://locale/items.csv")
	for ri5 in range(1, items_recs.size()):
		var rr5: Array = items_recs[ri5]
		if rr5.size() >= 1 and str(rr5[0]).strip_edges() != "":
			items_keyset[rr5[0]] = true

	var coverage_fail := false

	# STORY_NOTES — title / body
	for note_id in GameState.STORY_NOTES:
		var note: Dictionary = GameState.STORY_NOTES[note_id]
		var title_key: String = str(note.get("title", ""))
		var body_key: String = str(note.get("body", ""))
		if not _m2c_is_translation_key(title_key):
			printerr("FAIL M2-C: STORY_NOTES['%s'].title is not a translation key: %s" % [note_id, title_key])
			coverage_fail = true
		elif not story_keyset.has(title_key):
			printerr("FAIL M2-C: STORY_NOTES['%s'].title key '%s' missing from story.csv." % [note_id, title_key])
			coverage_fail = true
		if not _m2c_is_translation_key(body_key):
			printerr("FAIL M2-C: STORY_NOTES['%s'].body is not a translation key: %s" % [note_id, body_key])
			coverage_fail = true
		elif not story_keyset.has(body_key):
			printerr("FAIL M2-C: STORY_NOTES['%s'].body key '%s' missing from story.csv." % [note_id, body_key])
			coverage_fail = true

	# STORY_MESSAGES — 值即顯示用 key
	for msg_id in GameState.STORY_MESSAGES:
		var msg_key: String = str(GameState.STORY_MESSAGES[msg_id])
		if not _m2c_is_translation_key(msg_key):
			printerr("FAIL M2-C: STORY_MESSAGES['%s'] is not a translation key: %s" % [msg_id, msg_key])
			coverage_fail = true
		elif not story_keyset.has(msg_key):
			printerr("FAIL M2-C: STORY_MESSAGES['%s'] key '%s' missing from story.csv." % [msg_id, msg_key])
			coverage_fail = true

	# ITEMS_DB — name / description
	for item_id in GameState.ITEMS_DB:
		var item_meta: Dictionary = GameState.ITEMS_DB[item_id]
		var name_key: String = str(item_meta.get("name", ""))
		var desc_key: String = str(item_meta.get("description", ""))
		if not _m2c_is_translation_key(name_key):
			printerr("FAIL M2-C: ITEMS_DB['%s'].name is not a translation key: %s" % [item_id, name_key])
			coverage_fail = true
		elif not items_keyset.has(name_key):
			printerr("FAIL M2-C: ITEMS_DB['%s'].name key '%s' missing from items.csv." % [item_id, name_key])
			coverage_fail = true
		if not _m2c_is_translation_key(desc_key):
			printerr("FAIL M2-C: ITEMS_DB['%s'].description is not a translation key: %s" % [item_id, desc_key])
			coverage_fail = true
		elif not items_keyset.has(desc_key):
			printerr("FAIL M2-C: ITEMS_DB['%s'].description key '%s' missing from items.csv." % [item_id, desc_key])
			coverage_fail = true

	if coverage_fail:
		get_tree().quit(1)
		return
	print("PASS M2-C: data-driven coverage (STORY_NOTES title/body + STORY_MESSAGES + ITEMS_DB name/description) all keys present in CSV.")

	# (3) 抽樣 tr() 真實命中三語
	var sample_cases := [
		{"key": "MSG_DOOR_LOCKED", "zh_TW_substr": "門上了鎖", "zh_CN_substr": "门上了锁", "en_substr": "locked"},
		{"key": "ITEM_FINGERLESS_GLOVES_NAME", "zh_TW_substr": "無指", "zh_CN_substr": "无指", "en_substr": "Fingerless"},
		{"key": "NOTE_IDENTITY_GLEANER_TITLE", "zh_TW_substr": "拾遺", "zh_CN_substr": "拾遗", "en_substr": "Gleaner"},
		{"key": "CAT_ECHO", "zh_TW_substr": "殘響", "zh_CN_substr": "残响", "en_substr": "Echoes"},
	]
	var sample_pass := true
	for case in sample_cases:
		for loc in ["zh_TW", "zh_CN", "en"]:
			LocaleManager.set_locale(loc)
			var got_text := tr(case["key"])
			var expect_sub: String = case["%s_substr" % loc]
			if got_text == case["key"]:
				printerr("FAIL M2-C: tr('%s') in %s returned key itself (translation missing)." % [case["key"], loc])
				sample_pass = false
			elif not expect_sub in got_text:
				printerr("FAIL M2-C: tr('%s') in %s = '%s' missing expected substr '%s'." % [case["key"], loc, got_text, expect_sub])
				sample_pass = false
	if not sample_pass:
		get_tree().quit(1)
		return
	print("PASS M2-C: sample tr() across 3 locales for 4 keys (MSG / ITEM / NOTE / CAT).")

	# (4) 禁字檢查（跨三語）：mem_frag_* 等敘事訊息不得含「林霏」
	var forbidden_word := "林霏"
	var forbidden_check_keys := [
		GameState.STORY_MESSAGES.get("mem_frag_commute_topside", ""),
		GameState.STORY_MESSAGES.get("mem_frag_linfei_1", ""),
	]
	# 也掃 STORY_NOTES 全部 title/body 與 ITEMS_DB 全部 name/desc 的三語翻譯
	for note_id_f in GameState.STORY_NOTES:
		var nf: Dictionary = GameState.STORY_NOTES[note_id_f]
		forbidden_check_keys.append(str(nf.get("title", "")))
		forbidden_check_keys.append(str(nf.get("body", "")))
	for item_id_f in GameState.ITEMS_DB:
		var imf: Dictionary = GameState.ITEMS_DB[item_id_f]
		forbidden_check_keys.append(str(imf.get("name", "")))
		forbidden_check_keys.append(str(imf.get("description", "")))

	var forbidden_fail := false
	for loc2 in ["zh_TW", "zh_CN", "en"]:
		LocaleManager.set_locale(loc2)
		for key_f in forbidden_check_keys:
			if key_f.is_empty():
				continue
			var txt := tr(key_f)
			if forbidden_word in txt:
				printerr("FAIL M2-C: forbidden word '%s' appears in tr('%s') under locale %s: '%s'" % [forbidden_word, key_f, loc2, txt])
				forbidden_fail = true
	if forbidden_fail:
		get_tree().quit(1)
		return
	print("PASS M2-C: forbidden word '%s' absent from STORY_NOTES / STORY_MESSAGES / ITEMS_DB across 3 locales." % forbidden_word)

	# 恢復預設 locale
	LocaleManager.set_locale("zh_TW")
	print("--- Phase M2-C: ALL CHECKS PASSED ---")

