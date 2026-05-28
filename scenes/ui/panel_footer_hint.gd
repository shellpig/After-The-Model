extends Label
class_name PanelFooterHint

func set_hints(panel: Control, hints: Array) -> void:
	# Format hints array into a single spacer-joined string
	# e.g., ["E: 裝備/卸下", "R: 查看", "Esc/I: 關閉"] -> "E: 裝備/卸下   R: 查看   Esc/I: 關閉"
	var text_parts := []
	for hint in hints:
		text_parts.append(str(hint))
	
	self.text = "   ".join(text_parts)
