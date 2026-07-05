extends "res://tests/manual/phases/phase_20.gd"

func _run_phase_m2e() -> void:
	# ===================== Phase M2-E: 收尾與全域 i18n 驗證 =====================
	print("--- Phase M2-E: 收尾與全域 i18n 驗證 ---")

	var all_domains := ["ui", "story", "items", "dialogue", "data"]
	var global_keyset := {}
	var duplicate_keys := []
	var placeholder_mismatches := []
	var forbidden_mismatches := []

	for csv_domain in all_domains:
		var csv_path := "res://locale/%s.csv" % csv_domain
		var recs := _m2b_parse_csv(csv_path)
		if recs.size() < 2:
			printerr("FAIL M2-E: cannot parse %s (records=%d)" % [csv_path, recs.size()])
			get_tree().quit(1)
			return

		for ri in range(1, recs.size()):
			var rr: Array = recs[ri]
			if rr.size() == 1 and str(rr[0]).strip_edges() == "":
				continue
			if rr.size() < 4:
				continue
			var kk: String = rr[0]
			if kk.strip_edges() == "":
				continue

			# 1. 斷言跨 CSV 無重複 key (key 唯一)
			if global_keyset.has(kk):
				printerr("FAIL M2-E: duplicate key '%s' found in '%s' (previously in '%s')" % [kk, csv_domain, global_keyset[kk]])
				duplicate_keys.append(kk)
			else:
				global_keyset[kk] = csv_domain

			# 2. 佔位一致：比對 %s / %d 等型別的多重集（排序後簽章），允許跨語言換序但禁型別錯置
			var tw_sig := _m2e_placeholder_signature(str(rr[1]))
			var cn_sig := _m2e_placeholder_signature(str(rr[2]))
			var en_sig := _m2e_placeholder_signature(str(rr[3]))
			if tw_sig != cn_sig or tw_sig != en_sig:
				printerr("FAIL M2-E: placeholder signature mismatch for key '%s' in '%s'. zh_TW='%s', zh_CN='%s', en='%s'" % [kk, csv_domain, tw_sig, cn_sig, en_sig])
				placeholder_mismatches.append(kk)

			# 3. 禁字檢查（跨三語全文掃描無「林霏」或「Lin Fei」/「Linfei」）
			var locale_labels := ["zh_TW", "zh_CN", "en"]
			for idx in range(1, 4):
				var val := str(rr[idx])
				var locale_label: String = locale_labels[idx - 1]
				if "林霏" in val:
					printerr("FAIL M2-E: forbidden word '林霏' found in key '%s' (%s): '%s'" % [kk, locale_label, val])
					forbidden_mismatches.append(kk)
				var val_lower := val.to_lower()
				if "lin fei" in val_lower or "linfei" in val_lower:
					printerr("FAIL M2-E: forbidden word 'Lin Fei/Linfei' found in key '%s' (%s): '%s'" % [kk, locale_label, val])
					forbidden_mismatches.append(kk)

	if not duplicate_keys.is_empty():
		printerr("FAIL M2-E: Duplicate keys exist across CSV files!")
		get_tree().quit(1)
		return

	if not placeholder_mismatches.is_empty():
		printerr("FAIL M2-E: Placeholder count mismatches exist!")
		get_tree().quit(1)
		return

	if not forbidden_mismatches.is_empty():
		printerr("FAIL M2-E: Forbidden words detected in translations!")
		get_tree().quit(1)
		return

	print("PASS M2-E: CSV key uniqueness, placeholder consistency, and forbidden word scans passed successfully.")

	# 恢復預設 locale
	LocaleManager.set_locale("zh_TW")
	print("--- Phase M2-E: ALL CHECKS PASSED ---")

