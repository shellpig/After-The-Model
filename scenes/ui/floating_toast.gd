extends PanelContainer
class_name FloatingToast

@onready var label: Label = $Label

# Static helper — caller does not need an instance reference.
static func show_toast(text: String, anchor_node: Control = null) -> void:
	var toast_scene: PackedScene = load("res://scenes/ui/floating_toast.tscn") as PackedScene
	if toast_scene == null:
		return
	var toast := toast_scene.instantiate() as FloatingToast

	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.current_scene == null:
		return
	# MVP: mount on current_scene/UI; SceneRouter phase will switch to a global UI autoload.
	var ui_layer: Node = tree.current_scene.get_node_or_null("UI")
	if ui_layer != null:
		ui_layer.add_child(toast)
	else:
		tree.current_scene.add_child(toast)

	toast.display(text, anchor_node)

func display(text: String, anchor_node: Control = null) -> void:
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0.94, 0.92, 0.84, 1.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Per spec: semi-transparent black bg, 8px padding
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.7)
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	add_theme_stylebox_override("panel", style)

	reset_size()

	# Position: 8px above anchor panel, horizontally centered to it.
	if anchor_node != null:
		var anchor_pos: Vector2 = anchor_node.global_position
		var anchor_size: Vector2 = anchor_node.size
		global_position = anchor_pos + Vector2((anchor_size.x - size.x) * 0.5, -size.y - 8)
	else:
		var viewport_size: Vector2 = get_viewport_rect().size
		global_position = (viewport_size - size) * 0.5

	# Lifecycle: 1.5 s visible -> 0.5 s fade -> self queue_free
	modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)
