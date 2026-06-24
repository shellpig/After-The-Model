extends Node
# Autoload name: LocaleManager
# Phase M2-A: i18n 基礎建設
# 職責：locale 狀態管理 / 字型 runtime 切換 / settings.cfg 持久化 / OS locale 首啟偵測
# 與 SaveSystem 完全隔離，不入存檔槽。

signal locale_changed(locale: String)

const SUPPORTED   := ["zh_TW", "zh_CN", "en"]
const DEFAULT_LOCALE := "zh_TW"          # 同時為 TranslationServer fallback
const SETTINGS_PATH  := "user://settings.cfg"
const SETTINGS_SECTION := "i18n"
const SETTINGS_KEY     := "locale"

# en 共用 TC 字型（TC 涵蓋 Latin 字形，不另帶第三個字型）
const FONT_FOR := {
	"zh_TW": "res://assets/font/Noto_Sans_TC/static/NotoSansTC-Regular.ttf",
	"zh_CN": "res://assets/font/Noto_Sans_SC/static/NotoSansSC-Regular.ttf",
	"en":    "res://assets/font/Noto_Sans_TC/static/NotoSansTC-Regular.ttf",
}

var current_locale: String = DEFAULT_LOCALE
var _current_font: FontFile = null  # 追蹤目前載入的字型，方便切換時釋放

func _ready() -> void:
	# fallback locale 已於 project.godot [internationalization] locale/fallback="zh_TW" 設定
	# Godot 4.6.3 的 TranslationServer 不提供 set_fallback_locale() runtime API
	var saved := _load_saved_locale()
	var initial := saved if saved != "" else detect_default_locale()
	set_locale(initial)

# ─────────────────────────────────────────────
# 公開 API
# ─────────────────────────────────────────────

func set_locale(locale: String) -> void:
	if not SUPPORTED.has(locale):
		locale = DEFAULT_LOCALE
	current_locale = locale
	TranslationServer.set_locale(locale)
	_apply_font(locale)
	_save_locale(locale)
	locale_changed.emit(locale)

func get_locale() -> String:
	return current_locale

func detect_default_locale() -> String:
	# 依 OS.get_locale() 映射到支援語言
	# 例：zh_TW / zh_HK / zh_Hant → zh_TW
	#     zh_CN / zh_Hans_CN / zh_SG → zh_CN
	#     en_US / 其餘 → en
	var sys := OS.get_locale()
	if sys.begins_with("zh"):
		if "Hans" in sys or sys.ends_with("_CN") or sys.ends_with("_SG"):
			return "zh_CN"
		return "zh_TW"   # zh_TW / zh_HK / zh_Hant 等歸繁中
	return "en"

# ─────────────────────────────────────────────
# 內部：字型切換
# ─────────────────────────────────────────────

func _apply_font(locale: String) -> void:
	var path: String = FONT_FOR.get(locale, FONT_FOR[DEFAULT_LOCALE])

	# en 與 zh_TW 共用 TC 字型，路徑相同時不重載
	if _current_font != null:
		var current_path: String = FONT_FOR.get(
			_get_locale_of_current_font(), "")
		if current_path == path:
			return  # 字型未變，跳過重載

	var f := load(path) as FontFile
	if f == null:
		push_warning("LocaleManager: 無法載入字型 %s，沿用現有字型。" % path)
		return

	# 設為全域 theme fallback font
	ThemeDB.fallback_font = f

	# 釋放前一個字型參照（讓 GC 可回收記憶體）
	_current_font = f

func _get_locale_of_current_font() -> String:
	# 反查目前字型對應的 locale（用於判斷是否需重載）
	if _current_font == null:
		return ""
	var current_path := _current_font.resource_path
	for loc in FONT_FOR:
		if FONT_FOR[loc] == current_path:
			return loc
	return ""

# ─────────────────────────────────────────────
# 內部：settings.cfg 讀寫
# ─────────────────────────────────────────────

func _load_saved_locale() -> String:
	var cfg := ConfigFile.new()
	var err := cfg.load(SETTINGS_PATH)
	if err != OK:
		return ""   # 無檔或讀取失敗 → 交由 OS locale 偵測
	var saved = cfg.get_value(SETTINGS_SECTION, SETTINGS_KEY, "")
	if saved is String and SUPPORTED.has(saved):
		return saved
	return ""

func _save_locale(locale: String) -> void:
	var cfg := ConfigFile.new()
	# 先嘗試讀取既有設定（保留其他 section），再寫入
	cfg.load(SETTINGS_PATH)
	cfg.set_value(SETTINGS_SECTION, SETTINGS_KEY, locale)
	var err := cfg.save(SETTINGS_PATH)
	if err != OK:
		push_warning("LocaleManager: 無法寫入 settings.cfg（err=%d）" % err)
