extends Control
# Phase M2-A: 語言設定頁
# 最小設定頁 — 語言三選一 + 返回
# 入口：title_screen 的「設定」按鈕 / pause_menu 的「設定」項
# 鍵盤（W/S 移焦、E 確認）+ 觸控可操作（沿用既有面板觸控路由）

signal back_pressed

@onready var title_label: Label         = $Panel/VBoxContainer/TitleLabel
@onready var options_vbox: VBoxContainer = $Panel/VBoxContainer/OptionsVBox
@onready var btn_zh_tw: Button           = $Panel/VBoxContainer/OptionsVBox/BtnZhTW
@onready var btn_zh_cn: Button           = $Panel/VBoxContainer/OptionsVBox/BtnZhCN
@onready var btn_en: Button              = $Panel/VBoxContainer/OptionsVBox/BtnEn
@onready var btn_back: Button            = $Panel/VBoxContainer/BtnBack
@onready var footer_hint_label: Label    = $Panel/VBoxContainer/FooterHintLabel

var _buttons: Array = []

func _ready() -> void:
	_buttons = [btn_zh_tw, btn_zh_cn, btn_en, btn_back]

	btn_zh_tw.pressed.connect(_on_lang_pressed.bind("zh_TW"))
	btn_zh_cn.pressed.connect(_on_lang_pressed.bind("zh_CN"))
	btn_en.pressed.connect(_on_lang_pressed.bind("en"))
	btn_back.pressed.connect(_on_back_pressed)

	for btn in _buttons:
		btn.focus_mode = Control.FOCUS_ALL

	_apply_theme_style()

	# 即時跟隨 LocaleManager 重繪標籤文字
	LocaleManager.locale_changed.connect(_refresh_labels)

func open_panel() -> void:
	visible = true
	_refresh_labels()
	_highlight_current_lang()
	btn_zh_tw.grab_focus()

func _refresh_labels() -> void:
	title_label.text       = tr("UI_SETTINGS_TITLE")
	btn_zh_tw.text         = tr("UI_SETTINGS_LANG_ZH_TW")
	btn_zh_cn.text         = tr("UI_SETTINGS_LANG_ZH_CN")
	btn_en.text            = tr("UI_SETTINGS_LANG_EN")
	btn_back.text          = tr("UI_SETTINGS_BACK")
	footer_hint_label.text = tr("UI_SETTINGS_FOOTER_HINT")
	_highlight_current_lang()

func _highlight_current_lang() -> void:
	# 在目前語言按鈕加 ✓ 前綴，方便辨認
	var cur := LocaleManager.get_locale()
	btn_zh_tw.text = ("✓ " if cur == "zh_TW" else "  ") + tr("UI_SETTINGS_LANG_ZH_TW")
	btn_zh_cn.text = ("✓ " if cur == "zh_CN" else "  ") + tr("UI_SETTINGS_LANG_ZH_CN")
	btn_en.text    = ("✓ " if cur == "en"    else "  ") + tr("UI_SETTINGS_LANG_EN")

func _on_lang_pressed(locale: String) -> void:
	LocaleManager.set_locale(locale)
	# _highlight_current_lang 會在 locale_changed signal 後自動呼叫（_refresh_labels）

func _on_back_pressed() -> void:
	visible = false
	back_pressed.emit()

func _input(event: InputEvent) -> void:
	if not visible:
		return

	var vp := get_viewport()
	if not vp:
		return

	if event.is_action_pressed("move_up"):
		var focused := vp.gui_get_focus_owner()
		var idx := _buttons.find(focused)
		if idx > 0:
			_buttons[idx - 1].grab_focus()
			vp.set_input_as_handled()
	elif event.is_action_pressed("move_down"):
		var focused := vp.gui_get_focus_owner()
		var idx := _buttons.find(focused)
		if idx != -1 and idx < _buttons.size() - 1:
			_buttons[idx + 1].grab_focus()
			vp.set_input_as_handled()
	elif event.is_action_pressed("interact_primary"):
		var focused := vp.gui_get_focus_owner()
		if focused in _buttons:
			focused.emit_signal("pressed")
			vp.set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
		vp.set_input_as_handled()

func _apply_theme_style() -> void:
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color        = Color(0.08, 0.10, 0.12, 0.97)
	bg_style.border_color    = Color(0.22, 0.28, 0.29, 0.90)
	bg_style.border_width_left   = 2
	bg_style.border_width_top    = 2
	bg_style.border_width_right  = 2
	bg_style.border_width_bottom = 2
	bg_style.corner_radius_top_left     = 4
	bg_style.corner_radius_top_right    = 4
	bg_style.corner_radius_bottom_left  = 4
	bg_style.corner_radius_bottom_right = 4
	$Panel.add_theme_stylebox_override("panel", bg_style)

	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(0.78, 0.42, 0.20, 1.0))

	footer_hint_label.add_theme_font_size_override("font_size", 14)
	footer_hint_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6, 0.8))

	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color           = Color(0.10, 0.12, 0.14, 0.90)
	btn_normal.border_color       = Color(0.22, 0.28, 0.29, 0.85)
	btn_normal.border_width_left  = 1
	btn_normal.border_width_top   = 1
	btn_normal.border_width_right = 1
	btn_normal.border_width_bottom= 1
	btn_normal.corner_radius_top_left     = 3
	btn_normal.corner_radius_top_right    = 3
	btn_normal.corner_radius_bottom_left  = 3
	btn_normal.corner_radius_bottom_right = 3
	btn_normal.content_margin_left   = 20
	btn_normal.content_margin_top    = 10
	btn_normal.content_margin_right  = 20
	btn_normal.content_margin_bottom = 10

	var btn_hover := btn_normal.duplicate() as StyleBoxFlat
	btn_hover.bg_color     = Color(0.14, 0.17, 0.19, 0.95)
	btn_hover.border_color = Color(0.78, 0.42, 0.20, 1.0)

	var btn_pressed := btn_normal.duplicate() as StyleBoxFlat
	btn_pressed.bg_color     = Color(0.78, 0.42, 0.20, 0.30)
	btn_pressed.border_color = Color(0.78, 0.42, 0.20, 1.0)

	for btn in _buttons:
		btn.add_theme_stylebox_override("normal",  btn_normal)
		btn.add_theme_stylebox_override("hover",   btn_hover)
		btn.add_theme_stylebox_override("focus",   btn_hover)
		btn.add_theme_stylebox_override("pressed", btn_pressed)
		btn.add_theme_color_override("font_color",         Color(0.94, 0.92, 0.84, 0.90))
		btn.add_theme_color_override("font_hover_color",   Color(0.94, 0.92, 0.84, 1.00))
		btn.add_theme_color_override("font_focus_color",   Color(0.94, 0.92, 0.84, 1.00))
		btn.add_theme_color_override("font_pressed_color", Color(0.78, 0.42, 0.20, 1.00))
		btn.add_theme_font_size_override("font_size", 18)
