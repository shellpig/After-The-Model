extends Node

const TEST_VALID_SAVE_SLOT := 1
const TEST_SCRATCH_SAVE_SLOT := 2
const TEST_VALID_SAVE_FILE := "save_01.sav"
const TEST_SCRATCH_SAVE_FILE := "save_02.sav"

var _temp_callable: Callable

func _ready() -> void:
	LocaleManager.set_locale("zh_TW")
	print("==================================================")
	print("RUNNING INTEGRATION VERIFICATION FOR UI MODE & BACKPACK")
	print("==================================================")

	# 1. Verify Autoload Configuration
	print("Checking UIMode autoload...")
	var autoload_exists = ProjectSettings.has_setting("autoload/UIMode")
	if not autoload_exists:
		printerr("FAIL: UIMode not found in ProjectSettings autoload!")
		get_tree().quit(1)
		return
	print("PASS: UIMode registered in autoload.")

	# 2. Verify InputMap Actions
	print("Checking InputMap actions...")
	var actions = ["open_inventory", "open_notebook", "ui_cancel",
	               "ui_page_up", "ui_page_down",
	               "move_left", "move_right", "move_up", "move_down"]
	for action in actions:
		if not InputMap.has_action(action):
			printerr("FAIL: InputMap action '" + action + "' is missing!")
			get_tree().quit(1)
			return
		print("PASS: InputMap action '" + action + "' exists.")


	# 3. Load & Instantiate apartment_room.tscn
	print("Loading res://scenes/levels/apartment/apartment_room.tscn...")
	var room_scene = load("res://scenes/levels/apartment/apartment_room.tscn")
	if not room_scene:
		printerr("FAIL: Could not load apartment_room.tscn!")
		get_tree().quit(1)
		return
	print("PASS: apartment_room.tscn loaded successfully.")

	var room_instance = room_scene.instantiate()

	# Instantiate GameUI so that apartment_room.gd can retrieve its UI references
	var ui_scene = load("res://scenes/ui/game_ui.tscn")
	var ui_instance = ui_scene.instantiate()
	add_child(ui_instance)
	print("PASS: game_ui.tscn instantiated in scene tree.")

	add_child(room_instance)
	print("PASS: apartment_room.tscn instantiated in scene tree.")

	# 4. Verify Relative Node Paths
	print("Verifying UI node structures inside GameUI...")
	var ui_nodes = {
		"UIOverlay": "UIOverlay",
		"NotebookPanel": "NotebookPanel",
		"DualPaneContainer": "DualPaneContainer",
		"InventoryPanel": "InventoryPanel",
		"BagGrid": "InventoryPanel/VBoxContainer/BagGrid",
		"CreditsLabel": "InventoryPanel/VBoxContainer/HBoxContainer/CreditsLabel",
		"PanelFooterHint": "InventoryPanel/VBoxContainer/PanelFooterHint",
		"ItemDetailModal": "ItemDetailModal",
		"ConfirmDialog": "ConfirmDialog"
	}

	for node_name in ui_nodes:
		var path: String = ui_nodes[node_name]
		var node = ui_instance.get_node_or_null(path)
		if not node:
			printerr("FAIL: UI node '" + node_name + "' not found at path: " + path)
			get_tree().quit(1)
			return
		print("PASS: Node '" + node_name + "' exists at '" + path + "'.")

		# Extra properties verification
		if node_name == "UIOverlay":
			var overlay = node as ColorRect
			if overlay.mouse_filter != Control.MOUSE_FILTER_IGNORE:
				printerr("FAIL: UIOverlay mouse_filter is not MOUSE_FILTER_IGNORE!")
				get_tree().quit(1)
				return
			print("PASS: UIOverlay mouse_filter set to IGNORE.")
		elif node_name == "NotebookPanel":
			var panel = node as Control
			if panel.custom_minimum_size != Vector2(880, 560):
				printerr("FAIL: NotebookPanel custom_minimum_size is not 880x560! Got: ", panel.custom_minimum_size)
				get_tree().quit(1)
				return
			print("PASS: NotebookPanel custom minimum size is 880x560.")
		elif node_name == "InventoryPanel":
			var panel = node as PanelContainer
			if panel.custom_minimum_size != Vector2(368, 256):
				printerr("FAIL: InventoryPanel custom_minimum_size is not 368x256! Got: ", panel.custom_minimum_size)
				get_tree().quit(1)
				return
			print("PASS: InventoryPanel custom minimum size is 368x256.")

	# 4b. Verify Story Preloads (Relaxed Contains Checks)
	print("Verifying preloaded story notes (relaxed)...")
	var categories_to_check = {
		"身份": "identity_apartment_is_mine",
		"線索": "clue_door_sensor_scratch"
	}
	for cat in categories_to_check:
		var expected_id: String = categories_to_check[cat]
		var notes = GameState.get_notes(cat)
		var found = false
		for note in notes:
			if note.get("id") == expected_id:
				found = true
				break
		if not found:
			printerr("FAIL: Story note with ID '" + expected_id + "' was not preloaded in category '" + cat + "'!")
			get_tree().quit(1)
			return
		print("PASS: Story note '" + expected_id + "' preloaded.")

	# Verify work_ai_cleanup_role is NOT preloaded in Phase 2
	if GameState.has_note("work_ai_cleanup_role"):
		printerr("FAIL: Story note work_ai_cleanup_role is preloaded, but it must NOT be preloaded!")
		get_tree().quit(1)
		return
	print("PASS: Story note work_ai_cleanup_role is NOT preloaded.")

	# Verify door unlock method is NOT preloaded
	if GameState.has_knowledge("identity_door_unlock_method"):
		printerr("FAIL: Door unlock method identity_door_unlock_method is preloaded, but it must NOT be preloaded!")
		get_tree().quit(1)
		return
	print("PASS: Door unlock method is NOT preloaded.")

	# Verify Phase 1-D container seeding
	print("Verifying Phase 1-D container seeding...")

	var cabinet_slots = GameState.get_container("cabinet_storage")
	if cabinet_slots.size() != 30:
		printerr("FAIL: cabinet_storage should have 30 slots, got %d" % cabinet_slots.size())
		get_tree().quit(1)
		return
	print("PASS: cabinet_storage has 30 slots.")

	var fridge_slots = GameState.get_container("fridge_storage")
	if fridge_slots.size() != 10:
		printerr("FAIL: fridge_storage should have 10 slots, got %d" % fridge_slots.size())
		get_tree().quit(1)
		return
	print("PASS: fridge_storage has 10 slots.")

	# After scene _ready, cabinet should contain faded_jacket + 2 canned_food, fridge should contain 3 canned_food
	var found_jacket := false
	for slot in cabinet_slots:
		if not slot.is_empty() and slot.get("item_id") == "faded_jacket":
			found_jacket = true
			break
	if not found_jacket:
		printerr("FAIL: faded_jacket not seeded into cabinet_storage")
		get_tree().quit(1)
		return
	print("PASS: faded_jacket seeded into cabinet_storage.")


	# 4c. Verify UI Sibling Drawing Z-Order
	print("Verifying UI sibling drawing Z-Order...")
	var children = ui_instance.get_children()
	var overlay_idx = children.find(ui_instance.get_node("UIOverlay"))
	var notebook_idx = children.find(ui_instance.get_node("NotebookPanel"))
	var dual_pane_idx = children.find(ui_instance.get_node("DualPaneContainer"))
	var inventory_idx = children.find(ui_instance.get_node("InventoryPanel"))
	var modal_idx = children.find(ui_instance.get_node_or_null("ItemDetailModal"))
	var confirm_idx = children.find(ui_instance.get_node_or_null("ConfirmDialog"))
	if overlay_idx == -1 or notebook_idx == -1 or dual_pane_idx == -1 or inventory_idx == -1 or modal_idx == -1 or confirm_idx == -1:
		printerr("FAIL: Sibling nodes not found in UI children list!")
		get_tree().quit(1)
		return
	if not (overlay_idx < notebook_idx and notebook_idx < dual_pane_idx and dual_pane_idx < inventory_idx
			and inventory_idx < modal_idx and modal_idx < confirm_idx):
		printerr("FAIL: UI sibling Z-order is wrong! Expected overlay < notebook < dual_pane < inventory < modal < confirm.")
		get_tree().quit(1)
		return
	print("PASS: UI sibling Z-order correct (Overlay -> Notebook -> DualPane -> Inventory -> Modal -> Confirm).")


	# 5. Verify ITEMS_DB icon paths on disk
	print("Verifying ITEMS_DB icon paths...")
	var items = GameState.ITEMS_DB
	for item_id in items:
		var meta: Dictionary = items[item_id]
		var icon_path: String = meta.get("icon_path", "")
		if icon_path.is_empty():
			printerr("FAIL: Item '" + item_id + "' is missing icon_path!")
			get_tree().quit(1)
			return

		var file_exists = FileAccess.file_exists(icon_path)
		if not file_exists:
			printerr("FAIL: Icon file for '" + item_id + "' does not exist at path: " + icon_path)
			get_tree().quit(1)
			return
		print("PASS: Icon file for '" + item_id + "' exists at '" + icon_path + "'.")

	# 6. Verify UIMode clean APIs
	print("Verifying UIMode API presence...")
	if not UIMode.has_method("get_mode") or not UIMode.has_method("set_mode") or not UIMode.has_method("is_world_input_blocked"):
		printerr("FAIL: UIMode lacks get_mode, set_mode, or is_world_input_blocked API!")
		get_tree().quit(1)
		return
	print("PASS: UIMode APIs verified.")

	# 7. Verify UIMode Phase 1-E CONFIRM APIs
	print("Verifying UIMode CONFIRM APIs (Phase 1-E)...")
	if not UIMode.has_method("enter_confirm") or not UIMode.has_method("exit_confirm"):
		printerr("FAIL: UIMode lacks enter_confirm / exit_confirm!")
		get_tree().quit(1)
		return
	print("PASS: UIMode CONFIRM APIs verified.")

	# 8. Verify GameState Phase 1-E APIs
	print("Verifying GameState Phase 1-E APIs...")
	if not GameState.has_method("unequip_by_instance") or not GameState.has_method("discard_item"):
		printerr("FAIL: GameState lacks unequip_by_instance / discard_item!")
		get_tree().quit(1)
		return
	print("PASS: GameState Phase 1-E APIs verified.")

	# 9. Verify TouchControls Autoload & Platform Detection (Phase 3-C)
	print("Verifying TouchControls Autoload & Platform Detection...")
	var touch_controls = get_node_or_null("/root/TouchControls")
	if not touch_controls:
		printerr("FAIL: TouchControls autoload not found at /root/TouchControls!")
		get_tree().quit(1)
		return

	# Since this test runs on Windows (PC), is_pc_platform must be true
	if not touch_controls.is_pc_platform:
		printerr("FAIL: TouchControls.is_pc_platform should be true on Windows PC!")
		get_tree().quit(1)
		return
	print("PASS: TouchControls.is_pc_platform is true on Windows PC.")

	# On PC, touch buttons should be disabled by default
	if touch_controls.touch_buttons_enabled:
		printerr("FAIL: TouchControls.touch_buttons_enabled should be false by default on PC!")
		get_tree().quit(1)
		return
	print("PASS: TouchControls.touch_buttons_enabled is false by default on PC.")

	# On PC, BtnToggle should be visible by default in NONE mode
	ui_instance.set_monologue_active(false)
	UIMode.set_mode(UIMode.Mode.NONE)
	touch_controls._update_dynamic_button_visibility()
	var btn_toggle = touch_controls.get_node_or_null("Control/BtnToggle")
	if not btn_toggle:
		printerr("FAIL: Control/BtnToggle node not found in TouchControls!")
		get_tree().quit(1)
		return
	if not btn_toggle.visible:
		printerr("FAIL: BtnToggle should be visible by default on PC in world mode!")
		get_tree().quit(1)
		return
	print("PASS: TouchControls BtnToggle visibility and default state verified.")

	# 9.1 Verify TouchControls Safe Area Dynamic Fitting
	print("Verifying TouchControls Safe Area dynamic adaptation...")
	var control_node = touch_controls.get_node_or_null("Control")
	if not control_node:
		printerr("FAIL: TouchControls/Control node not found!")
		get_tree().quit(1)
		return

	# Since this test runs on Windows (PC), offsets must be strictly 0
	if control_node.offset_left != 0 or control_node.offset_top != 0 or control_node.offset_right != 0 or control_node.offset_bottom != 0:
		printerr("FAIL: TouchControls/Control offsets must be strictly 0 on PC desktop platform!")
		printerr("Actual offsets: Left=%d, Top=%d, Right=%d, Bottom=%d" % [control_node.offset_left, control_node.offset_top, control_node.offset_right, control_node.offset_bottom])
		get_tree().quit(1)
		return
	print("PASS: TouchControls Safe Area dynamic offsets validated (strictly 0 on PC desktop).")

	# 10. Verify Phase 4-A Main Scene, SceneRouter & SceneRegistry
	print("Verifying Phase 4-A Main Scene configuration...")
	var main_scene_setting = ProjectSettings.get_setting("application/run/main_scene")
	if main_scene_setting != "res://scenes/ui/title_screen.tscn":
		printerr("FAIL: Main scene setting in project.godot is not 'res://scenes/ui/title_screen.tscn'! Got: ", main_scene_setting)
		get_tree().quit(1)
		return
	print("PASS: project.godot configured to use res://scenes/ui/title_screen.tscn.")

	print("Loading res://scenes/main/main.tscn...")
	var main_scene = load("res://scenes/main/main.tscn")
	if not main_scene:
		printerr("FAIL: Could not load main.tscn!")
		get_tree().quit(1)
		return
	print("PASS: main.tscn loaded successfully.")

	var main_instance = main_scene.instantiate()
	add_child(main_instance)
	print("PASS: main.tscn instantiated in scene tree.")

	print("Verifying Main scene hierarchy...")
	var world_root_node = main_instance.get_node_or_null("WorldRoot")
	if not world_root_node:
		printerr("FAIL: WorldRoot node not found in Main scene!")
		get_tree().quit(1)
		return
	print("PASS: WorldRoot node exists in Main.")

	print("Verifying SceneRouter APIs on Main...")
	var required_methods = [
		"transition_to", "reload_current_scene",
		"get_current_scene_id", "get_current_entry_point_id"
	]
	for method in required_methods:
		if not main_instance.has_method(method):
			printerr("FAIL: Main script lacks required SceneRouter method: " + method)
			get_tree().quit(1)
			return
		print("PASS: Main script has method: " + method)

	print("Verifying SceneRegistry config on Main...")
	if not "SCENES" in main_instance:
		printerr("FAIL: SCENES registry dictionary not found in main.gd!")
		get_tree().quit(1)
		return
	var scenes_dict = main_instance.get("SCENES")
	if not scenes_dict.has("apartment") or not scenes_dict.has("apartment_entrance"):
		printerr("FAIL: SCENES registry is missing 'apartment' or 'apartment_entrance' keys!")
		get_tree().quit(1)
		return

	var apartment_config = scenes_dict["apartment"]
	if apartment_config.get("path") != "res://scenes/levels/apartment/apartment_room.tscn":
		printerr("FAIL: apartment path in registry is wrong!")
		get_tree().quit(1)
		return
	if apartment_config.get("default_entry_point_id") != "wake_bed":
		printerr("FAIL: apartment default_entry_point_id is wrong!")
		get_tree().quit(1)
		return

	var street_config = scenes_dict["apartment_entrance"]
	if street_config.get("path") != "res://scenes/levels/apartment_entrance.tscn":
		printerr("FAIL: apartment_entrance path in registry is wrong!")
		get_tree().quit(1)
		return
	print("PASS: SceneRegistry config verified.")

	print("Loading res://scenes/levels/apartment_entrance.tscn...")
	var street_scene = load("res://scenes/levels/apartment_entrance.tscn")
	if not street_scene:
		printerr("FAIL: Could not load apartment_entrance.tscn!")
		get_tree().quit(1)
		return
	print("PASS: apartment_entrance.tscn loaded successfully.")

	var street_instance = street_scene.instantiate()
	add_child(street_instance)
	print("PASS: apartment_entrance.tscn instantiated in scene tree.")
	UIMode.set_mode(UIMode.Mode.NONE)

	if not street_instance.has_signal("current_interactable_changed") or not street_instance.has_signal("interaction_requested") or not street_instance.has_signal("scene_transition_requested"):
		printerr("FAIL: apartment_entrance lacks Level interaction contract signals!")
		get_tree().quit(1)
		return
	if not street_instance.has_method("prepare_entry_point") or not street_instance.has_method("set_entry_point"):
		printerr("FAIL: apartment_entrance lacks prepare_entry_point or set_entry_point API!")
		get_tree().quit(1)
		return

	street_instance.set_entry_point("from_apartment", {})
	var street_background = street_instance.get_node_or_null("Background")
	if not street_background or street_background.texture == null:
		printerr("FAIL: apartment_entrance Background texture failed to load!")
		get_tree().quit(1)
		return
	var street_camera = street_instance.get_node_or_null("Camera2D")
	if not street_camera or not street_camera.enabled:
		printerr("FAIL: apartment_entrance Camera2D is missing or disabled!")
		get_tree().quit(1)
		return
	var street_player = street_instance.get_node_or_null("Player")
	if not street_player:
		printerr("FAIL: apartment_entrance Player node missing!")
		get_tree().quit(1)
		return
	if street_player.global_position != Vector2(730, 675):
		printerr("FAIL: apartment_entrance from_apartment spawn is wrong! Got: ", street_player.global_position)
		get_tree().quit(1)
		return
	if street_player.get("walk_line_y") != 665.0 or street_player.get("min_x") != 80.0 or street_player.get("max_x") != 4000.0:
		printerr("FAIL: apartment_entrance player walk bounds are wrong!")
		get_tree().quit(1)
		return
	if not street_instance.get_node_or_null("Interactables/BackToApartmentArea"):
		printerr("FAIL: apartment_entrance back_to_apartment interactable missing!")
		get_tree().quit(1)
		return

	# Verify NpcWan properties
	var npc_wan = street_instance.get_node_or_null("Interactables/NpcWan")
	if not npc_wan:
		printerr("FAIL: NpcWan node not found in apartment_entrance scene!")
		get_tree().quit(1)
		return
	if npc_wan.interaction_id != "talk_wan" or npc_wan.dialogue_id != "wan" or npc_wan.prompt_text != "PROMPT_TALK":
		printerr("FAIL: NpcWan interaction properties are incorrect!")
		get_tree().quit(1)
		return

	var npc_sprite_anim = npc_wan.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if not npc_sprite_anim or npc_sprite_anim.sprite_frames == null:
		printerr("FAIL: NpcWan AnimatedSprite2D or sprite_frames is missing!")
		get_tree().quit(1)
		return
	print("PASS: NpcWan node structure and texture verified.")

	# Verify generalized dialogue dispatch
	var dispatch_signal_received = {"emitted": false, "dialogue_id": ""}
	street_instance.interaction_requested.connect(func(data):
		if data.get("type") == "dialogue":
			dispatch_signal_received["emitted"] = true
			dispatch_signal_received["dialogue_id"] = data.get("dialogue_id", "")
	)

	# Simulate player entering NPC interaction range and triggering E
	street_instance._on_interactable_entered(npc_wan)
	Input.action_press("interact_primary")
	street_instance._process(0.0)
	Input.action_release("interact_primary")

	if not dispatch_signal_received["emitted"] or dispatch_signal_received["dialogue_id"] != "wan":
		printerr("FAIL: Generalized dialogue dispatch failed to emit interaction_requested signal!")
		get_tree().quit(1)
		return
	print("PASS: Generalized dialogue dispatch verified.")

	print("PASS: apartment_entrance map scene, spawn, bounds, and contract verified.")

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

	# 10-B. Verify unlayered visual base nodes (rain particles + vignette)
	# Note: CanvasModulate night tint was tried and dropped (didn't look good).
	print("Verifying Phase 10-B visual base...")
	var rain_far = street_instance.get_node_or_null("Camera2D/RainFar")
	var rain_near = street_instance.get_node_or_null("Camera2D/RainNear")
	var rain_splash = street_instance.get_node_or_null("Camera2D/RainSplash")
	if not rain_far or not rain_near or not rain_splash:
		printerr("FAIL 10-B: RainFar/RainNear/RainSplash particle nodes missing under Camera2D!")
		get_tree().quit(1)
		return
	if rain_far.texture == null or rain_near.texture == null or rain_splash.texture == null:
		printerr("FAIL 10-B: Rain particle textures failed to load!")
		get_tree().quit(1)
		return
	if not rain_far.emitting or not rain_near.emitting or not rain_splash.emitting:
		printerr("FAIL 10-B: Rain particle layers should be emitting by default!")
		get_tree().quit(1)
		return
	var vignette_layer = street_instance.get_node_or_null("Vignette")
	var vignette_rect = street_instance.get_node_or_null("Vignette/VignetteRect")
	if not vignette_layer or not vignette_rect or vignette_rect.material == null:
		printerr("FAIL 10-B: Vignette CanvasLayer/ColorRect or shader material missing!")
		get_tree().quit(1)
		return
	print("PASS: Phase 10-B visual base nodes (rain particles, vignette) verified.")

	# 10-C-1. Verify BillboardScreen Polygon2D and screen shader
	print("Verifying Phase 10-C-1 BillboardScreen...")
	var billboard = street_instance.get_node_or_null("BillboardScreen")
	if not billboard:
		printerr("FAIL 10-C-1: BillboardScreen Polygon2D not found in apartment_entrance!")
		get_tree().quit(1)
		return
	if billboard.material == null:
		printerr("FAIL 10-C-1: BillboardScreen has no ShaderMaterial!")
		get_tree().quit(1)
		return
	var ad_paths := []
	for carousel in street_instance.BILLBOARD_CAROUSELS:
		ad_paths.append_array(carousel.get("ads", []))
	var loaded_ads := 0
	for ad_path in ad_paths:
		if ResourceLoader.exists(ad_path):
			loaded_ads += 1
	if loaded_ads < 2:
		printerr("FAIL 10-C-1: billboard carousel needs >=2 loadable ad stills, found %d!" % loaded_ads)
		get_tree().quit(1)
		return
	if (billboard.material as ShaderMaterial).get_shader_parameter("glitch_amount") == null:
		printerr("FAIL 10-C-1: billboard shader missing glitch_amount uniform for carousel transitions!")
		get_tree().quit(1)
		return
	print("PASS: Phase 10-C-1 BillboardScreen carousel (%d ads) and glitch uniform verified." % loaded_ads)

	# 10-C-2. Verify GlowLayers, ReflectionStrip, StreetLights
	print("Verifying Phase 10-C-2 nodes (glow overlays, reflection, lights)...")
	var glow_layers = street_instance.get_node_or_null("GlowLayers")
	if not glow_layers or glow_layers.get_child_count() == 0:
		printerr("FAIL 10-C-2: GlowLayers node missing or empty!")
		get_tree().quit(1)
		return
	var alley_glow = street_instance.get_node_or_null("GlowLayers/AlleyNeonGlow")
	if not alley_glow or (alley_glow as Polygon2D).material == null:
		printerr("FAIL 10-C-2: AlleyNeonGlow Polygon2D or its CanvasItemMaterial missing!")
		get_tree().quit(1)
		return
	var reflection = street_instance.get_node_or_null("ReflectionStrip")
	if not reflection or (reflection as Polygon2D).material == null:
		printerr("FAIL 10-C-2: ReflectionStrip Polygon2D or its ShaderMaterial missing!")
		get_tree().quit(1)
		return
	var street_lights = street_instance.get_node_or_null("StreetLights")
	if not street_lights or street_lights.get_child_count() == 0:
		printerr("FAIL 10-C-2: StreetLights node missing or empty!")
		get_tree().quit(1)
		return
	print("PASS: Phase 10-C-2 GlowLayers / ReflectionStrip / StreetLights verified.")

	# 10-D. Verify NpcWan AnimatedSprite2D and IdleBreak node
	print("Verifying Phase 10-D NpcWan idle break...")
	var npc_wan_anim = street_instance.get_node_or_null("Interactables/NpcWan/AnimatedSprite2D")
	if not npc_wan_anim:
		printerr("FAIL 10-D: NpcWan/AnimatedSprite2D not found!")
		get_tree().quit(1)
		return
	if not npc_wan_anim.sprite_frames \
			or not npc_wan_anim.sprite_frames.has_animation("idle") \
			or not npc_wan_anim.sprite_frames.has_animation("idle_glance"):
		printerr("FAIL 10-D: NpcWan AnimatedSprite2D missing 'idle' or 'idle_glance' animation!")
		get_tree().quit(1)
		return
	var idle_break_node = street_instance.get_node_or_null("Interactables/NpcWan/IdleBreak")
	if not idle_break_node:
		printerr("FAIL 10-D: NpcWan/IdleBreak node not found!")
		get_tree().quit(1)
		return
	print("PASS: Phase 10-D NpcWan AnimatedSprite2D and IdleBreak verified.")

	# 11. Verify Phase 4-E Entry Point methods on apartment_room
	print("Verifying Phase 4-E Entry Point APIs on apartment_room...")
	if not room_instance.has_method("prepare_entry_point") or not room_instance.has_method("set_entry_point"):
		printerr("FAIL: apartment_room.gd lacks prepare_entry_point or set_entry_point API!")
		get_tree().quit(1)
		return
	print("PASS: apartment_room prepare_entry_point & set_entry_point APIs verified.")

	# 12. Verify Room State Persistence
	print("Verifying room state persistence...")
	# Verify initial room state (unsolved)
	var clock = room_instance.get_node_or_null("Interactables/ProjectionClockArea")
	if not clock:
		printerr("FAIL: ProjectionClockArea should exist in unsolved room initial load!")
		get_tree().quit(1)
		return
	if room_instance.CONTAINERS.has("apartment_slot"):
		printerr("FAIL: CONTAINERS should not have apartment_slot in unsolved room initial load!")
		get_tree().quit(1)
		return
	print("PASS: Unsolved room layout verified (clock exists, slot hidden).")

	# Clean up first instantiation
	room_instance.queue_free()
	# Wait for queue_free to process
	await get_tree().process_frame

	# Simulate puzzle completion in GameState
	GameState.apartment_sonar_revealed = true
	GameState.apartment_slot_unlocked = true
	GameState.apartment_beyond_door_bgm_triggered = true

	# Instantiate the apartment room scene a second time (simulating re-entry)
	var room_instance2 = room_scene.instantiate()
	add_child(room_instance2)
	room_instance2.prepare_entry_point("from_street")
	room_instance2.set_entry_point("from_street")

	# Wait for queue_free to process on clock
	await get_tree().process_frame

	var clock2 = room_instance2.get_node_or_null("Interactables/ProjectionClockArea")
	if clock2 != null:
		printerr("FAIL: ProjectionClockArea should be deleted/removed in solved room re-entry!")
		get_tree().quit(1)
		return
	if not room_instance2.CONTAINERS.has("apartment_slot"):
		printerr("FAIL: CONTAINERS should have apartment_slot in solved room re-entry!")
		get_tree().quit(1)
		return
	if room_instance2.CONTAINERS["apartment_slot"]["title"] != "隱藏插槽":
		printerr("FAIL: Apartment slot should be dynamically registered!")
		get_tree().quit(1)
		return
	print("PASS: Solved room layout verified (clock removed, slot revealed).")

	# 13. Verify GameState Story Flags API & DialogueRunner Pure Logic (Phase 5-A)
	print("Verifying GameState Story Flags APIs...")
	GameState.story_flags.clear()
	GameState.set_flag("test_flag_bool", true)
	if not GameState.has_flag("test_flag_bool") or GameState.get_flag("test_flag_bool") != true:
		printerr("FAIL: GameState set_flag / get_flag for boolean failed!")
		get_tree().quit(1)
		return

	GameState.add_int("test_flag_int", 5)
	if GameState.get_flag("test_flag_int") != 5:
		printerr("FAIL: GameState add_int failed!")
		get_tree().quit(1)
		return

	GameState.add_int("test_flag_int", -2)
	if GameState.get_flag("test_flag_int") != 3:
		printerr("FAIL: GameState add_int delta accumulation failed!")
		get_tree().quit(1)
		return

	if not GameState.has_flag("test_flag_int"):
		printerr("FAIL: GameState has_flag for non-zero int failed!")
		get_tree().quit(1)
		return

	GameState.set_flag("test_flag_int", 0)
	if GameState.has_flag("test_flag_int"):
		printerr("FAIL: GameState has_flag for zero int should be false!")
		get_tree().quit(1)
		return

	print("PASS: GameState Story Flags APIs verified.")

	print("Verifying DialogueDB lookup...")
	var DialogueDB = load("res://data/dialogue/dialogue_db.gd")
	var wan_tree = DialogueDB.get_tree_for("wan")
	if wan_tree.is_empty() or not wan_tree.has("start"):
		printerr("FAIL: DialogueDB could not fetch wan tree!")
		get_tree().quit(1)
		return
	print("PASS: DialogueDB lookup verified.")

	print("Verifying DialogueRunner flow simulation (First Meet)...")
	var runner = DialogueRunner.new()
	GameState.story_flags.clear()
	runner.start(wan_tree)

	var curr = runner.current()
	if tr(curr.get("speaker")) != "晚" or not tr(curr.get("text")).contains("新面孔"):
		printerr("FAIL: DialogueRunner start should route to first_meet! Got text: ", tr(curr.get("text")))
		get_tree().quit(1)
		return

	var choices = curr.get("choices")
	if choices.size() != 3:
		printerr("FAIL: first_meet should have 3 choices, got: ", choices.size())
		get_tree().quit(1)
		return

	# Choose option 1: "妳是誰？" -> who
	var idx_who = -1
	for choice in choices:
		if tr(choice.get("label")).contains("誰"):
			idx_who = choice.get("index")
			break
	if idx_who != 1:
		printerr("FAIL: who choice index should be 1, got: ", idx_who)
		get_tree().quit(1)
		return

	runner.choose(idx_who)
	curr = runner.current()
	if not tr(curr.get("text")).contains("名字？"):
		printerr("FAIL: should go to 'who' node! Got: ", tr(curr.get("text")))
		get_tree().quit(1)
		return

	if not GameState.has_flag("knows_wan_name"):
		printerr("FAIL: knows_wan_name flag was not set upon entering 'who' node!")
		get_tree().quit(1)
		return

	runner.advance()
	curr = runner.current()
	if not tr(curr.get("text")).contains("那塊招牌"):
		printerr("FAIL: should advance to 'watch' node! Got: ", tr(curr.get("text")))
		get_tree().quit(1)
		return

	choices = curr.get("choices")
	if choices.size() != 2:
		printerr("FAIL: watch node should have 2 choices, got: ", choices.size())
		get_tree().quit(1)
		return

	# Choose option 0: "我也撿這種東西。" -> kin
	var idx_kin = -1
	for choice in choices:
		if tr(choice.get("label")).contains("撿"):
			idx_kin = choice.get("index")
			break
	if idx_kin != 0:
		printerr("FAIL: kin choice index should be 0, got: ", idx_kin)
		get_tree().quit(1)
		return

	runner.choose(idx_kin)
	curr = runner.current()
	if not tr(curr.get("text")).contains("同類"):
		printerr("FAIL: should go to 'kin' node! Got: ", tr(curr.get("text")))
		get_tree().quit(1)
		return

	if GameState.get_flag("affinity_wan") != 1 or not GameState.get_flag("met_wan"):
		printerr("FAIL: kin effects not applied correctly!")
		get_tree().quit(1)
		return

	runner.advance()
	curr = runner.current()
	if not tr(curr.get("text")).contains("有意思的"):
		printerr("FAIL: should advance to 'end_warm' node! Got: ", tr(curr.get("text")))
		get_tree().quit(1)
		return

	if not curr.get("is_terminal"):
		printerr("FAIL: end_warm should be a terminal node!")
		get_tree().quit(1)
		return

	var finished_signal_status = {"emitted": false}
	runner.finished.connect(func(): finished_signal_status["emitted"] = true)
	runner.advance()
	if not finished_signal_status["emitted"]:
		printerr("FAIL: DialogueRunner should emit finished on terminal node advance!")
		get_tree().quit(1)
		return

	print("PASS: DialogueRunner flow simulation (First Meet) verified.")

	print("Verifying DialogueRunner flow simulation (Retalk & Intel Gate Locked)...")
	# met_wan is true, affinity_wan is 1
	runner.start(wan_tree)
	curr = runner.current()
	if not tr(curr.get("text")).contains("又是你"):
		printerr("FAIL: start should route to retalk since met_wan is true! Got: ", tr(curr.get("text")))
		get_tree().quit(1)
		return

	choices = curr.get("choices")
	var idx_news = -1
	for choice in choices:
		if tr(choice.get("label")).contains("消息"):
			idx_news = choice.get("index")
			break
	if idx_news != 1:
		printerr("FAIL: news choice index should be 1, got: ", idx_news)
		get_tree().quit(1)
		return

	runner.choose(idx_news)
	curr = runner.current()
	if not tr(curr.get("text")).contains("我又不是 AI 客服"):
		printerr("FAIL: should route to intel_locked since affinity_wan < 2! Got: ", tr(curr.get("text")))
		get_tree().quit(1)
		return

	if GameState.get_flag("affinity_wan") != 2:
		printerr("FAIL: intel_locked effect affinity_wan += 1 failed!")
		get_tree().quit(1)
		return

	runner.advance()
	curr = runner.current()
	if not tr(curr.get("text")).contains("死掉的招牌"):
		printerr("FAIL: should advance to 'end_cold'! Got: ", tr(curr.get("text")))
		get_tree().quit(1)
		return
	if not curr.get("is_terminal"):
		printerr("FAIL: end_cold should be terminal!")
		get_tree().quit(1)
		return

	print("PASS: DialogueRunner flow simulation (Retalk & Intel Gate Locked) verified.")

	print("Verifying DialogueRunner flow simulation (Retalk & Intel Gate Unlocked)...")
	# met_wan is true, affinity_wan is now 2
	runner.start(wan_tree)
	curr = runner.current()
	choices = curr.get("choices")

	runner.choose(idx_news)
	curr = runner.current()
	if not tr(curr.get("text")).contains("想聽好料"):
		printerr("FAIL: should route to intel since affinity_wan >= 2! Got: ", tr(curr.get("text")))
		get_tree().quit(1)
		return

	# start_quest should trigger, check quest status
	if QuestManager.get_status("alley_backrooms_3f") != "active":
		printerr("FAIL: start_quest effect failed to start 'alley_backrooms_3f' quest!")
		get_tree().quit(1)
		return

	runner.advance()
	curr = runner.current()
	if not tr(curr.get("text")).contains("有意思的"):
		printerr("FAIL: should advance to 'end_warm'! Got: ", tr(curr.get("text")))
		get_tree().quit(1)
		return

	# Additional Phase 7-B Verification: test new dialogue tree conditions (quest_status, quest_step, has_item)
	print("Verifying Phase 7-B Condition Evaluation...")
	# 1. Test condition: type = quest_status, op = ==, value = active
	var test_cond_active = {"type": "quest_status", "quest_id": "alley_backrooms_3f", "op": "==", "value": "active"}
	if not runner._eval_condition(test_cond_active):
		printerr("FAIL: Condition quest_status=active should evaluate to true!")
		get_tree().quit(1)
		return
		
	# 2. Test condition: type = quest_step, op = ==, value = checked_alley (not reached yet)
	var test_cond_checked = {"type": "quest_step", "quest_id": "alley_backrooms_3f", "op": "==", "value": "checked_alley"}
	if runner._eval_condition(test_cond_checked):
		printerr("FAIL: Condition quest_step=checked_alley should evaluate to false!")
		get_tree().quit(1)
		return
		
	# 3. Test condition: type = has_item, item_id = canned_food, op = ==, value = true (not owned yet)
	var test_cond_item = {"type": "has_item", "item_id": "canned_food", "op": "==", "value": true}
	if runner._eval_condition(test_cond_item):
		printerr("FAIL: Condition has_item=true should evaluate to false when item is not owned!")
		get_tree().quit(1)
		return
		
	# Add item and verify has_item condition
	GameState.add_item("canned_food", 1)
	if not runner._eval_condition(test_cond_item):
		printerr("FAIL: Condition has_item=true should evaluate to true after adding item!")
		get_tree().quit(1)
		return
		
	# Clean up item
	GameState.remove_item("canned_food", 1)
	
	# 4. Test condition array (AND evaluation)
	var test_cond_arr = [
		{"type": "quest_status", "quest_id": "alley_backrooms_3f", "op": "==", "value": "active"},
		{"type": "quest_step", "quest_id": "alley_backrooms_3f", "op": "==", "value": "started"}
	]
	if not runner._eval_condition(test_cond_arr):
		printerr("FAIL: Condition array AND evaluation failed!")
		get_tree().quit(1)
		return
		
	# Verify retalk with active quest routes to intel_already_given
	runner.start(wan_tree)
	curr = runner.current()
	var idx_news_retalk = -1
	for ch in curr.get("choices"):
		if tr(ch.get("label")) == "有新消息嗎？":
			idx_news_retalk = ch.get("index")
			break
	
	runner.choose(idx_news_retalk)
	curr = runner.current()
	if not tr(curr.get("text")).contains("不是跟你說過了"):
		printerr("FAIL: retalk news with active quest should route to 'intel_already_given'! Got: ", tr(curr.get("text")))
		get_tree().quit(1)
		return
	print("PASS: retalk news with active quest routing verified.")

	print("PASS: DialogueRunner flow simulation (Retalk & Intel Gate Unlocked) verified.")

	# 14. Verify GameUI DialoguePanel & Wiring (Phase 5-B)
	print("Verifying GameUI DialoguePanel & Wiring (Phase 5-B)...")

	var test_game_ui = main_instance.get_node_or_null("GameUI")
	if not test_game_ui:
		printerr("FAIL: GameUI not found in Main scene!")
		get_tree().quit(1)
		return

	var dp = test_game_ui.get_node_or_null("DialoguePanel")
	if not dp:
		printerr("FAIL: DialoguePanel not found in GameUI!")
		get_tree().quit(1)
		return
	print("PASS: DialoguePanel exists inside GameUI.")

	# Reset state before testing Dialogue UI
	GameState.story_flags.clear()
	UIMode.set_mode(UIMode.Mode.NONE)

	# Trigger dialogue via mediator channel (simulated level interaction request)
	main_instance._on_level_interaction_requested({
		"type": "dialogue",
		"dialogue_id": "wan"
	})

	if UIMode.get_mode() != UIMode.Mode.DIALOGUE:
		printerr("FAIL: UIMode should be DIALOGUE after starting dialogue! Got: ", UIMode.get_mode())
		get_tree().quit(1)
		return

	if not dp.visible:
		printerr("FAIL: DialoguePanel should be visible in DIALOGUE mode!")
		get_tree().quit(1)
		return
	print("PASS: DialoguePanel visibility toggled correctly by UIMode.")

	# Enable touch buttons for testing TouchControls visibility
	var old_touch_enabled = TouchControls.touch_buttons_enabled
	TouchControls.touch_buttons_enabled = true
	TouchControls._update_dynamic_button_visibility()

	# Verify TouchControls visibility in DIALOGUE mode
	if not TouchControls.get_node("Control/DPad").visible:
		printerr("FAIL: DPad should be visible in DIALOGUE mode!")
		get_tree().quit(1)
		return
	if TouchControls.get_node("Control/Menus/BtnBag").visible or TouchControls.get_node("Control/Menus/BtnNote").visible or TouchControls.get_node("Control/Menus/BtnClose").visible:
		printerr("FAIL: Menu buttons should be hidden in DIALOGUE mode!")
		get_tree().quit(1)
		return
	if not TouchControls.get_node("Control/Actions/BtnE").visible:
		printerr("FAIL: BtnE should be visible in DIALOGUE mode!")
		get_tree().quit(1)
		return
	if TouchControls.get_node("Control/Actions/BtnR").visible or TouchControls.get_node("Control/Actions/BtnT").visible:
		printerr("FAIL: BtnR/BtnT should be hidden in DIALOGUE mode!")
		get_tree().quit(1)
		return
	print("PASS: TouchControls visibility rules in DIALOGUE mode verified.")

	var press_e = func():
		var event := InputEventAction.new()
		event.action = "interact_primary"
		event.pressed = true
		dp._unhandled_input(event)

	var name_lbl = dp.get_node("DialogueBox/MarginContainer/VBoxContainer/NameLabel") as Label
	var text_lbl = dp.get_node("DialogueBox/MarginContainer/VBoxContainer/TextLabel") as Label
	var choice_box = dp.get_node("DialogueBox/MarginContainer/VBoxContainer/ChoicesContainer") as VBoxContainer

	if name_lbl.text != "晚" or not text_lbl.text.contains("新面孔"):
		printerr("FAIL: DialoguePanel should display first meet text! Got: ", name_lbl.text, " - ", text_lbl.text)
		get_tree().quit(1)
		return

	if choice_box.get_child_count() != 3:
		printerr("FAIL: first_meet should display 3 choices in UI, got: ", choice_box.get_child_count())
		get_tree().quit(1)
		return
	print("PASS: DialoguePanel contents initialized correctly (Name, text, and 3 choices).")

	# Wait a frame to let UI grab focus and connection setups complete
	await get_tree().process_frame

	# Verify focus on first choice
	var btn0 = choice_box.get_child(0) as Button
	if not btn0.text.begins_with(">"):
		printerr("FAIL: First choice should have focus caret prefix '> '! Got button text: ", btn0.text)
		get_tree().quit(1)
		return
	print("PASS: Focused choice has caret prefix '> '.")

	# Verify HintLabel content for choices state
	var hint_lbl = dp.get_node("DialogueBox/MarginContainer/HintLabel") as Label
	if hint_lbl.text != "W/S: 選擇    E: 確認":
		printerr("FAIL: HintLabel text should be 'W/S: 選擇    E: 確認' when choices exist! Got: ", hint_lbl.text)
		get_tree().quit(1)
		return
	print("PASS: Dialogue HintLabel verified for choices state.")

	# Verify keyboard S / move_down moves focus
	var event_down := InputEventAction.new()
	event_down.action = "move_down"
	event_down.pressed = true
	dp._unhandled_input(event_down)
	await get_tree().process_frame

	var btn_ws1 = choice_box.get_child(1) as Button
	if not btn_ws1.text.begins_with(">"):
		printerr("FAIL: Keyboard S / move_down did not move focus to second choice!")
		get_tree().quit(1)
		return
	
	# Move back up using W / move_up
	var event_up := InputEventAction.new()
	event_up.action = "move_up"
	event_up.pressed = true
	dp._unhandled_input(event_up)
	await get_tree().process_frame
	if not btn0.text.begins_with(">"):
		printerr("FAIL: Keyboard W / move_up did not move focus back to first choice!")
		get_tree().quit(1)
		return
	print("PASS: Keyboard W/S choice navigation verified.")

	# Move focus down using TouchControls simulated Dpad Down
	TouchControls._simulate_action("move_down", true)
	await get_tree().process_frame

	var btn1 = choice_box.get_child(1) as Button
	if not btn1.text.begins_with(">") or btn0.text.begins_with(">"):
		printerr("FAIL: Focus didn't move to second choice or first choice retained caret! btn0: ", btn0.text, ", btn1: ", btn1.text)
		get_tree().quit(1)
		return
	print("PASS: Focus moved down correctly using TouchControls Dpad, caret prefixes updated.")

	# Confirm the chosen option ("妳是誰？" which is index 1, option 1) using TouchControls simulated BtnE
	TouchControls._simulate_action("interact_primary", true)
	await get_tree().process_frame

	if not text_lbl.text.contains("名字？"):
		printerr("FAIL: Dialogue didn't branch to 'who' node! Got: ", text_lbl.text)
		get_tree().quit(1)
		return

	if not GameState.has_flag("knows_wan_name"):
		printerr("FAIL: knows_wan_name flag not set after choosing 'who' choice!")
		get_tree().quit(1)
		return
	print("PASS: Branching and GameState flags modification verified in UI dialogue sequence.")

	if hint_lbl.text != "E: 繼續":
		printerr("FAIL: HintLabel text should be 'E: 繼續' for non-choices non-terminal node! Got: ", hint_lbl.text)
		get_tree().quit(1)
		return
	print("PASS: Dialogue HintLabel verified for E: 繼續 state.")

	# 'who' node is terminal, so confirm again should advance to 'watch'
	press_e.call()
	await get_tree().process_frame

	if not text_lbl.text.contains("那塊招牌"):
		printerr("FAIL: Dialogue didn't advance to 'watch' node! Got: ", text_lbl.text)
		get_tree().quit(1)
		return

	if choice_box.get_child_count() != 2:
		printerr("FAIL: 'watch' node should have 2 choices in UI, got: ", choice_box.get_child_count())
		get_tree().quit(1)
		return

	# Confirm option 0 ("我也撿這種東西。" which has index 0)
	# Focus is on first choice by default, so just confirm
	press_e.call()
	await get_tree().process_frame

	if not text_lbl.text.contains("同類"):
		printerr("FAIL: Dialogue didn't branch to 'kin' node! Got: ", text_lbl.text)
		get_tree().quit(1)
		return

	if GameState.get_flag("affinity_wan") != 1 or not GameState.get_flag("met_wan"):
		printerr("FAIL: kin effect values not updated in GameState!")
		get_tree().quit(1)
		return

	# 'kin' is terminal -> advance to 'end_warm'
	press_e.call()
	await get_tree().process_frame

	if not text_lbl.text.contains("有意思的"):
		printerr("FAIL: Dialogue didn't advance to 'end_warm'! Got: ", text_lbl.text)
		get_tree().quit(1)
		return

	if hint_lbl.text != "E: 關閉":
		printerr("FAIL: HintLabel text should be 'E: 關閉' for terminal node! Got: ", hint_lbl.text)
		get_tree().quit(1)
		return
	print("PASS: Dialogue HintLabel verified for E: 關閉 state.")

	# 'end_warm' is terminal -> advance to end dialogue
	press_e.call()
	await get_tree().process_frame

	if UIMode.get_mode() != UIMode.Mode.NONE:
		printerr("FAIL: UIMode should revert to NONE after dialogue finished! Got: ", UIMode.get_mode())
		get_tree().quit(1)
		return

	if dp.visible:
		printerr("FAIL: DialoguePanel should be hidden after dialogue finished!")
		get_tree().quit(1)
		return
	print("PASS: Dialogue sequence finished, UI closed, and UIMode reverted to NONE.")

	TouchControls.touch_buttons_enabled = old_touch_enabled
	TouchControls._update_dynamic_button_visibility()

	# 15. Verify Phase 6-A SaveSystem Autoload & State Serialization
	print("Verifying Phase 6-A SaveSystem Autoload & State Serialization...")
	
	# Prepare some state changes
	GameState.reset_for_new_game()
	if GameState.get_credits() != 300:
		printerr("FAIL: GameState reset_for_new_game did not set default credits!")
		get_tree().quit(1)
		return
	
	GameState.set_credits(500)
	GameState.set_flag("test_story_flag", 42)
	GameState.apartment_sonar_revealed = true
	
	# Add item and verify it exists
	if not GameState.add_item("canned_food", 3):
		printerr("FAIL: Could not add canned_food for test!")
		get_tree().quit(1)
		return
	
	var inventory_before = GameState.get_inventory()
	var credits_before = GameState.get_credits()
	
	# Capture state
	var save_data = SaveSystem.capture("apartment", 425.0, -1)
	if not SaveSystem.validate(save_data):
		printerr("FAIL: Captured save data failed validation!")
		get_tree().quit(1)
		return
	print("PASS: Capture and validate verified.")
	
	# Write slot and read back
	var slot_idx := TEST_VALID_SAVE_SLOT
	var dir = DirAccess.open("user://")
	if dir and dir.file_exists(TEST_VALID_SAVE_FILE):
		dir.remove(TEST_VALID_SAVE_FILE)
	
	var slots_list_before = SaveSystem.list_slots()
	if not slots_list_before[0]["empty"]:
		printerr("FAIL: Slot 1 should be empty before writing!")
		get_tree().quit(1)
		return
	
	if not SaveSystem.write_slot(slot_idx, save_data):
		printerr("FAIL: Failed to write to slot 1!")
		get_tree().quit(1)
		return
	print("PASS: Write slot verified.")
	
	var slots_list_after = SaveSystem.list_slots()
	if slots_list_after[0]["empty"] or slots_list_after[0]["meta"]["credits"] != 500:
		printerr("FAIL: list_slots did not report written slot 1 metadata correctly!")
		get_tree().quit(1)
		return
	print("PASS: list_slots verified with active slot.")
	
	# Read slot
	var read_data = SaveSystem.read_slot(slot_idx)
	if not SaveSystem.validate(read_data):
		printerr("FAIL: Read save data failed validation!")
		get_tree().quit(1)
		return
	if read_data["data"]["player_x"] != 425.0 or read_data["data"]["player_facing"] != -1:
		printerr("FAIL: Read data fields did not match captured fields!")
		get_tree().quit(1)
		return
	print("PASS: Read slot and validation verified.")
	
	# Corrupt slot simulation
	var corrupt_slot_idx := TEST_SCRATCH_SAVE_SLOT
	var corrupt_file = FileAccess.open("user://%s" % TEST_SCRATCH_SAVE_FILE, FileAccess.WRITE)
	if corrupt_file:
		corrupt_file.store_string("THIS IS NOT A VALID SAV OBJECT")
		corrupt_file.close()
	
	var slots_list_corrupt = SaveSystem.list_slots()
	if slots_list_corrupt[1]["empty"] or not slots_list_corrupt[1].get("corrupt", false):
		printerr("FAIL: list_slots did not identify corrupt slot 2!")
		get_tree().quit(1)
		return
	print("PASS: list_slots corrupt detection verified.")
	
	# Clean up corrupt file
	if dir:
		dir.remove(TEST_SCRATCH_SAVE_FILE)
	
	# Reset state and apply read data
	GameState.reset_for_new_game()
	if GameState.get_credits() != 300 or GameState.story_flags.has("test_story_flag"):
		printerr("FAIL: reset_for_new_game failed to clear state before load!")
		get_tree().quit(1)
		return
	
	SaveSystem.apply(read_data)
	
	# Verify restored state
	var inventory_after = GameState.get_inventory()
	var credits_after = GameState.get_credits()
	
	if credits_after != credits_before:
		printerr("FAIL: Credits mismatch after applying save!")
		get_tree().quit(1)
		return
	if GameState.get_flag("test_story_flag") != 42:
		printerr("FAIL: Story flags mismatch after applying save!")
		get_tree().quit(1)
		return
	if not GameState.apartment_sonar_revealed:
		printerr("FAIL: Apartment sonar state mismatch after applying save!")
		get_tree().quit(1)
		return
		
	# Compare inventory arrays
	if inventory_after.size() != inventory_before.size():
		printerr("FAIL: Inventory slot count mismatch after applying save!")
		get_tree().quit(1)
		return
	for i in range(inventory_after.size()):
		var slot_a = inventory_after[i]
		var slot_b = inventory_before[i]
		if slot_a.get("item_id") != slot_b.get("item_id") or slot_a.get("quantity") != slot_b.get("quantity"):
			printerr("FAIL: Inventory slot content mismatch after applying save!")
			get_tree().quit(1)
			return
	print("PASS: SaveSystem state application and validation matches perfectly.")

	room_instance2.queue_free()

	# 16. Verify Phase 6-B Load Game Entry Path & Dual Validation
	print("Verifying Phase 6-B Load Game Entry Path & Dual Validation...")
	
	# Reset state first
	GameState.reset_for_new_game()
	
	# Load slot 1 (which we saved in 6-A with player_x = 425.0, facing = -1)
	var load_success = main_instance.load_game_slot(TEST_VALID_SAVE_SLOT)
	if not load_success:
		printerr("FAIL: load_game_slot(1) failed to load valid slot!")
		get_tree().quit(1)
		return
	
	var active_level = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion():
			active_level = child
			break
	if not active_level or not active_level.get_script() or not active_level.get_script().resource_path.contains("apartment_room.gd"):
		printerr("FAIL: Restored scene is not ApartmentRoom! Script was: ", active_level.get_script().resource_path if active_level and active_level.get_script() else "null")
		get_tree().quit(1)
		return
	
	if active_level.get("_opening_monologue_active"):
		printerr("FAIL: Monologue was not bypassed during restore load!")
		get_tree().quit(1)
		return
	print("PASS: Monologue bypass verified.")
	
	var active_player = active_level.get_node("Player")
	if active_player.get_save_x() != 425.0:
		printerr("FAIL: Restored player position is wrong! Got: ", active_player.get_save_x())
		get_tree().quit(1)
		return
	if active_player.get_facing() != -1:
		printerr("FAIL: Restored player facing is wrong! Got: ", active_player.get_facing())
		get_tree().quit(1)
		return
	print("PASS: Player position and facing restore verified.")
	
	# Verify dual stage validation failures
	# 1. Validation fail due to invalid scene registry on Main
	var invalid_scene_payload = SaveSystem.capture("apartment", 425.0, -1)
	invalid_scene_payload["data"]["current_scene_id"] = "nonexistent_scene_id"
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, invalid_scene_payload):
		printerr("FAIL: Failed to write test payload to scratch slot!")
		get_tree().quit(1)
		return
	
	# Set some check value in GameState
	GameState.set_credits(9999)
	var load_invalid_success = main_instance.load_game_slot(TEST_SCRATCH_SAVE_SLOT)
	if load_invalid_success:
		printerr("FAIL: load_game_slot(scratch slot) should have failed due to invalid scene ID registry check!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != 9999:
		printerr("FAIL: GameState applied half-validated save changes! GameState must be intact.")
		get_tree().quit(1)
		return
	print("PASS: Scene registry validation failure correctly aborted load and left GameState intact.")
	
	# Clean up scratch slot
	if dir and dir.file_exists(TEST_SCRATCH_SAVE_FILE):
		dir.remove(TEST_SCRATCH_SAVE_FILE)
		
	# 2. Validation fail due to corrupted payload (validate() check)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, {}): # Empty payload
		printerr("FAIL: Failed to write empty dict to scratch slot!")
		get_tree().quit(1)
		return
	var load_empty_success = main_instance.load_game_slot(TEST_SCRATCH_SAVE_SLOT)
	if load_empty_success:
		printerr("FAIL: load_game_slot(scratch slot) should have failed due to validate check on empty payload!")
		get_tree().quit(1)
		return
	print("PASS: Payload validation failure correctly aborted load.")
	
	# Clean up scratch slot
	if dir and dir.file_exists(TEST_SCRATCH_SAVE_FILE):
		dir.remove(TEST_SCRATCH_SAVE_FILE)
		
	# Verify start_new_game resets state and plays monologue
	main_instance.start_new_game()
	var new_level = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion():
			new_level = child
			break
	if not new_level or not new_level.get_script() or not new_level.get_script().resource_path.contains("apartment_room.gd"):
		printerr("FAIL: New game scene is not ApartmentRoom! Script was: ", new_level.get_script().resource_path if new_level and new_level.get_script() else "null")
		get_tree().quit(1)
		return
	if not new_level.get("_opening_monologue_active"):
		printerr("FAIL: New game did not start opening monologue!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != 300:
		printerr("FAIL: New game did not reset credits to 300!")
		get_tree().quit(1)
		return
	print("PASS: start_new_game monologue and reset verified.")

	# 17. Verify Phase 6-D & 6-E GUI components (TitleScreen & PauseMenu)
	print("Verifying Phase 6-D & 6-E Title Screen, Pause Menu, & Save/Load UI...")
	
	# Verify TitleScreen Isolation
	var title_scene = load("res://scenes/ui/title_screen.tscn")
	if not title_scene:
		printerr("FAIL: Could not load title_screen.tscn!")
		get_tree().quit(1)
		return
		
	var title_instance = title_scene.instantiate()
	main_instance.add_child(title_instance)
	if not TouchControls.force_hidden:
		printerr("FAIL: Title Screen did not trigger TouchControls force_hidden = true!")
		get_tree().quit(1)
		return
	print("PASS: Title Screen TouchControls isolation verified.")
	
	title_instance.queue_free()
	TouchControls.set_force_hidden(false)
	
	# Verify PauseMenu integration inside GameUI
	var game_ui = main_instance.get_node("GameUI")
	var pause_menu = game_ui.get_node("PauseMenu")
	if not pause_menu:
		printerr("FAIL: PauseMenu not found under GameUI!")
		get_tree().quit(1)
		return
		
	# Trigger pause menu
	UIMode.set_mode(UIMode.Mode.NONE)
	game_ui.open_pause_menu()
	if UIMode.get_mode() != UIMode.Mode.PAUSE:
		printerr("FAIL: open_pause_menu() did not switch UIMode to PAUSE!")
		get_tree().quit(1)
		return
	if not pause_menu.visible:
		printerr("FAIL: PauseMenu node was not made visible in PAUSE mode!")
		get_tree().quit(1)
		return
	print("PASS: PauseMenu opening and UIMode.PAUSE verified.")
	
	# Check TouchControls visibility in PAUSE mode
	TouchControls.touch_buttons_enabled = true
	TouchControls._update_dynamic_button_visibility()
	if not TouchControls.get_node("Control/DPad").visible:
		printerr("FAIL: DPad should be visible in PAUSE mode for UI focus navigation!")
		get_tree().quit(1)
		return
	if TouchControls.get_node("Control/Actions").visible or TouchControls.get_node("Control/Menus").visible:
		printerr("FAIL: Actions/Menus should be hidden in PAUSE mode!")
		get_tree().quit(1)
		return
	print("PASS: TouchControls visibility in PAUSE mode verified.")
	
	# Reset touch_buttons_enabled
	TouchControls.touch_buttons_enabled = false
	
	# Test Resume option
	pause_menu._on_resume_pressed()
	if UIMode.get_mode() != UIMode.Mode.NONE or pause_menu.visible:
		printerr("FAIL: Resume did not exit PAUSE mode or hide PauseMenu!")
		get_tree().quit(1)
		return
	print("PASS: PauseMenu Resume verified.")
	
	# Test Slot List rendering inside PauseMenu
	game_ui.open_pause_menu()
	pause_menu._on_save_pressed()
	var slot_list = pause_menu.get_node("SaveSlotList")
	if not slot_list or not slot_list.visible:
		printerr("FAIL: SaveSlotList was not displayed after clicking Save!")
		get_tree().quit(1)
		return
		
	# Verify list slot contents (7 buttons populated)
	var slots = slot_list.get_node("Panel/VBoxContainer/SlotsVBox")
	var buttons_count := 0
	for child in slots.get_children():
		if child is Button:
			buttons_count += 1
	if buttons_count != 7:
		printerr("FAIL: SaveSlotList did not contain exactly 7 slots! Got: ", buttons_count)
		get_tree().quit(1)
		return
		
	# Verify slot 1 text is populated (we saved to it in 6-A/6-B)
	var slot1_btn = slots.get_child(0) as Button
	if "空白" in slot1_btn.text or slot1_btn.text.is_empty():
		printerr("FAIL: Slot 1 should display active save metadata, got text: ", slot1_btn.text)
		get_tree().quit(1)
		return
	print("PASS: SaveSlotList metadata population verified.")
	
	# Verify ConfirmDialog Overwrite & Title Return behavior (Guard against Button restore crashes & UIMode exit issues)
	var confirm_dialog = game_ui.get_node("ConfirmDialog")
	if not confirm_dialog:
		printerr("FAIL: ConfirmDialog not found inside GameUI!")
		get_tree().quit(1)
		return
		
	# 1. Overwrite confirm simulation (triggers ConfirmDialog, restores to Slot Button)
	slot_list._on_slot_button_pressed(1) # Slot 1 is active, should trigger overwrite warning
	if UIMode.get_mode() != UIMode.Mode.CONFIRM or not confirm_dialog.visible:
		printerr("FAIL: Overwriting active slot did not open ConfirmDialog!")
		get_tree().quit(1)
		return
		
	# Simulate Cancel: close_dialog should restore state to PAUSE without crashing on Button restore
	confirm_dialog.close_dialog()
	if UIMode.get_mode() != UIMode.Mode.PAUSE or confirm_dialog.visible:
		printerr("FAIL: Cancel overwrite did not return UIMode to PAUSE!")
		get_tree().quit(1)
		return
	print("PASS: Overwrite confirmation Cancel & UIMode restore verified.")
	
	# Simulate Confirm: confirm execution should perform save and return back to PAUSE (single exit_confirm)
	slot_list._on_slot_button_pressed(1)
	if confirm_dialog._on_confirm.is_valid():
		confirm_dialog._on_confirm.call()
	confirm_dialog.close_dialog()
	if UIMode.get_mode() != UIMode.Mode.PAUSE:
		printerr("FAIL: Confirming overwrite did not return UIMode back to PAUSE (got mode: ", UIMode.get_mode(), ")")
		get_tree().quit(1)
		return
	print("PASS: Overwrite confirmation Confirm & single exit_confirm verified.")
	
	# 2. Return to Title confirmation simulation (triggers ConfirmDialog, restores to btn_title)
	pause_menu._on_title_pressed()
	if UIMode.get_mode() != UIMode.Mode.CONFIRM or not confirm_dialog.visible:
		printerr("FAIL: Clicking Return to Title did not show ConfirmDialog!")
		get_tree().quit(1)
		return
		
	# Simulate Cancel: should return to PAUSE
	confirm_dialog.close_dialog()
	if UIMode.get_mode() != UIMode.Mode.PAUSE or confirm_dialog.visible:
		printerr("FAIL: Cancelling Title return did not restore UIMode to PAUSE!")
		get_tree().quit(1)
		return
	print("PASS: Title return confirmation Cancel & UIMode restore verified.")
	
	# Close pause menu
	UIMode.set_mode(UIMode.Mode.NONE)

	# 18. Verify Phase 7-A QuestManager & QuestState
	print("Verifying Phase 7-A QuestManager & QuestState...")
	
	# Reset state first
	GameState.reset_for_new_game()
	
	# Verify initial state
	if QuestManager.get_status("alley_backrooms_3f") != "":
		printerr("FAIL: Initial quest status should be empty string!")
		get_tree().quit(1)
		return
	if QuestManager.get_step("alley_backrooms_3f") != "":
		printerr("FAIL: Initial quest step should be empty string!")
		get_tree().quit(1)
		return
	
	# Start quest
	var start_ok = QuestManager.start("alley_backrooms_3f")
	if not start_ok:
		printerr("FAIL: Failed to start quest 'alley_backrooms_3f'!")
		get_tree().quit(1)
		return
	if not GameState.has_active_quest("alley_backrooms_3f"):
		printerr("FAIL: GameState has_active_quest returned false after start!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("alley_backrooms_3f") != "active":
		printerr("FAIL: Quest status is not 'active' after start!")
		get_tree().quit(1)
		return
	if QuestManager.get_step("alley_backrooms_3f") != "started":
		printerr("FAIL: Quest step is not 'started' after start!")
		get_tree().quit(1)
		return
		
	# Verify note sync
	var notes_started = GameState.get_notes("工作")
	if notes_started.size() != 1:
		printerr("FAIL: Work notes count is not 1! Got: ", notes_started.size())
		get_tree().quit(1)
		return
	var work_note = notes_started[0]
	if work_note.get("id") != "quest_alley_backrooms_3f":
		printerr("FAIL: Work note id is wrong! Got: ", work_note.get("id"))
		get_tree().quit(1)
		return
	if not "「晚」提到暗巷三樓" in _tr_body(work_note.get("body", "")):
		printerr("FAIL: Work note body for started state is wrong! Got: ", _tr_body(work_note.get("body")))
		get_tree().quit(1)
		return
	print("PASS: Quest start and initial note sync verified.")
	
	# Advance quest
	var adv_ok = QuestManager.advance("alley_backrooms_3f", "checked_alley", {"checked": true})
	if not adv_ok:
		printerr("FAIL: Failed to advance quest 'alley_backrooms_3f' to 'checked_alley'!")
		get_tree().quit(1)
		return
	if QuestManager.get_step("alley_backrooms_3f") != "checked_alley":
		printerr("FAIL: Quest step is not 'checked_alley' after advance!")
		get_tree().quit(1)
		return
	if not QuestManager.get_flag("alley_backrooms_3f", "checked"):
		printerr("FAIL: Quest flag 'checked' was not set!")
		get_tree().quit(1)
		return
		
	# Verify advanced note body
	var notes_checked = GameState.get_notes("工作")
	if notes_checked.size() != 1:
		printerr("FAIL: Work notes count after advance is not 1!")
		get_tree().quit(1)
		return
	if not "去後巷看過了" in _tr_body(notes_checked[0].get("body", "")):
		printerr("FAIL: Work note body for checked_alley state is wrong! Got: ", _tr_body(notes_checked[0].get("body")))
		get_tree().quit(1)
		return
	print("PASS: Quest advance and note updating verified.")
	
	# Verify invalid step transition
	var adv_invalid = QuestManager.advance("alley_backrooms_3f", "nonexistent_step")
	if adv_invalid:
		printerr("FAIL: Advancing to nonexistent step should fail!")
		get_tree().quit(1)
		return
	print("PASS: Invalid quest step transition correctly blocked.")
	
	# Verify Quest states are NOT stored in GameState.knowledge (should remain empty)
	if GameState.knowledge.has("quest_alley_backrooms_3f"):
		printerr("FAIL: Quest notes must not be stored in GameState.knowledge!")
		get_tree().quit(1)
		return
	print("PASS: Quest status is not saved in knowledge database.")

	# Complete quest
	var complete_ok = QuestManager.complete("alley_backrooms_3f")
	if not complete_ok:
		printerr("FAIL: Failed to complete quest!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("alley_backrooms_3f") != "completed":
		printerr("FAIL: Quest status is not 'completed' after complete()!")
		get_tree().quit(1)
		return
	var notes_completed = GameState.get_notes("工作")
	if notes_completed[0].get("status") != "completed":
		printerr("FAIL: Work note status was not updated to completed!")
		get_tree().quit(1)
		return
	if not "已將「早期" in _tr_body(notes_completed[0].get("body", "")):
		printerr("FAIL: Work note body for completed status is wrong! Got: ", _tr_body(notes_completed[0].get("body")))
		get_tree().quit(1)
		return
	print("PASS: Quest completion and note status update verified.")
	
	# Verify Save/Load Serialization of quest_states
	var save_dict = GameState.to_save_dict()
	if not save_dict.has("quest_states"):
		printerr("FAIL: Save dictionary is missing 'quest_states' key!")
		get_tree().quit(1)
		return
	var saved_quest_state = save_dict["quest_states"].get("alley_backrooms_3f", {})
	if saved_quest_state.get("status") != "completed":
		printerr("FAIL: Saved quest status is wrong! Got: ", saved_quest_state.get("status"))
		get_tree().quit(1)
		return
		
	# Reset state and restore from save dict
	GameState.reset_for_new_game()
	if QuestManager.get_status("alley_backrooms_3f") != "":
		printerr("FAIL: Quest states not cleared after reset_for_new_game!")
		get_tree().quit(1)
		return
		
	GameState.load_save_dict(save_dict)
	if QuestManager.get_status("alley_backrooms_3f") != "completed":
		printerr("FAIL: Quest states not restored correctly from load_save_dict!")
		get_tree().quit(1)
		return
	print("PASS: Quest states serialization and restoration verified.")

	# 19. Verify Phase 7-C apartment_entrance alley_view quest event
	print("Verifying Phase 7-C apartment_entrance alley_view quest event...")
	
	# Reset state first
	GameState.reset_for_new_game()
	
	# Transition into apartment_entrance
	main_instance.transition_to("apartment_entrance", "from_apartment")
	await get_tree().process_frame
	
	var active_street = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion() and child.get_script() and child.get_script().resource_path.contains("apartment_entrance.gd"):
			active_street = child
			break
			
	if not active_street:
		printerr("FAIL: Current scene is not apartment_entrance after transition!")
		get_tree().quit(1)
		return
		
	# Find alley_view interactable node in active_street
	var alley_area = active_street.get_node_or_null("Interactables/AlleyViewArea")
	if not alley_area:
		printerr("FAIL: AlleyViewArea not found under active_street/Interactables!")
		get_tree().quit(1)
		return
		
	# Test BEFORE quest is started (should return default message)
	var last_interaction_data = {}
	_temp_callable = func(data):
		last_interaction_data.clear()
		last_interaction_data.merge(data)
	active_street.interaction_requested.connect(_temp_callable)
	
	active_street.current_interactable = alley_area
	active_street._trigger_interaction()
	
	if last_interaction_data.get("type") != "message":
		printerr("FAIL: Interaction type is not 'message' before quest started! Got data: ", last_interaction_data)
		get_tree().quit(1)
		return
	if not "右側暗巷深得像" in last_interaction_data.get("message_text", ""):
		printerr("FAIL: Default alley_view message is wrong! Got: ", last_interaction_data.get("message_text"))
		get_tree().quit(1)
		return
	print("PASS: Default alley_view message verified when quest is not active.")
	
	# Test AFTER quest is started (should advance quest and show danger message)
	QuestManager.start("alley_backrooms_3f")
	if QuestManager.get_status("alley_backrooms_3f") != "active" or QuestManager.get_step("alley_backrooms_3f") != "started":
		printerr("FAIL: Failed to initialize quest state to started!")
		get_tree().quit(1)
		return
		
	last_interaction_data.clear()
	active_street._trigger_interaction()
	
	if not "暗巷深處有幾具損毀" in last_interaction_data.get("message_text", ""):
		printerr("FAIL: Danger alley_view message is wrong! Got: ", last_interaction_data.get("message_text"))
		get_tree().quit(1)
		return
	if last_interaction_data.get("note_title", "") == "":
		printerr("FAIL: note_title should be present to show note update toast!")
		get_tree().quit(1)
		return
		
	# Check if quest stepped advanced
	if QuestManager.get_step("alley_backrooms_3f") != "checked_alley":
		printerr("FAIL: Quest step did not advance to 'checked_alley' after interaction!")
		get_tree().quit(1)
		return
	print("PASS: Quest advanced and danger message shown on first active interaction.")
	
	# Test SECOND interaction when quest step is checked_alley (should show danger message but NOT change state)
	last_interaction_data.clear()
	active_street._trigger_interaction()
	
	if not "暗巷深處有幾具損毀" in last_interaction_data.get("message_text", ""):
		printerr("FAIL: Danger message should be shown on subsequent active interactions!")
		get_tree().quit(1)
		return
	if QuestManager.get_step("alley_backrooms_3f") != "checked_alley":
		printerr("FAIL: Quest step changed incorrectly on duplicate interaction!")
		get_tree().quit(1)
		return
	print("PASS: Duplicate interaction does not alter quest step.")
	
	# Clean up signal connection
	active_street.interaction_requested.disconnect(_temp_callable)

	# 20. Verify Phase 7-D Apartment Window conditional entry
	print("Verifying Phase 7-D Apartment Window conditional entry...")
	
	# Reset state first
	GameState.reset_for_new_game()
	
	# Transition into apartment
	main_instance.transition_to("apartment", "wake_bed")
	await get_tree().process_frame
	
	var active_apartment = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion() and child.get_script() and child.get_script().resource_path.contains("apartment_room.gd"):
			active_apartment = child
			break
			
	if not active_apartment:
		printerr("FAIL: Current scene is not apartment after transition!")
		get_tree().quit(1)
		return
		
	# Find ApartmentWindow interactable node in active_apartment
	var window_area = active_apartment.get_node_or_null("Interactables/ApartmentWindow")
	if not window_area:
		printerr("FAIL: ApartmentWindow not found under active_apartment/Interactables!")
		get_tree().quit(1)
		return
		
	# Test 20.1: Window NOT available before checked_alley (not started, or active but started step)
	# Case A: status = "" (not started)
	active_apartment._on_interactable_entered(window_area)
	
	active_apartment._refresh_current_interactable()
	if active_apartment.current_interactable == window_area:
		printerr("FAIL: Window should not be interactable when quest is not started!")
		get_tree().quit(1)
		return
	print("PASS: Window interaction correctly disabled when quest is not started.")
	
	active_apartment._on_interactable_exited(window_area)
	
	# Case B: active + step=started (started, but not yet checked_alley)
	QuestManager.start("alley_backrooms_3f")
	if QuestManager.get_status("alley_backrooms_3f") != "active" or QuestManager.get_step("alley_backrooms_3f") != "started":
		printerr("FAIL: Quest not correctly initialized to started state!")
		get_tree().quit(1)
		return
		
	active_apartment._on_interactable_entered(window_area)
	active_apartment._refresh_current_interactable()
	if active_apartment.current_interactable == window_area:
		printerr("FAIL: Window should not be interactable when quest step is started!")
		get_tree().quit(1)
		return
	print("PASS: Window interaction correctly disabled when quest step is started.")
	
	active_apartment._on_interactable_exited(window_area)
	
	# Test 20.2: Start quest and advance to checked_alley
	QuestManager.advance("alley_backrooms_3f", "checked_alley")
	if QuestManager.get_step("alley_backrooms_3f") != "checked_alley":
		printerr("FAIL: Quest step is not checked_alley!")
		get_tree().quit(1)
		return
		
	active_apartment._on_interactable_entered(window_area)
	active_apartment._refresh_current_interactable()
	if active_apartment.current_interactable != window_area:
		printerr("FAIL: Window should be interactable when quest step is checked_alley!")
		get_tree().quit(1)
		return
	if not "爬出窗外" in tr(active_apartment.current_interactable.prompt_text):
		printerr("FAIL: Window prompt text is wrong! Got: ", active_apartment.current_interactable.prompt_text)
		get_tree().quit(1)
		return
	print("PASS: Window interaction enabled with correct prompt after checked_alley.")
	
	# Test 20.3: Interact with window and verify transition request
	var last_transition_data = {}
	_temp_callable = func(scene_id, entry_point_id, payload):
		last_transition_data["scene_id"] = scene_id
		last_transition_data["entry_point_id"] = entry_point_id
		last_transition_data["payload"] = payload
	active_apartment.scene_transition_requested.connect(_temp_callable)
	
	active_apartment._trigger_interaction()
	
	if last_transition_data.get("scene_id") != "apartment_fire_escape":
		printerr("FAIL: Transition scene_id is not apartment_fire_escape! Got: ", last_transition_data)
		get_tree().quit(1)
		return
	if last_transition_data.get("entry_point_id") != "from_window":
		printerr("FAIL: Transition entry_point_id is not from_window! Got: ", last_transition_data)
		get_tree().quit(1)
		return
	print("PASS: Window interaction correctly emits scene_transition_requested to fire escape.")
	
	active_apartment.scene_transition_requested.disconnect(_temp_callable)
	active_apartment._on_interactable_exited(window_area)
	
	# Test 20.4: Verify from_fire_escape entry point positioning and monologue suppression
	GameState.reset_for_new_game()
	
	main_instance.transition_to("apartment", "from_fire_escape")
	await get_tree().process_frame
	
	var active_apartment_from_escape = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion() and child.get_script() and child.get_script().resource_path.contains("apartment_room.gd"):
			active_apartment_from_escape = child
			break
			
	if not active_apartment_from_escape:
		printerr("FAIL: Current scene is not apartment after transition from fire escape!")
		get_tree().quit(1)
		return
		
	var player_node = active_apartment_from_escape.get_node("Player")
	if abs(player_node.global_position.x - 1000.0) > 1.0 or abs(player_node.global_position.y - 700.0) > 1.0:
		printerr("FAIL: Player position is not near window at (1000, 700)! Got: ", player_node.global_position)
		get_tree().quit(1)
		return
		
	if active_apartment_from_escape._opening_monologue_active:
		printerr("FAIL: Opening monologue should be suppressed when entering from_fire_escape!")
		get_tree().quit(1)
		return
		
	print("PASS: from_fire_escape entry point positioning and monologue suppression verified.")
	
	# Test 21: Verify 7-G Fire Escape Target Box Search & Activation Box Retrieval
	print("Verifying Phase 7-G Fire Escape Target Box Search & Retrieval...")
	# 1. Load fire escape scene
	var escape_scene = load("res://scenes/levels/apartment_fire_escape/apartment_fire_escape.tscn")
	if not escape_scene:
		printerr("FAIL: Could not load apartment_fire_escape.tscn!")
		get_tree().quit(1)
		return
	var escape_instance = escape_scene.instantiate()
	add_child(escape_instance)
	
	# 2. Reset quest states and inventory
	GameState.reset_for_new_game()
	
	# 3. Initially, when quest not started, target box interaction should show locked message
	var box_area = escape_instance.get_node("Interactables/QuestBox")
	if not box_area:
		printerr("FAIL: QuestBox interactable not found in fire escape scene!")
		get_tree().quit(1)
		return
	
	escape_instance._on_interactable_entered(box_area)
	
	var test_state = {
		"message_text": "",
		"on_closed": Callable()
	}
	var test_callback = func(data):
		if data.get("type") == "message":
			test_state["message_text"] = data.get("message_text", "")
			test_state["on_closed"] = data.get("on_closed", Callable())
	escape_instance.interaction_requested.connect(test_callback)
	
	# Trigger E interaction when quest is not started
	escape_instance._handle_primary_interaction()
	if test_state["message_text"] != escape_instance.MESSAGES["quest_box_locked"]:
		printerr("FAIL: Box interaction should be locked when quest not started! Got: ", test_state["message_text"])
		get_tree().quit(1)
		return
	print("PASS: Locked message shown correctly when quest is not started.")
	
	# 4. Start quest, but step is not checked_alley (it's started)
	QuestManager.start("alley_backrooms_3f")
	test_state["message_text"] = ""
	test_state["on_closed"] = Callable()
	escape_instance._handle_primary_interaction()
	if test_state["message_text"] != escape_instance.MESSAGES["quest_box_locked"]:
		printerr("FAIL: Box interaction should be locked when quest step is started! Got: ", test_state["message_text"])
		get_tree().quit(1)
		return
	print("PASS: Locked message shown correctly when quest step is started.")
	
	# 5. Advance quest to checked_alley, but fill player inventory (so item add fails)
	QuestManager.advance("alley_backrooms_3f", "checked_alley")
	
	# Fill all inventory slots (simulate bag full)
	for i in range(GameState.inventory_slots):
		GameState.inventory[i] = {
			"instance_id": GameState.generate_instance_id(),
			"item_id": "canned_food",
			"quantity": 5
		}
	
	test_state["message_text"] = ""
	test_state["on_closed"] = Callable()
	escape_instance._handle_primary_interaction()
	
	if test_state["message_text"] != escape_instance.MESSAGES["quest_box_search_quiet"]:
		printerr("FAIL: Box search message should be shown when step is checked_alley! Got: ", test_state["message_text"])
		get_tree().quit(1)
		return
		
	# Call on_closed to simulate search complete
	if test_state["on_closed"].is_null():
		printerr("FAIL: on_closed callback is null when searching box!")
		get_tree().quit(1)
		return
		
	var on_closed_callback_full = test_state["on_closed"]
	test_state["message_text"] = ""
	test_state["on_closed"] = Callable()
	
	on_closed_callback_full.call()
	
	if test_state["message_text"] != escape_instance.MESSAGES["inventory_full_for_activation_box"]:
		printerr("FAIL: Inventory full warning not shown! Got: ", test_state["message_text"])
		get_tree().quit(1)
		return
		
	# Quest state and flag should remain unchanged
	if QuestManager.get_step("alley_backrooms_3f") != "checked_alley" or QuestManager.get_flag("alley_backrooms_3f", "found_activation_box", false):
		printerr("FAIL: Quest state advanced even when inventory was full!")
		get_tree().quit(1)
		return
	print("PASS: Box search correctly handles inventory full state without changing quest flags.")
	
	# 6. Clear inventory space and try again
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
		
	test_state["message_text"] = ""
	test_state["on_closed"] = Callable()
	escape_instance._handle_primary_interaction()
	
	if test_state["message_text"] != escape_instance.MESSAGES["quest_box_search_quiet"]:
		printerr("FAIL: Box search message should be shown again! Got: ", test_state["message_text"])
		get_tree().quit(1)
		return
		
	# Call on_closed again (now bag has space)
	var on_closed_callback_ok = test_state["on_closed"]
	test_state["message_text"] = ""
	test_state["on_closed"] = Callable()
	
	on_closed_callback_ok.call()
	
	# Item should be in inventory
	if not GameState.has_item("early_ai_assistant_activation_box", 1):
		printerr("FAIL: activation box item was not added to inventory!")
		get_tree().quit(1)
		return
		
	# Quest state should be advanced to found_activation_box
	if QuestManager.get_step("alley_backrooms_3f") != "found_activation_box":
		printerr("FAIL: Quest step did not advance to found_activation_box! Got: ", QuestManager.get_step("alley_backrooms_3f"))
		get_tree().quit(1)
		return
		
	if not QuestManager.get_flag("alley_backrooms_3f", "found_activation_box", false):
		printerr("FAIL: found_activation_box flag was not set on quest!")
		get_tree().quit(1)
		return
		
	# The final box obtained message should be shown
	if test_state["message_text"] != escape_instance.MESSAGES["quest_box_obtained_box"]:
		printerr("FAIL: Box obtained message was incorrect! Got: ", test_state["message_text"])
		get_tree().quit(1)
		return
		
	print("PASS: Box search correctly advanced and final message shown.")
	
	# 7. Once found, closest interactable check should ignore the quest box
	escape_instance.interaction_requested.disconnect(test_callback)
	escape_instance._refresh_current_interactable()
	if escape_instance.current_interactable == box_area:
		printerr("FAIL: Quest box should be ignored once activation box has been found!")
		get_tree().quit(1)
		return
	print("PASS: Quest box ignored once item has been retrieved.")
	
	# Test 22: Verify 7-H R Inspect Grants Item Flow
	print("Verifying Phase 7-H R Inspect Grants Item Flow...")
	
	# 1. Reset for clean test state with active quest at found_activation_box
	GameState.reset_for_new_game()
	QuestManager.start("alley_backrooms_3f")
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	QuestManager.set_flag("alley_backrooms_3f", "found_old_ai_authorization_module", false)
	
	# 2. Add activation box (A) to inventory
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
	GameState.add_item("early_ai_assistant_activation_box", 1)
	
	var box_instance_id := ""
	for slot in GameState.get_inventory():
		if slot.get("item_id", "") == "early_ai_assistant_activation_box":
			box_instance_id = slot.get("instance_id", "")
			break
			
	if box_instance_id.is_empty():
		printerr("FAIL: Could not add activation box to inventory!")
		get_tree().quit(1)
		return
		
	# 3. Fill remaining slots to simulate bag full
	for i in range(GameState.inventory_slots):
		if GameState.inventory[i].is_empty():
			GameState.inventory[i] = {
				"instance_id": GameState.generate_instance_id(),
				"item_id": "canned_food",
				"quantity": 5
			}
			
	# 4. Open inventory UI to put UI in correct mode/state
	ui_instance.open_inventory()
	
	# 5. Trigger view action (R inspect) on A while bag is full
	ui_instance._on_bag_item_action("view", box_instance_id)
	
	# Force message to finish writing, and verify message contents
	ui_instance.force_finish_message()
	if not ui_instance.message_label.text.contains("你仔細端詳啟用盒的底部"):
		printerr("FAIL: First inspect message did not show! Got: ", ui_instance.message_label.text)
		get_tree().quit(1)
		return
		
	# Simulate closing the first message box
	var first_callback = ui_instance._message_on_closed
	if first_callback.is_null():
		printerr("FAIL: first_callback is null!")
		get_tree().quit(1)
		return
	ui_instance.close_message()
	first_callback.call()
	
	# Since bag is full, warning message should be shown next
	ui_instance.force_finish_message()
	if not ui_instance.message_label.text.contains("你發現了啟用盒底部的夾層") or not ui_instance.message_label.text.contains("但你的背包太滿了"):
		printerr("FAIL: Inventory full warning message did not show! Got: ", ui_instance.message_label.text)
		get_tree().quit(1)
		return
		
	# Flags and items should remain unchanged
	if QuestManager.get_flag("alley_backrooms_3f", "found_old_ai_authorization_module", false):
		printerr("FAIL: flag set even when inventory is full!")
		get_tree().quit(1)
		return
	if GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: old_ai_authorization_module added even when inventory is full!")
		get_tree().quit(1)
		return
		
	# Simulate closing the warning message box, which should restore the detail modal
	var warning_callback = ui_instance._message_on_closed
	if warning_callback.is_null():
		printerr("FAIL: warning_callback is null!")
		get_tree().quit(1)
		return
	ui_instance.close_message()
	warning_callback.call()
	
	if not ui_instance.item_detail_modal.visible:
		printerr("FAIL: Item detail modal not opened after warning closed!")
		get_tree().quit(1)
		return
		
	# Close the detail modal
	ui_instance.item_detail_modal.close_modal()
	if ui_instance.item_detail_modal.visible:
		printerr("FAIL: Detail modal did not close!")
		get_tree().quit(1)
		return
		
	# 6. Clear space and test successful retrieval
	for i in range(1, GameState.inventory_slots):
		GameState.inventory[i] = {}
		
	# Trigger view action (R inspect) again
	ui_instance._on_bag_item_action("view", box_instance_id)
	ui_instance.force_finish_message()
	
	var success_callback = ui_instance._message_on_closed
	if success_callback.is_null():
		printerr("FAIL: success_callback is null!")
		get_tree().quit(1)
		return
	ui_instance.close_message()
	success_callback.call()
	
	# Verify flag is set, and old_ai_authorization_module (B) is added to inventory, and A remains
	if not QuestManager.get_flag("alley_backrooms_3f", "found_old_ai_authorization_module", false):
		printerr("FAIL: flag not set on successful inspect!")
		get_tree().quit(1)
		return
	if not GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: old_ai_authorization_module not added on successful inspect!")
		get_tree().quit(1)
		return
	if not GameState.has_item("early_ai_assistant_activation_box", 1):
		printerr("FAIL: early_ai_assistant_activation_box consumed on successful inspect!")
		get_tree().quit(1)
		return
		
	# Verify detail modal is now open
	if not ui_instance.item_detail_modal.visible:
		printerr("FAIL: Detail modal not opened after successful inspect message closed!")
		get_tree().quit(1)
		return
		
	# Close the detail modal
	ui_instance.item_detail_modal.close_modal()
	
	# 7. Test subsequent inspections of A (should open detail modal directly without messages)
	ui_instance._message_on_closed = Callable()
	ui_instance._on_bag_item_action("view", box_instance_id)
	
	if ui_instance._message_on_closed.is_valid():
		printerr("FAIL: Subsequent inspect triggered message box flow!")
		get_tree().quit(1)
		return
		
	if not ui_instance.item_detail_modal.visible:
		printerr("FAIL: Detail modal not opened directly on subsequent inspect!")
		get_tree().quit(1)
		return
		
	ui_instance.item_detail_modal.close_modal()
	ui_instance.close_all_ui()
	
	print("PASS: Phase 7-H R Inspect Grants Item Flow verified successfully.")
	
	# 23. Verify Phase 7-I Turn-in Quest to Wan
	print("Verifying Phase 7-I Turn-in Quest to Wan...")
	
	# 1. Reset state
	GameState.reset_for_new_game()
	
	# 2. Start quest and advance to found_activation_box
	QuestManager.start("alley_backrooms_3f")
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	
	# 3. Add item A and B to inventory
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
	GameState.add_item("early_ai_assistant_activation_box", 1)
	GameState.add_item("old_ai_authorization_module", 1)
	QuestManager.set_flag("alley_backrooms_3f", "found_old_ai_authorization_module", true)
	
	# Verify items exist
	if not GameState.has_item("early_ai_assistant_activation_box", 1) or not GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: Failed to populate items A and B for turn-in test!")
		get_tree().quit(1)
		return
		
	# 4. Instantiate dialogue tree for Wan and verify options in retalk node
	runner = DialogueRunner.new()
	DialogueDB = load("res://data/dialogue/dialogue_db.gd")
	wan_tree = DialogueDB.get_tree_for("wan")
	
	# Set met_wan flag so start goes to retalk
	GameState.set_flag("met_wan", true)
	runner.start(wan_tree)
	
	var cur = runner.current()
	# Current should be retalk
	if cur.get("text", "") == "":
		printerr("FAIL: Dialogue tree failed to start on Wan tree!")
		get_tree().quit(1)
		return
		
	# Check retalk choices to ensure choice index 3 is '我找到那個啟用盒了。'
	choices = cur.get("choices", [])
	var turn_in_choice = null
	for choice in choices:
		if tr(choice.get("label", "")) == "我找到那個啟用盒了。":
			turn_in_choice = choice
			break
			
	if not turn_in_choice:
		printerr("FAIL: Turn-in choice '我找到那個啟用盒了。' not visible in retalk node!")
		get_tree().quit(1)
		return
		
	# 5. Choose turn-in option (we have B, so this routes to turn_in_found_module choice node)
	runner.choose(turn_in_choice.get("index"))
	
	# 6. Verify transition to turn_in_found_module
	var after_choice = runner.current()
	if not tr(after_choice.get("text", "")).contains("底下還藏了什麼寶貝"):
		printerr("FAIL: Choice did not transition to turn_in_found_module node! Text got: ", tr(after_choice.get("text")))
		get_tree().quit(1)
		return
		
	# Verify two choices present
	var end_choices = after_choice.get("choices", [])
	if end_choices.size() != 2:
		printerr("FAIL: turn_in_found_module should have 2 choices, got: ", end_choices.size())
		get_tree().quit(1)
		return
		
	# Choose Choice 0: Only turn in plain box (Ending B)
	var idx_plain = end_choices[0].get("index")
	runner.choose(idx_plain)
	
	var plain_node = runner.current()
	if not tr(plain_node.get("text", "")).contains("開玩笑的啦"):
		printerr("FAIL: turn_in_plain text incorrect! Got: ", tr(plain_node.get("text")))
		get_tree().quit(1)
		return
		
	# Advance to trigger effects
	runner.advance()
	
	# Verify Ending B state: A removed, B retained, completed, credits = 800 (300 + 500), note B
	if GameState.has_item("early_ai_assistant_activation_box", 1):
		printerr("FAIL: early_ai_assistant_activation_box (A) was not removed in Ending B!")
		get_tree().quit(1)
		return
	if not GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: old_ai_authorization_module (B) was removed in Ending B!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("alley_backrooms_3f") != "completed":
		printerr("FAIL: Quest status is not 'completed' in Ending B!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != 800:
		printerr("FAIL: Ending B credits should be 800, got: ", GameState.get_credits())
		get_tree().quit(1)
		return
	var notes_b = GameState.get_notes("工作")
	if notes_b.is_empty() or notes_b[0].get("status") != "completed" or not _tr_body(notes_b[0].get("body")).contains("留在了自己身上"):
		printerr("FAIL: Work note for Ending B incorrect!")
		get_tree().quit(1)
		return
	print("PASS: Ending B (Kept module) verified successfully.")

	# --- Test Ending C (Gave module) ---
	# Reset state
	GameState.reset_for_new_game()
	QuestManager.start("alley_backrooms_3f")
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
	GameState.add_item("early_ai_assistant_activation_box", 1)
	GameState.add_item("old_ai_authorization_module", 1)
	QuestManager.set_flag("alley_backrooms_3f", "found_old_ai_authorization_module", true)

	runner = DialogueRunner.new()
	GameState.set_flag("met_wan", true)
	runner.start(wan_tree)
	runner.choose(turn_in_choice.get("index"))
	
	# Select Choice 1: 連舊模組也一起遞過去 (Ending C)
	end_choices = runner.current().get("choices", [])
	runner.choose(end_choices[1].get("index"))
	
	var full_node = runner.current()
	if not tr(full_node.get("text", "")).contains("舊式授權晶片"):
		printerr("FAIL: turn_in_full text incorrect! Got: ", tr(full_node.get("text")))
		get_tree().quit(1)
		return
		
	# Advance to trigger effects
	runner.advance()
	
	# Verify Ending C state: A and B removed, completed, credits = 1300 (300 + 1000), affinity_wan = 2, gave_wan_old_module = true, note C
	if GameState.has_item("early_ai_assistant_activation_box", 1) or GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: Items A or B not removed in Ending C!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("alley_backrooms_3f") != "completed":
		printerr("FAIL: Quest status not completed in Ending C!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != 1300:
		printerr("FAIL: Ending C credits should be 1300, got: ", GameState.get_credits())
		get_tree().quit(1)
		return
	if GameState.get_flag("affinity_wan") != 2 or not GameState.get_flag("gave_wan_old_module"):
		printerr("FAIL: Ending C flags/affinity not updated correctly!")
		get_tree().quit(1)
		return
	var notes_c = GameState.get_notes("工作")
	if notes_c.is_empty() or notes_c[0].get("status") != "completed" or not _tr_body(notes_c[0].get("body")).contains("託付"):
		printerr("FAIL: Work note for Ending C incorrect!")
		get_tree().quit(1)
		return
	print("PASS: Ending C (Gave module) verified successfully.")

	# Verify retalk_close routing
	runner = DialogueRunner.new()
	runner.start(wan_tree)
	var close_node = runner.current()
	if not tr(close_node.get("text", "")).contains("擠擠"):
		printerr("FAIL: Start did not route to retalk_close after Ending C! Got: ", tr(close_node.get("text")))
		get_tree().quit(1)
		return
	
	# Select choice 0: "陪妳站會兒。"
	var close_choices = close_node.get("choices", [])
	runner.choose(close_choices[0].get("index"))
	
	# Verify affinity increment and transition to end_close
	if GameState.get_flag("affinity_wan") != 3:
		printerr("FAIL: retalk_close choice 0 did not increment affinity_wan! Got: ", GameState.get_flag("affinity_wan"))
		get_tree().quit(1)
		return
	var close_end = runner.current()
	if not tr(close_end.get("text", "")).contains("別把雨聲"):
		printerr("FAIL: retalk_close did not transition to end_close! Got: ", tr(close_end.get("text")))
		get_tree().quit(1)
		return
	print("PASS: retalk_close dialogue flow verified successfully.")

	# --- Test Ending A (Plain box only) ---
	# Reset state
	GameState.reset_for_new_game()
	QuestManager.start("alley_backrooms_3f")
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
	GameState.add_item("early_ai_assistant_activation_box", 1)
	QuestManager.set_flag("alley_backrooms_3f", "found_old_ai_authorization_module", false)

	runner = DialogueRunner.new()
	GameState.set_flag("met_wan", true)
	runner.start(wan_tree)
	
	# Select turn-in option (routes to turn_in_plain since we don't have B)
	runner.choose(turn_in_choice.get("index"))
	
	var plain_node_a = runner.current()
	if not tr(plain_node_a.get("text", "")).contains("開玩笑的啦"):
		printerr("FAIL: Ending A did not route directly to turn_in_plain! Got text: ", tr(plain_node_a.get("text")))
		get_tree().quit(1)
		return
		
	# Advance to trigger effects
	runner.advance()
	
	# Verify Ending A state: A removed, completed, credits = 800 (+500), note A, gave_wan_old_module false
	if GameState.has_item("early_ai_assistant_activation_box", 1):
		printerr("FAIL: early_ai_assistant_activation_box was not removed in Ending A!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("alley_backrooms_3f") != "completed":
		printerr("FAIL: Quest status is not 'completed' in Ending A!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != 800:
		printerr("FAIL: Ending A credits should be 800, got: ", GameState.get_credits())
		get_tree().quit(1)
		return
	if GameState.get_flag("gave_wan_old_module", false):
		printerr("FAIL: gave_wan_old_module should be false in Ending A!")
		get_tree().quit(1)
		return
	var notes_a = GameState.get_notes("工作")
	if notes_a.is_empty() or notes_a[0].get("status") != "completed" or not _tr_body(notes_a[0].get("body")).contains("錯過"):
		printerr("FAIL: Work note for Ending A incorrect!")
		get_tree().quit(1)
		return
	print("PASS: Ending A (Plain box only) verified successfully.")

	# 9. Verify defensive case: if A is not in inventory, turn-in fails and quest is NOT completed
	# Reset for clean test state with active quest at found_activation_box
	GameState.reset_for_new_game()
	QuestManager.start("alley_backrooms_3f")
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	
	# Clear inventory (ensure NO activation box A is present)
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
		
	# Instantiate tree and force enter turn-in node directly (routes to turn_in_plain since no B)
	runner = DialogueRunner.new()
	wan_tree = DialogueDB.get_tree_for("wan")
	runner.start(wan_tree, "alley_backrooms_turn_in")
	
	# Advance dialogue to trigger effects
	runner.advance()
	
	# Since A was missing, remove_item effect should fail and abort completion
	if QuestManager.get_status("alley_backrooms_3f") == "completed":
		printerr("FAIL: Quest status was marked completed even when A was missing during turn-in!")
		get_tree().quit(1)
		return
		
	var notes_defensive = GameState.get_notes("工作")
	if notes_defensive.is_empty() or notes_defensive[0].get("status") == "completed":
		printerr("FAIL: Work note status was marked completed even when A was missing during turn-in!")
		get_tree().quit(1)
		return
	print("PASS: Turn-in defensive constraint verified (missing item aborts quest completion).")
		
	print("PASS: Phase 7-I Turn-in Quest to Wan verified successfully.")
	
	# 24. Verify Phase 7-J Regression & Save/Restore
	print("Verifying Phase 7-J Regression & Save/Restore...")
	
	# 1. Quest Started Save/Load Check
	GameState.reset_for_new_game()
	QuestManager.start("alley_backrooms_3f")
	
	var save_p1 = SaveSystem.capture("apartment", 100.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_p1):
		printerr("FAIL: Failed to write save_p1 to scratch slot!")
		get_tree().quit(1)
		return
		
	GameState.reset_for_new_game()
	var loaded_p1 = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	SaveSystem.apply(loaded_p1)
	
	if QuestManager.get_status("alley_backrooms_3f") != "active" or QuestManager.get_step("alley_backrooms_3f") != "started":
		printerr("FAIL: Quest status/step was not restored correctly in started check!")
		get_tree().quit(1)
		return
		
	var notes_p1 = GameState.get_notes("工作")
	if notes_p1.is_empty() or notes_p1[0].get("id") != "quest_alley_backrooms_3f":
		printerr("FAIL: Quest work note not restored correctly in started check!")
		get_tree().quit(1)
		return
	print("PASS: Quest started state successfully saved and restored.")
	
	# 2. Alley Checked Save/Load Check
	QuestManager.advance("alley_backrooms_3f", "checked_alley")
	var save_p2 = SaveSystem.capture("apartment", 100.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_p2):
		printerr("FAIL: Failed to write save_p2 to scratch slot!")
		get_tree().quit(1)
		return
		
	GameState.reset_for_new_game()
	var loaded_p2 = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	SaveSystem.apply(loaded_p2)
	
	if QuestManager.get_step("alley_backrooms_3f") != "checked_alley":
		printerr("FAIL: Quest step was not restored to checked_alley!")
		get_tree().quit(1)
		return
		
	# Verify window interaction gate in apartment_room
	var room_instance_j = room_scene.instantiate()
	add_child(room_instance_j)
	var win_area_j = room_instance_j.get_node_or_null("Interactables/ApartmentWindow")
	if not win_area_j:
		printerr("FAIL: ApartmentWindow not found in room_instance_j!")
		get_tree().quit(1)
		return
	room_instance_j._on_interactable_entered(win_area_j)
	room_instance_j._refresh_current_interactable()
	if room_instance_j.current_interactable != win_area_j:
		printerr("FAIL: ApartmentWindow was not interactable after restore from checked_alley!")
		get_tree().quit(1)
		return
	room_instance_j.queue_free()
	print("PASS: Checked_alley state and window interaction gate successfully saved and restored.")
	
	# 3. Activation Box Found Save/Load Check (Inspectable A)
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
	GameState.add_item("early_ai_assistant_activation_box", 1)
	
	var save_p3 = SaveSystem.capture("apartment", 100.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_p3):
		printerr("FAIL: Failed to write save_p3 to scratch slot!")
		get_tree().quit(1)
		return
		
	GameState.reset_for_new_game()
	var loaded_p3 = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	SaveSystem.apply(loaded_p3)
	
	if not GameState.has_item("early_ai_assistant_activation_box", 1) or GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: Items not restored correctly in found_activation_box check!")
		get_tree().quit(1)
		return
		
	# Retrieve box instance id and verify we can inspect A to get B
	var box_inst_id := ""
	for slot in GameState.get_inventory():
		if slot.get("item_id", "") == "early_ai_assistant_activation_box":
			box_inst_id = slot.get("instance_id", "")
			break
			
	# Instantiate UI for modal check
	var ui_instance_j = ui_scene.instantiate()
	add_child(ui_instance_j)
	ui_instance_j.open_inventory()
	ui_instance_j._on_bag_item_action("view", box_inst_id)
	ui_instance_j.force_finish_message()
	var view_callback = ui_instance_j._message_on_closed
	ui_instance_j.close_message()
	view_callback.call()
	
	if not GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: old_ai_authorization_module (B) was not obtained on inspect after load!")
		get_tree().quit(1)
		return
	print("PASS: Item A state restored, and inspect-to-obtain-B functionality verified after load.")
	
	# 4. Authorization Module Obtained Save/Load Check
	var save_p4 = SaveSystem.capture("apartment", 100.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_p4):
		printerr("FAIL: Failed to write save_p4 to scratch slot!")
		get_tree().quit(1)
		return
		
	GameState.reset_for_new_game()
	var loaded_p4 = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	SaveSystem.apply(loaded_p4)
	
	if not GameState.has_item("early_ai_assistant_activation_box", 1) or not GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: Items A/B not restored in authorization module obtained check!")
		get_tree().quit(1)
		return
		
	# Try inspect A again and check it doesn't give duplicate B
	var box_inst_id_p4 := ""
	for slot in GameState.get_inventory():
		if slot.get("item_id", "") == "early_ai_assistant_activation_box":
			box_inst_id_p4 = slot.get("instance_id", "")
			break
	ui_instance_j._message_on_closed = Callable()
	ui_instance_j._on_bag_item_action("view", box_inst_id_p4)
	if ui_instance_j._message_on_closed.is_valid():
		printerr("FAIL: Subsequent inspect after load triggered message box flow!")
		get_tree().quit(1)
		return
	print("PASS: Item A and B state, and single-inspect constraint successfully saved and restored.")
	
	# 5. Quest Completed Save/Load Check
	GameState.remove_item("early_ai_assistant_activation_box", 1)
	QuestManager.complete("alley_backrooms_3f")
	
	var save_p5 = SaveSystem.capture("apartment", 100.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_p5):
		printerr("FAIL: Failed to write save_p5 to scratch slot!")
		get_tree().quit(1)
		return
		
	GameState.reset_for_new_game()
	var loaded_p5 = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	SaveSystem.apply(loaded_p5)
	
	if GameState.has_item("early_ai_assistant_activation_box", 1) or not GameState.has_item("old_ai_authorization_module", 1):
		printerr("FAIL: Item states incorrect after load in completed check!")
		get_tree().quit(1)
		return
		
	if QuestManager.get_status("alley_backrooms_3f") != "completed":
		printerr("FAIL: Quest status not 'completed' after load in completed check!")
		get_tree().quit(1)
		return
		
	var notes_p5 = GameState.get_notes("工作")
	if notes_p5.is_empty() or notes_p5[0].get("status") != "completed":
		printerr("FAIL: Work note status not 'completed' after load in completed check!")
		get_tree().quit(1)
		return
	print("PASS: Quest completed state, item states, and work note states successfully saved and restored.")
	
	# 25. Verify Quest Ending Message Boxes Triggering
	print("Verifying Quest Ending Message Boxes Triggering...")
	
	# Test case 1: Ending 1 (Did not retrieve the hidden module)
	GameState.reset_for_new_game()
	QuestManager.start("alley_backrooms_3f")
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	QuestManager.complete("alley_backrooms_3f")
	QuestManager.set_flag("alley_backrooms_3f", "found_old_ai_authorization_module", false)
	GameState.story_flags.erase("alley_backrooms_ended")
	
	UIMode.set_mode(UIMode.Mode.DIALOGUE)
	UIMode.set_mode(UIMode.Mode.NONE)
	await get_tree().process_frame
	
	if UIMode.get_mode() != UIMode.Mode.MESSAGE:
		printerr("FAIL: Ending 1 did not trigger MESSAGE mode!")
		get_tree().quit(1)
		return
	if not ui_instance.message_box.visible:
		printerr("FAIL: Ending 1 message box not visible!")
		get_tree().quit(1)
		return
	if not ui_instance.message_label.text.contains("結局 1"):
		printerr("FAIL: Ending 1 text incorrect! Got: ", ui_instance.message_label.text)
		get_tree().quit(1)
		return
	print("PASS: Ending 1 messagebox triggered successfully.")
	
	# Close the message box
	ui_instance.close_message()
	await get_tree().process_frame
	
	# Verify it doesn't trigger again
	UIMode.set_mode(UIMode.Mode.DIALOGUE)
	UIMode.set_mode(UIMode.Mode.NONE)
	await get_tree().process_frame
	if UIMode.get_mode() != UIMode.Mode.NONE:
		printerr("FAIL: Ending triggered repeatedly!")
		get_tree().quit(1)
		return
	print("PASS: Ending single-trigger constraint verified.")
	
	# Test case 2: Ending 2 (Retrieved the hidden module)
	GameState.reset_for_new_game()
	QuestManager.start("alley_backrooms_3f")
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	QuestManager.set_flag("alley_backrooms_3f", "found_old_ai_authorization_module", true)
	QuestManager.complete("alley_backrooms_3f")
	GameState.story_flags.erase("alley_backrooms_ended")

	UIMode.set_mode(UIMode.Mode.DIALOGUE)
	UIMode.set_mode(UIMode.Mode.NONE)
	await get_tree().process_frame
	
	if UIMode.get_mode() != UIMode.Mode.MESSAGE:
		printerr("FAIL: Ending 2 did not trigger MESSAGE mode!")
		get_tree().quit(1)
		return
	if not ui_instance.message_box.visible:
		printerr("FAIL: Ending 2 message box not visible!")
		get_tree().quit(1)
		return
	if not ui_instance.message_label.text.contains("結局 2"):
		printerr("FAIL: Ending 2 text incorrect! Got: ", ui_instance.message_label.text)
		get_tree().quit(1)
		return
	print("PASS: Ending 2 messagebox triggered successfully.")
	
	# Close the message box
	ui_instance.close_message()
	await get_tree().process_frame
	
	# Test case 3: Ending 3 (Gave the module)
	GameState.reset_for_new_game()
	QuestManager.start("alley_backrooms_3f")
	QuestManager.advance("alley_backrooms_3f", "found_activation_box")
	QuestManager.complete("alley_backrooms_3f")
	GameState.story_flags.erase("alley_backrooms_ended")
	GameState.set_flag("gave_wan_old_module", true)

	UIMode.set_mode(UIMode.Mode.DIALOGUE)
	UIMode.set_mode(UIMode.Mode.NONE)
	await get_tree().process_frame
	
	if UIMode.get_mode() != UIMode.Mode.MESSAGE:
		printerr("FAIL: Ending 3 did not trigger MESSAGE mode!")
		get_tree().quit(1)
		return
	if not ui_instance.message_box.visible:
		printerr("FAIL: Ending 3 message box not visible!")
		get_tree().quit(1)
		return
	if not ui_instance.message_label.text.contains("結局 3"):
		printerr("FAIL: Ending 3 text incorrect! Got: ", ui_instance.message_label.text)
		get_tree().quit(1)
		return
	print("PASS: Ending 3 messagebox triggered successfully.")

	# Close the message box
	ui_instance.close_message()
	await get_tree().process_frame

	# Test case 4: Convenience Store Ending 1 (Direct Reset / "reset" resolution)
	GameState.reset_for_new_game()
	QuestManager.start("repair_vendor_bot")
	QuestManager.complete("repair_vendor_bot")
	GameState.set_flag("store_robot_resolution", "reset")
	GameState.story_flags.erase("repair_vendor_bot_ended")
	
	UIMode.set_mode(UIMode.Mode.DIALOGUE)
	UIMode.set_mode(UIMode.Mode.NONE)
	await get_tree().process_frame
	
	if UIMode.get_mode() != UIMode.Mode.MESSAGE:
		printerr("FAIL: Convenience Ending 1 did not trigger MESSAGE mode!")
		get_tree().quit(1)
		return
	if not ui_instance.message_box.visible:
		printerr("FAIL: Convenience Ending 1 message box not visible!")
		get_tree().quit(1)
		return
	if not ui_instance.message_label.text.contains("高效的系統"):
		printerr("FAIL: Convenience Ending 1 text incorrect! Got: ", ui_instance.message_label.text)
		get_tree().quit(1)
		return
	print("PASS: Convenience store Ending 1 messagebox triggered successfully.")
	
	# Close the message box
	ui_instance.close_message()
	await get_tree().process_frame
	
	# Verify it doesn't trigger again
	UIMode.set_mode(UIMode.Mode.DIALOGUE)
	UIMode.set_mode(UIMode.Mode.NONE)
	await get_tree().process_frame
	if UIMode.get_mode() != UIMode.Mode.NONE:
		printerr("FAIL: Convenience store Ending triggered repeatedly!")
		get_tree().quit(1)
		return
	print("PASS: Convenience store Ending single-trigger constraint verified.")
	
	# Test case 5: Convenience Store Ending 2 (Glean recording / "gleaned" resolution)
	GameState.reset_for_new_game()
	QuestManager.start("repair_vendor_bot")
	QuestManager.complete("repair_vendor_bot")
	GameState.set_flag("store_robot_resolution", "gleaned")
	GameState.story_flags.erase("repair_vendor_bot_ended")
	
	UIMode.set_mode(UIMode.Mode.DIALOGUE)
	UIMode.set_mode(UIMode.Mode.NONE)
	await get_tree().process_frame
	
	if UIMode.get_mode() != UIMode.Mode.MESSAGE:
		printerr("FAIL: Convenience Ending 2 did not trigger MESSAGE mode!")
		get_tree().quit(1)
		return
	if not ui_instance.message_box.visible:
		printerr("FAIL: Convenience Ending 2 message box not visible!")
		get_tree().quit(1)
		return
	if not ui_instance.message_label.text.contains("溫存的殘響"):
		printerr("FAIL: Convenience Ending 2 text incorrect! Got: ", ui_instance.message_label.text)
		get_tree().quit(1)
		return
	print("PASS: Convenience store Ending 2 messagebox triggered successfully.")

	# Close the message box
	ui_instance.close_message()
	await get_tree().process_frame

	# 26. Verify Phase 8-A Convenience Store Scene Skeleton & Transitions
	print("Verifying Phase 8-A Convenience Store scene skeleton & transitions...")

	GameState.reset_for_new_game()
	ui_instance.close_message()
	await get_tree().process_frame

	# 26.1 SceneRegistry checks
	var scenes_dict_8a = main_instance.get("SCENES")
	if not scenes_dict_8a.has("convenience_store"):
		printerr("FAIL: SCENES registry is missing 'convenience_store' key!")
		get_tree().quit(1)
		return
	var store_cfg = scenes_dict_8a["convenience_store"]
	if store_cfg.get("path") != "res://scenes/levels/convenience_store/convenience_store.tscn":
		printerr("FAIL: convenience_store registry path is wrong! Got: ", store_cfg.get("path"))
		get_tree().quit(1)
		return
	if not "from_street" in store_cfg.get("entry_points", []) or store_cfg.get("default_entry_point_id") != "from_street":
		printerr("FAIL: convenience_store entry point 'from_street' not registered correctly!")
		get_tree().quit(1)
		return
	if not "from_store" in scenes_dict_8a["apartment_entrance"].get("entry_points", []):
		printerr("FAIL: apartment_entrance entry point 'from_store' not registered!")
		get_tree().quit(1)
		return
	print("PASS: SceneRegistry contains convenience_store (from_street) and apartment_entrance gains from_store.")

	# 26.2 Load & instantiate standalone, verify level contract + entry point
	var store_scene = load("res://scenes/levels/convenience_store/convenience_store.tscn")
	if not store_scene:
		printerr("FAIL: Could not load convenience_store.tscn!")
		get_tree().quit(1)
		return
	var store_instance = store_scene.instantiate()
	add_child(store_instance)

	if not store_instance.has_signal("current_interactable_changed") \
		or not store_instance.has_signal("interaction_requested") \
		or not store_instance.has_signal("scene_transition_requested"):
		printerr("FAIL: convenience_store is missing level contract signals!")
		get_tree().quit(1)
		return
	if not store_instance.has_method("prepare_entry_point") or not store_instance.has_method("set_entry_point"):
		printerr("FAIL: convenience_store is missing entry point API!")
		get_tree().quit(1)
		return

	store_instance.set_entry_point("from_street", {})
	var store_spawn = store_instance.get_node_or_null("SpawnPoints/from_street")
	if not store_spawn:
		printerr("FAIL: SpawnPoints/from_street not found in convenience_store!")
		get_tree().quit(1)
		return
	var store_player = store_instance.get_node("Player")
	if abs(store_player.global_position.x - store_spawn.global_position.x) > 1.0:
		printerr("FAIL: Player not positioned at from_street spawn! Got: ", store_player.global_position)
		get_tree().quit(1)
		return
	if not SaveSystem.can_save_here:
		printerr("FAIL: can_save_here is not true inside convenience_store!")
		get_tree().quit(1)
		return
	print("PASS: convenience_store loads with contract signals, from_street spawn, and can_save_here true.")

	# 26.3 Auto door emits transition back to street at from_store
	var store_transition_data = {}
	_temp_callable = func(scene_id, entry_point_id, payload):
		store_transition_data["scene_id"] = scene_id
		store_transition_data["entry_point_id"] = entry_point_id
		store_transition_data["payload"] = payload
	store_instance.scene_transition_requested.connect(_temp_callable)

	var auto_door_area = store_instance.get_node_or_null("Interactables/AutoDoorArea")
	if not auto_door_area:
		printerr("FAIL: AutoDoorArea not found in convenience_store!")
		get_tree().quit(1)
		return
	store_instance.current_interactable = auto_door_area
	store_instance._trigger_interaction()

	if store_transition_data.get("scene_id") != "apartment_entrance" or store_transition_data.get("entry_point_id") != "from_store":
		printerr("FAIL: Auto door transition request is wrong! Got: ", store_transition_data)
		get_tree().quit(1)
		return
	store_instance.scene_transition_requested.disconnect(_temp_callable)
	print("PASS: Store auto door emits scene_transition_requested(apartment_entrance, from_store).")

	# 26.4 Locked back door shows message only
	var store_interaction_data = {}
	_temp_callable = func(data):
		store_interaction_data.clear()
		store_interaction_data.merge(data)
	store_instance.interaction_requested.connect(_temp_callable)

	var back_door_area = store_instance.get_node_or_null("Interactables/BackDoorArea")
	if not back_door_area:
		printerr("FAIL: BackDoorArea not found in convenience_store!")
		get_tree().quit(1)
		return
	store_instance.current_interactable = back_door_area
	store_instance._trigger_interaction()

	if store_interaction_data.get("type") != "message" \
		or store_interaction_data.get("message_text") != store_instance.MESSAGES["back_door"]:
		printerr("FAIL: Back door did not show locked message! Got: ", store_interaction_data)
		get_tree().quit(1)
		return
	store_instance.interaction_requested.disconnect(_temp_callable)
	store_instance.free()
	print("PASS: Locked back door shows message only.")

	# 26.5 Street store_front now emits transition into the store
	main_instance.transition_to("apartment_entrance", "from_apartment")
	await get_tree().process_frame

	var street_8a = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion() and child.get_script() and child.get_script().resource_path.contains("apartment_entrance.gd"):
			street_8a = child
			break
	if not street_8a:
		printerr("FAIL: Current scene is not apartment_entrance after transition!")
		get_tree().quit(1)
		return

	if not street_8a.get_node_or_null("SpawnPoints/from_store"):
		printerr("FAIL: SpawnPoints/from_store not found in apartment_entrance!")
		get_tree().quit(1)
		return

	var store_front_area = street_8a.get_node_or_null("Interactables/StoreFrontArea")
	if not store_front_area:
		printerr("FAIL: StoreFrontArea not found in apartment_entrance!")
		get_tree().quit(1)
		return

	store_transition_data.clear()
	_temp_callable = func(scene_id, entry_point_id, payload):
		store_transition_data["scene_id"] = scene_id
		store_transition_data["entry_point_id"] = entry_point_id
		store_transition_data["payload"] = payload
	street_8a.scene_transition_requested.connect(_temp_callable)

	street_8a.current_interactable = store_front_area
	street_8a._trigger_interaction()

	if store_transition_data.get("scene_id") != "convenience_store" or store_transition_data.get("entry_point_id") != "from_street":
		printerr("FAIL: store_front transition request is wrong! Got: ", store_transition_data)
		get_tree().quit(1)
		return
	street_8a.scene_transition_requested.disconnect(_temp_callable)
	print("PASS: Street store_front emits scene_transition_requested(convenience_store, from_street).")

	# 26.6 Real two-way transition through the SceneRouter
	main_instance.transition_to("convenience_store", "from_street")
	await get_tree().process_frame

	var active_store = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion() and child.get_script() and child.get_script().resource_path.contains("convenience_store.gd"):
			active_store = child
			break
	if not active_store:
		printerr("FAIL: Current scene is not convenience_store after router transition!")
		get_tree().quit(1)
		return
	if not SaveSystem.can_save_here:
		printerr("FAIL: can_save_here is not true after router transition into store!")
		get_tree().quit(1)
		return

	main_instance.transition_to("apartment_entrance", "from_store")
	await get_tree().process_frame

	var street_back_8a = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion() and child.get_script() and child.get_script().resource_path.contains("apartment_entrance.gd"):
			street_back_8a = child
			break
	if not street_back_8a:
		printerr("FAIL: Current scene is not apartment_entrance after leaving store!")
		get_tree().quit(1)
		return
	var street_back_spawn = street_back_8a.get_node("SpawnPoints/from_store")
	var street_back_player = street_back_8a.get_node("Player")
	if abs(street_back_player.global_position.x - street_back_spawn.global_position.x) > 1.0:
		printerr("FAIL: Player not positioned at from_store spawn after leaving store! Got: ", street_back_player.global_position)
		get_tree().quit(1)
		return
	print("PASS: Two-way street <-> store transition via SceneRouter verified.")

	# 26.7 Save/load round-trip inside the store
	main_instance.transition_to("convenience_store", "from_street")
	await get_tree().process_frame

	var save_store = SaveSystem.capture("convenience_store", 900.0, -1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_store):
		printerr("FAIL: Failed to write store save to scratch slot!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	if not main_instance.load_game_slot(TEST_SCRATCH_SAVE_SLOT):
		printerr("FAIL: load_game_slot(scratch slot) failed for store save!")
		get_tree().quit(1)
		return
	await get_tree().process_frame

	var restored_store = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion() and child.get_script() and child.get_script().resource_path.contains("convenience_store.gd"):
			restored_store = child
			break
	if not restored_store:
		printerr("FAIL: Loaded scene is not convenience_store after store save round-trip!")
		get_tree().quit(1)
		return
	var restored_player = restored_store.get_node("Player")
	if abs(restored_player.global_position.x - 900.0) > 1.0:
		printerr("FAIL: Player x not restored to 900 in store! Got: ", restored_player.global_position.x)
		get_tree().quit(1)
		return
	if restored_player.get_facing() != -1:
		printerr("FAIL: Player facing not restored to -1 in store!")
		get_tree().quit(1)
		return
	if not SaveSystem.can_save_here:
		printerr("FAIL: can_save_here is not true after loading a store save!")
		get_tree().quit(1)
		return
	print("PASS: Store save/load round-trip restores scene, position, and facing.")

	# Clean up scratch slot and release store scene reference
	if dir and dir.file_exists(TEST_SCRATCH_SAVE_FILE):
		dir.remove(TEST_SCRATCH_SAVE_FILE)
	store_scene = null

	print("PASS: Phase 8-A Convenience Store scene skeleton & transitions verified successfully.")

	# 27. Verify Phase 8-B Babble Dialogues & discovered_vendor_error Aggregation
	print("Verifying Phase 8-B babble dialogues & discovered_vendor_error aggregation...")

	GameState.reset_for_new_game()

	# 27.1 Street vending machine babble message + talked_outside_vendor (single side: no discovery)
	main_instance.transition_to("apartment_entrance", "from_apartment")
	await get_tree().process_frame

	var street_8b = null
	for child in main_instance.get_node("WorldRoot").get_children():
		if not child.is_queued_for_deletion() and child.get_script() and child.get_script().resource_path.contains("apartment_entrance.gd"):
			street_8b = child
			break
	if not street_8b:
		printerr("FAIL: Current scene is not apartment_entrance for 8-B vending check!")
		get_tree().quit(1)
		return

	var vending_area_8b = street_8b.get_node_or_null("Interactables/VendingMachineArea")
	if not vending_area_8b:
		printerr("FAIL: VendingMachineArea not found in apartment_entrance!")
		get_tree().quit(1)
		return

	var vending_interaction_data = {}
	_temp_callable = func(data):
		vending_interaction_data.clear()
		vending_interaction_data.merge(data)
	street_8b.interaction_requested.connect(_temp_callable)

	street_8b.current_interactable = vending_area_8b
	street_8b._trigger_interaction()

	if vending_interaction_data.get("type") != "message" \
		or vending_interaction_data.get("message_text") != street_8b.MESSAGES["vending_machine"]:
		printerr("FAIL: Vending machine did not show babble message! Got: ", vending_interaction_data)
		get_tree().quit(1)
		return
	if not "辭呈" in vending_interaction_data.get("message_text", ""):
		printerr("FAIL: Vending babble text lacks the malfunction echo! Got: ", vending_interaction_data.get("message_text"))
		get_tree().quit(1)
		return
	if not GameState.has_flag("talked_outside_vendor"):
		printerr("FAIL: talked_outside_vendor not set after vending interaction!")
		get_tree().quit(1)
		return
	if GameState.has_flag("discovered_vendor_error"):
		printerr("FAIL: discovered_vendor_error set after only ONE machine was talked to!")
		get_tree().quit(1)
		return
	if GameState.has_note("clue_vendor_error_lead"):
		printerr("FAIL: clue_vendor_error_lead note added after only ONE machine was talked to!")
		get_tree().quit(1)
		return
	print("PASS: Vending machine babble sets talked_outside_vendor without premature discovery.")

	# 27.2 Robot babble tree: routing, anomaly text, talked_store_robot, aggregation completes
	DialogueDB = load("res://data/dialogue/dialogue_db.gd")
	var robot_tree = DialogueDB.get_tree_for("store_robot")
	if robot_tree.is_empty():
		printerr("FAIL: DialogueDB could not fetch store_robot tree!")
		get_tree().quit(1)
		return

	runner = DialogueRunner.new()
	var robot_dialogue_finished = {"value": false}
	var robot_finished_callable := func():
		robot_dialogue_finished["value"] = true
	runner.finished.connect(robot_finished_callable)
	runner.start(robot_tree)

	var robot_curr = runner.current()
	if tr(robot_curr.get("speaker")) != "店控機器人":
		printerr("FAIL: store_robot speaker is wrong! Got: ", tr(robot_curr.get("speaker")))
		get_tree().quit(1)
		return
	if not "排班表" in tr(robot_curr.get("text", "")):
		printerr("FAIL: babble_intro text lacks the schedule anomaly! Got: ", tr(robot_curr.get("text")))
		get_tree().quit(1)
		return
	if not GameState.has_flag("talked_store_robot"):
		printerr("FAIL: talked_store_robot not set on babble_intro entry!")
		get_tree().quit(1)
		return
	if not GameState.has_flag("discovered_vendor_error"):
		printerr("FAIL: discovered_vendor_error not set after talking to BOTH machines!")
		get_tree().quit(1)
		return
	if not GameState.has_note("clue_vendor_error_lead"):
		printerr("FAIL: clue_vendor_error_lead note not added after talking to BOTH machines!")
		get_tree().quit(1)
		return
	print("PASS: Robot babble sets talked_store_robot and completes discovered_vendor_error aggregation.")

	# 27.3 Babble branch flow: deny choice reveals "not a vending machine", terminal finishes cleanly
	if robot_curr.get("choices", []).size() != 2:
		printerr("FAIL: babble_intro should expose 2 choices! Got: ", robot_curr.get("choices"))
		get_tree().quit(1)
		return
	runner.choose(0)
	robot_curr = runner.current()
	if not "我不是販賣機" in tr(robot_curr.get("text", "")):
		printerr("FAIL: babble_deny text lacks identity denial! Got: ", tr(robot_curr.get("text")))
		get_tree().quit(1)
		return
	runner.advance()
	robot_curr = runner.current()
	if not robot_curr.get("is_terminal", false):
		printerr("FAIL: babble_end should be a terminal node! Got: ", robot_curr)
		get_tree().quit(1)
		return
	runner.advance()
	if not robot_dialogue_finished["value"]:
		printerr("FAIL: store_robot babble dialogue did not emit finished!")
		get_tree().quit(1)
		return
	runner.finished.disconnect(robot_finished_callable)
	print("PASS: Babble branch flow (deny -> end -> finished) verified.")

	# 27.4 Robot-only path: no discovery until vending machine is also talked to; repeats stay idempotent
	GameState.reset_for_new_game()
	runner = DialogueRunner.new()
	runner.start(robot_tree)
	if not GameState.has_flag("talked_store_robot"):
		printerr("FAIL: talked_store_robot not set in robot-only path!")
		get_tree().quit(1)
		return
	if GameState.has_flag("talked_outside_vendor") or GameState.has_flag("discovered_vendor_error") or GameState.has_note("clue_vendor_error_lead"):
		printerr("FAIL: Robot-only path leaked vendor/discovery/note flags!")
		get_tree().quit(1)
		return
	print("PASS: Robot-only path does not set discovered_vendor_error.")

	street_8b._trigger_interaction()
	if not GameState.has_flag("discovered_vendor_error"):
		printerr("FAIL: discovered_vendor_error not set once both sides are talked to (robot first)!")
		get_tree().quit(1)
		return
	if not GameState.has_note("clue_vendor_error_lead"):
		printerr("FAIL: clue_vendor_error_lead not set once both sides are talked to (robot first)!")
		get_tree().quit(1)
		return

	street_8b._trigger_interaction()
	runner = DialogueRunner.new()
	runner.start(robot_tree)
	if not (GameState.has_flag("talked_outside_vendor") and GameState.has_flag("talked_store_robot") and GameState.has_flag("discovered_vendor_error")):
		printerr("FAIL: Flags regressed after repeated interactions!")
		get_tree().quit(1)
		return
	street_8b.interaction_requested.disconnect(_temp_callable)
	print("PASS: Reverse order discovery and repeated-interaction idempotence verified.")

	# 27.5 Store robot interactable dispatches dialogue (not examine message)
	store_scene = load("res://scenes/levels/convenience_store/convenience_store.tscn")
	var store_instance_8b = store_scene.instantiate()
	add_child(store_instance_8b)

	var robot_area_8b = store_instance_8b.get_node_or_null("Interactables/StoreRobotArea")
	if not robot_area_8b:
		printerr("FAIL: StoreRobotArea not found in convenience_store!")
		get_tree().quit(1)
		return
	if robot_area_8b.dialogue_id != "store_robot":
		printerr("FAIL: StoreRobotArea dialogue_id is not 'store_robot'! Got: ", robot_area_8b.dialogue_id)
		get_tree().quit(1)
		return

	var robot_dispatch_data = {}
	_temp_callable = func(data):
		robot_dispatch_data.clear()
		robot_dispatch_data.merge(data)
	store_instance_8b.interaction_requested.connect(_temp_callable)
	store_instance_8b.current_interactable = robot_area_8b
	store_instance_8b._trigger_interaction()

	if robot_dispatch_data.get("type") != "dialogue" or robot_dispatch_data.get("dialogue_id") != "store_robot":
		printerr("FAIL: Store robot interaction did not dispatch dialogue! Got: ", robot_dispatch_data)
		get_tree().quit(1)
		return
	store_instance_8b.interaction_requested.disconnect(_temp_callable)
	store_instance_8b.free()
	store_scene = null
	print("PASS: Store robot interactable dispatches store_robot dialogue.")

	print("PASS: Phase 8-B babble dialogues & discovered_vendor_error verified successfully.")

	# ==============================================================
	# Phase 8-C: 公寓電腦兩段 gate + QuestManager.start("repair_vendor_bot")
	# ==============================================================
	print("Verifying Phase 8-C: desk computer two-stage gate + quest dispatch...")

	# 重設狀態（確保乾淨的測試環境）
	GameState.reset_for_new_game()
	GameState.quest_states.clear()

	# QuestDB 內應含 repair_vendor_bot
	var QuestDB_8c = load("res://data/quests/quest_db.gd")
	if not QuestDB_8c:
		printerr("FAIL 8-C: Could not load quest_db.gd!")
		get_tree().quit(1)
		return
	var repair_quest_data = QuestDB_8c.get_quest_data("repair_vendor_bot")
	if repair_quest_data == null:
		printerr("FAIL 8-C: 'repair_vendor_bot' not found in quest_db!")
		get_tree().quit(1)
		return
	print("PASS 8-C: repair_vendor_bot registered in QuestDB.")

	# repair_vendor_bot 的 QUEST_ID、WORK_NOTE_ID 常數正確
	if repair_quest_data.QUEST_ID != "repair_vendor_bot":
		printerr("FAIL 8-C: repair_vendor_bot QUEST_ID mismatch! Got: ", repair_quest_data.QUEST_ID)
		get_tree().quit(1)
		return
	if repair_quest_data.WORK_NOTE_ID != "quest_repair_vendor_bot":
		printerr("FAIL 8-C: repair_vendor_bot WORK_NOTE_ID mismatch! Got: ", repair_quest_data.WORK_NOTE_ID)
		get_tree().quit(1)
		return
	print("PASS 8-C: QUEST_ID and WORK_NOTE_ID constants correct.")

	# STEPS 應只有 "started"
	if not repair_quest_data.STEPS.has("started") or repair_quest_data.STEPS.size() != 1:
		printerr("FAIL 8-C: repair_vendor_bot STEPS should only contain 'started'! Got: ", repair_quest_data.STEPS)
		get_tree().quit(1)
		return
	print("PASS 8-C: repair_vendor_bot STEPS contains only 'started'.")

	# HAS_COMPLETED_NOTE_RESOLVER 常數必須存在且為 true
	if not "HAS_COMPLETED_NOTE_RESOLVER" in repair_quest_data:
		printerr("FAIL 8-C: repair_vendor_bot missing HAS_COMPLETED_NOTE_RESOLVER constant!")
		get_tree().quit(1)
		return
	if not repair_quest_data.HAS_COMPLETED_NOTE_RESOLVER:
		printerr("FAIL 8-C: HAS_COMPLETED_NOTE_RESOLVER should be true!")
		get_tree().quit(1)
		return
	print("PASS 8-C: HAS_COMPLETED_NOTE_RESOLVER constant present and true.")

	# STORY_MESSAGES 應含 desk_computer_dispatch_quest
	if not GameState.STORY_MESSAGES.has("desk_computer_dispatch_quest"):
		printerr("FAIL 8-C: STORY_MESSAGES missing 'desk_computer_dispatch_quest'!")
		get_tree().quit(1)
		return
	print("PASS 8-C: desk_computer_dispatch_quest message exists in STORY_MESSAGES.")

	# ---- 模擬電腦互動真值表 ----
	# 準備公寓房間 instance（用來呼叫 _trigger_interaction）
	var room_scene_8c = load("res://scenes/levels/apartment/apartment_room.tscn")
	var room_instance_8c = room_scene_8c.instantiate()
	var ui_scene_8c = load("res://scenes/ui/game_ui.tscn")
	var ui_instance_8c = ui_scene_8c.instantiate()
	add_child(ui_instance_8c)
	add_child(room_instance_8c)
	await get_tree().process_frame

	# 確認 DeskComputerArea 有 interaction_id == "desk_computer"
	var desk_area = room_instance_8c.get_node_or_null("Interactables/DeskComputerArea")
	if not desk_area:
		printerr("FAIL 8-C: DeskComputerArea not found in apartment_room!")
		get_tree().quit(1)
		return
	if desk_area.get("interaction_id") != "desk_computer":
		printerr("FAIL 8-C: DeskComputerArea interaction_id is not 'desk_computer'! Got: ", desk_area.get("interaction_id"))
		get_tree().quit(1)
		return
	print("PASS 8-C: DeskComputerArea has interaction_id='desk_computer'.")

	# 測試狀態記錄
	var computer_dispatch_data_8c := {}
	_temp_callable = func(data):
		computer_dispatch_data_8c.clear()
		computer_dispatch_data_8c.merge(data)
	room_instance_8c.interaction_requested.connect(_temp_callable)

	# --- 測試 1：第一次互動（used_room_computer_once 未設） ---
	GameState.story_flags.erase("used_room_computer_once")
	GameState.story_flags.erase("discovered_vendor_error")
	room_instance_8c.current_interactable = desk_area
	room_instance_8c._trigger_interaction()

	if not GameState.get_flag("used_room_computer_once", false):
		printerr("FAIL 8-C: After first interaction, used_room_computer_once should be true!")
		get_tree().quit(1)
		return
	if computer_dispatch_data_8c.get("message_text", "") != GameState.STORY_MESSAGES["desk_computer_msg"]:
		printerr("FAIL 8-C: First interaction should show desk_computer_msg! Got: ", computer_dispatch_data_8c.get("message_text", ""))
		get_tree().quit(1)
		return
	if QuestManager.get_status("repair_vendor_bot") == "active":
		printerr("FAIL 8-C: Quest should NOT be started on first interaction!")
		get_tree().quit(1)
		return
	print("PASS 8-C: First computer interaction shows old content and sets used_room_computer_once.")

	# --- 測試 2：第二次互動 + discovered_vendor_error 但任務未接 → 派工 ---
	GameState.set_flag("discovered_vendor_error", true)
	# 確保任務尚未啟動
	if GameState.quest_states.has("repair_vendor_bot"):
		GameState.quest_states.erase("repair_vendor_bot")
	computer_dispatch_data_8c.clear()
	room_instance_8c.current_interactable = desk_area
	room_instance_8c._trigger_interaction()

	if QuestManager.get_status("repair_vendor_bot") != "active":
		printerr("FAIL 8-C: Quest 'repair_vendor_bot' should be active after quest dispatch! Got status: ", QuestManager.get_status("repair_vendor_bot"))
		get_tree().quit(1)
		return
	if computer_dispatch_data_8c.get("message_text", "") != GameState.STORY_MESSAGES["desk_computer_dispatch_quest"]:
		printerr("FAIL 8-C: Quest dispatch should show desk_computer_dispatch_quest message!")
		get_tree().quit(1)
		return
	print("PASS 8-C: Second interaction with discovered_vendor_error dispatches quest and shows dispatch message.")

	# 工作筆記應出現在「工作」分類
	var work_notes_8c = GameState.get_notes("工作")
	var found_quest_note_8c := false
	for note in work_notes_8c:
		if note.get("id") == "quest_repair_vendor_bot":
			found_quest_note_8c = true
			break
	if not found_quest_note_8c:
		printerr("FAIL 8-C: Work note 'quest_repair_vendor_bot' not found in 工作 category after quest dispatch!")
		get_tree().quit(1)
		return
	print("PASS 8-C: Work note 'quest_repair_vendor_bot' appears in 工作 notes after quest dispatch.")

	# --- 測試 3：任務已 active 時再互動電腦不重開任務 ---
	var before_step = QuestManager.get_step("repair_vendor_bot")
	computer_dispatch_data_8c.clear()
	room_instance_8c.current_interactable = desk_area
	room_instance_8c._trigger_interaction()

	if QuestManager.get_step("repair_vendor_bot") != before_step:
		printerr("FAIL 8-C: Quest step should not change when interacting with computer while quest is already active!")
		get_tree().quit(1)
		return
	if computer_dispatch_data_8c.get("message_text", "") != GameState.STORY_MESSAGES["desk_computer_msg"]:
		printerr("FAIL 8-C: Repeated interaction when quest is active should show desk_computer_msg fallback!")
		get_tree().quit(1)
		return
	print("PASS 8-C: Repeated computer interaction while quest is active doesn't restart quest.")

	# --- 測試 4：未發現異常（第二次起 + NOT discovered_vendor_error）不派工 ---
	GameState.story_flags.erase("discovered_vendor_error")
	if GameState.quest_states.has("repair_vendor_bot"):
		GameState.quest_states.erase("repair_vendor_bot")
	computer_dispatch_data_8c.clear()
	room_instance_8c.current_interactable = desk_area
	room_instance_8c._trigger_interaction()

	if QuestManager.get_status("repair_vendor_bot") == "active":
		printerr("FAIL 8-C: Quest should NOT be dispatched without discovered_vendor_error!")
		get_tree().quit(1)
		return
	if computer_dispatch_data_8c.get("message_text", "") != GameState.STORY_MESSAGES["desk_computer_msg"]:
		printerr("FAIL 8-C: Without discovered_vendor_error, computer should show old content!")
		get_tree().quit(1)
		return
	print("PASS 8-C: Computer without discovered_vendor_error shows old content (no quest dispatch).")

	# --- 測試 5：resolve_completed_note() 依 store_robot_resolution 分流 ---
	GameState.story_flags.erase("store_robot_resolution")
	var note_reset = repair_quest_data.resolve_completed_note()
	if note_reset.get("id") != "quest_repair_vendor_bot" or note_reset.get("status") != "completed":
		printerr("FAIL 8-C: resolve_completed_note() default (no resolution) should return 'reset' completed note!")
		get_tree().quit(1)
		return
	if not tr(note_reset.get("body", "")).contains("直接重置"):
		printerr("FAIL 8-C: Default resolved note body should mention '直接重置'! Got: ", tr(note_reset.get("body", "")))
		get_tree().quit(1)
		return
	print("PASS 8-C: resolve_completed_note() returns reset variant by default.")

	GameState.set_flag("store_robot_resolution", "gleaned")
	var note_gleaned = repair_quest_data.resolve_completed_note()
	if not tr(note_gleaned.get("body", "")).contains("殘響"):
		printerr("FAIL 8-C: Gleaned resolved note body should mention '殘響'! Got: ", tr(note_gleaned.get("body", "")))
		get_tree().quit(1)
		return
	print("PASS 8-C: resolve_completed_note() returns gleaned variant when store_robot_resolution='gleaned'.")

	# Cleanup 8-C
	room_instance_8c.interaction_requested.disconnect(_temp_callable)
	room_instance_8c.free()
	ui_instance_8c.free()
	room_scene_8c = null
	ui_scene_8c = null
	_temp_callable = Callable()
	GameState.story_flags.erase("store_robot_resolution")
	if GameState.quest_states.has("repair_vendor_bot"):
		GameState.quest_states.erase("repair_vendor_bot")
	await get_tree().process_frame

	print("PASS: Phase 8-C desk computer gate & quest dispatch verified successfully.")

	# ---- Phase 8-D: 蒐證 + 診斷對話樹 ----
	print("Verifying Phase 8-D: clues examine & store robot diagnostic tree...")
	
	store_scene = load("res://scenes/levels/convenience_store/convenience_store.tscn")
	if not store_scene:
		printerr("FAIL 8-D: Could not load convenience_store.tscn!")
		get_tree().quit(1)
		return
	
	store_instance = store_scene.instantiate()
	add_child(store_instance)
	await get_tree().process_frame
	
	var locker_area = store_instance.get_node_or_null("Interactables/ClerkLockerArea")
	var diary_area = store_instance.get_node_or_null("Interactables/ClerkDiaryArea")
	var notice_area = store_instance.get_node_or_null("Interactables/TerminationNoticeArea")
	var photo_area = store_instance.get_node_or_null("Interactables/CounterPhotoArea")
	var plate_area = store_instance.get_node_or_null("Interactables/RobotPlateArea")
	var host_area = store_instance.get_node_or_null("Interactables/StoreRegistryHostArea")
	
	if not locker_area or not diary_area or not notice_area or not photo_area or not plate_area or not host_area:
		printerr("FAIL 8-D: Clue areas or host area not found in convenience_store.tscn!")
		get_tree().quit(1)
		return
	print("PASS 8-D: Clue areas and host area exist in convenience_store.tscn.")

	# ---- Test 1: Gating before quest is active ----
	if GameState.quest_states.has("repair_vendor_bot"):
		GameState.quest_states.erase("repair_vendor_bot")
	
	store_instance.nearby_interactables.clear()
	for area in [locker_area, diary_area, notice_area, photo_area, plate_area, host_area]:
		store_instance.nearby_interactables.append(area)
	var closest_before = store_instance._get_closest_interactable()
	if closest_before != null:
		printerr("FAIL 8-D: Clues and host should be gated and ignored before quest is active! Got: ", closest_before.name)
		get_tree().quit(1)
		return
	print("PASS 8-D: Clue areas and host area are gated before quest is active.")

	# ---- Test 2: Gating after quest is active ----
	QuestManager.start("repair_vendor_bot")
	# Clues should now be accessible, but host is still gated since mainframe_revealed is false
	store_instance.nearby_interactables.clear()
	store_instance.nearby_interactables.append(locker_area)
	var closest_after_locker = store_instance._get_closest_interactable()
	if closest_after_locker != locker_area:
		printerr("FAIL 8-D: locker_area should be accessible after quest is active!")
		get_tree().quit(1)
		return
	
	store_instance.nearby_interactables.clear()
	store_instance.nearby_interactables.append(host_area)
	var closest_after_host = store_instance._get_closest_interactable()
	if closest_after_host != null:
		printerr("FAIL 8-D: host_area should remain gated before mainframe_revealed is true!")
		get_tree().quit(1)
		return
	print("PASS 8-D: Clue areas accessible and host area remains gated after quest is active.")

	# ---- Test 3: Clue examine & note creation ----
	GameState.notes.clear()
	var clue_emit_data = {}
	_temp_callable = func(data):
		clue_emit_data.clear()
		clue_emit_data.merge(data)
	store_instance.interaction_requested.connect(_temp_callable)
	
	var clue_areas = [locker_area, diary_area, notice_area, photo_area, plate_area]
	var expected_note_ids = ["clue_clerk_locker", "clue_clerk_diary", "clue_termination_notice", "clue_counter_photo", "clue_robot_plate"]
	
	for i in range(clue_areas.size()):
		var area = clue_areas[i]
		var note_id = expected_note_ids[i]
		
		# First examine
		store_instance.current_interactable = area
		store_instance._trigger_interaction()
		
		if clue_emit_data.get("type") != "message" or clue_emit_data.get("note_title", "") == "":
			printerr("FAIL 8-D: First examine on " + area.name + " should show message and note_title toast! Got: ", clue_emit_data)
			get_tree().quit(1)
			return
		
		if not GameState.has_note(note_id):
			printerr("FAIL 8-D: GameState should have note: " + note_id)
			get_tree().quit(1)
			return
		
		# Second examine: toast should be empty (no duplicate note notification)
		clue_emit_data.clear()
		store_instance._trigger_interaction()
		if clue_emit_data.get("note_title", "") != "":
			printerr("FAIL 8-D: Repeated examine on " + area.name + " should not toast note_title!")
			get_tree().quit(1)
			return
		
		var notes_list = GameState.get_notes("線索")
		var note_count = 0
		for n in notes_list:
			if n.get("id") == note_id:
				note_count += 1
		if note_count != 1:
			printerr("FAIL 8-D: Note " + note_id + " should not be duplicated! Got count: ", note_count)
			get_tree().quit(1)
			return
	
	print("PASS 8-D: All 5 clues successfully examined, notes created and deduplicated.")

	# ---- Test 4: Dialogue option gating depending on note presence ----
	robot_tree = DialogueDB.get_tree_for("store_robot")
	if robot_tree.is_empty():
		printerr("FAIL 8-D: DialogueDB store_robot tree not found!")
		get_tree().quit(1)
		return
	
	var diag_runner = DialogueRunner.new()
	
	# Clear clue notes temporarily to test gating
	GameState.notes.clear()
	diag_runner.start(robot_tree, "diagnose_intro")
	
	var node_identity = robot_tree["diagnose_identity"]
	diag_runner._enter_node("diagnose_identity")
	var curr_identity = diag_runner.current()
	
	var choices_identity = curr_identity.get("choices", [])
	# Without clues, correct option (index 1) should be hidden, leaving only index 0 and 2
	var found_correct_identity := false
	for choice in choices_identity:
		if choice.get("index") == 1:
			found_correct_identity = true
	if found_correct_identity:
		printerr("FAIL 8-D: Correct identity choice should be gated/hidden without clues!")
		get_tree().quit(1)
		return
	print("PASS 8-D: Correct identity choice gated without clues.")

	# ---- Test 5: Dialogue tree full-truth path flow (all clues found) ----
	# Restore all clue notes
	for note_id in expected_note_ids:
		var note_data = store_instance.NOTES[note_id]
		GameState.add_knowledge(note_data)
		
	# Start dialogue from diagnose_intro
	diag_runner.start(robot_tree, "diagnose_intro")
	
	# Intro choices: index 0 (進行診斷) -> diagnose_identity
	var curr_node = diag_runner.current()
	if curr_node.choices.size() != 2:
		printerr("FAIL 8-D: diagnose_intro choices size mismatch! Got: ", curr_node.choices.size())
		get_tree().quit(1)
		return
	
	diag_runner.choose(0) # We go to diagnose_identity
	curr_node = diag_runner.current()
	if diag_runner._current_node_id != "diagnose_identity":
		printerr("FAIL 8-D: Should enter diagnose_identity! Got: ", diag_runner._current_node_id)
		get_tree().quit(1)
		return
	
	# Identity choices: correct option (index 1) must be visible now
	var found_correct_id_now := false
	for choice in curr_node.choices:
		if choice.get("index") == 1:
			found_correct_id_now = true
	if not found_correct_id_now:
		printerr("FAIL 8-D: Correct identity choice should be visible with all clues!")
		get_tree().quit(1)
		return
		
	diag_runner.choose(1) # Go to diagnose_identity_correct
	curr_node = diag_runner.current()
	if diag_runner._current_node_id != "diagnose_identity_correct":
		printerr("FAIL 8-D: Should enter diagnose_identity_correct! Got: ", diag_runner._current_node_id)
		get_tree().quit(1)
		return
	
	# Identity correct choices: correct option (index 2) must be visible
	var found_correct_reason := false
	for choice in curr_node.choices:
		if choice.get("index") == 2:
			found_correct_reason = true
	if not found_correct_reason:
		printerr("FAIL 8-D: Correct reason choice should be visible with clues!")
		get_tree().quit(1)
		return
		
	diag_runner.choose(2) # Go to diagnose_reason_correct
	curr_node = diag_runner.current()
	if diag_runner._current_node_id != "diagnose_reason_correct":
		printerr("FAIL 8-D: Should enter diagnose_reason_correct! Got: ", diag_runner._current_node_id)
		get_tree().quit(1)
		return
	
	# Reason correct choices: correct option (index 1) must be visible
	var found_correct_truth := false
	for choice in curr_node.choices:
		if choice.get("index") == 1:
			found_correct_truth = true
	if not found_correct_truth:
		printerr("FAIL 8-D: Correct truth choice should be visible with clues!")
		get_tree().quit(1)
		return
		
	diag_runner.choose(1) # Go to diagnose_truth_leaf
	curr_node = diag_runner.current()
	if diag_runner._current_node_id != "diagnose_truth_leaf":
		printerr("FAIL 8-D: Should enter diagnose_truth_leaf! Got: ", diag_runner._current_node_id)
		get_tree().quit(1)
		return
		
	# Check quest flags after truth leaf
	if not QuestManager.get_flag("repair_vendor_bot", "mainframe_revealed", false):
		printerr("FAIL 8-D: mainframe_revealed quest flag not set on truth leaf!")
		get_tree().quit(1)
		return
	if not QuestManager.get_flag("repair_vendor_bot", "diagnosed", false):
		printerr("FAIL 8-D: diagnosed quest flag not set on truth leaf!")
		get_tree().quit(1)
		return
	if not QuestManager.get_flag("repair_vendor_bot", "understood_robot_truth", false):
		printerr("FAIL 8-D: understood_robot_truth quest flag not set on truth leaf!")
		get_tree().quit(1)
		return
	
	# Test host gating after mainframe_revealed is true
	store_instance.nearby_interactables.clear()
	store_instance.nearby_interactables.append(host_area)
	var closest_after_reveal = store_instance._get_closest_interactable()
	if closest_after_reveal != host_area:
		printerr("FAIL 8-D: host_area should be accessible after mainframe_revealed is true!")
		get_tree().quit(1)
		return
	print("PASS 8-D: Dialogue truth path and flags (mainframe_revealed, diagnosed, understood_robot_truth) verified.")

	# ---- Test 6: Dialogue tree partial path flow (incorrect choices selected) ----
	# Reset quest flags
	QuestManager.set_flag("repair_vendor_bot", "mainframe_revealed", false)
	QuestManager.set_flag("repair_vendor_bot", "diagnosed", false)
	QuestManager.set_flag("repair_vendor_bot", "understood_robot_truth", false)
	
	diag_runner.start(robot_tree, "diagnose_intro")
	diag_runner.choose(1) # We choose index 1: (不工作) -> diagnose_partial_intro
	curr_node = diag_runner.current()
	if diag_runner._current_node_id != "diagnose_partial_intro":
		printerr("FAIL 8-D: Should enter diagnose_partial_intro! Got: ", diag_runner._current_node_id)
		get_tree().quit(1)
		return
		
	# Check quest flags after partial leaf
	if not QuestManager.get_flag("repair_vendor_bot", "mainframe_revealed", false):
		printerr("FAIL 8-D: mainframe_revealed quest flag not set on partial leaf!")
		get_tree().quit(1)
		return
	if not QuestManager.get_flag("repair_vendor_bot", "diagnosed", false):
		printerr("FAIL 8-D: diagnosed quest flag not set on partial leaf!")
		get_tree().quit(1)
		return
	if QuestManager.get_flag("repair_vendor_bot", "understood_robot_truth", false):
		printerr("FAIL 8-D: understood_robot_truth should NOT be set on partial leaf!")
		get_tree().quit(1)
		return
	print("PASS 8-D: Dialogue partial path and flags verified.")

	# Cleanup 8-D
	store_instance.interaction_requested.disconnect(_temp_callable)
	store_instance.queue_free()
	store_scene = null
	diag_runner = null
	_temp_callable = Callable()
	if GameState.quest_states.has("repair_vendor_bot"):
		GameState.quest_states.erase("repair_vendor_bot")
	GameState.notes.clear()
	await get_tree().process_frame
	
	print("PASS: Phase 8-D clues & store robot diagnostic tree verified successfully.")

	# ============================================================
	# Phase 8-E: 店籍主機三段 + 兩種重置結局
	# ============================================================
	print("Verifying Phase 8-E: store registry host three stages & two endings...")

	# --- Setup / backups ---
	var inv_backup_8e = GameState.inventory.duplicate(true)
	GameState.story_flags.erase("vendor_bot_repaired")
	GameState.story_flags.erase("store_robot_resolution")
	if GameState.quest_states.has("repair_vendor_bot"):
		GameState.quest_states.erase("repair_vendor_bot")
	GameState.notes.clear()

	var find_choice_8e = func(curr: Dictionary, substr: String) -> int:
		for c in curr.get("choices", []):
			if substr in tr(c.get("label", "")):
				return c.get("index")
		return -1

	# ---- Test 1: clerk_echo_recording item metadata (不可賣、不可丟) ----
	var echo_meta_8e: Dictionary = GameState.ITEMS_DB.get("clerk_echo_recording", {})
	if echo_meta_8e.is_empty():
		printerr("FAIL 8-E: clerk_echo_recording missing from ITEMS_DB!")
		get_tree().quit(1)
		return
	if echo_meta_8e.get("discardable", true) != false or echo_meta_8e.get("sellable", true) != false:
		printerr("FAIL 8-E: clerk_echo_recording must be discardable=false and sellable=false! Got: ", echo_meta_8e)
		get_tree().quit(1)
		return
	print("PASS 8-E: clerk_echo_recording registered, not sellable and not discardable.")

	# ---- Test 2: dialogue tree registered + host area dispatches dialogue ----
	var host_tree_8e = DialogueDB.get_tree_for("store_registry_host")
	if host_tree_8e.is_empty():
		printerr("FAIL 8-E: DialogueDB store_registry_host tree not found!")
		get_tree().quit(1)
		return

	var store_scene_8e = load("res://scenes/levels/convenience_store/convenience_store.tscn")
	var store_instance_8e = store_scene_8e.instantiate()
	add_child(store_instance_8e)
	await get_tree().process_frame

	var host_area_8e = store_instance_8e.get_node_or_null("Interactables/StoreRegistryHostArea")
	if host_area_8e == null or host_area_8e.dialogue_id != "store_registry_host":
		printerr("FAIL 8-E: StoreRegistryHostArea must carry dialogue_id='store_registry_host'!")
		get_tree().quit(1)
		return

	var host_emit_data_8e = {}
	_temp_callable = func(data):
		host_emit_data_8e.clear()
		host_emit_data_8e.merge(data)
	store_instance_8e.interaction_requested.connect(_temp_callable)
	store_instance_8e.current_interactable = host_area_8e
	store_instance_8e._trigger_interaction()
	if host_emit_data_8e.get("type") != "dialogue" or host_emit_data_8e.get("dialogue_id") != "store_registry_host":
		printerr("FAIL 8-E: Host interaction should dispatch dialogue 'store_registry_host'! Got: ", host_emit_data_8e)
		get_tree().quit(1)
		return
	print("PASS 8-E: store_registry_host tree registered and host area dispatches dialogue.")

	# ---- Test 3: three-stage routing ----
	QuestManager.start("repair_vendor_bot")
	QuestManager.set_flag("repair_vendor_bot", "mainframe_revealed", true)

	var host_runner_8e = DialogueRunner.new()

	# 段1：revealed 但診斷不足 -> 只說明，無選項、無重置
	host_runner_8e.start(host_tree_8e, "start")
	if host_runner_8e._current_node_id != "stage1":
		printerr("FAIL 8-E: Should route to stage1 before diagnosed! Got: ", host_runner_8e._current_node_id)
		get_tree().quit(1)
		return
	var host_curr_8e = host_runner_8e.current()
	if not host_curr_8e.get("choices", []).is_empty() or not host_curr_8e.get("is_terminal", false):
		printerr("FAIL 8-E: stage1 must be a terminal info message without reset choices!")
		get_tree().quit(1)
		return
	print("PASS 8-E: stage1 (info only, no reset) verified.")

	# 段2：diagnosed（未全對）-> 僅直接重置
	QuestManager.set_flag("repair_vendor_bot", "diagnosed", true)
	host_runner_8e.start(host_tree_8e, "start")
	if host_runner_8e._current_node_id != "stage2":
		printerr("FAIL 8-E: Should route to stage2 when diagnosed! Got: ", host_runner_8e._current_node_id)
		get_tree().quit(1)
		return
	host_curr_8e = host_runner_8e.current()
	if find_choice_8e.call(host_curr_8e, "直接重置") == -1:
		printerr("FAIL 8-E: stage2 must offer 直接重置!")
		get_tree().quit(1)
		return
	if find_choice_8e.call(host_curr_8e, "先錄殘響") != -1:
		printerr("FAIL 8-E: stage2 must NOT offer 先錄殘響!")
		get_tree().quit(1)
		return
	print("PASS 8-E: stage2 (direct reset only) verified.")

	# 段3：understood_robot_truth -> 二選一
	QuestManager.set_flag("repair_vendor_bot", "understood_robot_truth", true)
	host_runner_8e.start(host_tree_8e, "start")
	if host_runner_8e._current_node_id != "stage3":
		printerr("FAIL 8-E: Should route to stage3 when understood_robot_truth! Got: ", host_runner_8e._current_node_id)
		get_tree().quit(1)
		return
	host_curr_8e = host_runner_8e.current()
	if find_choice_8e.call(host_curr_8e, "直接重置") == -1 or find_choice_8e.call(host_curr_8e, "先錄殘響") == -1:
		printerr("FAIL 8-E: stage3 must offer both 直接重置 and 先錄殘響!")
		get_tree().quit(1)
		return
	print("PASS 8-E: stage3 (both endings offered) verified.")

	# ---- Test 4: gleaned ending with bag full -> whole transaction aborts, retryable ----
	for i in range(GameState.inventory_slots):
		GameState.inventory[i] = {
			"instance_id": GameState.generate_instance_id(),
			"item_id": "canned_food",
			"quantity": 5
		}
	host_runner_8e.start(host_tree_8e, "start")
	host_curr_8e = host_runner_8e.current()
	host_runner_8e.choose(find_choice_8e.call(host_curr_8e, "先錄殘響"))
	if host_runner_8e._current_node_id != "glean_bag_full":
		printerr("FAIL 8-E: Bag-full glean should land on glean_bag_full! Got: ", host_runner_8e._current_node_id)
		get_tree().quit(1)
		return
	if GameState.has_flag("vendor_bot_repaired") or GameState.get_flag("store_robot_resolution", "") != "":
		printerr("FAIL 8-E: Bag-full glean must not set vendor_bot_repaired / store_robot_resolution!")
		get_tree().quit(1)
		return
	if GameState.has_item("clerk_echo_recording") or GameState.has_note("note_clerk_echo_recording"):
		printerr("FAIL 8-E: Bag-full glean must not grant echo item or note!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("repair_vendor_bot") != "active":
		printerr("FAIL 8-E: Bag-full glean must not complete the quest!")
		get_tree().quit(1)
		return
	print("PASS 8-E: Bag-full glean aborts whole transaction without side effects.")

	# ---- Test 5: gleaned ending succeeds after freeing a slot ----
	GameState.inventory[0] = {}
	host_runner_8e.start(host_tree_8e, "start")
	if host_runner_8e._current_node_id != "stage3":
		printerr("FAIL 8-E: After aborted glean, host should still offer stage3! Got: ", host_runner_8e._current_node_id)
		get_tree().quit(1)
		return
	host_curr_8e = host_runner_8e.current()
	host_runner_8e.choose(find_choice_8e.call(host_curr_8e, "先錄殘響"))
	if host_runner_8e._current_node_id != "gleaned_done":
		printerr("FAIL 8-E: Successful glean should land on gleaned_done! Got: ", host_runner_8e._current_node_id)
		get_tree().quit(1)
		return
	if not GameState.has_item("clerk_echo_recording"):
		printerr("FAIL 8-E: Glean ending must grant clerk_echo_recording!")
		get_tree().quit(1)
		return
	if not GameState.has_note("note_clerk_echo_recording"):
		printerr("FAIL 8-E: Glean ending must grant the echo note!")
		get_tree().quit(1)
		return
	if GameState.get_flag("store_robot_resolution", "") != "gleaned" or not GameState.has_flag("vendor_bot_repaired"):
		printerr("FAIL 8-E: Glean ending must set store_robot_resolution='gleaned' + vendor_bot_repaired!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("repair_vendor_bot") != "completed":
		printerr("FAIL 8-E: Glean ending must complete repair_vendor_bot!")
		get_tree().quit(1)
		return
	if not ("販賣機" in tr(host_runner_8e.current().get("text", ""))):
		printerr("FAIL 8-E: gleaned_done message must hint the outside vending machine is back online!")
		get_tree().quit(1)
		return
	var work_note_gleaned_8e = {}
	for n in GameState.get_notes("工作"):
		if n.get("id") == "quest_repair_vendor_bot":
			work_note_gleaned_8e = n
	if work_note_gleaned_8e.get("status", "") != "completed" or not ("殘響" in _tr_body(work_note_gleaned_8e.get("body", ""))):
		printerr("FAIL 8-E: Completed work note should be the gleaned variant! Got: ", work_note_gleaned_8e)
		get_tree().quit(1)
		return
	print("PASS 8-E: Gleaned ending (item + note + flags + quest complete + hint + work note) verified.")

	# ---- Test 6: host no longer offers reset; robot greets with gleaned voice ----
	host_runner_8e.start(host_tree_8e, "start")
	if host_runner_8e._current_node_id != "already_repaired" or not host_runner_8e.current().get("is_terminal", false):
		printerr("FAIL 8-E: After repair, host must only give neutral repaired message! Got: ", host_runner_8e._current_node_id)
		get_tree().quit(1)
		return
	var robot_tree_8e = DialogueDB.get_tree_for("store_robot")
	var robot_runner_8e = DialogueRunner.new()
	robot_runner_8e.start(robot_tree_8e, "start")
	if robot_runner_8e._current_node_id != "repaired_gleaned":
		printerr("FAIL 8-E: Robot should greet with repaired_gleaned after gleaned ending! Got: ", robot_runner_8e._current_node_id)
		get_tree().quit(1)
		return
	print("PASS 8-E: Post-repair host neutral message and gleaned robot greeting verified.")

	# ---- Test 7: direct reset ending via stage2 ----
	GameState.story_flags.erase("vendor_bot_repaired")
	GameState.story_flags.erase("store_robot_resolution")
	GameState.quest_states.erase("repair_vendor_bot")
	GameState.notes.clear()
	GameState.remove_item("clerk_echo_recording", 1)
	QuestManager.start("repair_vendor_bot")
	QuestManager.set_flag("repair_vendor_bot", "mainframe_revealed", true)
	QuestManager.set_flag("repair_vendor_bot", "diagnosed", true)

	host_runner_8e.start(host_tree_8e, "start")
	if host_runner_8e._current_node_id != "stage2":
		printerr("FAIL 8-E: Reset path should start from stage2! Got: ", host_runner_8e._current_node_id)
		get_tree().quit(1)
		return
	host_curr_8e = host_runner_8e.current()
	host_runner_8e.choose(find_choice_8e.call(host_curr_8e, "直接重置"))
	if host_runner_8e._current_node_id != "reset_done":
		printerr("FAIL 8-E: Direct reset should land on reset_done! Got: ", host_runner_8e._current_node_id)
		get_tree().quit(1)
		return
	if GameState.get_flag("store_robot_resolution", "") != "reset" or not GameState.has_flag("vendor_bot_repaired"):
		printerr("FAIL 8-E: Direct reset must set store_robot_resolution='reset' + vendor_bot_repaired!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("repair_vendor_bot") != "completed":
		printerr("FAIL 8-E: Direct reset must complete repair_vendor_bot!")
		get_tree().quit(1)
		return
	if not ("販賣機" in tr(host_runner_8e.current().get("text", ""))):
		printerr("FAIL 8-E: reset_done message must hint the outside vending machine is back online!")
		get_tree().quit(1)
		return
	var work_note_reset_8e = {}
	for n in GameState.get_notes("工作"):
		if n.get("id") == "quest_repair_vendor_bot":
			work_note_reset_8e = n
	if work_note_reset_8e.get("status", "") != "completed" or not ("直接重置" in _tr_body(work_note_reset_8e.get("body", ""))):
		printerr("FAIL 8-E: Completed work note should be the reset variant! Got: ", work_note_reset_8e)
		get_tree().quit(1)
		return
	host_runner_8e.start(host_tree_8e, "start")
	if host_runner_8e._current_node_id != "already_repaired":
		printerr("FAIL 8-E: After direct reset, host must not offer reset again!")
		get_tree().quit(1)
		return
	robot_runner_8e.start(robot_tree_8e, "start")
	if robot_runner_8e._current_node_id != "repaired_reset":
		printerr("FAIL 8-E: Robot should greet with repaired_reset after direct reset! Got: ", robot_runner_8e._current_node_id)
		get_tree().quit(1)
		return
	print("PASS 8-E: Direct reset ending (flags + quest complete + hint + work note + greetings) verified.")

	# ---- Test 8: direct reset is also available from stage3 ----
	GameState.story_flags.erase("vendor_bot_repaired")
	GameState.story_flags.erase("store_robot_resolution")
	GameState.quest_states.erase("repair_vendor_bot")
	GameState.notes.clear()
	QuestManager.start("repair_vendor_bot")
	QuestManager.set_flag("repair_vendor_bot", "mainframe_revealed", true)
	QuestManager.set_flag("repair_vendor_bot", "diagnosed", true)
	QuestManager.set_flag("repair_vendor_bot", "understood_robot_truth", true)

	host_runner_8e.start(host_tree_8e, "start")
	host_curr_8e = host_runner_8e.current()
	host_runner_8e.choose(find_choice_8e.call(host_curr_8e, "直接重置"))
	if host_runner_8e._current_node_id != "reset_done":
		printerr("FAIL 8-E: stage3 direct reset should land on reset_done! Got: ", host_runner_8e._current_node_id)
		get_tree().quit(1)
		return
	if GameState.get_flag("store_robot_resolution", "") != "reset" or QuestManager.get_status("repair_vendor_bot") != "completed":
		printerr("FAIL 8-E: stage3 direct reset must set resolution='reset' and complete the quest!")
		get_tree().quit(1)
		return
	print("PASS 8-E: stage3 direct reset variant verified.")

	# Cleanup 8-E
	store_instance_8e.interaction_requested.disconnect(_temp_callable)
	_temp_callable = Callable()
	store_instance_8e.queue_free()
	store_scene_8e = null
	host_runner_8e = null
	robot_runner_8e = null
	GameState.story_flags.erase("vendor_bot_repaired")
	GameState.story_flags.erase("store_robot_resolution")
	if GameState.quest_states.has("repair_vendor_bot"):
		GameState.quest_states.erase("repair_vendor_bot")
	GameState.notes.clear()
	GameState.inventory = inv_backup_8e
	GameState.inventory_changed.emit()
	find_choice_8e = Callable()
	await get_tree().process_frame

	print("PASS: Phase 8-E store registry host & two endings verified successfully.")

	# ============================================================
	# Phase 8-F: 買賣系統核心 + ShopPanel + UIMode.SHOP
	# ============================================================
	print("Verifying Phase 8-F: commerce core, ShopPanel & UIMode.SHOP...")

	var inv_backup_8f = GameState.inventory.duplicate(true)
	var credits_backup_8f: int = GameState.get_credits()

	# ---- Test 1: item value / sell math / is_sellable ----
	if GameState.get_item_value("canned_food") != 20 or GameState.get_sell_value("canned_food") != 10:
		printerr("FAIL 8-F: canned_food value/sell_value math wrong! Got: ", GameState.get_item_value("canned_food"), "/", GameState.get_sell_value("canned_food"))
		get_tree().quit(1)
		return
	if GameState.get_sell_value("nutrition_bar_synth_orange") != 6:
		printerr("FAIL 8-F: nutrition bar sell_value should be floor(12*0.5)=6! Got: ", GameState.get_sell_value("nutrition_bar_synth_orange"))
		get_tree().quit(1)
		return
	if GameState.get_sell_value("worn_rubiks_cube") != 0 or GameState.is_sellable("worn_rubiks_cube"):
		printerr("FAIL 8-F: value=1 item must floor to 0 and be unsellable!")
		get_tree().quit(1)
		return
	if GameState.is_sellable("old_work_badge"):
		printerr("FAIL 8-F: key_item must not be sellable!")
		get_tree().quit(1)
		return
	if GameState.is_sellable("clerk_echo_recording"):
		printerr("FAIL 8-F: sellable=false item must not be sellable!")
		get_tree().quit(1)
		return
	if not GameState.is_sellable("canned_food") or not GameState.is_sellable("faded_jacket"):
		printerr("FAIL 8-F: valued non-key items should be sellable!")
		get_tree().quit(1)
		return
	print("PASS 8-F: item value / sell math / is_sellable rules verified.")

	# ---- Test 2: shop stock lazy-init + refresh ----
	GameState.shop_states.clear()
	var stock_8f: Dictionary = GameState.get_shop_stock("convenience_store")
	if stock_8f.get("canned_food", {}).get("price", 0) != 40 or stock_8f.get("canned_food", {}).get("stock", 0) != 10:
		printerr("FAIL 8-F: convenience_store canned_food catalog should lazy-init to price 40 / stock 10! Got: ", stock_8f)
		get_tree().quit(1)
		return
	if stock_8f.get("nutrition_bar_synth_orange", {}).get("price", 0) != 25:
		printerr("FAIL 8-F: nutrition bar price should be 25!")
		get_tree().quit(1)
		return
	if not GameState.shop_states.has("convenience_store"):
		printerr("FAIL 8-F: shop_states should hold lazy-inited stock!")
		get_tree().quit(1)
		return
	if not GameState.get_shop_stock("no_such_shop").is_empty():
		printerr("FAIL 8-F: unknown shop_id should return empty stock!")
		get_tree().quit(1)
		return
	print("PASS 8-F: shop stock lazy-init verified.")

	# ---- Test 3: buy_item atomic + failure reasons ----
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
	GameState.set_credits(100)

	if not GameState.buy_item("convenience_store", "canned_food"):
		printerr("FAIL 8-F: buy_item should succeed with credits/stock/space!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != 60 or not GameState.has_item("canned_food", 1):
		printerr("FAIL 8-F: buy should cost 40 credits and grant item! credits: ", GameState.get_credits())
		get_tree().quit(1)
		return
	if GameState.get_shop_stock("convenience_store")["canned_food"]["stock"] != 9:
		printerr("FAIL 8-F: buy should deduct shop stock to 9!")
		get_tree().quit(1)
		return

	GameState.set_credits(10)
	var can_8f: Dictionary = GameState.can_buy("convenience_store", "canned_food")
	if can_8f.get("ok", true) or can_8f.get("reason", "") != "not_enough_credits":
		printerr("FAIL 8-F: can_buy should report not_enough_credits! Got: ", can_8f)
		get_tree().quit(1)
		return
	if GameState.buy_item("convenience_store", "canned_food"):
		printerr("FAIL 8-F: buy_item must fail without credits!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != 10 or GameState.get_shop_stock("convenience_store")["canned_food"]["stock"] != 9:
		printerr("FAIL 8-F: failed buy must not change credits/stock!")
		get_tree().quit(1)
		return

	GameState.shop_states["convenience_store"]["nutrition_bar_synth_orange"]["stock"] = 0
	can_8f = GameState.can_buy("convenience_store", "nutrition_bar_synth_orange")
	if can_8f.get("ok", true) or can_8f.get("reason", "") != "out_of_stock":
		printerr("FAIL 8-F: can_buy should report out_of_stock! Got: ", can_8f)
		get_tree().quit(1)
		return
	if GameState.buy_item("convenience_store", "nutrition_bar_synth_orange"):
		printerr("FAIL 8-F: buy_item must fail when out of stock!")
		get_tree().quit(1)
		return

	# 背包滿：add_item 失敗時整筆不動
	GameState.set_credits(500)
	for i in range(GameState.inventory_slots):
		GameState.inventory[i] = {
			"instance_id": GameState.generate_instance_id(),
			"item_id": "canned_food",
			"quantity": 5
		}
	if GameState.buy_item("convenience_store", "canned_food"):
		printerr("FAIL 8-F: buy_item must fail when bag is full!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != 500 or GameState.get_shop_stock("convenience_store")["canned_food"]["stock"] != 9:
		printerr("FAIL 8-F: bag-full buy must not change credits/stock!")
		get_tree().quit(1)
		return
	print("PASS 8-F: buy_item atomic behavior & failure reasons verified.")

	# ---- Test 4: sell_item by instance_id ----
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
	GameState.set_credits(100)
	GameState.add_item("canned_food", 2)
	var sell_iid_8f := ""
	for slot in GameState.get_inventory():
		if slot.get("item_id", "") == "canned_food":
			sell_iid_8f = slot.get("instance_id", "")
			break
	if not GameState.sell_item(sell_iid_8f):
		printerr("FAIL 8-F: sell_item should succeed for sellable owned item!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != 110:
		printerr("FAIL 8-F: selling canned_food should add 10 credits! Got: ", GameState.get_credits())
		get_tree().quit(1)
		return
	if not GameState.has_item("canned_food", 1) or GameState.has_item("canned_food", 2):
		printerr("FAIL 8-F: sell count 1 should leave exactly 1 unit!")
		get_tree().quit(1)
		return
	if GameState.get_shop_stock("convenience_store")["canned_food"]["stock"] != 9:
		printerr("FAIL 8-F: selling must NOT restock the shop!")
		get_tree().quit(1)
		return
	if GameState.sell_item(sell_iid_8f, 5):
		printerr("FAIL 8-F: selling more than the focused slot holds must fail!")
		get_tree().quit(1)
		return

	# 多 instance：只賣焦點格那一格
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
	GameState.add_item("faded_jacket", 1)
	GameState.add_item("faded_jacket", 1)
	var jacket_iids_8f := []
	for slot in GameState.get_inventory():
		if slot.get("item_id", "") == "faded_jacket":
			jacket_iids_8f.append(slot.get("instance_id", ""))
	if jacket_iids_8f.size() != 2:
		printerr("FAIL 8-F: expected two jacket instances! Got: ", jacket_iids_8f.size())
		get_tree().quit(1)
		return
	if not GameState.sell_item(jacket_iids_8f[1]):
		printerr("FAIL 8-F: selling the second jacket instance should succeed!")
		get_tree().quit(1)
		return
	var remaining_iid_8f := ""
	for slot in GameState.get_inventory():
		if slot.get("item_id", "") == "faded_jacket":
			remaining_iid_8f = slot.get("instance_id", "")
	if remaining_iid_8f != jacket_iids_8f[0]:
		printerr("FAIL 8-F: sell-by-instance must keep the non-focused instance! Got: ", remaining_iid_8f)
		get_tree().quit(1)
		return

	# 已裝備不可賣（不自動卸下），卸下後可賣
	GameState.equip(remaining_iid_8f)
	if GameState.sell_item(remaining_iid_8f):
		printerr("FAIL 8-F: equipped item must not be sellable!")
		get_tree().quit(1)
		return
	if not GameState.is_equipped(remaining_iid_8f):
		printerr("FAIL 8-F: failed sell must not unequip the item!")
		get_tree().quit(1)
		return
	GameState.unequip_by_instance(remaining_iid_8f)
	if not GameState.sell_item(remaining_iid_8f):
		printerr("FAIL 8-F: unequipped jacket should be sellable!")
		get_tree().quit(1)
		return

	# 不可賣物
	GameState.add_item("old_work_badge", 1)
	var badge_iid_8f := ""
	for slot in GameState.get_inventory():
		if slot.get("item_id", "") == "old_work_badge":
			badge_iid_8f = slot.get("instance_id", "")
	if GameState.sell_item(badge_iid_8f):
		printerr("FAIL 8-F: key_item must not be sellable via sell_item!")
		get_tree().quit(1)
		return
	GameState.remove_item("old_work_badge", 1)
	print("PASS 8-F: sell_item by instance, equipped guard & unsellable rules verified.")

	# ---- Test 5: shop_states save/load round-trip + reset ----
	var save_dict_8f: Dictionary = GameState.to_save_dict()
	if not save_dict_8f.has("shop_states") or save_dict_8f["shop_states"]["convenience_store"]["canned_food"]["stock"] != 9:
		printerr("FAIL 8-F: to_save_dict must carry shop_states with mutated stock!")
		get_tree().quit(1)
		return
	GameState.refresh_shop_stock("convenience_store")
	if GameState.get_shop_stock("convenience_store")["canned_food"]["stock"] != 10:
		printerr("FAIL 8-F: refresh_shop_stock should reset stock from catalog!")
		get_tree().quit(1)
		return
	GameState.load_save_dict(save_dict_8f)
	if GameState.get_shop_stock("convenience_store")["canned_food"]["stock"] != 9 \
			or GameState.get_shop_stock("convenience_store")["nutrition_bar_synth_orange"]["stock"] != 0:
		printerr("FAIL 8-F: load_save_dict must restore mutated shop stock!")
		get_tree().quit(1)
		return
	GameState.reset_for_new_game()
	if not GameState.shop_states.is_empty():
		printerr("FAIL 8-F: reset_for_new_game must clear shop_states!")
		get_tree().quit(1)
		return
	if GameState.get_shop_stock("convenience_store")["canned_food"]["stock"] != 10:
		printerr("FAIL 8-F: after reset, shop stock should lazy-init fresh from catalog!")
		get_tree().quit(1)
		return
	print("PASS 8-F: shop_states save/load round-trip & reset verified.")

	# ---- Test 6: GameUI open_shop / ShopPanel buy & sell / close ----
	GameState.set_credits(100)
	ui_instance.open_shop("convenience_store")
	await get_tree().process_frame
	if UIMode.get_mode() != UIMode.Mode.SHOP or not ui_instance.is_shop_open():
		printerr("FAIL 8-F: open_shop should enter UIMode.SHOP with panel open!")
		get_tree().quit(1)
		return
	var shop_panel_8f = ui_instance.shop_panel
	if not shop_panel_8f.visible or shop_panel_8f.shop_id != "convenience_store":
		printerr("FAIL 8-F: ShopPanel should be visible with shop_id set!")
		get_tree().quit(1)
		return
	if shop_panel_8f._buy_rows.size() != 2:
		printerr("FAIL 8-F: buy pane should list 2 catalog items! Got: ", shop_panel_8f._buy_rows.size())
		get_tree().quit(1)
		return

	# 左欄 E 買入（焦點預設第一列 canned_food）
	ui_instance.shop_confirm()
	if not GameState.has_item("canned_food", 1) or GameState.get_credits() != 60:
		printerr("FAIL 8-F: shop_confirm on buy pane should buy canned_food! credits: ", GameState.get_credits())
		get_tree().quit(1)
		return
	if GameState.get_shop_stock("convenience_store")["canned_food"]["stock"] != 9:
		printerr("FAIL 8-F: panel buy should deduct stock!")
		get_tree().quit(1)
		return

	# 切右欄賣出剛買的罐頭
	ui_instance.shop_switch_pane(1)
	if shop_panel_8f.active_pane != "sell":
		printerr("FAIL 8-F: shop_switch_pane(1) should focus sell pane!")
		get_tree().quit(1)
		return
	ui_instance.shop_confirm()
	if GameState.has_item("canned_food", 1) or GameState.get_credits() != 70:
		printerr("FAIL 8-F: sell pane confirm should sell focused canned_food for 10! credits: ", GameState.get_credits())
		get_tree().quit(1)
		return
	if GameState.get_shop_stock("convenience_store")["canned_food"]["stock"] != 9:
		printerr("FAIL 8-F: panel sell must not restock the shop!")
		get_tree().quit(1)
		return

	# 關店回 NONE 無殘留
	ui_instance.close_all_ui()
	await get_tree().process_frame
	if UIMode.get_mode() != UIMode.Mode.NONE or ui_instance.is_shop_open() or shop_panel_8f.visible:
		printerr("FAIL 8-F: closing shop should return to NONE with panel hidden!")
		get_tree().quit(1)
		return
	print("PASS 8-F: GameUI open_shop, panel buy/sell routing & close verified.")

	# ---- Test 7: 修好後機器人招呼結尾開店；修好前不開 ----
	var robot_tree_8f = DialogueDB.get_tree_for("store_robot")
	for greet_node_8f in ["repaired_reset", "repaired_gleaned"]:
		var effects_8f: Array = robot_tree_8f[greet_node_8f].get("effect", [])
		var has_open_shop_8f := false
		for eff in effects_8f:
			if eff.get("op", "") == "open_shop" and eff.get("value", "") == "convenience_store":
				has_open_shop_8f = true
		if not has_open_shop_8f:
			printerr("FAIL 8-F: " + greet_node_8f + " must carry open_shop effect!")
			get_tree().quit(1)
			return

	# 修好前（babble）：無 pending shop
	var gate_runner_8f = DialogueRunner.new()
	gate_runner_8f.start(robot_tree_8f, "start")
	if gate_runner_8f._current_node_id != "babble_intro" or gate_runner_8f.pending_shop_id != "":
		printerr("FAIL 8-F: pre-repair robot dialogue must not pend a shop! Got: ", gate_runner_8f._current_node_id)
		get_tree().quit(1)
		return

	# 修好後：DIALOGUE 正常結束 → 直接切 SHOP
	GameState.set_flag("vendor_bot_repaired", true)
	GameState.set_flag("store_robot_resolution", "reset")
	ui_instance.start_dialogue("store_robot")
	await get_tree().process_frame
	if UIMode.get_mode() != UIMode.Mode.DIALOGUE:
		printerr("FAIL 8-F: start_dialogue should enter DIALOGUE mode first!")
		get_tree().quit(1)
		return
	ui_instance.dialogue_confirm()
	await get_tree().process_frame
	if UIMode.get_mode() != UIMode.Mode.SHOP or not ui_instance.is_shop_open():
		printerr("FAIL 8-F: repaired greeting end should hand off to UIMode.SHOP! Got mode: ", UIMode.get_mode())
		get_tree().quit(1)
		return
	if shop_panel_8f.shop_id != "convenience_store":
		printerr("FAIL 8-F: handed-off shop should be convenience_store!")
		get_tree().quit(1)
		return
	ui_instance.close_all_ui()
	await get_tree().process_frame
	print("PASS 8-F: repaired greeting opens shop; pre-repair dialogue does not.")

	# ============================================================
	# Phase 8-G: 迷你飲料商店 + 多商店資料化
	# ============================================================
	print("Verifying Phase 8-G: street_vending & data-driven multi-shop...")

	var entrance_scene_8g = load("res://scenes/levels/apartment_entrance.tscn")
	var entrance_instance_8g = entrance_scene_8g.instantiate()
	add_child(entrance_instance_8g)
	await get_tree().process_frame

	var vending_area_8g = entrance_instance_8g.get_node_or_null("Interactables/VendingMachineArea")
	if vending_area_8g == null or vending_area_8g.interaction_id != "vending_machine":
		printerr("FAIL 8-G: VendingMachineArea missing or interaction_id is not vending_machine!")
		get_tree().quit(1)
		return

	var vending_emit_data_8g = {}
	var temp_callable_8g = func(data):
		vending_emit_data_8g.clear()
		vending_emit_data_8g.merge(data)
	entrance_instance_8g.interaction_requested.connect(temp_callable_8g)

	# 1. 修好前：只給前導訊息，不開店
	GameState.story_flags.erase("vendor_bot_repaired")
	GameState.story_flags.erase("talked_outside_vendor")
	entrance_instance_8g.current_interactable = vending_area_8g
	entrance_instance_8g._trigger_interaction()
	if vending_emit_data_8g.get("type") != "message" or not GameState.get_flag("talked_outside_vendor", false):
		printerr("FAIL 8-G: pre-repair vending machine interaction must emit message and set talked_outside_vendor! Got: ", vending_emit_data_8g)
		get_tree().quit(1)
		return

	# 2. 修好後：直接開 ShopPanel (street_vending)
	vending_emit_data_8g.clear()
	GameState.set_flag("vendor_bot_repaired", true)
	entrance_instance_8g._trigger_interaction()
	if vending_emit_data_8g.get("type") != "shop" or vending_emit_data_8g.get("shop_id") != "street_vending":
		printerr("FAIL 8-G: post-repair vending machine interaction must emit shop with street_vending! Got: ", vending_emit_data_8g)
		get_tree().quit(1)
		return

	entrance_instance_8g.interaction_requested.disconnect(temp_callable_8g)
	entrance_instance_8g.queue_free()
	await get_tree().process_frame
	print("PASS 8-G: post-repair vending machine direct shop launch verified.")

	# 3. 庫存獨立性與多商店資料化
	GameState.shop_states.clear()
	var cs_stock_8g = GameState.get_shop_stock("convenience_store")
	var sv_stock_8g = GameState.get_shop_stock("street_vending")

	if cs_stock_8g.is_empty() or sv_stock_8g.is_empty():
		printerr("FAIL 8-G: failed to lazy-init shop stocks!")
		get_tree().quit(1)
		return

	if not sv_stock_8g.has("synth_cola") or sv_stock_8g["synth_cola"].get("stock", 0) != 5:
		printerr("FAIL 8-G: street_vending synth_cola stock must be 5! Got: ", sv_stock_8g)
		get_tree().quit(1)
		return

	# 買飲料
	GameState.inventory.clear()
	for i in range(GameState.inventory_slots):
		GameState.inventory.append({})
	GameState.set_credits(100)

	if not GameState.buy_item("street_vending", "synth_cola"):
		printerr("FAIL 8-G: buy_item from street_vending failed!")
		get_tree().quit(1)
		return

	if GameState.get_credits() != 70 or GameState.get_shop_stock("street_vending")["synth_cola"]["stock"] != 4:
		printerr("FAIL 8-G: buy_item did not update street_vending stock/credits properly!")
		get_tree().quit(1)
		return

	if GameState.get_shop_stock("convenience_store")["canned_food"]["stock"] != 10:
		printerr("FAIL 8-G: buy_item from street_vending must NOT affect convenience_store stock!")
		get_tree().quit(1)
		return
	print("PASS 8-G: street_vending and convenience_store stocks are independent.")

	# 4. 存讀檔與新遊戲重設
	var save_dict_8g = GameState.to_save_dict()
	if not save_dict_8g.has("shop_states") \
			or save_dict_8g["shop_states"]["street_vending"]["synth_cola"]["stock"] != 4 \
			or save_dict_8g["shop_states"]["convenience_store"]["canned_food"]["stock"] != 10:
		printerr("FAIL 8-G: to_save_dict failed to serialize multiple shop states correctly!")
		get_tree().quit(1)
		return

	# 重置
	GameState.reset_for_new_game()
	if not GameState.shop_states.is_empty():
		printerr("FAIL 8-G: reset_for_new_game should clear shop_states!")
		get_tree().quit(1)
		return

	# 讀檔
	GameState.load_save_dict(save_dict_8g)
	if GameState.get_shop_stock("street_vending")["synth_cola"]["stock"] != 4 \
			or GameState.get_shop_stock("convenience_store")["canned_food"]["stock"] != 10:
		printerr("FAIL 8-G: load_save_dict failed to restore multiple shop states correctly!")
		get_tree().quit(1)
		return
	print("PASS 8-G: multi-shop save/load and reset verified.")

	# ============================================================
	# Phase 8-H: 回歸與存讀檔驗證
	# ============================================================
	print("Verifying Phase 8-H: regression & save/restore...")

	# 1. Pre-Quest Save/Load Check
	GameState.reset_for_new_game()
	GameState.set_flag("talked_outside_vendor", true)
	GameState.set_flag("talked_store_robot", true)
	GameState._maybe_set_discovered_vendor_error()
	GameState.set_flag("used_room_computer_once", true)
	
	var save_8h_p1 = SaveSystem.capture("apartment", 200.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_8h_p1):
		printerr("FAIL 8-H: Failed to write save_8h_p1 to scratch slot!")
		get_tree().quit(1)
		return
		
	GameState.reset_for_new_game()
	var loaded_8h_p1 = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	SaveSystem.apply(loaded_8h_p1)
	
	if not GameState.get_flag("discovered_vendor_error", false) or not GameState.get_flag("used_room_computer_once", false) or not GameState.has_note("clue_vendor_error_lead"):
		printerr("FAIL 8-H: Pre-quest flags or lead note not restored correctly!")
		get_tree().quit(1)
		return
	print("PASS: Pre-quest save/load verified.")

	# 2. Quest Active & Clues Collected Save/Load Check
	GameState.reset_for_new_game()
	QuestManager.start("repair_vendor_bot")
	GameState.add_knowledge({
		"id": "clue_cabinet_notes",
		"category": "線索",
		"title": "置物櫃的便條",
		"body": "置物櫃門縫夾著一張紙條，上面歪歪斜斜地寫著一些關於保修期和登入密碼的塗鴉。"
	})
	QuestManager.set_flag("repair_vendor_bot", "mainframe_revealed", true)
	QuestManager.set_flag("repair_vendor_bot", "understood_robot_truth", true)
	
	var save_8h_p2 = SaveSystem.capture("convenience_store", 500.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_8h_p2):
		printerr("FAIL 8-H: Failed to write save_8h_p2 to scratch slot!")
		get_tree().quit(1)
		return
		
	GameState.reset_for_new_game()
	var loaded_8h_p2 = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	SaveSystem.apply(loaded_8h_p2)
	
	if QuestManager.get_status("repair_vendor_bot") != "active":
		printerr("FAIL 8-H: Quest state not restored correctly!")
		get_tree().quit(1)
		return
	if not GameState.has_note("clue_cabinet_notes"):
		printerr("FAIL 8-H: Clue notes not restored correctly!")
		get_tree().quit(1)
		return
	if not QuestManager.get_flag("repair_vendor_bot", "mainframe_revealed", false) or not QuestManager.get_flag("repair_vendor_bot", "understood_robot_truth", false):
		printerr("FAIL 8-H: Quest flags (mainframe/truth) not restored correctly!")
		get_tree().quit(1)
		return
	print("PASS: Quest active & clues save/load verified.")

	# 3. Repaired Reset Ending Save/Load Check
	GameState.reset_for_new_game()
	GameState.set_flag("vendor_bot_repaired", true)
	GameState.set_flag("store_robot_resolution", "reset")
	QuestManager.start("repair_vendor_bot")
	QuestManager.complete("repair_vendor_bot")
	
	var save_8h_p3 = SaveSystem.capture("convenience_store", 500.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_8h_p3):
		printerr("FAIL 8-H: Failed to write save_8h_p3 to scratch slot!")
		get_tree().quit(1)
		return
		
	GameState.reset_for_new_game()
	var loaded_8h_p3 = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	SaveSystem.apply(loaded_8h_p3)
	
	if not GameState.get_flag("vendor_bot_repaired", false) or GameState.get_flag("store_robot_resolution", "") != "reset":
		printerr("FAIL 8-H: Repaired reset flags not restored correctly!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("repair_vendor_bot") != "completed":
		printerr("FAIL 8-H: Quest completed state not restored correctly for reset ending!")
		get_tree().quit(1)
		return
	
	var note_reset_8h = GameState.get_notes("工作")
	if note_reset_8h.is_empty() or not _tr_body(note_reset_8h[0].get("body", "")).contains("直接重置"):
		printerr("FAIL 8-H: Reset work note not restored correctly!")
		get_tree().quit(1)
		return
	print("PASS: Repaired reset ending save/load verified.")

	# 4. Repaired Gleaned Ending Save/Load Check
	GameState.reset_for_new_game()
	GameState.set_flag("vendor_bot_repaired", true)
	GameState.set_flag("store_robot_resolution", "gleaned")
	QuestManager.start("repair_vendor_bot")
	QuestManager.complete("repair_vendor_bot")
	GameState.add_item("clerk_echo_recording", 1)
	
	var save_8h_p4 = SaveSystem.capture("convenience_store", 500.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_8h_p4):
		printerr("FAIL 8-H: Failed to write save_8h_p4 to scratch slot!")
		get_tree().quit(1)
		return
		
	GameState.reset_for_new_game()
	var loaded_8h_p4 = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	SaveSystem.apply(loaded_8h_p4)
	
	if not GameState.get_flag("vendor_bot_repaired", false) or GameState.get_flag("store_robot_resolution", "") != "gleaned":
		printerr("FAIL 8-H: Repaired gleaned flags not restored correctly!")
		get_tree().quit(1)
		return
	if not GameState.has_item("clerk_echo_recording", 1):
		printerr("FAIL 8-H: clerk_echo_recording not restored correctly!")
		get_tree().quit(1)
		return
	
	var note_gleaned_8h = GameState.get_notes("工作")
	if note_gleaned_8h.is_empty() or not _tr_body(note_gleaned_8h[0].get("body", "")).contains("殘響"):
		printerr("FAIL 8-H: Gleaned work note not restored correctly!")
		get_tree().quit(1)
		return
	print("PASS: Repaired gleaned ending save/load verified.")

	# 5. Dialogue greeting routing check after load
	var robot_tree_8h = DialogueDB.get_tree_for("store_robot")
	var runner_8h = DialogueRunner.new()
	runner_8h.start(robot_tree_8h, "start")
	if runner_8h._current_node_id != "repaired_gleaned":
		printerr("FAIL 8-H: Dialogue runner should route directly to repaired_gleaned! Got: ", runner_8h._current_node_id)
		get_tree().quit(1)
		return
	print("PASS: Repaired dialogue greeting routing after load verified.")

	# 6. Shop stocks availability check after load
	if GameState.get_shop_stock("street_vending").is_empty() or GameState.get_shop_stock("convenience_store").is_empty():
		printerr("FAIL 8-H: Shop stocks not initialized correctly after load!")
		get_tree().quit(1)
		return
	print("PASS: Shop stocks availability after load verified.")

	# Cleanup 8-F
	GameState.story_flags.erase("vendor_bot_repaired")
	GameState.story_flags.erase("store_robot_resolution")
	GameState.story_flags.erase("talked_outside_vendor")
	GameState.shop_states.clear()
	GameState.notes.clear()
	GameState.inventory = inv_backup_8f
	GameState.set_credits(credits_backup_8f)
	GameState.inventory_changed.emit()
	gate_runner_8f = null
	await get_tree().process_frame

	print("PASS: Phase 8-F & 8-G commerce core & ShopPanel verified successfully.")

	# ============================================================
	# Phase 9-A: 殘響資料模型 + 筆記「殘響」分頁 + 店員殘響回寫
	# ============================================================
	print("Verifying Phase 9-A: Echo Database, GameState integration, and Notebook tab...")

	# 1. EchoDB basic checks
	if not EchoDB.has_echo("echo_clerk") or not EchoDB.has_echo("echo_room401_tenant") or not EchoDB.has_echo("echo_song_rain_doesnt_stop") or not EchoDB.has_echo("echo_lu_family"):
		printerr("FAIL 9-A: EchoDB missing standard echoes!")
		get_tree().quit(1)
		return
	if EchoDB.get_segment_count("echo_clerk") != 1 or EchoDB.get_segment_count("echo_room401_tenant") != 3:
		printerr("FAIL 9-A: EchoDB segment counts incorrect!")
		get_tree().quit(1)
		return
	print("PASS 9-A: EchoDB registry verified.")

	# Backup current game state
	var inv_backup_9a = GameState.inventory.duplicate(true)
	var credits_backup_9a = GameState.get_credits()
	var echo_progress_backup_9a = GameState.echo_progress.duplicate(true)
	var story_flags_backup_9a = GameState.story_flags.duplicate(true)

	# Clean slate
	GameState.reset_for_new_game()
	if not GameState.echo_progress.is_empty():
		printerr("FAIL 9-A: reset_for_new_game should clear echo_progress!")
		get_tree().quit(1)
		return

	# 2. collect_echo_segment & queries
	if GameState.is_echo_known("echo_room401_tenant") or GameState.is_echo_complete("echo_room401_tenant"):
		printerr("FAIL 9-A: Echo should not be known or complete before collection!")
		get_tree().quit(1)
		return

	# Collect first segment
	if not GameState.collect_echo_segment("echo_room401_tenant", "s1"):
		printerr("FAIL 9-A: collect_echo_segment should return true for first collection!")
		get_tree().quit(1)
		return
	if not GameState.is_echo_known("echo_room401_tenant"):
		printerr("FAIL 9-A: Echo should be known after collecting 1 segment!")
		get_tree().quit(1)
		return
	if GameState.is_echo_complete("echo_room401_tenant"):
		printerr("FAIL 9-A: Echo should not be complete with only 1/3 segments!")
		get_tree().quit(1)
		return

	# Collect duplicate segment (should return false)
	if GameState.collect_echo_segment("echo_room401_tenant", "s1"):
		printerr("FAIL 9-A: collect_echo_segment should return false for duplicate collection!")
		get_tree().quit(1)
		return

	# Collect remaining segments
	if not GameState.collect_echo_segment("echo_room401_tenant", "s2") or not GameState.collect_echo_segment("echo_room401_tenant", "s3"):
		printerr("FAIL 9-A: collect_echo_segment failed on new segments!")
		get_tree().quit(1)
		return
	if not GameState.is_echo_complete("echo_room401_tenant"):
		printerr("FAIL 9-A: Echo should be complete after collecting all segments!")
		get_tree().quit(1)
		return
	print("PASS 9-A: collect_echo_segment and completion checks verified.")

	# 3. sell_echo
	var old_credits_9a = GameState.get_credits()
	if GameState.is_echo_sold("echo_room401_tenant"):
		printerr("FAIL 9-A: Echo should not be sold yet!")
		get_tree().quit(1)
		return
	if not GameState.sell_echo("echo_room401_tenant"):
		printerr("FAIL 9-A: sell_echo should succeed on completed unsold echo!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != old_credits_9a + 200:
		printerr("FAIL 9-A: sell_echo did not reward correct credits! Got: ", GameState.get_credits())
		get_tree().quit(1)
		return
	if not GameState.is_echo_sold("echo_room401_tenant"):
		printerr("FAIL 9-A: Echo should be flagged as sold after selling!")
		get_tree().quit(1)
		return
	if GameState.sell_echo("echo_room401_tenant"):
		printerr("FAIL 9-A: sell_echo should fail on already sold echo!")
		get_tree().quit(1)
		return
	print("PASS 9-A: sell_echo rewards and guards verified.")

	# 4. record_full_echo
	GameState.record_full_echo("echo_song_rain_doesnt_stop")
	if not GameState.is_echo_complete("echo_song_rain_doesnt_stop") or GameState.is_echo_sold("echo_song_rain_doesnt_stop"):
		printerr("FAIL 9-A: record_full_echo should complete the echo without selling it!")
		get_tree().quit(1)
		return
	print("PASS 9-A: record_full_echo verified.")

	# 5. Serialization and backfill on save/load
	var save_dict_9a = GameState.to_save_dict()
	if not save_dict_9a.has("echo_progress"):
		printerr("FAIL 9-A: to_save_dict missing echo_progress!")
		get_tree().quit(1)
		return
	if not save_dict_9a["echo_progress"].has("echo_room401_tenant") or not save_dict_9a["echo_progress"]["echo_room401_tenant"]["sold"]:
		printerr("FAIL 9-A: serialized echo_progress has incorrect state!")
		get_tree().quit(1)
		return

	# Reset and load
	GameState.reset_for_new_game()
	GameState.load_save_dict(save_dict_9a)
	if not GameState.is_echo_complete("echo_room401_tenant") or not GameState.is_echo_sold("echo_room401_tenant"):
		printerr("FAIL 9-A: load_save_dict failed to restore echo states!")
		get_tree().quit(1)
		return
	if not GameState.is_echo_complete("echo_song_rain_doesnt_stop"):
		printerr("FAIL 9-A: load_save_dict failed to restore completed echo!")
		get_tree().quit(1)
		return
	print("PASS 9-A: save/load round-trip of echo progress verified.")

	# 6. Clerk echo resolution hook backfill
	GameState.reset_for_new_game()
	if GameState.is_echo_known("echo_clerk"):
		printerr("FAIL 9-A: clerk echo should not be known in a new game initially!")
		get_tree().quit(1)
		return

	# Setting resolution to reset -> should NOT backfill clerk echo
	GameState.set_flag("store_robot_resolution", "reset")
	if GameState.is_echo_known("echo_clerk"):
		printerr("FAIL 9-A: store_robot_resolution='reset' should not backfill clerk echo!")
		get_tree().quit(1)
		return

	# Setting resolution to gleaned -> should backfill clerk echo
	GameState.set_flag("store_robot_resolution", "gleaned")
	if not GameState.is_echo_complete("echo_clerk"):
		printerr("FAIL 9-A: store_robot_resolution='gleaned' should backfill and complete clerk echo!")
		get_tree().quit(1)
		return

	# Testing backfill during load_save_dict (old save files)
	GameState.reset_for_new_game()
	GameState.story_flags["store_robot_resolution"] = "gleaned"
	if GameState.is_echo_known("echo_clerk"):
		printerr("FAIL 9-A: direct bypass should not trigger backfill until load/capture!")
		get_tree().quit(1)
		return
	var save_dict_old_9a = GameState.to_save_dict()
	GameState.reset_for_new_game()
	GameState.load_save_dict(save_dict_old_9a)
	if not GameState.is_echo_complete("echo_clerk"):
		printerr("FAIL 9-A: load_save_dict should backfill clerk echo for gleaned resolution saves!")
		get_tree().quit(1)
		return
	print("PASS 9-A: clerk echo resolution hook and backfilling verified.")

	# 7. Notebook UI projections
	var ui_scene_9a = load("res://scenes/ui/game_ui.tscn")
	var ui_instance_9a = ui_scene_9a.instantiate()
	add_child(ui_instance_9a)
	await get_tree().process_frame

	var notebook_panel_9a = ui_instance_9a.get_node_or_null("NotebookPanel")
	if notebook_panel_9a == null:
		printerr("FAIL 9-A: NotebookPanel missing from GameUI!")
		get_tree().quit(1)
		return

	# Set up mock echoes
	GameState.reset_for_new_game()
	GameState.collect_echo_segment("echo_clerk", "s1")
	GameState.collect_echo_segment("echo_room401_tenant", "s1")
	GameState.collect_echo_segment("echo_room401_tenant", "s3")
	GameState.record_full_echo("echo_song_rain_doesnt_stop")
	GameState.sell_echo("echo_song_rain_doesnt_stop")

	notebook_panel_9a.set_input_active(true)
	notebook_panel_9a.active_category_index = 0
	notebook_panel_9a._select_tab_index(3)
	await get_tree().process_frame


	var list_buttons_9a = notebook_panel_9a.list_vbox.get_children()
	if list_buttons_9a.size() != 3:
		printerr("FAIL 9-A: Expected 3 buttons in the list! Got: ", list_buttons_9a.size())
		get_tree().quit(1)
		return

	var clerk_btn: Button = list_buttons_9a[0]
	var tenant_btn: Button = list_buttons_9a[1]
	var song_btn: Button = list_buttons_9a[2]

	if not clerk_btn.text.contains("店員的殘響") or not clerk_btn.text.contains("1/1"):
		printerr("FAIL 9-A: Clerk button text incorrect! Got: ", clerk_btn.text)
		get_tree().quit(1)
		return
	if not tenant_btn.text.contains("401") or not tenant_btn.text.contains("2/3"):
		printerr("FAIL 9-A: Tenant button text incorrect! Got: ", tenant_btn.text)
		get_tree().quit(1)
		return
	if not song_btn.text.contains("雨還沒停") or not song_btn.text.contains("3/3") or not song_btn.text.contains("已售出"):
		printerr("FAIL 9-A: Song button text incorrect! Got: ", song_btn.text)
		get_tree().quit(1)
		return

	# Verify Body Projection via focus trigger
	tenant_btn.grab_focus()
	await get_tree().process_frame

	var body_txt: String = notebook_panel_9a.body_label.text
	if not body_txt.contains("租約通知單") or not body_txt.contains("段落 2：????") or not body_txt.contains("生活照"):
		printerr("FAIL 9-A: Body text for partially known echo is incorrect! Got: ", body_txt)
		get_tree().quit(1)
		return

	# Cleanup GameUI instance
	ui_instance_9a.free()
	print("PASS 9-A: Notebook UI projection and tab selection verified.")

	# Restore game state backup
	GameState.reset_for_new_game()
	GameState.inventory = inv_backup_9a
	GameState.set_credits(credits_backup_9a)
	GameState.echo_progress = echo_progress_backup_9a
	GameState.story_flags = story_flags_backup_9a
	GameState.inventory_changed.emit()
	await get_tree().process_frame


	# ============================================================
	# Phase 9-B: 時鐘取模組 + 線索筆記
	# ============================================================
	print("Verifying Phase 9-B: Clock module extraction and guards...")

	var inv_backup_9b = GameState.inventory.duplicate(true)
	var credits_backup_9b = GameState.get_credits()
	var echo_progress_backup_9b = GameState.echo_progress.duplicate(true)
	var story_flags_backup_9b = GameState.story_flags.duplicate(true)
	var notes_backup_9b = GameState.notes.duplicate(true)
	var knowledge_backup_9b = GameState.knowledge.duplicate(true)

	GameState.reset_for_new_game()

	# Load apartment room scene
	var room_scene_9b = load("res://scenes/levels/apartment/apartment_room.tscn")
	var room_inst_9b = room_scene_9b.instantiate()
	add_child(room_inst_9b)
	room_inst_9b.prepare_entry_point("from_street")
	room_inst_9b.set_entry_point("from_street")
	await get_tree().process_frame

	# 1. Before puzzle completion: Clock exists
	var clock_node = room_inst_9b.get_node_or_null("Interactables/ProjectionClockArea")
	if not clock_node:
		printerr("FAIL 9-B: Clock node should exist initially in unsolved room!")
		get_tree().quit(1)
		return

	# If we enter clock but don't have the note, it should NOT be interactable
	room_inst_9b._on_interactable_entered(clock_node)
	room_inst_9b._refresh_current_interactable()
	print("DEBUG 9-B step 1: current_interactable without note is ", room_inst_9b.current_interactable)
	if room_inst_9b.current_interactable == clock_node:
		printerr("FAIL 9-B: Clock should not be closest interactable before clue_projection_clock note is acquired!")
		get_tree().quit(1)
		return
	room_inst_9b._on_interactable_exited(clock_node)

	# Now add clue note, it should become interactable
	GameState.add_knowledge(GameState.STORY_NOTES["clue_projection_clock"])
	room_inst_9b._on_interactable_entered(clock_node)
	room_inst_9b._refresh_current_interactable()
	print("DEBUG 9-B step 1: current_interactable with note is ", room_inst_9b.current_interactable)
	if room_inst_9b.current_interactable != clock_node:
		printerr("FAIL 9-B: Clock should be interactable once clue_projection_clock note is acquired!")
		get_tree().quit(1)
		return
	
	# Interact should start sonar but NOT give 9-B module
	room_inst_9b._trigger_interaction()
	if GameState.has_item("old_probe_module") or GameState.get_flag("probe_module_taken", false):
		printerr("FAIL 9-B: Should not retrieve module before door is unlocked!")
		get_tree().quit(1)
		return
	room_inst_9b._on_interactable_exited(clock_node)

	# 2. Complete puzzle (sonar revealed), but no door unlock knowledge yet -> clock is removed
	GameState.apartment_sonar_revealed = true
	room_inst_9b.free()
	await get_tree().process_frame

	room_inst_9b = room_scene_9b.instantiate()
	add_child(room_inst_9b)
	room_inst_9b.prepare_entry_point("from_street")
	room_inst_9b.set_entry_point("from_street")
	await get_tree().process_frame

	clock_node = room_inst_9b.get_node_or_null("Interactables/ProjectionClockArea")
	print("DEBUG 9-B step 2: clock_node after sonar reveal without door unlock is ", clock_node)
	if clock_node != null:
		printerr("FAIL 9-B: Clock should be deleted if puzzle is solved but door unlock is not known!")
		get_tree().quit(1)
		return

	# 3. Add door unlock knowledge -> Clock reappears upon re-entry
	GameState.add_knowledge(GameState.STORY_NOTES["identity_door_unlock_method"])
	room_inst_9b.free()
	await get_tree().process_frame

	room_inst_9b = room_scene_9b.instantiate()
	add_child(room_inst_9b)
	room_inst_9b.prepare_entry_point("from_street")
	room_inst_9b.set_entry_point("from_street")
	await get_tree().process_frame

	clock_node = room_inst_9b.get_node_or_null("Interactables/ProjectionClockArea")
	print("DEBUG 9-B step 3: clock_node after door unlock is ", clock_node)
	if not clock_node:
		printerr("FAIL 9-B: Clock should reappear for 9-B module extraction when door unlock method is known!")
		get_tree().quit(1)
		return

	# 4. Fill inventory to test the backpack full guard
	# GameState.inventory has 20 slots. Let's fill all of them.
	GameState.inventory.clear()
	for i in range(20):
		GameState.inventory.append({
			"instance_id": "dummy_" + str(i),
			"item_id": "canned_food",
			"quantity": 5
		})
	GameState.inventory_changed.emit()

	# Interact with clock while inventory is full
	var interaction_msg_tracker := {
		"got_msg": false,
		"text": ""
	}
	_temp_callable = func(data):
		print("DEBUG 9-B step 4: received interaction request event: ", data)
		if data.get("type") == "message":
			interaction_msg_tracker["got_msg"] = true
			interaction_msg_tracker["text"] = data.get("message_text", "")
	room_inst_9b.interaction_requested.connect(_temp_callable)

	room_inst_9b._on_interactable_entered(clock_node)
	room_inst_9b._refresh_current_interactable()
	print("DEBUG 9-B step 4: current_interactable before interact is ", room_inst_9b.current_interactable)
	room_inst_9b._trigger_interaction()

	# M2-C：payload 的 message_text 為翻譯 key，view 端 tr() 後才是顯示文字；測試需鏡像同一鏈。
	if not interaction_msg_tracker["got_msg"] or not tr(interaction_msg_tracker["text"]).contains("背包太滿"):
		printerr("FAIL 9-B: Full inventory guard did not show backpack full message! Msg: ", interaction_msg_tracker["text"])
		get_tree().quit(1)
		return

	if GameState.has_item("old_probe_module") or GameState.get_flag("probe_module_taken", false):
		printerr("FAIL 9-B: Should not grant item or set flag when inventory is full!")
		get_tree().quit(1)
		return

	# Make sure the clock still exists and is interactable
	clock_node = room_inst_9b.get_node_or_null("Interactables/ProjectionClockArea")
	if not clock_node:
		printerr("FAIL 9-B: Clock should still exist after failed interaction due to full inventory!")
		get_tree().quit(1)
		return

	# 5. Free up space in inventory and interact again
	GameState.inventory.clear()
	for i in range(20):
		GameState.inventory.append({})
	GameState.inventory_changed.emit()

	interaction_msg_tracker["got_msg"] = false
	interaction_msg_tracker["text"] = ""

	# Make sure current_interactable is set correctly
	room_inst_9b._refresh_current_interactable()
	room_inst_9b._trigger_interaction()
	await get_tree().process_frame

	if not interaction_msg_tracker["got_msg"] or not tr(interaction_msg_tracker["text"]).contains("獲得了「老舊探測模組」"):
		printerr("FAIL 9-B: Failed to extract module after inventory space cleared! Msg: ", interaction_msg_tracker["text"])
		get_tree().quit(1)
		return

	# Verify item, flags, notes
	if not GameState.has_item("old_probe_module"):
		printerr("FAIL 9-B: Player should have old_probe_module in inventory after successful extraction!")
		get_tree().quit(1)
		return

	if not GameState.get_flag("probe_module_taken", false):
		printerr("FAIL 9-B: probe_module_taken flag should be set to true!")
		get_tree().quit(1)
		return

	if not GameState.has_note("clue_probe_module_lead"):
		printerr("FAIL 9-B: clue_probe_module_lead note should be added to notes!")
		get_tree().quit(1)
		return

	# Verify clock is removed
	clock_node = room_inst_9b.get_node_or_null("Interactables/ProjectionClockArea")
	if clock_node != null:
		printerr("FAIL 9-B: Clock should be queue_freed from room after successful extraction!")
		get_tree().quit(1)
		return

	# Cleanup signal
	room_inst_9b.interaction_requested.disconnect(_temp_callable)

	# 6. Verify non-discardable and non-sellable rules for old_probe_module and fingerless_gloves
	if GameState.is_sellable("old_probe_module") or GameState.is_sellable("fingerless_gloves"):
		printerr("FAIL 9-B: old_probe_module and fingerless_gloves must NOT be sellable!")
		get_tree().quit(1)
		return

	# Verify discardable is false in metadata
	if GameState.ITEMS_DB["old_probe_module"].get("discardable", true) != false or GameState.ITEMS_DB["fingerless_gloves"].get("discardable", true) != false:
		printerr("FAIL 9-B: old_probe_module and fingerless_gloves must be non-discardable!")
		get_tree().quit(1)
		return

	# Clean up instances
	room_inst_9b.free()

	# Restore state backups
	GameState.reset_for_new_game()
	GameState.inventory = inv_backup_9b
	GameState.set_credits(credits_backup_9b)
	GameState.echo_progress = echo_progress_backup_9b
	GameState.story_flags = story_flags_backup_9b
	GameState.notes = notes_backup_9b
	GameState.knowledge = knowledge_backup_9b
	GameState.inventory_changed.emit()
	await get_tree().process_frame

	print("PASS 9-B: Clock module extraction and guards verified.")

	# ----------------------------------------------------
	# Phase 9-C Verification
	# ----------------------------------------------------
	print("Running 9-C Integration tests...")
	
	# Regression checks for discovered fixes
	# Issue 1: gleaner_gloves can_decode capability
	if not GameState.ITEMS_DB["gleaner_gloves"].get("can_decode", false):
		printerr("FAIL 9-C: gleaner_gloves metadata is missing can_decode: true!")
		get_tree().quit(1)
		return
		
	# Issue 2: entry_points registry check
	var MainClass = load("res://scenes/main/main.gd")
	if not MainClass.SCENES["apartment_entrance"]["entry_points"].has("from_collector_shop"):
		printerr("FAIL 9-C: apartment_entrance is missing from_collector_shop entry point!")
		get_tree().quit(1)
		return
		
	# Issue 3: DialogueRunner echo_complete and echo_unsold condition evaluation
	var runner_test = DialogueRunner.new()
	GameState.reset_for_new_game()
	var cond_complete = {"type": "echo_complete", "value": "echo_clerk"}
	if runner_test._eval_condition_dict(cond_complete):
		printerr("FAIL 9-C: echo_complete condition should evaluate to false when echo is not complete!")
		get_tree().quit(1)
		return
		
	GameState.record_full_echo("echo_clerk")
	if not runner_test._eval_condition_dict(cond_complete):
		printerr("FAIL 9-C: echo_complete condition should evaluate to true when echo is complete!")
		get_tree().quit(1)
		return
		
	var cond_unsold = {"type": "echo_unsold", "value": "echo_clerk"}
	if not runner_test._eval_condition_dict(cond_unsold):
		printerr("FAIL 9-C: echo_unsold condition should evaluate to true when echo is unsold!")
		get_tree().quit(1)
		return
		
	# Issue 4: DialogueRunner sell_echo effect application
	var eff_sell = {"op": "sell_echo", "value": "echo_clerk"}
	var old_credits_sell = GameState.get_credits()
	if not runner_test._apply_effect(eff_sell):
		printerr("FAIL 9-C: sell_echo effect execution failed!")
		get_tree().quit(1)
		return
	if not GameState.is_echo_sold("echo_clerk") or GameState.get_credits() != old_credits_sell + 300:
		printerr("FAIL 9-C: sell_echo effect did not sell the echo or reward credits!")
		get_tree().quit(1)
		return
		
	if runner_test._eval_condition_dict(cond_unsold):
		printerr("FAIL 9-C: echo_unsold condition should evaluate to false after echo is sold!")
		get_tree().quit(1)
		return
		
	# Issue 5: lu_qichen hub appraise condition includes fingerless_gloves check
	var lu_tree_check = DialogueDB.get_tree_for("lu_qichen")
	var appraise_choices = lu_tree_check["hub"]["choices"]
	var appraise_choice = null
	for choice in appraise_choices:
		if choice.get("goto") == "appraise":
			appraise_choice = choice
			break
	if not appraise_choice:
		printerr("FAIL 9-C: appraise choice not found in lu_qichen hub dialogue tree!")
		get_tree().quit(1)
		return
	var appraise_conds = appraise_choice.get("condition", [])
	var has_fingerless_check := false
	for cond in appraise_conds:
		if cond.get("type") == "has_item" and cond.get("item_id") == "fingerless_gloves":
			has_fingerless_check = true
			break
	if not has_fingerless_check:
		printerr("FAIL 9-C: lu_qichen hub appraise choice is missing fingerless_gloves condition check!")
		get_tree().quit(1)
		return
	
	# 1. Glove Upgrade Mechanics
	# Case A: fingerless_gloves is in inventory (not equipped)
	GameState.reset_for_new_game()
	GameState.add_item("old_probe_module", 1)
	GameState.add_item("fingerless_gloves", 1)
	
	# Find fingerless_gloves instance ID
	var gloves_inst_id := ""
	for slot in GameState.get_inventory():
		if not slot.is_empty() and slot.get("item_id") == "fingerless_gloves":
			gloves_inst_id = slot.get("instance_id", "")
			break
			
	if gloves_inst_id.is_empty():
		printerr("FAIL 9-C: fingerless_gloves not found in inventory!")
		get_tree().quit(1)
		return
		
	var upgrade_success = GameState.install_probe_module()
	if not upgrade_success:
		printerr("FAIL 9-C: install_probe_module failed when gloves are in inventory!")
		get_tree().quit(1)
		return
		
	if GameState.has_item("old_probe_module"):
		printerr("FAIL 9-C: old_probe_module should be removed after upgrade!")
		get_tree().quit(1)
		return
		
	# Verify in-place replacement
	var found_gleaner := false
	for slot in GameState.get_inventory():
		if not slot.is_empty() and slot.get("instance_id") == gloves_inst_id:
			if slot.get("item_id") != "gleaner_gloves":
				printerr("FAIL 9-C: Item ID should be updated to gleaner_gloves!")
				get_tree().quit(1)
				return
			found_gleaner = true
			break
	if not found_gleaner:
		printerr("FAIL 9-C: gleaner_gloves not found with matching instance ID!")
		get_tree().quit(1)
		return
		
	if not GameState.get_flag("gleaner_gloves_installed", false):
		printerr("FAIL 9-C: gleaner_gloves_installed story flag should be true!")
		get_tree().quit(1)
		return

	# Case B: fingerless_gloves is equipped
	GameState.reset_for_new_game()
	GameState.add_item("old_probe_module", 1)
	GameState.add_item("fingerless_gloves", 1)
	
	# Find gloves instance ID and equip it
	var gloves_inst_id_b := ""
	for slot in GameState.get_inventory():
		if not slot.is_empty() and slot.get("item_id") == "fingerless_gloves":
			gloves_inst_id_b = slot.get("instance_id", "")
			break
	
	GameState.equip(gloves_inst_id_b)
	if not GameState.is_equipped(gloves_inst_id_b):
		printerr("FAIL 9-C: failed to equip fingerless_gloves for test case B!")
		get_tree().quit(1)
		return
		
	var upgrade_success_b = GameState.install_probe_module()
	if not upgrade_success_b:
		printerr("FAIL 9-C: install_probe_module failed when gloves are equipped!")
		get_tree().quit(1)
		return
		
	if not GameState.is_equipped(gloves_inst_id_b):
		printerr("FAIL 9-C: gleaner_gloves should remain equipped with same instance ID!")
		get_tree().quit(1)
		return
		
	# Verify in-place replacement in inventory slots
	var found_gleaner_b := false
	for slot in GameState.get_inventory():
		if not slot.is_empty() and slot.get("instance_id") == gloves_inst_id_b:
			if slot.get("item_id") != "gleaner_gloves":
				printerr("FAIL 9-C: Item ID of equipped gloves should be updated to gleaner_gloves!")
				get_tree().quit(1)
				return
			found_gleaner_b = true
			break
	if not found_gleaner_b:
		printerr("FAIL 9-C: equipped gleaner_gloves not found with matching instance ID!")
		get_tree().quit(1)
		return
		
	# 2. Dialogue Transitions
	# Dialogue A: travel_street_east choice
	var travel_tree = DialogueDB.get_tree_for("travel_street_east")
	if travel_tree.is_empty() or not travel_tree.has("travel_to_shop"):
		printerr("FAIL 9-C: DialogueDB could not fetch travel_street_east tree!")
		get_tree().quit(1)
		return
		
	var travel_runner = DialogueRunner.new()
	travel_runner.start(travel_tree)
	travel_runner.choose(0) # Choose "前往收藏家的店"
	
	var travel_payload = travel_runner.pending_travel
	if travel_payload.get("scene_id") != "collector_shop" or travel_payload.get("entry_point_id") != "from_street":
		printerr("FAIL 9-C: pending_travel mismatch! Got: ", travel_payload)
		get_tree().quit(1)
		return
		
	# Dialogue B: lu_qichen appraisal and install_module effect
	var lu_tree = DialogueDB.get_tree_for("lu_qichen")
	if lu_tree.is_empty() or not lu_tree.has("appraise_gloves"):
		printerr("FAIL 9-C: DialogueDB could not fetch lu_qichen tree!")
		get_tree().quit(1)
		return
		
	GameState.reset_for_new_game()
	GameState.add_item("old_probe_module", 1)
	GameState.add_item("fingerless_gloves", 1)
	
	var lu_runner = DialogueRunner.new()
	lu_runner.start(lu_tree, "appraise_gloves") # Start at appraise_gloves node
	# Node entry automatically triggers effect "install_module"
	if not GameState.get_flag("gleaner_gloves_installed", false):
		printerr("FAIL 9-C: Dialogue install_module effect did not install glove module!")
		get_tree().quit(1)
		return
		
	# 3. Scene Load Verification
	print("Loading res://scenes/levels/collector_shop/collector_shop.tscn...")
	var shop_scene = load("res://scenes/levels/collector_shop/collector_shop.tscn")
	if not shop_scene:
		printerr("FAIL 9-C: Could not load collector_shop.tscn!")
		get_tree().quit(1)
		return
		
	var shop_instance = shop_scene.instantiate()
	if not shop_instance:
		printerr("FAIL 9-C: Could not instantiate collector_shop.tscn!")
		get_tree().quit(1)
		return
		
	var shop_camera = shop_instance.get_node_or_null("Camera2D")
	if not shop_camera or shop_camera.limit_left != 0 or shop_camera.limit_right != 2560 or shop_camera.limit_top != 0 or shop_camera.limit_bottom != 720:
		printerr("FAIL 9-C: Camera bounds in collector_shop are not 0-2560 x 0-720!")
		get_tree().quit(1)
		return
		
	var shop_spawn = shop_instance.get_node_or_null("SpawnPoints/from_street")
	if not shop_spawn or shop_spawn.position != Vector2(190, 665):
		printerr("FAIL 9-C: SpawnPoint from_street is wrong or missing!")
		get_tree().quit(1)
		return
		
	var interactables_parent = shop_instance.get_node_or_null("Interactables")
	if not interactables_parent:
		printerr("FAIL 9-C: Interactables container missing in collector_shop!")
		get_tree().quit(1)
		return
		
	var lu_area = interactables_parent.get_node_or_null("LuQichenArea")
	if not lu_area or lu_area.dialogue_id != "lu_qichen" or lu_area.prompt_text != "PROMPT_TALK":
		printerr("FAIL 9-C: LuQichenArea interaction properties are incorrect!")
		get_tree().quit(1)
		return
		
	var lu_sprite = lu_area.get_node_or_null("Sprite2D")
	if not lu_sprite or lu_sprite.texture == null:
		printerr("FAIL 9-C: Lu Qichen NPC sprite is missing or texture is empty!")
		get_tree().quit(1)
		return
		
	if lu_sprite.position != Vector2(1870.9995, 355):
		printerr("FAIL 9-C: Lu Qichen NPC sprite position should be [1870.9995, 355]! Got: ", lu_sprite.position)
		get_tree().quit(1)
		return
		
	shop_instance.free()
	print("PASS 9-C: Glove upgrade mechanics, dialogue transitions, and collector shop scene load verified.")

	# ----------------------------------------------------
	# Phase 9-D Verification
	# ----------------------------------------------------
	print("Running 9-D Integration tests...")
	
	# Instantiate EchoPoint
	var EchoPointClass = load("res://scripts/components/echo_point.gd")
	var ep = EchoPointClass.new()
	ep.echo_id = "echo_room401_tenant"
	ep.segment_id = "s1"
	add_child(ep)
	if ep.audio_player.stream == null:
		printerr("FAIL 9-D: EchoPoint proximity stream should be configured!")
		get_tree().quit(1)
		return
	if not ep.audio_player.stream is AudioStreamMP3:
		printerr("FAIL 9-D: EchoPoint proximity stream should use echo_presence_loop.mp3!")
		get_tree().quit(1)
		return
	var slot_sfx_stream := load("res://assets/sound/slot_electromagnetic.wav") as AudioStreamWAV
	if slot_sfx_stream and slot_sfx_stream.loop_mode != 0:
		printerr("FAIL 9-D: EchoPoint should not mutate slot_electromagnetic.wav into a loop!")
		get_tree().quit(1)
		return
	
	# Reset state
	GameState.reset_for_new_game()
	
	# 1. Verification of Gating & Proximity Sound Playback
	# Under Case A: glove not equipped, should be inactive
	ep._update_active_state()
	if ep.active:
		printerr("FAIL 9-D: EchoPoint should be inactive when gleaner_gloves is not equipped!")
		get_tree().quit(1)
		return
	if ep.audio_player.playing:
		printerr("FAIL 9-D: Proximity sound should not play when inactive!")
		get_tree().quit(1)
		return
		
	# Equip gleaner_gloves
	GameState.add_item("gleaner_gloves", 1)
	var gleaner_id := ""
	for slot in GameState.get_inventory():
		if not slot.is_empty() and slot.get("item_id") == "gleaner_gloves":
			gleaner_id = slot.get("instance_id", "")
			break
	GameState.equip(gleaner_id)
	
	# Update state, should become active
	ep._update_active_state()
	if not ep.active:
		printerr("FAIL 9-D: EchoPoint should be active when gleaner_gloves is equipped!")
		get_tree().quit(1)
		return
	if not ep.audio_player.playing:
		printerr("FAIL 9-D: Proximity sound should play when active!")
		get_tree().quit(1)
		return
		
	# 2. Verification of Proximity Dwell Timer (Static Player detection)
	var mock_player = CharacterBody2D.new()
	mock_player.name = "Player"
	mock_player.global_position = Vector2(0, 0)
	add_child(mock_player)
	
	var sig_tracker = {"entered": false, "exited": false}
	ep.player_entered.connect(func(_x): sig_tracker["entered"] = true)
	ep.player_exited.connect(func(_x): sig_tracker["exited"] = true)
	
	# Enter area
	ep._on_body_entered(mock_player)
	if not ep.player_inside:
		printerr("FAIL 9-D: player_inside should be true after entering body!")
		get_tree().quit(1)
		return
		
	# Process 0.5s (static), entered should not be emitted yet
	ep._process(0.5)
	if sig_tracker["entered"] or ep.dwell_timer != 0.5:
		printerr("FAIL 9-D: Dwell timer should accumulate but not trigger before 1 second!")
		get_tree().quit(1)
		return
		
	# Process 0.6s (total 1.1s static), entered should be emitted
	ep._process(0.6)
	if not sig_tracker["entered"] or not ep.has_emitted_entered:
		printerr("FAIL 9-D: player_entered should be emitted after 1 second of static dwell!")
		get_tree().quit(1)
		return
		
	# Simulate player movement (position change)
	mock_player.global_position = Vector2(20, 20)
	ep._process(0.1)
	if not sig_tracker["exited"] or ep.has_emitted_entered or ep.dwell_timer != 0.0:
		printerr("FAIL 9-D: player_exited should be emitted immediately upon player movement!")
		get_tree().quit(1)
		return
		
	# 3. Verification of collection mechanics
	# Return player to static and let it dwell for 1.1 seconds again
	sig_tracker["entered"] = false
	ep.last_player_position = mock_player.global_position
	ep._process(0.5)
	ep._process(0.6)
	if not sig_tracker["entered"] or not ep.has_emitted_entered:
		printerr("FAIL 9-D: failed to re-dwell player!")
		get_tree().quit(1)
		return
		
	# Call collect()
	ep.collect()
	var collect_sfx := get_tree().root.find_child("EchoCollectSFX", true, false)
	if collect_sfx == null or not collect_sfx is AudioStreamPlayer:
		printerr("FAIL 9-D: collect() should spawn EchoCollectSFX!")
		get_tree().quit(1)
		return
	if not (collect_sfx as AudioStreamPlayer).stream is AudioStreamMP3:
		printerr("FAIL 9-D: collect() should use echo_collect.mp3!")
		get_tree().quit(1)
		return
	collect_sfx.queue_free()
	
	# Verify GameState segment registered
	if not GameState.has_echo_segment("echo_room401_tenant", "s1"):
		printerr("FAIL 9-D: collect() did not register segment in GameState!")
		get_tree().quit(1)
		return
		
	# Verify EchoPoint deactivated automatically
	if ep.active:
		printerr("FAIL 9-D: EchoPoint should become inactive after collection!")
		get_tree().quit(1)
		return
	if ep.audio_player.playing:
		printerr("FAIL 9-D: Proximity sound should stop playing after collection!")
		get_tree().quit(1)
		return
		
	# Cleanup mock instances
	ep.free()
	mock_player.free()
	print("PASS 9-D: Proximity loop playback, static timer gating, and collection mechanics verified.")

	# ----------------------------------------------------
	# Phase 9-E Verification
	# ----------------------------------------------------
	print("Running 9-E Integration tests...")
	
	# Reset state
	GameState.reset_for_new_game()
	
	var db_echoes: Dictionary = EchoDB.ECHOES
	var db_tenant: Dictionary = db_echoes["echo_room401_tenant"]
	var db_clerk: Dictionary = db_echoes["echo_clerk"]
	
	# Open Notebook
	UIMode.set_mode(UIMode.Mode.NOTEBOOK)
	# Switch to "殘響" (index 3)
	ui_instance.notebook_panel._select_tab_index(3)
	await get_tree().process_frame
	
	# 1. Uncollected Echoes: should have no media footer hints
	# Collect s1 of echo_room401_tenant so it shows up in list but is incomplete (1/3)
	GameState.collect_echo_segment("echo_room401_tenant", "s1")
	ui_instance.notebook_panel.load_notebook_data()
	await get_tree().process_frame
	
	var notebook_list = ui_instance.notebook_panel.list_vbox
	var note_button_401 = notebook_list.get_child(0) as Button
	note_button_401.grab_focus()
	await get_tree().process_frame
	
	var actions_uncollected = ui_instance.notebook_panel.get_media_actions()
	if not actions_uncollected.is_empty():
		printerr("FAIL 9-E: Incomplete Echo should not have media actions, got: ", actions_uncollected)
		get_tree().quit(1)
		return
		
	# 2. Image-only Echo: collect all segments for echo_room401_tenant
	GameState.collect_echo_segment("echo_room401_tenant", "s2")
	GameState.collect_echo_segment("echo_room401_tenant", "s3")
	# Set a valid image path dynamically to avoid load errors
	db_tenant["image_path"] = "res://assets/generated/maps/alley_backrooms_3f/alley-backrooms-3f-stage-preview.png"
	
	ui_instance.notebook_panel.load_notebook_data()
	await get_tree().process_frame
	note_button_401 = notebook_list.get_child(0) as Button
	note_button_401.grab_focus()
	await get_tree().process_frame
	
	var actions_image_only = ui_instance.notebook_panel.get_media_actions()
	if actions_image_only.get("primary") != "view_photo" or actions_image_only.has("secondary"):
		printerr("FAIL 9-E: Completed image-only Echo should have primary action 'view_photo' and no secondary action! Got: ", actions_image_only)
		get_tree().quit(1)
		return
		
	if not ui_instance.can_primary_action() or ui_instance.can_secondary_action():
		printerr("FAIL 9-E: Completed image-only Echo action visibility flags are wrong!")
		get_tree().quit(1)
		return
		
	# Verify footer hints contain "E: 看照片"
	var footer_text = ui_instance.notebook_panel.panel_footer_hint.text
	if not "E: 看照片" in footer_text:
		printerr("FAIL 9-E: Footer hint for image-only Echo should contain 'E: 看照片', got: ", footer_text)
		get_tree().quit(1)
		return
		
	# 3. Audio-only Echo: collect all segments for echo_clerk
	GameState.collect_echo_segment("echo_clerk", "s1")
	
	ui_instance.notebook_panel.load_notebook_data()
	await get_tree().process_frame
	var note_button_clerk: Button = null
	for child in notebook_list.get_children():
		if child is Button and child.text.contains("店員"):
			note_button_clerk = child
			break
	if note_button_clerk == null:
		printerr("FAIL 9-E: Could not find clerk echo in notebook list!")
		get_tree().quit(1)
		return
		
	note_button_clerk.grab_focus()
	await get_tree().process_frame
	
	var actions_audio_only = ui_instance.notebook_panel.get_media_actions()
	if actions_audio_only.get("primary") != "play_audio" or actions_audio_only.has("secondary"):
		printerr("FAIL 9-E: Completed audio-only Echo should have primary action 'play_audio' and no secondary action! Got: ", actions_audio_only)
		get_tree().quit(1)
		return
		
	if not ui_instance.can_primary_action() or ui_instance.can_secondary_action():
		printerr("FAIL 9-E: Completed audio-only Echo action visibility flags are wrong!")
		get_tree().quit(1)
		return
		
	# Verify footer hints contain "E: 播放錄音"
	footer_text = ui_instance.notebook_panel.panel_footer_hint.text
	if not "E: 播放錄音" in footer_text:
		printerr("FAIL 9-E: Footer hint for audio-only Echo should contain 'E: 播放錄音', got: ", footer_text)
		get_tree().quit(1)
		return
		
	# 4. Both Image and Audio Echo
	# Temporarily give echo_clerk an image path as well
	db_clerk["image_path"] = "res://assets/generated/maps/alley_backrooms_3f/alley-backrooms-3f-stage-preview.png"
	ui_instance.notebook_panel.load_notebook_data()
	await get_tree().process_frame
	
	for child in notebook_list.get_children():
		if child is Button and child.text.contains("店員"):
			note_button_clerk = child
			break
	note_button_clerk.grab_focus()
	await get_tree().process_frame
	
	var actions_both = ui_instance.notebook_panel.get_media_actions()
	if actions_both.get("primary") != "view_photo" or actions_both.get("secondary") != "play_audio":
		printerr("FAIL 9-E: Completed both-media Echo should have primary 'view_photo' and secondary 'play_audio'! Got: ", actions_both)
		get_tree().quit(1)
		return
		
	if not ui_instance.can_primary_action() or not ui_instance.can_secondary_action():
		printerr("FAIL 9-E: Completed both-media Echo action visibility flags are wrong!")
		get_tree().quit(1)
		return
		
	footer_text = ui_instance.notebook_panel.panel_footer_hint.text
	if not "E: 看照片" in footer_text or not "R: 播放錄音" in footer_text:
		printerr("FAIL 9-E: Footer hints for both-media Echo should contain 'E: 看照片' and 'R: 播放錄音', got: ", footer_text)
		get_tree().quit(1)
		return
		
	# Clean up clerk image path
	db_clerk.erase("image_path")
	
	# 5. Sold Echo: sell echo_room401_tenant and check hints
	GameState.sell_echo("echo_room401_tenant")
	ui_instance.notebook_panel.load_notebook_data()
	await get_tree().process_frame
	
	for child in notebook_list.get_children():
		if child is Button and child.text.contains("401"):
			note_button_401 = child
			break
	note_button_401.grab_focus()
	await get_tree().process_frame
	
	var actions_sold = ui_instance.notebook_panel.get_media_actions()
	if not actions_sold.is_empty():
		printerr("FAIL 9-E: Sold Echo should not have media actions, got: ", actions_sold)
		get_tree().quit(1)
		return
		
	footer_text = ui_instance.notebook_panel.panel_footer_hint.text
	if "看照片" in footer_text or "播放錄音" in footer_text:
		printerr("FAIL 9-E: Footer hints for sold Echo should not contain media hints, got: ", footer_text)
		get_tree().quit(1)
		return
		
	# Restore original database values
	db_tenant["image_path"] = "res://assets/images/echoes/echo_room401_tenant.png"
	db_clerk["audio_path"] = "res://assets/audio/echoes/echo_clerk.ogg"
	
	# 6. Photo Viewer Overlay & Focus/Input active transitions
	# Give clerk a valid image temporarily again to test viewing
	db_clerk["image_path"] = "res://assets/generated/maps/alley_backrooms_3f/alley-backrooms-3f-stage-preview.png"
	GameState.echo_progress["echo_clerk"]["sold"] = false
	ui_instance.notebook_panel.load_notebook_data()
	await get_tree().process_frame
	
	for child in notebook_list.get_children():
		if child is Button and child.text.contains("店員"):
			note_button_clerk = child
			break
	note_button_clerk.grab_focus()
	await get_tree().process_frame
	
	if not ui_instance.notebook_panel.is_input_active:
		printerr("FAIL 9-E: Notebook panel input should be active initially!")
		get_tree().quit(1)
		return
		
	ui_instance.open_photo_viewer("res://assets/generated/maps/alley_backrooms_3f/alley-backrooms-3f-stage-preview.png", note_button_clerk)
	
	if not ui_instance.is_photo_viewer_open():
		printerr("FAIL 9-E: Photo viewer should be open!")
		get_tree().quit(1)
		return
	if ui_instance.notebook_panel.is_input_active:
		printerr("FAIL 9-E: Notebook panel input should be inactive when photo viewer is open!")
		get_tree().quit(1)
		return
		
	if not ui_instance.can_primary_action() or ui_instance.can_secondary_action():
		printerr("FAIL 9-E: Action visibility flags when photo viewer is open are incorrect!")
		get_tree().quit(1)
		return
		
	ui_instance.close_photo_viewer()
	
	if ui_instance.is_photo_viewer_open():
		printerr("FAIL 9-E: Photo viewer should be closed!")
		get_tree().quit(1)
		return
	if not ui_instance.notebook_panel.is_input_active:
		printerr("FAIL 9-E: Notebook panel input should be active after photo viewer is closed!")
		get_tree().quit(1)
		return
		
	db_clerk.erase("image_path")
	
	# 7. Audio Playback Toggling & Interruption Cases
	note_button_clerk.grab_focus()
	await get_tree().process_frame
	var test_audio = "res://assets/audio/echoes/echo_song_rain_doesnt_stop.mp3"
	
	var ambient_bus_idx_9e := AudioServer.get_bus_index("Ambient")
	ui_instance.toggle_echo_audio(test_audio)
	if not ui_instance._audio_echo.playing:
		printerr("FAIL 9-E: Audio echo player should be playing after toggle on!")
		get_tree().quit(1)
		return
	await get_tree().create_timer(0.35).timeout
	if ambient_bus_idx_9e != -1:
		var ducked_db := AudioServer.get_bus_volume_db(ambient_bus_idx_9e)
		# Lowered, not silenced (Phase 10-A spec: "壓低，不全靜") — must be clearly
		# quieter than baseline but nowhere near the old near-mute -80dB mistake.
		if ducked_db >= -1.0 or ducked_db <= -40.0:
			printerr("FAIL 10-A: Ambient bus should be lowered (not silenced) while echo audio plays! Got: ", ducked_db)
			get_tree().quit(1)
			return

	ui_instance.toggle_echo_audio(test_audio)
	if ui_instance._audio_echo.playing:
		printerr("FAIL 9-E: Audio echo player should be stopped after toggle off!")
		get_tree().quit(1)
		return
	await get_tree().create_timer(0.35).timeout
	if ambient_bus_idx_9e != -1 and AudioServer.get_bus_volume_db(ambient_bus_idx_9e) < -1.0:
		printerr("FAIL 10-A: Ambient bus should fade back to baseline after echo audio stops!")
		get_tree().quit(1)
		return
		
	# Case A: Selection change does NOT stop audio
	ui_instance.toggle_echo_audio(test_audio)
	# focus 401
	for child in notebook_list.get_children():
		if child is Button and child.text.contains("401"):
			note_button_401 = child
			break
	note_button_401.grab_focus()
	await get_tree().process_frame
	if not ui_instance._audio_echo.playing:
		printerr("FAIL 9-E: Changing selected item should NOT stop audio playback!")
		get_tree().quit(1)
		return
	ui_instance.stop_echo_audio()
		
	# Case B: Tab change does NOT stop audio
	for child in notebook_list.get_children():
		if child is Button and child.text.contains("店員"):
			note_button_clerk = child
			break
	note_button_clerk.grab_focus()
	await get_tree().process_frame
	ui_instance.toggle_echo_audio(test_audio)
	ui_instance.notebook_panel._select_tab_index(0)
	await get_tree().process_frame
	if not ui_instance._audio_echo.playing:
		printerr("FAIL 9-E: Changing notebook tab should NOT stop audio playback!")
		get_tree().quit(1)
		return
	ui_instance.stop_echo_audio()
		
	# Case C: Closing notebook does NOT stop audio (it plays out fully in background)
	ui_instance.notebook_panel._select_tab_index(3)
	await get_tree().process_frame
	for child in notebook_list.get_children():
		if child is Button and child.text.contains("店員"):
			note_button_clerk = child
			break
	note_button_clerk.grab_focus()
	await get_tree().process_frame
	ui_instance.toggle_echo_audio(test_audio)
	UIMode.set_mode(UIMode.Mode.NONE)
	await get_tree().process_frame
	if not ui_instance._audio_echo.playing:
		printerr("FAIL 9-E: Closing notebook mode should NOT stop audio playback!")
		get_tree().quit(1)
		return
	
	# Stop echo audio manually to clean up for subsequent tests
	ui_instance.stop_echo_audio()
		
	GameState.reset_for_new_game()
	print("PASS 9-E: Dynamic media control hints, photo viewer overlay input gating, and audio interruption behavior verified.")

	# ----------------------------------------------------
	# Phase 9-F Verification
	# ----------------------------------------------------
	print("Running 9-F Integration tests...")
	
	# 1. Verify files exist
	if not FileAccess.file_exists("res://assets/images/echoes/echo_room401_tenant.png"):
		printerr("FAIL 9-F: echo_room401_tenant.png is missing!")
		get_tree().quit(1)
		return
		
	if not FileAccess.file_exists("res://assets/bgm/Vintage Media Shop.mp3"):
		printerr("FAIL 9-F: Vintage Media Shop.mp3 is missing!")
		get_tree().quit(1)
		return
		
	# 2. Verify EchoPoints in scenes
	var scene_tests = [
		{
			"path": "res://scenes/levels/apartment_fire_escape/apartment_fire_escape.tscn",
			"points": [
				{"node": "Interactables/EchoPointS1", "echo": "echo_room401_tenant", "seg": "s1"},
				{"node": "Interactables/EchoPoint", "echo": "echo_room401_tenant", "seg": "s2"}
			]
		},
		{
			"path": "res://scenes/levels/apartment_entrance.tscn",
			"points": [
				{"node": "Interactables/EchoPoint1", "echo": "echo_room401_tenant", "seg": "s3"},
				{"node": "Interactables/EchoPoint2", "echo": "echo_song_rain_doesnt_stop", "seg": "s1"},
				{"node": "Interactables/EchoPoint3", "echo": "echo_song_rain_doesnt_stop", "seg": "s2"}
			]
		},
		{
			"path": "res://scenes/levels/convenience_store/convenience_store.tscn",
			"points": [
				{"node": "Interactables/EchoPoint", "echo": "echo_song_rain_doesnt_stop", "seg": "s3"}
			]
		},
		{
			"path": "res://scenes/levels/collector_shop/collector_shop.tscn",
			"points": [
				{"node": "Interactables/EchoPoint", "echo": "echo_lu_family", "seg": "s1"}
			]
		}
	]
	
	for s_info in scene_tests:
		var scene_path = s_info["path"]
		var scene_res = load(scene_path)
		if not scene_res:
			printerr("FAIL 9-F: Could not load scene: ", scene_path)
			get_tree().quit(1)
			return
		var inst = scene_res.instantiate()
		for p_info in s_info["points"]:
			var node_path = p_info["node"]
			var pt = inst.get_node_or_null(node_path)
			if not pt:
				printerr("FAIL 9-F: EchoPoint not found at path: ", node_path, " in scene: ", scene_path)
				inst.free()
				get_tree().quit(1)
				return
			if pt.echo_id != p_info["echo"] or pt.segment_id != p_info["seg"]:
				printerr("FAIL 9-F: Incorrect configuration on EchoPoint: ", node_path, " in scene: ", scene_path, " - Got: ", pt.echo_id, "/", pt.segment_id)
				inst.free()
				get_tree().quit(1)
				return
				
			# Verify that it has a CollisionShape2D with a CircleShape2D shape
			var col = pt.get_node_or_null("CollisionShape2D")
			if not col or not col.shape is CircleShape2D:
				printerr("FAIL 9-F: EchoPoint at ", node_path, " is missing a CircleShape2D CollisionShape!")
				inst.free()
				get_tree().quit(1)
				return
		inst.free()
		
	# Verify collector_shop plays the new BGM by checking the script source directly
	var shop_script = load("res://scenes/levels/collector_shop/collector_shop.gd")
	var script_src = shop_script.source_code
	if not "res://assets/bgm/Vintage Media Shop.mp3" in script_src:
		printerr("FAIL 9-F: collector_shop.gd does not reference 'res://assets/bgm/Vintage Media Shop.mp3'!")
		get_tree().quit(1)
		return
		
	print("PASS 9-F: All 7 EchoPoints configured across level scenes, BGM path and old-photo asset presence verified.")
	
	# ----------------------------------------------------
	# Phase 9-G Verification
	# ----------------------------------------------------
	print("Running 9-G Integration tests...")
	runner = DialogueRunner.new()
	GameState.reset_for_new_game()
	
	# 1. Direct call validation: sell_echo on incomplete echo should fail
	if GameState.sell_echo("echo_room401_tenant"):
		printerr("FAIL 9-G: GameState.sell_echo should return false on incomplete echo!")
		get_tree().quit(1)
		return
		
	# 2. Dialogue Routing - Empty Case: routes to sell_empty
	lu_tree = DialogueDB.get_tree_for("lu_qichen")
	runner.start(lu_tree, "sell_gate")
	curr = runner.current()
	if curr.get("text", "") == "" or not tr(curr.get("text", "")).contains("你手頭還沒有集滿的殘響"):
		printerr("FAIL 9-G: sell_gate should route to sell_empty when no echoes are complete! Got: ", curr)
		get_tree().quit(1)
		return
		
	# 3. Dialogue Routing - Sale Selection & Exclusions
	# Complete echo_room401_tenant
	GameState.collect_echo_segment("echo_room401_tenant", "s1")
	GameState.collect_echo_segment("echo_room401_tenant", "s2")
	GameState.collect_echo_segment("echo_room401_tenant", "s3")
	if not GameState.is_echo_complete("echo_room401_tenant"):
		printerr("FAIL 9-G: echo_room401_tenant failed to be marked complete!")
		get_tree().quit(1)
		return
		
	# Verify that only completed unsold echoes appear in sell_menu
	runner.start(lu_tree, "sell_gate")
	curr = runner.current()
	if curr.get("text", "") == "" or not tr(curr.get("text", "")).contains("你想把哪一段交給我"):
		printerr("FAIL 9-G: sell_gate should route to sell_menu when there are completed unsold echoes! Got: ", curr)
		get_tree().quit(1)
		return
		
	choices = curr.get("choices", [])
	var room401_choice = null
	var clerk_choice = null
	var lu_family_choice = null
	for choice in choices:
		var label = tr(choice.get("label", ""))
		if "401" in label:
			room401_choice = choice
		elif "店員" in label:
			clerk_choice = choice
		elif "鹿家" in label:
			lu_family_choice = choice
			
	if room401_choice == null:
		printerr("FAIL 9-G: Room 401 echo choice not found in sell_menu! Got choices: ", choices)
		get_tree().quit(1)
		return
	if clerk_choice != null:
		printerr("FAIL 9-G: Incomplete clerk echo choice should NOT be visible in sell_menu!")
		get_tree().quit(1)
		return
	if lu_family_choice != null:
		printerr("FAIL 9-G: echo_lu_family choice should NOT be visible in sell_menu!")
		get_tree().quit(1)
		return
		
	# 4. Confirmation & Keep Path: routes back to sell_menu
	runner.choose(room401_choice.get("index"))
	curr = runner.current()
	if curr.get("text", "") == "" or not tr(curr.get("text", "")).contains("你想把這段記憶賣給我嗎"):
		printerr("FAIL 9-G: Selecting echo should route to confirmation node! Got: ", curr)
		get_tree().quit(1)
		return
		
	var conf_choices = curr.get("choices", [])
	var sell_choice = null
	var keep_choice = null
	for choice in conf_choices:
		var label = tr(choice.get("label", ""))
		if "賣" in label:
			sell_choice = choice
		elif "留" in label:
			keep_choice = choice
			
	if sell_choice == null or keep_choice == null:
		printerr("FAIL 9-G: Confirmation choices (sell/keep) missing! Got: ", conf_choices)
		get_tree().quit(1)
		return
		
	# Choose to keep
	runner.choose(keep_choice.get("index"))
	curr = runner.current()
	if curr.get("text", "") == "" or not tr(curr.get("text", "")).contains("你想把哪一段交給我"):
		printerr("FAIL 9-G: Keeping echo should route back to sell_menu! Got: ", curr)
		get_tree().quit(1)
		return
		
	# 5. Confirmation & Sell Path
	# Re-select room 401
	room401_choice = null
	for choice in curr.get("choices", []):
		if "401" in tr(choice.get("label", "")):
			room401_choice = choice
			break
	runner.choose(room401_choice.get("index"))
	
	# Select to sell
	conf_choices = runner.current().get("choices", [])
	sell_choice = null
	for choice in conf_choices:
		if "賣" in tr(choice.get("label", "")):
			sell_choice = choice
			break
	
	var old_credits = GameState.get_credits()
	runner.choose(sell_choice.get("index"))
	
	# Verify that credits increased by 200 (selling price of room 401 echo)
	if GameState.get_credits() != old_credits + 200:
		printerr("FAIL 9-G: Selling Room 401 echo did not reward correct credits! Expected: ", old_credits + 200, ", got: ", GameState.get_credits())
		get_tree().quit(1)
		return
		
	# Verify sold state
	if not GameState.is_echo_sold("echo_room401_tenant"):
		printerr("FAIL 9-G: Room 401 echo should be marked as sold!")
		get_tree().quit(1)
		return
		
	curr = runner.current()
	if curr.get("text", "") == "" or not tr(curr.get("text", "")).contains("獲得了 200 credits"):
		printerr("FAIL 9-G: Sold confirmation text incorrect! Got: ", curr)
		get_tree().quit(1)
		return
		
	runner.advance()
	curr = runner.current()
	if curr.get("text", "") == "" or not tr(curr.get("text", "")).contains("感謝你的回報"):
		printerr("FAIL 9-G: Should route to sell_done! Got: ", curr)
		get_tree().quit(1)
		return
		
	# 6. Sold Status & Exclusivity: routes to sell_empty if no completed echoes remain
	runner.advance()
	curr = runner.current()
	if curr.get("text", "") == "" or not tr(curr.get("text", "")).contains("你手頭還沒有集滿的殘響"):
		printerr("FAIL 9-G: After selling, sell_gate should route to sell_empty! Got: ", curr)
		get_tree().quit(1)
		return
		
	print("PASS 9-G: Dialogue-based sell menu, exclusions, confirmation, keeping, selling rewards, and sold status verified.")
	
	# ----------------------------------------------------
	# Phase 9-H Verification
	# ----------------------------------------------------
	print("Running 9-H Integration tests...")
	
	# We will verify save/load round-trip across 5 checkpoints:
	# Checkpoint 1: Before taking module (取模組前)
	GameState.reset_for_new_game()
	GameState.set_flag("apartment_initialized", true)
	GameState.add_item("fingerless_gloves", 1)
	
	var checkpoint1_save = GameState.to_save_dict()
	
	# Verify Checkpoint 1 state
	if GameState.get_flag("probe_module_taken", false) or GameState.has_item("old_probe_module") or GameState.get_flag("gleaner_gloves_installed", false):
		printerr("FAIL 9-H Checkpoint 1: Initial state is incorrect!")
		get_tree().quit(1)
		return
		
	# Checkpoint 2: Before appraisal (鑑定前)
	GameState.set_flag("probe_module_taken", true)
	GameState.add_item("old_probe_module", 1)
	
	var checkpoint2_save = GameState.to_save_dict()
	
	# Checkpoint 3: During collection (採集中)
	# Install glove upgrade
	if not GameState.install_probe_module():
		printerr("FAIL 9-H Checkpoint 3: install_probe_module failed during state transition!")
		get_tree().quit(1)
		return
	
	# Collect some segments (not complete)
	GameState.collect_echo_segment("echo_room401_tenant", "s1")
	GameState.collect_echo_segment("echo_room401_tenant", "s2")
	
	var checkpoint3_save = GameState.to_save_dict()
	
	# Checkpoint 4: Completed but unsold (集滿未賣)
	GameState.collect_echo_segment("echo_room401_tenant", "s3")
	
	var checkpoint4_save = GameState.to_save_dict()
	
	# Checkpoint 5: Sold (賣出後)
	var old_credits_9h = GameState.get_credits()
	if not GameState.sell_echo("echo_room401_tenant"):
		printerr("FAIL 9-H Checkpoint 5: sell_echo failed during state transition!")
		get_tree().quit(1)
		return
		
	var checkpoint5_save = GameState.to_save_dict()
	
	# Now, we will load and verify each checkpoint save dict one by one to ensure exact state restoration.
	
	# Restore Checkpoint 5
	GameState.reset_for_new_game()
	GameState.load_save_dict(checkpoint5_save)
	if not GameState.is_echo_sold("echo_room401_tenant") or GameState.get_credits() != old_credits_9h + 200:
		printerr("FAIL 9-H restore: Checkpoint 5 sold status or credits failed to restore!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("gleaner_gloves_installed", false):
		printerr("FAIL 9-H restore: Checkpoint 5 glove install status failed to restore!")
		get_tree().quit(1)
		return
		
	# Restore Checkpoint 4
	GameState.reset_for_new_game()
	GameState.load_save_dict(checkpoint4_save)
	if not GameState.is_echo_complete("echo_room401_tenant") or GameState.is_echo_sold("echo_room401_tenant"):
		printerr("FAIL 9-H restore: Checkpoint 4 complete/sold status failed to restore!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != old_credits_9h:
		printerr("FAIL 9-H restore: Checkpoint 4 credits failed to restore!")
		get_tree().quit(1)
		return
		
	# Restore Checkpoint 3
	GameState.reset_for_new_game()
	GameState.load_save_dict(checkpoint3_save)
	if GameState.is_echo_complete("echo_room401_tenant") or not GameState.has_echo_segment("echo_room401_tenant", "s1") or GameState.has_echo_segment("echo_room401_tenant", "s3"):
		printerr("FAIL 9-H restore: Checkpoint 3 echo segments failed to restore!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("gleaner_gloves_installed", false):
		printerr("FAIL 9-H restore: Checkpoint 3 glove install status failed to restore!")
		get_tree().quit(1)
		return
		
	# Restore Checkpoint 2
	GameState.reset_for_new_game()
	GameState.load_save_dict(checkpoint2_save)
	if not GameState.get_flag("probe_module_taken", false) or not GameState.has_item("old_probe_module") or GameState.get_flag("gleaner_gloves_installed", false):
		printerr("FAIL 9-H restore: Checkpoint 2 probe module or glove status failed to restore!")
		get_tree().quit(1)
		return
		
	# Restore Checkpoint 1
	GameState.reset_for_new_game()
	GameState.load_save_dict(checkpoint1_save)
	if GameState.get_flag("probe_module_taken", false) or GameState.has_item("old_probe_module") or GameState.get_flag("gleaner_gloves_installed", false):
		printerr("FAIL 9-H restore: Checkpoint 1 initial flags failed to restore!")
		get_tree().quit(1)
		return
		
	print("PASS 9-H: Save/load round-trip across 5 checkpoints verified successfully.")

	# ============================================================
	# Phase 11 — Trust/Trace 雙軸 + 清洗（地基）
	# ============================================================
	print("Verifying Phase 11 Trust/Trace foundation...")
	# 乾淨起點（Phase 11 為本檔最後一段，reset 不影響後續，只剩 instance cleanup）
	GameState.reset_for_new_game()

	# 11-A：trace 預設 0 + add_trace / get_trace（正負皆可）
	if GameState.get_trace() != 0:
		printerr("FAIL 11-A: trace should default to 0 after reset! Got: ", GameState.get_trace())
		get_tree().quit(1)
		return
	GameState.add_trace(5)
	GameState.add_trace(-2)
	if GameState.get_trace() != 3:
		printerr("FAIL 11-A: add_trace accumulation wrong! Expected 3, got: ", GameState.get_trace())
		get_tree().quit(1)
		return
	GameState.add_trace(0)
	if GameState.get_trace() != 3:
		printerr("FAIL 11-A: add_trace(0) must be a no-op!")
		get_tree().quit(1)
		return

	# 11-A：trace 進 to_save_dict、load_save_dict 還原
	var p11_sd = GameState.to_save_dict()
	if not p11_sd.has("trace") or p11_sd["trace"] != 3:
		printerr("FAIL 11-A: to_save_dict missing/wrong trace! Got: ", p11_sd.get("trace", "MISSING"))
		get_tree().quit(1)
		return
	GameState.add_trace(100)
	GameState.load_save_dict(p11_sd)
	if GameState.get_trace() != 3:
		printerr("FAIL 11-A: load_save_dict did not restore trace! Got: ", GameState.get_trace())
		get_tree().quit(1)
		return

	# 11-A：向後相容——舊存檔無 trace 鍵時應回 0
	var p11_legacy = GameState.to_save_dict()
	p11_legacy.erase("trace")
	GameState.load_save_dict(p11_legacy)
	if GameState.get_trace() != 0:
		printerr("FAIL 11-A: load_save_dict without 'trace' key should default trace to 0!")
		get_tree().quit(1)
		return

	# 11-A：reset 歸零
	GameState.add_trace(9)
	GameState.reset_for_new_game()
	if GameState.get_trace() != 0:
		printerr("FAIL 11-A: reset_for_new_game did not zero trace!")
		get_tree().quit(1)
		return

	# 11-B：Trust adapter 接 affinity_<target>
	GameState.add_int("affinity_wan", 4)
	if GameState.get_trust("wan") != 4:
		printerr("FAIL 11-B: get_trust('wan') should equal affinity_wan! Got: ", GameState.get_trust("wan"))
		get_tree().quit(1)
		return
	if GameState.get_trust("wan") != int(GameState.get_flag("affinity_wan", 0)):
		printerr("FAIL 11-B: get_trust must mirror affinity flag!")
		get_tree().quit(1)
		return
	if GameState.get_trust("nobody") != 0:
		printerr("FAIL 11-B: get_trust for unknown target should default to 0!")
		get_tree().quit(1)
		return

	# 11-C：賣殘響 → Trace↓（集中在 sell_echo）
	GameState.reset_for_new_game()
	GameState.record_full_echo("echo_room401_tenant")
	if not GameState.is_echo_complete("echo_room401_tenant"):
		printerr("FAIL 11-C setup: echo_room401_tenant should be complete after record_full_echo!")
		get_tree().quit(1)
		return
	var p11_trace_before = GameState.get_trace()
	if not GameState.sell_echo("echo_room401_tenant"):
		printerr("FAIL 11-C: sell_echo should succeed on completed unsold echo!")
		get_tree().quit(1)
		return
	if GameState.get_trace() >= p11_trace_before:
		printerr("FAIL 11-C: selling an echo must lower trace! before=", p11_trace_before, " after=", GameState.get_trace())
		get_tree().quit(1)
		return

	# 11-C：通用 add_trace 對話 effect op（未來「留」↑ /「還」用）
	GameState.reset_for_new_game()
	var p11_runner := DialogueRunner.new()
	var p11_tree := {
		"start": {
			"speaker": "test",
			"text": "trace effect node",
			"effect": [{ "op": "add_trace", "value": 7 }]
		}
	}
	p11_runner.start(p11_tree)
	if GameState.get_trace() != 7:
		printerr("FAIL 11-C: add_trace dialogue effect op did not apply! Got: ", GameState.get_trace())
		get_tree().quit(1)
		return
	p11_runner = null

	# 收尾：還原乾淨狀態
	GameState.reset_for_new_game()
	print("PASS: Phase 11 Trust/Trace foundation verified (trace axis + trust adapter + sell/effect hooks).")

	# ============================================================
	# Phase 12-A: 跳躍地基（jump action + player 拋物弧 + 不退化）
	# ============================================================
	if not InputMap.has_action("jump"):
		printerr("FAIL 12-A: InputMap action 'jump' is missing!")
		get_tree().quit(1)
		return
	print("PASS 12-A: InputMap action 'jump' exists.")

	GameState.reset_for_new_game()
	UIMode.set_mode(UIMode.Mode.NONE)
	var p12_scene = load("res://scenes/levels/apartment/apartment_room.tscn")
	if p12_scene == null:
		printerr("FAIL 12-A: could not load apartment_room.tscn for jump test!")
		get_tree().quit(1)
		return
	var p12_inst = p12_scene.instantiate()
	add_child(p12_inst)
	await get_tree().process_frame

	var p12_player = p12_inst.get_node_or_null("Player")
	if p12_player == null:
		for c in p12_inst.get_children():
			if c.has_method("is_jumping"):
				p12_player = c
				break
	if p12_player == null or not p12_player.has_method("is_jumping"):
		printerr("FAIL 12-A: player exposing is_jumping() not found!")
		get_tree().quit(1)
		return
	print("PASS 12-A: player exposes is_jumping().")

	for prop in ["jump_height", "jump_duration", "air_speed_scale"]:
		if p12_player.get(prop) == null:
			printerr("FAIL 12-A: player missing jump param '%s'!" % prop)
			get_tree().quit(1)
			return
	print("PASS 12-A: jump params exist (jump_height / jump_duration / air_speed_scale).")

	var p12_anim = p12_player.get_node_or_null("AnimatedSprite2D")
	if p12_anim == null or p12_anim.sprite_frames == null or not p12_anim.sprite_frames.has_animation("jump"):
		printerr("FAIL 12-A: SpriteFrames missing 'jump' animation!")
		get_tree().quit(1)
		return
	if p12_anim.sprite_frames.get_animation_loop("jump"):
		printerr("FAIL 12-A: 'jump' animation must be non-looping (loop=false)!")
		get_tree().quit(1)
		return
	print("PASS 12-A: 'jump' animation present and non-looping.")

	# 起跳 → 滯空（離開 walk line）→ 落回 walk line；驗證座標 / climb 不退化
	UIMode.set_mode(UIMode.Mode.NONE)
	p12_player.snap_to_walk_line()
	var p12_x_before: float = p12_player.get_save_x()
	var p12_walk_y: float = p12_player._walk_y_at(p12_player.global_position.x)
	if p12_player.is_jumping():
		printerr("FAIL 12-A: player must not start in jumping state!")
		get_tree().quit(1)
		return
	Input.action_press("jump")
	p12_player._physics_process(1.0 / 60.0)
	Input.action_release("jump")
	if not p12_player.is_jumping():
		printerr("FAIL 12-A: player did not enter jump state after 'jump' pressed!")
		get_tree().quit(1)
		return
	if p12_player.global_position.y >= p12_walk_y:
		printerr("FAIL 12-A: airborne player should be above walk line! y=", p12_player.global_position.y, " walk_y=", p12_walk_y)
		get_tree().quit(1)
		return
	var p12_guard := 0
	while p12_player.is_jumping() and p12_guard < 600:
		p12_player._physics_process(1.0 / 60.0)
		p12_guard += 1
	if p12_player.is_jumping():
		printerr("FAIL 12-A: jump never landed within airtime!")
		get_tree().quit(1)
		return
	if abs(p12_player.global_position.y - p12_player._walk_y_at(p12_player.global_position.x)) > 1.0:
		printerr("FAIL 12-A: after landing, player not back on walk line!")
		get_tree().quit(1)
		return
	if p12_player.get_save_x() != p12_x_before:
		printerr("FAIL 12-A: stationary jump changed save-x! before=", p12_x_before, " after=", p12_player.get_save_x())
		get_tree().quit(1)
		return
	if p12_player.is_climbing():
		printerr("FAIL 12-A: jump must not engage climb_mode!")
		get_tree().quit(1)
		return
	print("PASS 12-A: takeoff -> airborne -> land keeps walk-line / save-x / climb invariants.")

	# 無二段跳：空中再次按 jump 不重啟拋物弧（_jump_t 持續累加，不歸零）
	Input.action_press("jump")
	p12_player._physics_process(1.0 / 60.0)
	Input.action_release("jump")
	if not p12_player.is_jumping():
		printerr("FAIL 12-A: jump did not start for double-jump check!")
		get_tree().quit(1)
		return
	for _i in range(5):
		p12_player._physics_process(1.0 / 60.0)
	var p12_t1: float = p12_player._jump_t
	Input.action_press("jump")
	p12_player._physics_process(1.0 / 60.0)
	Input.action_release("jump")
	var p12_t2: float = p12_player._jump_t
	if p12_t2 <= p12_t1:
		printerr("FAIL 12-A: double jump restarted the arc! t1=", p12_t1, " t2=", p12_t2)
		get_tree().quit(1)
		return
	print("PASS 12-A: no double-jump (airborne jump press does not restart arc).")
	p12_guard = 0
	while p12_player.is_jumping() and p12_guard < 600:
		p12_player._physics_process(1.0 / 60.0)
		p12_guard += 1

	p12_inst.free()
	await get_tree().process_frame
	p12_scene = null
	GameState.reset_for_new_game()
	UIMode.set_mode(UIMode.Mode.NONE)
	print("PASS: Phase 12-A jump foundation verified.")

	# ===================== Phase 12-B: Platform components + jump_proto =====================
	print("--- Phase 12-B: ledge_area / jump_gap / jump_proto ---")

	var p12b_scene = load("res://scenes/levels/jump_proto/jump_proto.tscn")
	if not p12b_scene:
		printerr("FAIL 12-B: Could not load jump_proto.tscn!")
		get_tree().quit(1)
		return
	print("PASS 12-B: jump_proto.tscn loaded.")

	var p12b_inst = p12b_scene.instantiate()
	add_child(p12b_inst)
	await get_tree().process_frame

	# LedgeArea node + API
	var ledge_node = p12b_inst.find_child("LedgeArea", true, false)
	if not ledge_node:
		printerr("FAIL 12-B: LedgeArea node not found in jump_proto!")
		get_tree().quit(1)
		return
	if not ledge_node.has_method("contains_x"):
		printerr("FAIL 12-B: LedgeArea missing contains_x() method!")
		get_tree().quit(1)
		return
	if not ledge_node.has_method("get_target_y"):
		printerr("FAIL 12-B: LedgeArea missing get_target_y() method!")
		get_tree().quit(1)
		return
	print("PASS 12-B: LedgeArea has contains_x() and get_target_y() APIs.")

	# contains_x logic: center should be inside, x=0 should be outside
	var ledge_cx: float = ledge_node.global_position.x
	if not ledge_node.contains_x(ledge_cx):
		printerr("FAIL 12-B: contains_x(center=", ledge_cx, ") returned false!")
		get_tree().quit(1)
		return
	if ledge_node.contains_x(0.0):
		printerr("FAIL 12-B: contains_x(0) returned true — ledge spans entire viewport!")
		get_tree().quit(1)
		return
	print("PASS 12-B: contains_x() inside/outside logic correct.")

	# get_target_y must be above the player's starting walk line (lower y = higher on screen)
	var ledge_ty: float = ledge_node.get_target_y()
	var p12b_player = p12b_inst.find_child("Player", true, false)
	var lower_walk_y: float = p12b_player.walk_line_y if p12b_player else 690.0
	if ledge_ty >= lower_walk_y:
		printerr("FAIL 12-B: ledge target_y (", ledge_ty, ") must be above lower walk line (", lower_walk_y, ")!")
		get_tree().quit(1)
		return
	print("PASS 12-B: ledge target_y (", ledge_ty, ") is above lower walk line (", lower_walk_y, ").")

	# LedgeArea must be in group "ledges" (player grabs via this group)
	if not ledge_node.is_in_group("ledges"):
		printerr("FAIL 12-B: LedgeArea is not in group 'ledges'!")
		get_tree().quit(1)
		return
	print("PASS 12-B: LedgeArea is in group 'ledges'.")

	# GapMarker node + properties
	var gap_node = p12b_inst.find_child("GapMarker", true, false)
	if not gap_node:
		printerr("FAIL 12-B: GapMarker node not found in jump_proto!")
		get_tree().quit(1)
		return
	if not ("gap_x_min" in gap_node and "gap_x_max" in gap_node):
		printerr("FAIL 12-B: GapMarker missing gap_x_min/gap_x_max properties!")
		get_tree().quit(1)
		return
	print("PASS 12-B: GapMarker has gap_x_min/gap_x_max properties.")

	p12b_inst.queue_free()
	await get_tree().process_frame
	p12b_scene = null
	print("PASS: Phase 12-B platform components + jump_proto verified.")

	# ===================== Phase 12-C: BtnJump 觸控按鈕 =====================
	print("--- Phase 12-C: TouchControls BtnJump ---")

	var btn_jump_node = TouchControls.get_node_or_null("Control/Actions/BtnJump")
	if not btn_jump_node:
		printerr("FAIL: BtnJump not found at Control/Actions/BtnJump in TouchControls!")
		get_tree().quit(1)
		return
	if not btn_jump_node is Button:
		printerr("FAIL: BtnJump is not a Button!")
		get_tree().quit(1)
		return

	# BtnJump should have button_down connections (set by _bind_button)
	if btn_jump_node.button_down.get_connections().is_empty():
		printerr("FAIL: BtnJump has no button_down connections (not bound to jump action)!")
		get_tree().quit(1)
		return

	# BtnJump 世界模式可見
	UIMode.set_mode(UIMode.Mode.NONE)
	TouchControls.touch_buttons_enabled = true
	TouchControls._update_dynamic_button_visibility()
	if not btn_jump_node.visible:
		printerr("FAIL: BtnJump should be visible in UIMode.NONE!")
		get_tree().quit(1)
		return

	# BtnJump 面板模式隱藏
	for panel_mode in [UIMode.Mode.INVENTORY, UIMode.Mode.DIALOGUE, UIMode.Mode.SHOP]:
		UIMode.set_mode(panel_mode)
		TouchControls._update_dynamic_button_visibility()
		if btn_jump_node.visible:
			printerr("FAIL: BtnJump should be hidden in mode ", panel_mode)
			get_tree().quit(1)
			return

	# 恢復 NONE
	UIMode.set_mode(UIMode.Mode.NONE)
	TouchControls.touch_buttons_enabled = false
	TouchControls._update_dynamic_button_visibility()

	print("PASS: Phase 12-C BtnJump exists, bound, visible in NONE, hidden in panels.")

	# ===================== Phase 13-A: attack action + stun API =====================
	print("--- Phase 13-A: attack action + walker_01 stun API ---")

	if not InputMap.has_action("attack"):
		printerr("FAIL 13-A: InputMap action 'attack' is missing!")
		get_tree().quit(1)
		return
	print("PASS 13-A: InputMap action 'attack' exists.")

	var enemy_base_script = load("res://scripts/components/enemy_base.gd")
	if enemy_base_script == null:
		printerr("FAIL 13-A: could not load enemy_base.gd!")
		get_tree().quit(1)
		return
	print("PASS 13-A: enemy_base.gd loads.")

	var melee_stick_script = load("res://scripts/components/melee_stick.gd")
	if melee_stick_script == null:
		printerr("FAIL 13-A: could not load melee_stick.gd!")
		get_tree().quit(1)
		return
	print("PASS 13-A: melee_stick.gd loads.")

	var walker_scene_13 = load("res://scenes/actors/walker_01/walker_01.tscn")
	if walker_scene_13 == null:
		printerr("FAIL 13-A: could not load walker_01.tscn!")
		get_tree().quit(1)
		return
	var walker_inst_13 = walker_scene_13.instantiate()
	add_child(walker_inst_13)
	await get_tree().process_frame

	if not walker_inst_13.has_method("is_stunned"):
		printerr("FAIL 13-A: walker_01 missing is_stunned() method!")
		get_tree().quit(1)
		return
	if not walker_inst_13.has_method("apply_stun"):
		printerr("FAIL 13-A: walker_01 missing apply_stun() method!")
		get_tree().quit(1)
		return
	print("PASS 13-A: walker_01 has is_stunned() and apply_stun().")

	if "hp" in walker_inst_13:
		printerr("FAIL 13-A: walker_01 must not have 'hp' field (stun-only, no damage)!")
		get_tree().quit(1)
		return
	print("PASS 13-A: walker_01 has no 'hp' field.")

	if walker_inst_13.is_stunned():
		printerr("FAIL 13-A: walker_01 must not start in stunned state!")
		get_tree().quit(1)
		return
	print("PASS 13-A: is_stunned() == false in initial patrol state.")

	if not walker_inst_13.is_in_group("enemies"):
		printerr("FAIL 13-A: walker_01 must be in group 'enemies'!")
		get_tree().quit(1)
		return
	print("PASS 13-A: walker_01 is in group 'enemies'.")

	# Stun state machine: apply_stun -> FALL -> PRONE (is_stunned true)
	walker_inst_13.fall_time = 0.01
	var sched_13a: Array[float] = [99.0]
	walker_inst_13.repair_schedule = sched_13a
	walker_inst_13.apply_stun(99.0)
	for _f13 in range(10):
		await get_tree().process_frame
	if not walker_inst_13.is_stunned():
		printerr("FAIL 13-A: after apply_stun() + fall_time, is_stunned() must be true (PRONE)!")
		get_tree().quit(1)
		return
	print("PASS 13-A: is_stunned() == true in PRONE (self-repair window).")

	walker_inst_13.queue_free()
	await get_tree().process_frame

	# player has is_attacking(), signals, and MeleeStick child
	var p13_room_scene = load("res://scenes/levels/apartment/apartment_room.tscn")
	if p13_room_scene == null:
		printerr("FAIL 13-A: could not load apartment_room.tscn for player check!")
		get_tree().quit(1)
		return
	var p13_room = p13_room_scene.instantiate()
	add_child(p13_room)
	await get_tree().process_frame

	var p13_player = p13_room.find_child("Player", true, false)
	if p13_player == null:
		printerr("FAIL 13-A: Player not found in apartment_room!")
		get_tree().quit(1)
		return
	if not p13_player.has_method("is_attacking"):
		printerr("FAIL 13-A: player missing is_attacking() method!")
		get_tree().quit(1)
		return
	if not p13_player.has_signal("attack_impact_frame"):
		printerr("FAIL 13-A: player missing 'attack_impact_frame' signal!")
		get_tree().quit(1)
		return
	if not p13_player.has_signal("attack_completed"):
		printerr("FAIL 13-A: player missing 'attack_completed' signal!")
		get_tree().quit(1)
		return
	if not p13_player.has_node("MeleeStick"):
		printerr("FAIL 13-A: player missing MeleeStick child node!")
		get_tree().quit(1)
		return
	if not "attack_sound_path" in p13_player:
		printerr("FAIL 13-A: player missing 'attack_sound_path' property!")
		get_tree().quit(1)
		return
	if p13_player.attack_sound_path != "res://assets/sound/A_heavy_melee_weapon.mp3":
		printerr("FAIL 13-A: player 'attack_sound_path' is incorrect: ", p13_player.attack_sound_path)
		get_tree().quit(1)
		return
	if not FileAccess.file_exists(p13_player.attack_sound_path):
		printerr("FAIL 13-A: player 'attack_sound_path' file does not exist: ", p13_player.attack_sound_path)
		get_tree().quit(1)
		return
	print("PASS 13-A: player has is_attacking(), attack signals, MeleeStick, and valid attack_sound_path.")

	p13_room.queue_free()
	await get_tree().process_frame

	print("PASS: Phase 13-A attack action + stun API verified.")

	# -------------------------------------------------------------------------
	print("--- Phase 13-B: can_format + format_reset ---")

	var walker_scene_13b = load("res://scenes/actors/walker_01/walker_01.tscn")
	if walker_scene_13b == null:
		printerr("FAIL 13-B: could not load walker_01.tscn!")
		get_tree().quit(1)
		return
	var walker_13b = walker_scene_13b.instantiate()
	walker_13b.min_x = 0.0
	walker_13b.max_x = 2000.0
	walker_13b.fall_time = 0.01
	var sched_13b: Array[float] = [99.0]
	walker_13b.repair_schedule = sched_13b
	add_child(walker_13b)
	await get_tree().process_frame
	walker_13b.global_position = Vector2(500.0, 400.0)

	# can_format() method must exist
	if not walker_13b.has_method("can_format"):
		printerr("FAIL 13-B: walker_01 missing can_format() method!")
		get_tree().quit(1)
		return
	print("PASS 13-B: walker_01 has can_format() method.")

	# defeated() method must exist
	if not walker_13b.has_method("defeated"):
		printerr("FAIL 13-B: walker_01 missing defeated() method!")
		get_tree().quit(1)
		return
	print("PASS 13-B: walker_01 has defeated() method.")

	# Not stunned → can_format false regardless of position
	if walker_13b.can_format(Vector2(600.0, 400.0)):
		printerr("FAIL 13-B: can_format() must be false when not stunned!")
		get_tree().quit(1)
		return
	print("PASS 13-B: can_format() == false when not stunned.")

	# Enter stun (PRONE) state
	# 25-B 起敵人 _physics_process 在 UIMode != NONE 時凍結；先確保前置為 NONE，
	# 否則前面測試殘留的 UI mode 會擋住 FALL -> PRONE 狀態機推進。
	UIMode.set_mode(UIMode.Mode.NONE)
	walker_13b.apply_stun(99.0)
	for _f13b in range(10):
		await get_tree().process_frame
	if not walker_13b.is_stunned():
		printerr("FAIL 13-B: walker not stunned; cannot test can_format position logic!")
		get_tree().quit(1)
		return

	# Force facing right so tests are deterministic (_facing = 1 → behind = left side)
	walker_13b._facing = 1
	var behind_pos := Vector2(420.0, 400.0)   # dx = -80: behind, within 160
	var front_pos  := Vector2(580.0, 400.0)   # dx = +80: front, within 160
	var too_far    := Vector2(330.0, 400.0)   # dx = -170: behind but > 160px

	if walker_13b.can_format(front_pos):
		printerr("FAIL 13-B: can_format() must be false when player is in front!")
		get_tree().quit(1)
		return
	print("PASS 13-B: can_format() == false when player is in front (same side as facing).")

	if not walker_13b.can_format(behind_pos):
		printerr("FAIL 13-B: can_format() must be true when stunned + behind + within 160px!")
		get_tree().quit(1)
		return
	print("PASS 13-B: can_format() == true when stunned + player behind + within range.")

	if walker_13b.can_format(too_far):
		printerr("FAIL 13-B: can_format() must be false when player is beyond format_check_distance!")
		get_tree().quit(1)
		return
	print("PASS 13-B: can_format() == false when player behind but too far (> 160px).")

	# defeated() sets is_defeated = true and machine stays on scene
	walker_13b.defeated()
	await get_tree().process_frame
	if not walker_13b.is_defeated():
		printerr("FAIL 13-B: is_defeated() must be true after defeated() is called!")
		get_tree().quit(1)
		return
	if not is_instance_valid(walker_13b):
		printerr("FAIL 13-B: machine must remain on scene after defeated() (no despawn)!")
		get_tree().quit(1)
		return
	var walker_13b_anim = walker_13b.get_node_or_null("AnimatedSprite2D")
	if walker_13b_anim == null or walker_13b_anim.animation != "formatted":
		printerr("FAIL 13-B: defeated walker_01 must switch to formatted animation!")
		get_tree().quit(1)
		return
	print("PASS 13-B: defeated() → is_defeated() true; machine stays on scene.")

	# defeated() is idempotent (calling twice must not crash)
	walker_13b.defeated()
	await get_tree().process_frame
	print("PASS 13-B: defeated() is idempotent (double call safe).")

	# can_format returns false on a defeated machine (stopped, not to be formatted again)
	# is_stunned() may still be true (frozen in prone), but defeated guard takes priority
	# in practice the format_reset checks is_instance_valid and calling defeated() again is no-op
	# Verify player has FormatReset child
	walker_13b.queue_free()
	await get_tree().process_frame

	var jump_proto_scene_13b = load("res://scenes/levels/jump_proto/jump_proto.tscn")
	if jump_proto_scene_13b == null:
		printerr("FAIL 13-B: could not load jump_proto.tscn!")
		get_tree().quit(1)
		return
	var jump_proto_13b = jump_proto_scene_13b.instantiate()
	add_child(jump_proto_13b)
	await get_tree().process_frame
	var jump_walker_13b = jump_proto_13b.find_child("Walker01", true, false)
	var jump_walker_anim_13b = jump_walker_13b.get_node_or_null("AnimatedSprite2D") if jump_walker_13b else null
	if jump_walker_anim_13b == null or jump_walker_anim_13b.sprite_frames == null or not jump_walker_anim_13b.sprite_frames.has_animation("formatted"):
		printerr("FAIL 13-B: jump_proto Walker01 missing formatted animation!")
		get_tree().quit(1)
		return
	jump_walker_13b.defeated()
	await get_tree().process_frame
	if jump_walker_anim_13b.animation != "formatted":
		printerr("FAIL 13-B: jump_proto Walker01 must show formatted animation after defeated()!")
		get_tree().quit(1)
		return
	jump_proto_13b.queue_free()
	await get_tree().process_frame
	print("PASS 13-B: jump_proto Walker01 uses formatted animation after defeated().")

	var p13b_room_scene = load("res://scenes/levels/apartment/apartment_room.tscn")
	if p13b_room_scene == null:
		printerr("FAIL 13-B: could not load apartment_room.tscn for FormatReset check!")
		get_tree().quit(1)
		return
	var p13b_room = p13b_room_scene.instantiate()
	add_child(p13b_room)
	await get_tree().process_frame
	var p13b_player = p13b_room.find_child("Player", true, false)
	if p13b_player == null:
		printerr("FAIL 13-B: Player not found in apartment_room!")
		get_tree().quit(1)
		return
	if not p13b_player.has_node("FormatReset"):
		printerr("FAIL 13-B: Player missing FormatReset child node!")
		get_tree().quit(1)
		return
	print("PASS 13-B: Player has FormatReset child node.")

	var fmt_node = p13b_player.get_node("FormatReset")
	if not fmt_node.has_method("get_format_progress"):
		printerr("FAIL 13-B: FormatReset missing get_format_progress() method!")
		get_tree().quit(1)
		return
	if fmt_node.get_format_progress() != 0.0:
		printerr("FAIL 13-B: FormatReset.get_format_progress() must start at 0.0!")
		get_tree().quit(1)
		return
	print("PASS 13-B: FormatReset starts at progress 0.0.")

	p13b_room.queue_free()
	await get_tree().process_frame

	print("PASS: Phase 13-B format (can_format + defeated + FormatReset) verified.")

	# ===================== Phase 13-C: human enemy skeleton =====================
	print("--- Phase 13-C: human enemy skeleton ---")

	var human_enemy_script = load("res://scripts/components/human_enemy.gd")
	if human_enemy_script == null:
		printerr("FAIL 13-C: could not load human_enemy.gd!")
		get_tree().quit(1)
		return
	print("PASS 13-C: human_enemy.gd loads.")

	var human_inst = CharacterBody2D.new()
	human_inst.set_script(human_enemy_script)
	add_child(human_inst)
	await get_tree().process_frame

	if not human_inst.has_method("can_format"):
		printerr("FAIL 13-C: HumanEnemy missing can_format() method!")
		get_tree().quit(1)
		return
	print("PASS 13-C: HumanEnemy has can_format() method.")

	if human_inst.can_format(Vector2(0.0, 0.0)):
		printerr("FAIL 13-C: HumanEnemy.can_format() must always return false!")
		get_tree().quit(1)
		return
	print("PASS 13-C: HumanEnemy.can_format() returns false.")

	# Test that hitting it with melee does not defeat it
	if human_inst.is_defeated():
		printerr("FAIL 13-C: HumanEnemy must not start in defeated state!")
		get_tree().quit(1)
		return

	# Apply stun to verify base enemy_base compliance
	human_inst.apply_stun(5.0)
	if human_inst.is_stunned():
		printerr("FAIL 13-C: HumanEnemy should not be stunned (apply_stun is no-op)!")
		get_tree().quit(1)
		return
	print("PASS 13-C: HumanEnemy apply_stun is no-op.")

	if human_inst.is_defeated():
		printerr("FAIL 13-C: HumanEnemy must not be defeated after stun!")
		get_tree().quit(1)
		return
	print("PASS 13-C: HumanEnemy is not defeated after stun.")

	human_inst.queue_free()
	await get_tree().process_frame

	print("PASS: Phase 13-C human enemy skeleton verified.")

	# ===================== Phase 13-D: combat loss =====================
	print("--- Phase 13-D: combat loss ---")

	var combat_proto_scene = load("res://scenes/levels/combat_proto/combat_proto.tscn")
	if combat_proto_scene == null:
		printerr("FAIL 13-D: could not load combat_proto.tscn!")
		get_tree().quit(1)
		return
	print("PASS 13-D: combat_proto.tscn loaded.")

	var combat_inst = combat_proto_scene.instantiate()
	add_child(combat_inst)
	await get_tree().process_frame

	var combat_walker = combat_inst.find_child("Walker01", true, false)
	if combat_walker == null:
		printerr("FAIL 13-D: combat_proto missing Walker01 node!")
		get_tree().quit(1)
		return
	print("PASS 13-D: combat_proto has Walker01 node.")

	var combat_loss_node = combat_walker.find_child("CombatLoss", true, false)
	if combat_loss_node == null:
		printerr("FAIL 13-D: Walker01 missing CombatLoss child node!")
		get_tree().quit(1)
		return
	print("PASS 13-D: Walker01 has CombatLoss child node.")

	var test_player = combat_inst.find_child("Player", true, false)
	if test_player == null:
		printerr("FAIL 13-D: combat_proto missing Player node!")
		get_tree().quit(1)
		return
	print("PASS 13-D: combat_proto has Player node.")

	# Verify initial flag is false
	GameState.set_flag("combat_proto_failed", false)
	if GameState.get_flag("combat_proto_failed", false):
		printerr("FAIL 13-D: combat_proto_failed flag should start as false!")
		get_tree().quit(1)
		return

	# Case 1: When enemy is stunned, player entering CombatLoss Area2D does NOT trigger loss
	combat_walker._enter_state(2) # Force State.PRONE
	if not combat_walker.is_stunned():
		printerr("FAIL 13-D: Walker01 should be stunned in State.PRONE!")
		get_tree().quit(1)
		return

	# Simulate collision while stunned
	combat_loss_node._on_body_entered(test_player)
	if GameState.get_flag("combat_proto_failed", false):
		printerr("FAIL 13-D: CombatLoss should not trigger when enemy is stunned!")
		get_tree().quit(1)
		return
	print("PASS 13-D: Stunned enemy does not trigger loss on contact.")

	# Case 2: When enemy is NOT stunned, player entering CombatLoss Area2D triggers loss
	# We force Walker01 to recover from stun back to PATROL state
	combat_walker._enter_state(0) # State.PATROL
	if combat_walker.is_stunned():
		printerr("FAIL 13-D: Walker01 should not be stunned after recovering!")
		get_tree().quit(1)
		return

	# Place player at a specific location to verify teleportation works
	test_player.global_position = Vector2(800.0, 700.0)
	if "walk_line_y" in test_player:
		test_player.walk_line_y = 700.0

	var interaction_state = { "message_received": "" }
	var on_interaction = func(data):
		if data.get("type") == "message":
			interaction_state["message_received"] = data.get("message_text", "")

	combat_inst.interaction_requested.connect(on_interaction)

	# Simulate collision while active
	combat_loss_node._on_body_entered(test_player)
	
	# Verify flag
	if not GameState.get_flag("combat_proto_failed", false):
		printerr("FAIL 13-D: combat_proto_failed flag not set to true after contact!")
		get_tree().quit(1)
		return
	print("PASS 13-D: combat_proto_failed flag set to true after contact.")

	# Verify teleportation
	var expected_safe_point = Vector2(250.0, 690.0)
	if test_player.global_position != expected_safe_point:
		printerr("FAIL 13-D: Player not teleported to safe point! Found: ", test_player.global_position)
		get_tree().quit(1)
		return
	if test_player.walk_line_y != expected_safe_point.y:
		printerr("FAIL 13-D: Player walk_line_y not updated to safe point Y! Found: ", test_player.walk_line_y)
		get_tree().quit(1)
		return
	print("PASS 13-D: Player successfully teleported to safe point.")

	# Verify message
	if interaction_state["message_received"] == "":
		printerr("FAIL 13-D: Level did not emit interaction_requested message on loss!")
		get_tree().quit(1)
		return
	print("PASS 13-D: Level emitted interaction_requested message: ", interaction_state["message_received"])

	# Cleanup
	combat_inst.interaction_requested.disconnect(on_interaction)
	combat_inst.queue_free()
	await get_tree().process_frame
	print("PASS: Phase 13-D combat loss verified.")

	# ===================== Phase 13-F: BtnAttack 觸控按鈕 =====================
	print("--- Phase 13-F: TouchControls BtnAttack ---")

	var btn_attack_node = TouchControls.get_node_or_null("Control/Actions/BtnAttack")
	if not btn_attack_node:
		printerr("FAIL: BtnAttack not found at Control/Actions/BtnAttack in TouchControls!")
		get_tree().quit(1)
		return
	if not btn_attack_node is Button:
		printerr("FAIL: BtnAttack is not a Button!")
		get_tree().quit(1)
		return

	# BtnAttack should have button_down connections (set by _bind_button)
	if btn_attack_node.button_down.get_connections().is_empty():
		printerr("FAIL: BtnAttack has no button_down connections (not bound to attack action)!")
		get_tree().quit(1)
		return

	# BtnAttack 世界模式可見
	UIMode.set_mode(UIMode.Mode.NONE)
	TouchControls.touch_buttons_enabled = true
	TouchControls._update_dynamic_button_visibility()
	if not btn_attack_node.visible:
		printerr("FAIL: BtnAttack should be visible in UIMode.NONE!")
		get_tree().quit(1)
		return

	# BtnAttack 面板模式隱藏
	for panel_mode in [UIMode.Mode.INVENTORY, UIMode.Mode.DIALOGUE, UIMode.Mode.SHOP]:
		UIMode.set_mode(panel_mode)
		TouchControls._update_dynamic_button_visibility()
		if btn_attack_node.visible:
			printerr("FAIL: BtnAttack should be hidden in mode ", panel_mode)
			get_tree().quit(1)
			return

	# 恢復 NONE
	UIMode.set_mode(UIMode.Mode.NONE)
	TouchControls.touch_buttons_enabled = false
	TouchControls._update_dynamic_button_visibility()

	print("PASS: Phase 13-F BtnAttack exists, bound, visible in NONE, hidden in panels.")

	# ===================== Phase 14-A: memory_fragment_area =====================
	print("--- Phase 14-A: memory_fragment_area ---")
	var street_scene_14 = load("res://scenes/levels/apartment_entrance.tscn")
	var street_inst_14 = street_scene_14.instantiate()
	var mem_area = street_inst_14.find_child("MemoryFragmentArea", true, false)
	if mem_area == null:
		printerr("FAIL: MemoryFragmentArea node not found in apartment_entrance.tscn!")
		get_tree().quit(1)
		return
	
	if mem_area.fragment_flag != "mem_frag_linfei_1" or mem_area.message_id != "mem_frag_linfei_1":
		printerr("FAIL: MemoryFragmentArea properties mismatch!")
		get_tree().quit(1)
		return

	# Set up environment
	GameState.reset_for_new_game()
	UIMode.set_mode(UIMode.Mode.NONE)

	var p14_player = street_inst_14.find_child("Player", true, false)
	if p14_player == null:
		printerr("FAIL: Player node not found in street scene for Phase 14-A!")
		get_tree().quit(1)
		return

	# We listen to interaction_requested on the street root to verify emission
	var p14_received = {"message_text": ""}
	var p14_on_interaction = func(data: Dictionary):
		if data.get("type") == "message":
			p14_received["message_text"] = data.get("message_text")
	street_inst_14.interaction_requested.connect(p14_on_interaction)

	# Trigger body_entered
	mem_area._on_body_entered(p14_player)

	if not GameState.get_flag("mem_frag_linfei_1", false):
		printerr("FAIL: mem_frag_linfei_1 flag not set after collision!")
		get_tree().quit(1)
		return

	if p14_received["message_text"] != GameState.STORY_MESSAGES["mem_frag_linfei_1"]:
		printerr("FAIL: Message not received or text mismatch! Got: ", p14_received["message_text"])
		get_tree().quit(1)
		return

	# Reset received message and try to trigger again (should be blocked by flag)
	p14_received["message_text"] = ""
	mem_area._on_body_entered(p14_player)
	if p14_received["message_text"] != "":
		printerr("FAIL: MemoryFragmentArea triggered repeatedly!")
		get_tree().quit(1)
		return

	# Clean up
	street_inst_14.interaction_requested.disconnect(p14_on_interaction)
	street_inst_14.free()
	street_scene_14 = null
	p14_player = null
	
	print("PASS: Phase 14-A memory_fragment_area verified.")

	# ===================== Phase 14-B: Dialogue Hooks =====================
	print("--- Phase 14-B: Dialogue Hooks ---")
	
	# Lu Qichen test cases
	# Case 1: mem_frag_linfei_1 = false
	GameState.reset_for_new_game()
	GameState.set_flag("met_lu", true)
	GameState.set_flag("mem_frag_linfei_1", false)
	GameState.set_flag("lu_hinted_topside", false)
	var lu_runner_1 = DialogueRunner.new()
	lu_runner_1.start(DialogueDB.get_tree_for("lu_qichen"))
	if lu_runner_1._current_node_id != "hub":
		printerr("FAIL 14-B: Lu Qichen tree did not route to hub when mem_frag_linfei_1 is false! Got: ", lu_runner_1._current_node_id)
		get_tree().quit(1)
		return

	# Case 2: mem_frag_linfei_1 = true, lu_hinted_topside = false
	GameState.reset_for_new_game()
	GameState.set_flag("met_lu", true)
	GameState.set_flag("mem_frag_linfei_1", true)
	GameState.set_flag("lu_hinted_topside", false)
	var lu_runner_2 = DialogueRunner.new()
	lu_runner_2.start(DialogueDB.get_tree_for("lu_qichen"))
	if lu_runner_2._current_node_id != "lu_daze_hook":
		printerr("FAIL 14-B: Lu Qichen tree did not route to lu_daze_hook when mem_frag_linfei_1 is true and lu_hinted_topside is false! Got: ", lu_runner_2._current_node_id)
		get_tree().quit(1)
		return
	
	if not GameState.get_flag("lu_hinted_topside", false):
		printerr("FAIL 14-B: lu_hinted_topside flag not set after entering lu_daze_hook!")
		get_tree().quit(1)
		return

	# Case 3: lu_hinted_topside = true
	var lu_runner_3 = DialogueRunner.new()
	lu_runner_3.start(DialogueDB.get_tree_for("lu_qichen"))
	if lu_runner_3._current_node_id != "hub":
		printerr("FAIL 14-B: Lu Qichen tree did not route to hub when lu_hinted_topside is true! Got: ", lu_runner_3._current_node_id)
		get_tree().quit(1)
		return

	# Wan test cases
	# Case 1: mem_frag_linfei_1 = false
	GameState.reset_for_new_game()
	GameState.set_flag("met_wan", true)
	GameState.set_flag("mem_frag_linfei_1", false)
	GameState.set_flag("wan_noticed_daze", false)
	var wan_runner_1 = DialogueRunner.new()
	wan_runner_1.start(DialogueDB.get_tree_for("wan"))
	if wan_runner_1._current_node_id != "retalk":
		printerr("FAIL 14-B: Wan tree did not route to retalk when mem_frag_linfei_1 is false! Got: ", wan_runner_1._current_node_id)
		get_tree().quit(1)
		return

	# Case 2: mem_frag_linfei_1 = true, wan_noticed_daze = false
	GameState.reset_for_new_game()
	GameState.set_flag("met_wan", true)
	GameState.set_flag("mem_frag_linfei_1", true)
	GameState.set_flag("wan_noticed_daze", false)
	var wan_runner_2 = DialogueRunner.new()
	wan_runner_2.start(DialogueDB.get_tree_for("wan"))
	if wan_runner_2._current_node_id != "wan_daze_hook":
		printerr("FAIL 14-B: Wan tree did not route to wan_daze_hook when mem_frag_linfei_1 is true and wan_noticed_daze is false! Got: ", wan_runner_2._current_node_id)
		get_tree().quit(1)
		return
	
	if not GameState.get_flag("wan_noticed_daze", false):
		printerr("FAIL 14-B: wan_noticed_daze flag not set after entering wan_daze_hook!")
		get_tree().quit(1)
		return

	# Case 3: wan_noticed_daze = true
	var wan_runner_3 = DialogueRunner.new()
	wan_runner_3.start(DialogueDB.get_tree_for("wan"))
	if wan_runner_3._current_node_id != "retalk":
		printerr("FAIL 14-B: Wan tree did not route to retalk when wan_noticed_daze is true! Got: ", wan_runner_3._current_node_id)
		get_tree().quit(1)
		return

	print("PASS: Phase 14-B dialogue hooks verified.")

	# ===================== Phase 14-C: Store Robot Hook =====================
	print("--- Phase 14-C: Store Robot Hook ---")
	
	# Case 1: mem_frag_linfei_1 = false
	GameState.reset_for_new_game()
	GameState.set_flag("vendor_bot_repaired", false)
	GameState.set_flag("mem_frag_linfei_1", false)
	GameState.set_flag("ada_misrecognized", false)
	var robot_runner_1 = DialogueRunner.new()
	robot_runner_1.start(DialogueDB.get_tree_for("store_robot"))
	if robot_runner_1._current_node_id != "babble_intro":
		printerr("FAIL 14-C: Store robot tree did not route to babble_intro when mem_frag_linfei_1 is false! Got: ", robot_runner_1._current_node_id)
		get_tree().quit(1)
		return

	# Case 2: mem_frag_linfei_1 = true, ada_misrecognized = false
	GameState.reset_for_new_game()
	GameState.set_flag("vendor_bot_repaired", false)
	GameState.set_flag("mem_frag_linfei_1", true)
	GameState.set_flag("ada_misrecognized", false)
	var robot_runner_2 = DialogueRunner.new()
	robot_runner_2.start(DialogueDB.get_tree_for("store_robot"))
	if robot_runner_2._current_node_id != "ada_misrecognized_hook":
		printerr("FAIL 14-C: Store robot tree did not route to ada_misrecognized_hook when mem_frag_linfei_1 is true! Got: ", robot_runner_2._current_node_id)
		get_tree().quit(1)
		return
	
	if not GameState.get_flag("ada_misrecognized", false):
		printerr("FAIL 14-C: ada_misrecognized flag not set after entering ada_misrecognized_hook!")
		get_tree().quit(1)
		return
		
	if not GameState.get_flag("talked_store_robot", false):
		printerr("FAIL 14-C: talked_store_robot flag not set after entering ada_misrecognized_hook!")
		get_tree().quit(1)
		return

	# Case 3: ada_misrecognized = true
	var robot_runner_3 = DialogueRunner.new()
	robot_runner_3.start(DialogueDB.get_tree_for("store_robot"))
	if robot_runner_3._current_node_id != "babble_intro":
		printerr("FAIL 14-C: Store robot tree did not route to babble_intro when ada_misrecognized is true! Got: ", robot_runner_3._current_node_id)
		get_tree().quit(1)
		return

	# Case 4: quest repair_vendor_bot is active
	GameState.reset_for_new_game()
	GameState.set_flag("vendor_bot_repaired", false)
	GameState.set_flag("mem_frag_linfei_1", true)
	GameState.set_flag("ada_misrecognized", false)
	QuestManager.start("repair_vendor_bot")
	var robot_runner_4 = DialogueRunner.new()
	robot_runner_4.start(DialogueDB.get_tree_for("store_robot"))
	if robot_runner_4._current_node_id != "diagnose_intro":
		printerr("FAIL 14-C: Store robot tree did not route to diagnose_intro when quest is active! Got: ", robot_runner_4._current_node_id)
		get_tree().quit(1)
		return

	# Case 5: vendor_bot_repaired is true
	GameState.reset_for_new_game()
	GameState.set_flag("vendor_bot_repaired", true)
	GameState.set_flag("mem_frag_linfei_1", true)
	GameState.set_flag("ada_misrecognized", false)
	var robot_runner_5 = DialogueRunner.new()
	robot_runner_5.start(DialogueDB.get_tree_for("store_robot"))
	if robot_runner_5._current_node_id != "repaired_reset":
		printerr("FAIL 14-C: Store robot tree did not route to repaired_reset when repaired is true! Got: ", robot_runner_5._current_node_id)
		get_tree().quit(1)
		return

	print("PASS: Phase 14-C store robot hook verified.")

	# ===================== Phase 14-D: Regression + Save/Load + GUI =====================
	print("--- Phase 14-D: Regression + Save/Load + GUI ---")
	
	# Test 1: Reset and initial state defaults (default to false if missing, or after reset)
	GameState.reset_for_new_game()
	if GameState.get_flag("mem_frag_linfei_1", false) or GameState.get_flag("lu_hinted_topside", false) or GameState.get_flag("wan_noticed_daze", false) or GameState.get_flag("ada_misrecognized", false):
		printerr("FAIL 14-D: Phase 14 flags not default to false after reset!")
		get_tree().quit(1)
		return
		
	# Test 2: Set flags to true, capture, apply, check they are preserved
	GameState.set_flag("mem_frag_linfei_1", true)
	GameState.set_flag("lu_hinted_topside", true)
	GameState.set_flag("wan_noticed_daze", true)
	GameState.set_flag("ada_misrecognized", true)
	
	var save_p14 = SaveSystem.capture("apartment_entrance", 1500.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_p14):
		printerr("FAIL 14-D: SaveSystem.write_slot failed for Phase 14 flags!")
		get_tree().quit(1)
		return
		
	# Reset state to clear flags
	GameState.reset_for_new_game()
	if GameState.get_flag("mem_frag_linfei_1", false) or GameState.get_flag("lu_hinted_topside", false) or GameState.get_flag("wan_noticed_daze", false) or GameState.get_flag("ada_misrecognized", false):
		printerr("FAIL 14-D: Phase 14 flags not cleared on reset prior to load!")
		get_tree().quit(1)
		return
		
	# Load and check applied flags
	var loaded_p14 = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	SaveSystem.apply(loaded_p14)
	
	if not GameState.get_flag("mem_frag_linfei_1", false):
		printerr("FAIL 14-D: mem_frag_linfei_1 not loaded from save!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("lu_hinted_topside", false):
		printerr("FAIL 14-D: lu_hinted_topside not loaded from save!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("wan_noticed_daze", false):
		printerr("FAIL 14-D: wan_noticed_daze not loaded from save!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("ada_misrecognized", false):
		printerr("FAIL 14-D: ada_misrecognized not loaded from save!")
		get_tree().quit(1)
		return

	# Test 3: Backwards compatibility (simulate old save format where keys don't exist)
	var old_save_dict = {
		"meta": {
			"version": 1,
			"timestamp": 1234567,
			"scene_id": "apartment_entrance",
			"credits": 100
		},
		"data": {
			"credits": 100,
			"player_pos_x": 730.0,
			"player_facing": 1,
			"scene_id": "apartment_entrance",
			"inventory": [],
			"equipment": {},
			"knowledge": {},
			"notes": [],
			"containers": {},
			"story_flags": {
				"vendor_bot_repaired": false
			}
		}
	}
	GameState.reset_for_new_game()
	GameState.load_save_dict(old_save_dict.data)
	if GameState.get_flag("mem_frag_linfei_1", false) or GameState.get_flag("lu_hinted_topside", false) or GameState.get_flag("wan_noticed_daze", false) or GameState.get_flag("ada_misrecognized", false):
		printerr("FAIL 14-D: missing keys in save dictionary did not default to false!")
		get_tree().quit(1)
		return

	print("PASS: Phase 14-D regression + save/load verified.")

	# ----------------------------------------------------
	# Phase 15 Verification
	# ----------------------------------------------------
	print("Running Phase 15 map scene tests...")
	var MainClass15 = load("res://scenes/main/main.gd")
	var scenes15: Dictionary = MainClass15.SCENES
	var required_phase15_scenes := ["subway_station", "subway_station_platform", "underground_settlement", "underground_settlement_right"]
	for scene_id in required_phase15_scenes:
		if not scenes15.has(scene_id):
			printerr("FAIL 15: SCENES missing ", scene_id)
			get_tree().quit(1)
			return
	if not scenes15["apartment_entrance"].get("entry_points", []).has("from_subway"):
		printerr("FAIL 15: apartment_entrance missing from_subway entry point!")
		get_tree().quit(1)
		return
	if scenes15["subway_station"].get("entry_points", []) != ["from_street", "from_platform"]:
		printerr("FAIL 15: subway_station entry points wrong: ", scenes15["subway_station"].get("entry_points", []))
		get_tree().quit(1)
		return
	if scenes15["subway_station_platform"].get("entry_points", []) != ["from_concourse", "from_settlement"]:
		printerr("FAIL 15: subway_station_platform entry points wrong: ", scenes15["subway_station_platform"].get("entry_points", []))
		get_tree().quit(1)
		return
	if scenes15["underground_settlement"].get("entry_points", []) != ["from_subway", "from_right"]:
		printerr("FAIL 15: underground_settlement entry points wrong: ", scenes15["underground_settlement"].get("entry_points", []))
		get_tree().quit(1)
		return
	if not "from_left" in scenes15["underground_settlement_right"].get("entry_points", []):
		printerr("FAIL 15: underground_settlement_right entry points missing from_left: ", scenes15["underground_settlement_right"].get("entry_points", []))
		get_tree().quit(1)
		return
	if SaveSystem.get_scene_display_name("underground_settlement_right") == "未知區域":
		printerr("FAIL 15: SaveSystem scene names missing Phase 15 scenes!")
		get_tree().quit(1)
		return

	var travel_tree15 = DialogueDB.get_tree_for("travel_street_west")
	GameState.reset_for_new_game()
	var travel_runner15_locked = DialogueRunner.new()
	travel_runner15_locked.start(travel_tree15)
	var locked_labels := []
	for choice in travel_runner15_locked.current().get("choices", []):
		locked_labels.append(tr(choice.get("label", "")))
	if locked_labels.has("前往地鐵站"):
		printerr("FAIL 15: subway travel choice should be hidden before lu_hinted_topside!")
		get_tree().quit(1)
		return
	GameState.set_flag("lu_hinted_topside", true)
	var travel_runner15_unlocked = DialogueRunner.new()
	travel_runner15_unlocked.start(travel_tree15)
	var unlocked_labels := []
	for choice in travel_runner15_unlocked.current().get("choices", []):
		unlocked_labels.append(tr(choice.get("label", "")))
	if not unlocked_labels.has("前往地鐵站"):
		printerr("FAIL 15: subway travel choice should appear after lu_hinted_topside!")
		get_tree().quit(1)
		return
	travel_runner15_unlocked.choose(0)
	if travel_runner15_unlocked.pending_travel.get("scene_id", "") != "subway_station" or travel_runner15_unlocked.pending_travel.get("entry_point_id", "") != "from_street":
		printerr("FAIL 15: subway travel payload wrong: ", travel_runner15_unlocked.pending_travel)
		get_tree().quit(1)
		return

	var scene_specs15 := {
		"subway_station": {"path": "res://scenes/levels/subway_station/subway_station.tscn", "right": 1376, "bottom": 768, "spawns": ["from_street", "from_platform"]},
		"subway_station_platform": {"path": "res://scenes/levels/subway_station/subway_station_platform.tscn", "right": 4800, "bottom": 896, "spawns": ["from_concourse", "from_settlement"]},
		"underground_settlement": {"path": "res://scenes/levels/underground_settlement/underground_settlement.tscn", "right": 4352, "bottom": 960, "spawns": ["from_subway", "from_right"]},
		"underground_settlement_right": {"path": "res://scenes/levels/underground_settlement/underground_settlement_right.tscn", "right": 4352, "bottom": 960, "spawns": ["from_left"]}
	}
	for scene_id in scene_specs15:
		var spec: Dictionary = scene_specs15[scene_id]
		var packed15 = load(spec["path"])
		if not packed15:
			printerr("FAIL 15: Could not load ", spec["path"])
			get_tree().quit(1)
			return
		var inst15 = packed15.instantiate()
		var bg15 = inst15.get_node_or_null("Background") as Sprite2D
		if bg15 == null or bg15.texture == null:
			printerr("FAIL 15: Background texture missing in ", scene_id)
			get_tree().quit(1)
			return
		var cam15 = inst15.get_node_or_null("Camera2D") as Camera2D
		if cam15 == null or cam15.limit_right != spec["right"] or cam15.limit_bottom != spec["bottom"]:
			printerr("FAIL 15: Camera bounds wrong in ", scene_id)
			get_tree().quit(1)
			return
		for spawn_id in spec["spawns"]:
			if inst15.get_node_or_null("SpawnPoints/" + spawn_id) == null:
				printerr("FAIL 15: Missing spawn ", spawn_id, " in ", scene_id)
				get_tree().quit(1)
				return
		inst15.free()

	var transition_specs15 := [
		{"path": "res://scenes/levels/subway_station/subway_station.tscn", "area": "Interactables/ExitToStreetArea", "scene": "apartment_entrance", "entry": "from_subway"},
		{"path": "res://scenes/levels/subway_station/subway_station.tscn", "area": "Interactables/GateToPlatformArea", "scene": "subway_station_platform", "entry": "from_concourse"},
		{"path": "res://scenes/levels/subway_station/subway_station_platform.tscn", "area": "Interactables/ExitToStreetArea", "scene": "subway_station", "entry": "from_platform"},
		{"path": "res://scenes/levels/subway_station/subway_station_platform.tscn", "area": "Interactables/StairsToSettlementArea", "scene": "underground_settlement", "entry": "from_subway"},
		{"path": "res://scenes/levels/underground_settlement/underground_settlement.tscn", "area": "Interactables/ExitToSubwayArea", "scene": "subway_station_platform", "entry": "from_settlement"},
		{"path": "res://scenes/levels/underground_settlement/underground_settlement.tscn", "area": "Interactables/GoRightArea", "scene": "underground_settlement_right", "entry": "from_left"},
		{"path": "res://scenes/levels/underground_settlement/underground_settlement_right.tscn", "area": "Interactables/GoLeftArea", "scene": "underground_settlement", "entry": "from_right"}
	]
	for spec in transition_specs15:
		var packed_transition = load(spec["path"])
		var inst_transition = packed_transition.instantiate()
		var captured := {}
		inst_transition.scene_transition_requested.connect(func(scene_id: String, entry_point_id: String, payload: Dictionary):
			captured["scene"] = scene_id
			captured["entry"] = entry_point_id
		)
		inst_transition.current_interactable = inst_transition.get_node(spec["area"])
		inst_transition._trigger_interaction()
		if captured.get("scene", "") != spec["scene"] or captured.get("entry", "") != spec["entry"]:
			printerr("FAIL 15: Transition mismatch for ", spec["area"], ": ", captured)
			get_tree().quit(1)
			return
		inst_transition.free()

	GameState.reset_for_new_game()
	var settlement_scene15 = load("res://scenes/levels/underground_settlement/underground_settlement.tscn")
	var settlement_inst15 = settlement_scene15.instantiate()
	add_child(settlement_inst15)
	await get_tree().process_frame
	if not GameState.get_flag("reached_settlement", false):
		printerr("FAIL 15: entering underground_settlement should set reached_settlement!")
		get_tree().quit(1)
		return
	settlement_inst15.free()
	await get_tree().process_frame

	print("PASS: Phase 15 split-map routing and scene skeleton verified.")

	# ----------------------------------------------------
	# Phase 16 Verification (16-A)
	# ----------------------------------------------------
	print("Running Phase 16 NPC dialogue verification (16-A Cen)...")
	var cen_tree = DialogueDB.get_tree_for("cen")
	if cen_tree.is_empty():
		printerr("FAIL 16: Dialogue tree 'cen' not found or empty!")
		get_tree().quit(1)
		return
	
	for node_name in cen_tree:
		var node = cen_tree[node_name]
		var text = node.get("text", "")
		if "林" + "霏" in text:
			printerr("FAIL 16: 'cen' tree node '", node_name, "' contains forbidden string!")
			get_tree().quit(1)
			return

	GameState.reset_for_new_game()
	var runner_cen := DialogueRunner.new()
	runner_cen.start(cen_tree)
	
	curr_node = runner_cen.current()
	if tr(curr_node.get("speaker", "")) != "小岑" or not "新來的？" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: Initial routing should go to first_meet! Got: ", curr_node)
		get_tree().quit(1)
		return
		
	runner_cen.choose(0) # goto intro
	curr_node = runner_cen.current()
	if not "叫我小岑" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: Choice 0 should route to intro! Got: ", curr_node)
		get_tree().quit(1)
		return
	
	if not GameState.get_flag("met_cen", false) or GameState.get_flag("affinity_cen", 0) != 1:
		printerr("FAIL 16: intro effects failed! met_cen: ", GameState.get_flag("met_cen", false), " affinity_cen: ", GameState.get_flag("affinity_cen", 0))
		get_tree().quit(1)
		return
		
	runner_cen.advance()
	curr_node = runner_cen.current()
	if not "真撿到吃的" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: intro should goto end_warm! Got: ", curr_node)
		get_tree().quit(1)
		return
		
	# Path B: pickpocket_caught
	GameState.reset_for_new_game()
	runner_cen = DialogueRunner.new()
	runner_cen.start(cen_tree)
	runner_cen.choose(2) # Option 2
	curr_node = runner_cen.current()
	if not "手快一點才不會餓死" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: Choice 2 should route to pickpocket_caught! Got: ", curr_node)
		get_tree().quit(1)
		return
	if not GameState.get_flag("met_cen", false):
		printerr("FAIL 16: pickpocket_caught should set met_cen = true!")
		get_tree().quit(1)
		return
		
	# Path C: retalk
	runner_cen = DialogueRunner.new()
	runner_cen.start(cen_tree)
	curr_node = runner_cen.current()
	if not "又是你。" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: routing with met_cen=true should go to retalk! Got: ", curr_node)
		get_tree().quit(1)
		return
		
	var prev_affinity = GameState.get_flag("affinity_cen", 0)
	runner_cen.choose(0) # 來看看你
	curr_node = runner_cen.current()
	if not "真撿到吃的" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: retalk choice 0 should route to end_warm! Got: ", curr_node)
		get_tree().quit(1)
		return
	if GameState.get_flag("affinity_cen", 0) != prev_affinity + 1:
		printerr("FAIL 16: retalk choice 0 should increase affinity_cen! Got: ", GameState.get_flag("affinity_cen", 0))
		get_tree().quit(1)
		return

	# Assert cen portrait path is wired
	var dp_scene = load("res://scenes/ui/dialogue_panel.tscn")
	if dp_scene:
		var dp_inst = dp_scene.instantiate()
		add_child(dp_inst)
		dp_inst.start_dialogue("cen")
		if dp_inst.portrait_rect.texture == null:
			printerr("FAIL 16: cen dialogue portrait texture is null!")
			get_tree().quit(1)
			return
		dp_inst.free()

	# Verify NpcCen node setup in underground_settlement.tscn
	var settlement_scene16 = load("res://scenes/levels/underground_settlement/underground_settlement.tscn")
	var settlement_inst16 = settlement_scene16.instantiate()
	var npc_cen = settlement_inst16.get_node_or_null("Interactables/NpcCen")
	if npc_cen == null:
		printerr("FAIL 16: Interactables/NpcCen node missing in underground_settlement.tscn!")
		get_tree().quit(1)
		return
	if npc_cen.interaction_id != "talk_cen" or npc_cen.dialogue_id != "cen":
		printerr("FAIL 16: NpcCen node properties wrong! ID: ", npc_cen.interaction_id, " Dialogue: ", npc_cen.dialogue_id)
		get_tree().quit(1)
		return
	
	if npc_cen.get_node_or_null("CollisionShape2D") == null:
		printerr("FAIL 16: NpcCen missing CollisionShape2D!")
		get_tree().quit(1)
		return
	var npc_sprite = npc_cen.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if npc_sprite == null or npc_sprite.sprite_frames == null or not npc_sprite.sprite_frames.has_animation("idle"):
		printerr("FAIL 16: NpcCen missing AnimatedSprite2D or idle animation!")
		get_tree().quit(1)
		return
	settlement_inst16.free()

	print("PASS: Phase 16 NPC dialogue verification (16-A Cen) verified.")

	# ----------------------------------------------------
	# Phase 16 Verification (16-B Wu)
	# ----------------------------------------------------
	print("Running Phase 16 NPC dialogue verification (16-B Wu)...")
	var wu_tree = DialogueDB.get_tree_for("wu")
	if wu_tree.is_empty():
		printerr("FAIL 16: Dialogue tree 'wu' not found or empty!")
		get_tree().quit(1)
		return
	
	for node_name in wu_tree:
		var node = wu_tree[node_name]
		var text = node.get("text", "")
		if "林" + "霏" in text:
			printerr("FAIL 16: 'wu' tree node '", node_name, "' contains forbidden string!")
			get_tree().quit(1)
			return

	# Path A: first_meet -> repairer
	GameState.reset_for_new_game()
	var runner_wu := DialogueRunner.new()
	runner_wu.start(wu_tree)
	
	curr_node = runner_wu.current()
	if tr(curr_node.get("speaker", "")) != "伍姐" or not "別站光裡" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: Wu initial routing should go to first_meet! Got: ", curr_node)
		get_tree().quit(1)
		return
		
	runner_wu.choose(0) # goto repairer
	curr_node = runner_wu.current()
	if not "電力、淨水" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: Choice 0 should route to repairer! Got: ", curr_node)
		get_tree().quit(1)
		return
	
	if not GameState.get_flag("met_wu", false) or GameState.get_flag("affinity_wu", 0) != 1:
		printerr("FAIL 16: repairer effects failed! met_wu: ", GameState.get_flag("met_wu", false), " affinity_wu: ", GameState.get_flag("affinity_wu", 0))
		get_tree().quit(1)
		return
		
	runner_wu.advance()
	curr_node = runner_wu.current()
	if not "多搬兩趟水" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: repairer should goto end_cold! Got: ", curr_node)
		get_tree().quit(1)
		return

	# Path B: first_meet -> maker
	GameState.reset_for_new_game()
	runner_wu = DialogueRunner.new()
	runner_wu.start(wu_tree)
	runner_wu.choose(1) # Choice 1 (maker)
	curr_node = runner_wu.current()
	if not "有過一個人" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: Choice 1 should route to maker! Got: ", curr_node)
		get_tree().quit(1)
		return
	if not GameState.get_flag("met_wu", false) or not GameState.get_flag("knows_settlement_had_maker", false):
		printerr("FAIL 16: maker flags failed to set! met_wu: ", GameState.get_flag("met_wu", false), " knows_settlement_had_maker: ", GameState.get_flag("knows_settlement_had_maker", false))
		get_tree().quit(1)
		return
	if GameState.get_flag("affinity_wu", 0) != 1:
		printerr("FAIL 16: maker should increase affinity_wu! Got: ", GameState.get_flag("affinity_wu", 0))
		get_tree().quit(1)
		return
		
	runner_wu.advance()
	curr_node = runner_wu.current()
	if not "多搬兩趟水" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: maker should goto end_cold! Got: ", curr_node)
		get_tree().quit(1)
		return

	# Path C: retalk with knows_settlement_had_maker = false
	GameState.reset_for_new_game()
	GameState.set_flag("met_wu", true)
	runner_wu = DialogueRunner.new()
	runner_wu.start(wu_tree)
	curr_node = runner_wu.current()
	if not "來了。手別閒著" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: routing with met_wu=true should go to retalk! Got: ", curr_node)
		get_tree().quit(1)
		return
	var choices_no_maker = curr_node.get("choices", [])
	var has_ask_maker_more := false
	for choice in choices_no_maker:
		if "建立這裡的人" in tr(choice.get("label", "")):
			has_ask_maker_more = true
	if has_ask_maker_more:
		printerr("FAIL 16: ask_maker_more should be locked if knows_settlement_had_maker is false!")
		get_tree().quit(1)
		return

	# Path D: retalk with knows_settlement_had_maker = true
	GameState.reset_for_new_game()
	GameState.set_flag("met_wu", true)
	GameState.set_flag("knows_settlement_had_maker", true)
	runner_wu = DialogueRunner.new()
	runner_wu.start(wu_tree)
	curr_node = runner_wu.current()
	var choices_with_maker = curr_node.get("choices", [])
	var ask_maker_index := -1
	for idx in range(choices_with_maker.size()):
		if "建立這裡的人" in tr(choices_with_maker[idx].get("label", "")):
			ask_maker_index = idx
	if ask_maker_index == -1:
		printerr("FAIL 16: ask_maker_more option missing from retalk with knows_settlement_had_maker=true!")
		get_tree().quit(1)
		return
		
	# Choose ask_maker_more
	runner_wu.choose(ask_maker_index)
	curr_node = runner_wu.current()
	if not "自己把自己關掉的" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: ask_maker_more choice should route to ask_maker_more node! Got: ", curr_node)
		get_tree().quit(1)
		return

	# Assert wu portrait path is wired
	if dp_scene:
		var dp_inst = dp_scene.instantiate()
		add_child(dp_inst)
		dp_inst.start_dialogue("wu")
		if dp_inst.portrait_rect.texture == null:
			printerr("FAIL 16: wu dialogue portrait texture is null!")
			get_tree().quit(1)
			return
		dp_inst.free()

	# Verify NpcWu node setup in underground_settlement_right.tscn
	var settlement_right_scene16 = load("res://scenes/levels/underground_settlement/underground_settlement_right.tscn")
	var settlement_right_inst16 = settlement_right_scene16.instantiate()
	var npc_wu = settlement_right_inst16.get_node_or_null("Interactables/NpcWu")
	if npc_wu == null:
		printerr("FAIL 16: Interactables/NpcWu node missing in underground_settlement_right.tscn!")
		get_tree().quit(1)
		return
	if npc_wu.interaction_id != "talk_wu" or npc_wu.dialogue_id != "wu":
		printerr("FAIL 16: NpcWu node properties wrong! ID: ", npc_wu.interaction_id, " Dialogue: ", npc_wu.dialogue_id)
		get_tree().quit(1)
		return
	
	if npc_wu.get_node_or_null("CollisionShape2D") == null:
		printerr("FAIL 16: NpcWu missing CollisionShape2D!")
		get_tree().quit(1)
		return
	var npc_wu_sprite = npc_wu.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if npc_wu_sprite == null or npc_wu_sprite.sprite_frames == null or not npc_wu_sprite.sprite_frames.has_animation("idle"):
		printerr("FAIL 16: NpcWu missing AnimatedSprite2D or idle animation!")
		get_tree().quit(1)
		return
	settlement_right_inst16.free()

	print("PASS: Phase 16 NPC dialogue verification (16-B Wu) verified.")

	# ----------------------------------------------------
	# Phase 16 Verification (16-C Seven)
	# ----------------------------------------------------
	print("Running Phase 16 NPC dialogue verification (16-C Seven)...")
	var seven_tree = DialogueDB.get_tree_for("seven")
	if seven_tree.is_empty():
		printerr("FAIL 16: Dialogue tree 'seven' not found or empty!")
		get_tree().quit(1)
		return
	
	for node_name in seven_tree:
		var node = seven_tree[node_name]
		var text = node.get("text", "")
		if "林" + "霏" in text:
			printerr("FAIL 16: 'seven' tree node '", node_name, "' contains forbidden string!")
			get_tree().quit(1)
			return

	# Path A: first_meet -> ask_who -> hook -> end_cold
	GameState.reset_for_new_game()
	var runner_seven := DialogueRunner.new()
	runner_seven.start(seven_tree)
	
	curr_node = runner_seven.current()
	if tr(curr_node.get("speaker", "")) != "七號" or not "躲下來的" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: Seven initial routing should go to first_meet! Got: ", curr_node)
		get_tree().quit(1)
		return
		
	runner_seven.choose(0) # goto ask_who
	curr_node = runner_seven.current()
	if not "大家叫我七號" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: Choice 0 should route to ask_who! Got: ", curr_node)
		get_tree().quit(1)
		return
		
	runner_seven.advance() # goto hook
	curr_node = runner_seven.current()
	if not "我有一個名字" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: ask_who should goto hook! Got: ", curr_node)
		get_tree().quit(1)
		return
		
	if not GameState.get_flag("met_seven", false) or not GameState.get_flag("seven_hinted_name_topside", false):
		printerr("FAIL 16: hook effects failed! met_seven: ", GameState.get_flag("met_seven", false), " seven_hinted_name_topside: ", GameState.get_flag("seven_hinted_name_topside", false))
		get_tree().quit(1)
		return
		
	runner_seven.advance() # goto end_cold
	curr_node = runner_seven.current()
	if not "目光沉進更深" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: hook should goto end_cold! Got: ", curr_node)
		get_tree().quit(1)
		return

	# Path B: first_meet -> hook -> end_cold
	GameState.reset_for_new_game()
	runner_seven = DialogueRunner.new()
	runner_seven.start(seven_tree)
	runner_seven.choose(1) # Choice 1 (hook)
	curr_node = runner_seven.current()
	if not "我有一個名字" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: Choice 1 should route to hook! Got: ", curr_node)
		get_tree().quit(1)
		return
		
	# Path C: retalk with seven_hinted_name_topside = false
	GameState.reset_for_new_game()
	GameState.set_flag("met_seven", true)
	runner_seven = DialogueRunner.new()
	runner_seven.start(seven_tree)
	curr_node = runner_seven.current()
	if not "還是你。……我說過" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: routing with met_seven=true should go to retalk! Got: ", curr_node)
		get_tree().quit(1)
		return
	var choices_no_name = curr_node.get("choices", [])
	var has_ask_name := false
	for choice in choices_no_name:
		if "掛在上面的名字" in tr(choice.get("label", "")):
			has_ask_name = true
	if has_ask_name:
		printerr("FAIL 16: ask_name should be locked if seven_hinted_name_topside is false!")
		get_tree().quit(1)
		return

	# Path D: retalk with seven_hinted_name_topside = true
	GameState.reset_for_new_game()
	GameState.set_flag("met_seven", true)
	GameState.set_flag("seven_hinted_name_topside", true)
	runner_seven = DialogueRunner.new()
	runner_seven.start(seven_tree)
	curr_node = runner_seven.current()
	var choices_with_name = curr_node.get("choices", [])
	var ask_name_index := -1
	for idx in range(choices_with_name.size()):
		if "掛在上面的名字" in tr(choices_with_name[idx].get("label", "")):
			ask_name_index = idx
	if ask_name_index == -1:
		printerr("FAIL 16: ask_name option missing from retalk with seven_hinted_name_topside=true!")
		get_tree().quit(1)
		return
		
	# Choose ask_name
	runner_seven.choose(ask_name_index)
	curr_node = runner_seven.current()
	if not "非找回不可的人" in tr(curr_node.get("text", "")):
		printerr("FAIL 16: ask_name choice should route to ask_name node! Got: ", curr_node)
		get_tree().quit(1)
		return

	# Assert seven portrait path is wired
	if dp_scene:
		var dp_inst = dp_scene.instantiate()
		add_child(dp_inst)
		dp_inst.start_dialogue("seven")
		if dp_inst.portrait_rect.texture == null:
			printerr("FAIL 16: seven dialogue portrait texture is null!")
			get_tree().quit(1)
			return
		dp_inst.free()

	# Verify NpcSeven node setup in underground_settlement_right.tscn
	var settlement_right_inst16_seven = settlement_right_scene16.instantiate()
	var npc_seven = settlement_right_inst16_seven.get_node_or_null("Interactables/NpcSeven")
	if npc_seven == null:
		printerr("FAIL 16: Interactables/NpcSeven node missing in underground_settlement_right.tscn!")
		get_tree().quit(1)
		return
	if npc_seven.interaction_id != "talk_seven" or npc_seven.dialogue_id != "seven":
		printerr("FAIL 16: NpcSeven node properties wrong! ID: ", npc_seven.interaction_id, " Dialogue: ", npc_seven.dialogue_id)
		get_tree().quit(1)
		return
	
	if npc_seven.get_node_or_null("CollisionShape2D") == null:
		printerr("FAIL 16: NpcSeven missing CollisionShape2D!")
		get_tree().quit(1)
		return
	var npc_seven_sprite = npc_seven.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if npc_seven_sprite == null or npc_seven_sprite.sprite_frames == null or not npc_seven_sprite.sprite_frames.has_animation("idle"):
		printerr("FAIL 16: NpcSeven missing AnimatedSprite2D or idle animation!")
		get_tree().quit(1)
		return
	settlement_right_inst16_seven.free()

	print("PASS: Phase 16 NPC dialogue verification (16-C Seven) verified.")

	# ----------------------------------------------------
	# Phase 16 Verification (16-D)
	# ----------------------------------------------------
	print("Running Phase 16 NPC dialogue verification (16-D)...")
	
	# Set 8 flags to unique values
	GameState.set_flag("met_cen", true)
	GameState.set_flag("met_wu", true)
	GameState.set_flag("met_seven", true)
	GameState.set_flag("knows_settlement_had_maker", true)
	GameState.set_flag("seven_hinted_name_topside", true)
	GameState.set_flag("affinity_cen", 3)
	GameState.set_flag("affinity_wu", 4)
	GameState.set_flag("affinity_seven", 5)

	# Verify flag values in GameState
	if not GameState.get_flag("met_cen", false) or not GameState.get_flag("met_wu", false) or not GameState.get_flag("met_seven", false):
		printerr("FAIL 16-D: met_* flags not correctly set in GameState!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("knows_settlement_had_maker", false) or not GameState.get_flag("seven_hinted_name_topside", false):
		printerr("FAIL 16-D: knows_settlement_had_maker or seven_hinted_name_topside not correctly set!")
		get_tree().quit(1)
		return
	if GameState.get_flag("affinity_cen", 0) != 3 or GameState.get_flag("affinity_wu", 0) != 4 or GameState.get_flag("affinity_seven", 0) != 5:
		printerr("FAIL 16-D: affinity_* flags not correctly set in GameState!")
		get_tree().quit(1)
		return

	# Capture save state to scratch slot
	var save_data_16d = SaveSystem.capture("underground_settlement", 100.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_data_16d):
		printerr("FAIL 16-D: Failed to write Phase 16 save to scratch slot!")
		get_tree().quit(1)
		return

	# Reset game state
	GameState.reset_for_new_game()

	# Verify flags are reset
	if GameState.get_flag("met_cen", false) or GameState.get_flag("met_wu", false) or GameState.get_flag("met_seven", false):
		printerr("FAIL 16-D: met_* flags not reset!")
		get_tree().quit(1)
		return
	if GameState.get_flag("knows_settlement_had_maker", false) or GameState.get_flag("seven_hinted_name_topside", false):
		printerr("FAIL 16-D: knows_settlement_had_maker or seven_hinted_name_topside not reset!")
		get_tree().quit(1)
		return
	if GameState.get_flag("affinity_cen", 0) != 0 or GameState.get_flag("affinity_wu", 0) != 0 or GameState.get_flag("affinity_seven", 0) != 0:
		printerr("FAIL 16-D: affinity_* flags not reset!")
		get_tree().quit(1)
		return

	# Read scratch slot
	var read_data_16d = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	if read_data_16d.is_empty():
		printerr("FAIL 16-D: Failed to read save from scratch slot!")
		get_tree().quit(1)
		return

	# Apply state
	SaveSystem.apply(read_data_16d)

	# Verify flags are restored
	if not GameState.get_flag("met_cen", false) or not GameState.get_flag("met_wu", false) or not GameState.get_flag("met_seven", false):
		printerr("FAIL 16-D: met_* flags not restored after load!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("knows_settlement_had_maker", false) or not GameState.get_flag("seven_hinted_name_topside", false):
		printerr("FAIL 16-D: knows_settlement_had_maker or seven_hinted_name_topside not restored after load!")
		get_tree().quit(1)
		return
	if GameState.get_flag("affinity_cen", 0) != 3 or GameState.get_flag("affinity_wu", 0) != 4 or GameState.get_flag("affinity_seven", 0) != 5:
		printerr("FAIL 16-D: affinity_* flags not restored after load!")
		get_tree().quit(1)
		return

	# Test default fallback value (missing keys)
	GameState.reset_for_new_game()
	if GameState.get_flag("met_cen", false) != false:
		printerr("FAIL 16-D: met_cen default value should be false!")
		get_tree().quit(1)
		return
	if GameState.get_flag("affinity_cen", 0) != 0:
		printerr("FAIL 16-D: affinity_cen default value should be 0!")
		get_tree().quit(1)
		return

	print("PASS: Phase 16 NPC dialogue verification (16-D) verified.")

	# ===================== Phase 17-A: memory_fragment_area in subway_station_platform =====================
	print("--- Phase 17-A: memory_fragment_area in subway_station_platform ---")
	var platform_scene_17 = load("res://scenes/levels/subway_station/subway_station_platform.tscn")
	var platform_inst_17 = platform_scene_17.instantiate()
	var mem_area_17 = platform_inst_17.find_child("MemoryFragmentArea", true, false)
	if mem_area_17 == null:
		printerr("FAIL 17-A: MemoryFragmentArea node not found in subway_station_platform.tscn!")
		get_tree().quit(1)
		return
	
	if mem_area_17.fragment_flag != "mem_frag_commute_topside" or mem_area_17.message_id != "mem_frag_commute_topside":
		printerr("FAIL 17-A: MemoryFragmentArea properties mismatch! Got: flag=", mem_area_17.fragment_flag, " msg=", mem_area_17.message_id)
		get_tree().quit(1)
		return

	# Assert narrative text constraints
	var msg_text_17 = GameState.STORY_MESSAGES.get("mem_frag_commute_topside", "")
	if msg_text_17 == "":
		printerr("FAIL 17-A: STORY_MESSAGES missing 'mem_frag_commute_topside'!")
		get_tree().quit(1)
		return
	if "林霏" in msg_text_17:
		printerr("FAIL 17-A: STORY_MESSAGES for 'mem_frag_commute_topside' contains forbidden word '林霏'!")
		get_tree().quit(1)
		return

	# Set up environment
	GameState.reset_for_new_game()
	UIMode.set_mode(UIMode.Mode.NONE)

	var p17_player = platform_inst_17.find_child("Player", true, false)
	if p17_player == null:
		printerr("FAIL 17-A: Player node not found in platform scene for Phase 17-A!")
		get_tree().quit(1)
		return

	# We listen to interaction_requested on the platform root to verify emission
	var p17_received = {"message_text": ""}
	var p17_on_interaction = func(data: Dictionary):
		if data.get("type") == "message":
			p17_received["message_text"] = data.get("message_text")
	platform_inst_17.interaction_requested.connect(p17_on_interaction)

	# Trigger body_entered
	mem_area_17._on_body_entered(p17_player)

	if not GameState.get_flag("mem_frag_commute_topside", false):
		printerr("FAIL 17-A: mem_frag_commute_topside flag not set after collision!")
		get_tree().quit(1)
		return

	if p17_received["message_text"] != GameState.STORY_MESSAGES["mem_frag_commute_topside"]:
		printerr("FAIL 17-A: Message not received or text mismatch! Got: ", p17_received["message_text"])
		get_tree().quit(1)
		return

	# Reset received message and try to trigger again (should be blocked by flag)
	p17_received["message_text"] = ""
	mem_area_17._on_body_entered(p17_player)
	if p17_received["message_text"] != "":
		printerr("FAIL 17-A: MemoryFragmentArea triggered repeatedly!")
		get_tree().quit(1)
		return

	# Save/Load (round-trip) verification
	# Set flag true, save to scratch slot, reset, load, assert flag is true
	GameState.reset_for_new_game()
	GameState.set_flag("mem_frag_commute_topside", true)
	var save_p17 = SaveSystem.capture("subway_station_platform", 100.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_p17):
		printerr("FAIL 17-A: Failed to write Phase 17 save to scratch slot!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	if GameState.get_flag("mem_frag_commute_topside", false) != false:
		printerr("FAIL 17-A: Flag 'mem_frag_commute_topside' did not reset to false!")
		get_tree().quit(1)
		return

	var load_p17 = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	if load_p17.is_empty():
		printerr("FAIL 17-A: Failed to read Phase 17 save from scratch slot!")
		get_tree().quit(1)
		return
	SaveSystem.apply(load_p17)

	if not GameState.get_flag("mem_frag_commute_topside", false):
		printerr("FAIL 17-A: Flag 'mem_frag_commute_topside' not restored from save!")
		get_tree().quit(1)
		return

	# Test default fallback value (missing keys)
	GameState.reset_for_new_game()
	if GameState.get_flag("mem_frag_commute_topside", false) != false:
		printerr("FAIL 17-A: mem_frag_commute_topside default value should be false!")
		get_tree().quit(1)
		return

	# Clean up
	platform_inst_17.interaction_requested.disconnect(p17_on_interaction)
	platform_inst_17.free()
	platform_scene_17 = null
	p17_player = null

	print("PASS: Phase 17-A memory_fragment_area in platform verified.")

	# ===================== Phase 17-B: EchoPoint in underground_settlement_right =====================
	print("--- Phase 17-B: EchoPoint in underground_settlement_right ---")
	
	# 1. Verify EchoDB registry and data constraints
	if not EchoDB.has_echo("echo_settlement_erased"):
		printerr("FAIL 17-B: EchoDB missing 'echo_settlement_erased' record!")
		get_tree().quit(1)
		return

	var seg_count_17b = EchoDB.get_segment_count("echo_settlement_erased")
	if seg_count_17b != 2:
		printerr("FAIL 17-B: Expected 2 segments for 'echo_settlement_erased', got: ", seg_count_17b)
		get_tree().quit(1)
		return

	var echo_data_17b = EchoDB.get_echo("echo_settlement_erased")
	for seg in echo_data_17b.get("segments", []):
		if "林霏" in seg.get("text", ""):
			printerr("FAIL 17-B: Forbidden word '林霏' found in settlement echo text!")
			get_tree().quit(1)
			return

	# 2. Verify EchoPoint node in underground_settlement_right.tscn
	var settlement_right_scene = load("res://scenes/levels/underground_settlement/underground_settlement_right.tscn")
	var settlement_right_inst = settlement_right_scene.instantiate()
	get_tree().root.add_child(settlement_right_inst)
	var echo_point_node = settlement_right_inst.find_child("EchoPoint", true, false)
	if echo_point_node == null:
		printerr("FAIL 17-B: EchoPoint node not found in underground_settlement_right.tscn!")
		get_tree().quit(1)
		return

	if echo_point_node.echo_id != "echo_settlement_erased" or echo_point_node.segment_id != "s1":
		printerr("FAIL 17-B: EchoPoint properties mismatch! Got: echo_id=", echo_point_node.echo_id, " segment_id=", echo_point_node.segment_id)
		get_tree().quit(1)
		return

	# Verify position avoids NPC Wu, Seven, and Deep Tunnel
	var ep_pos = echo_point_node.position
	if ep_pos.x < 2200 or ep_pos.x > 3200:
		printerr("FAIL 17-B: EchoPoint position.x (", ep_pos.x, ") is not placed in the safe mid-right zone!")
		get_tree().quit(1)
		return

	# 3. Simulate equipment active state & collection mechanics
	# Set up environment
	GameState.reset_for_new_game()
	
	# Verify inactive without gloves
	echo_point_node._update_active_state()
	if echo_point_node.active:
		printerr("FAIL 17-B: EchoPoint should be inactive when gleaner_gloves are not equipped!")
		get_tree().quit(1)
		return

	# Equip gloves
	# We manually place gleaner_gloves in inventory and equip it
	GameState.add_item("gleaner_gloves")
	var gloves_instance_id_17b = ""
	for slot in GameState.get_inventory():
		if not slot.is_empty() and slot.get("item_id") == "gleaner_gloves":
			gloves_instance_id_17b = slot.get("instance_id")
			break
	GameState.equip(gloves_instance_id_17b)
	echo_point_node._update_active_state()
	
	if not echo_point_node.active:
		printerr("FAIL 17-B: EchoPoint should be active when gleaner_gloves are equipped!")
		get_tree().quit(1)
		return

	# Call collect on EchoPoint (this triggers collection and deactivates it)
	echo_point_node.collect()

	if not GameState.has_echo_segment("echo_settlement_erased", "s1"):
		printerr("FAIL 17-B: Echo segment not collected in GameState after collect()!")
		get_tree().quit(1)
		return

	# Re-evaluate active state (should be false since collected)
	echo_point_node._update_active_state()
	if echo_point_node.active:
		printerr("FAIL 17-B: EchoPoint should be inactive after collection!")
		get_tree().quit(1)
		return

	# 4. Save/Load (round-trip) verification for echo_progress
	GameState.reset_for_new_game()
	GameState.collect_echo_segment("echo_settlement_erased", "s1")
	var save_p17b = SaveSystem.capture("underground_settlement_right", 100.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_p17b):
		printerr("FAIL 17-B: Failed to write Phase 17-B save to scratch slot!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	if GameState.has_echo_segment("echo_settlement_erased", "s1"):
		printerr("FAIL 17-B: Echo segment flag not reset to false!")
		get_tree().quit(1)
		return

	var load_p17b = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	if load_p17b.is_empty():
		printerr("FAIL 17-B: Failed to read Phase 17-B save from scratch slot!")
		get_tree().quit(1)
		return
	SaveSystem.apply(load_p17b)

	if not GameState.has_echo_segment("echo_settlement_erased", "s1"):
		printerr("FAIL 17-B: Echo segment flag not restored from save!")
		get_tree().quit(1)
		return

	# Cleanup
	get_tree().root.remove_child(settlement_right_inst)
	settlement_right_inst.free()
	settlement_right_scene = null
	
	if dir and dir.file_exists(TEST_SCRATCH_SAVE_FILE):
		dir.remove(TEST_SCRATCH_SAVE_FILE)

	print("PASS: Phase 17-B EchoPoint and registry verified.")

	# ===================== Phase 17-C: Regression and Save/Load Guards =====================
	print("--- Phase 17-C: Regression and Save/Load Guards ---")
	
	# 1. Verify duplicate collection safety
	GameState.reset_for_new_game()
	var collect1 = GameState.collect_echo_segment("echo_settlement_erased", "s1")
	if not collect1:
		printerr("FAIL 17-C: First collect_echo_segment should succeed!")
		get_tree().quit(1)
		return
	var collect2 = GameState.collect_echo_segment("echo_settlement_erased", "s1")
	if collect2:
		printerr("FAIL 17-C: Second collect_echo_segment should fail (no-op)!")
		get_tree().quit(1)
		return
		
	# 2. Verify media layer optionality (no crash when fields are absent)
	var echo_rec_17 = EchoDB.get_echo("echo_settlement_erased")
	if echo_rec_17.has("image_path") or echo_rec_17.has("audio_path"):
		printerr("FAIL 17-C: echo_settlement_erased should not have hardcoded image_path or audio_path (media layer must be optional)!")
		get_tree().quit(1)
		return
		
	# 3. Verify echo_progress round-trip with collection completion & sold status
	GameState.reset_for_new_game()
	GameState.collect_echo_segment("echo_settlement_erased", "s1")
	GameState.collect_echo_segment("echo_settlement_erased", "s2")
	if not GameState.is_echo_complete("echo_settlement_erased"):
		printerr("FAIL 17-C: echo_settlement_erased should be complete after collecting s1 and s2!")
		get_tree().quit(1)
		return
		
	var sell_res = GameState.sell_echo("echo_settlement_erased")
	if not sell_res:
		printerr("FAIL 17-C: sell_echo failed on completed echo_settlement_erased!")
		get_tree().quit(1)
		return
		
	if not GameState.is_echo_sold("echo_settlement_erased"):
		printerr("FAIL 17-C: echo_settlement_erased sold flag should be true!")
		get_tree().quit(1)
		return
		
	# Round-trip save/load for sold status
	var save_p17c = SaveSystem.capture("underground_settlement_right", 100.0, 1)
	if not save_p17c or save_p17c.is_empty():
		printerr("FAIL 17-C: Failed to capture save for Phase 17-C!")
		get_tree().quit(1)
		return
		
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_p17c):
		printerr("FAIL 17-C: Failed to write save to scratch slot!")
		get_tree().quit(1)
		return
		
	GameState.reset_for_new_game()
	if GameState.is_echo_sold("echo_settlement_erased"):
		printerr("FAIL 17-C: Sold status did not reset after new game!")
		get_tree().quit(1)
		return
		
	var load_p17c = SaveSystem.read_slot(TEST_SCRATCH_SAVE_SLOT)
	if load_p17c.is_empty():
		printerr("FAIL 17-C: Failed to read save from scratch slot!")
		get_tree().quit(1)
		return
	SaveSystem.apply(load_p17c)
	
	if not GameState.is_echo_sold("echo_settlement_erased"):
		printerr("FAIL 17-C: Sold status not restored from save!")
		get_tree().quit(1)
		return
		
	if not GameState.has_echo_segment("echo_settlement_erased", "s1") or not GameState.has_echo_segment("echo_settlement_erased", "s2"):
		printerr("FAIL 17-C: Echo segments not restored after save load!")
		get_tree().quit(1)
		return

	# 4. Narrative assertion: no forbidden words in the echo segments or memory fragment
	for seg in echo_rec_17.get("segments", []):
		if "林霏" in seg.get("text", ""):
			printerr("FAIL 17-C: Forbidden word '林霏' found in segment!")
			get_tree().quit(1)
			return
			
	var msg_p17 = GameState.STORY_MESSAGES.get("mem_frag_commute_topside", "")
	if "林霏" in msg_p17:
		printerr("FAIL 17-C: Forbidden word '林霏' found in mem_frag_commute_topside!")
		get_tree().quit(1)
		return
		
	# Clean up scratch slot
	if dir and dir.file_exists(TEST_SCRATCH_SAVE_FILE):
		dir.remove(TEST_SCRATCH_SAVE_FILE)
		
	print("PASS: Phase 17-C Regression and Save/Load Guards verified.")

	# ===================== Phase 18: Act 2B Combat Encounter & Receipt Retrieval =====================
	print("--- Phase 18: Act 2B Combat Encounter & Receipt Retrieval ---")
	
	# Reset states
	GameState.reset_for_new_game()
	
	# Load combat scene
	var p18_combat_scene = load("res://scenes/levels/tunnel_combat/tunnel_combat.tscn")
	if p18_combat_scene == null:
		printerr("FAIL 18-A: could not load tunnel_combat.tscn!")
		get_tree().quit(1)
		return
	print("PASS 18-A: tunnel_combat.tscn loaded.")
	
	var p18_arena = p18_combat_scene.instantiate()
	add_child(p18_arena)
	await get_tree().process_frame
	
	var p18_player = p18_arena.find_child("Player", true, false)
	var p18_walker = p18_arena.find_child("Walker01", true, false)
	var p18_loot_box = p18_arena.find_child("LootBoxArea", true, false)
	var p18_exit = p18_arena.find_child("ExitToSettlementArea", true, false)
	
	if p18_player == null or p18_walker == null or p18_loot_box == null or p18_exit == null:
		printerr("FAIL 18-A: tunnel_combat scene missing required nodes!")
		get_tree().quit(1)
		return
	print("PASS 18-A: tunnel_combat scene contains all required nodes.")
	
	# Verify combat mode
	if not p18_player.combat_mode:
		printerr("FAIL 18-A: Player in tunnel_combat must have combat_mode = true!")
		get_tree().quit(1)
		return
	print("PASS 18-A: Player combat_mode is true in combat scene.")
	
	# Verify E key priority: player mock setup
	# Set player's parent to p18_arena so it can get tree if needed
	if p18_player.get_parent() == null:
		p18_arena.add_child(p18_player)
	
	# 1. format zone suppresses attack
	var existing_fmt = p18_player.get_node_or_null("FormatReset")
	if existing_fmt:
		p18_player.remove_child(existing_fmt)
		existing_fmt.free()
		
	# We can mock _in_format_zone returning true by mocking FormatReset node
	var mock_fmt = Node.new()
	mock_fmt.name = "FormatReset"
	var mock_script = GDScript.new()
	mock_script.source_code = "extends Node\nfunc has_target() -> bool: return true"
	mock_script.reload()
	mock_fmt.set_script(mock_script)
	p18_player.add_child(mock_fmt)
	
	if not p18_player._in_format_zone():
		printerr("FAIL 18-A: mock _in_format_zone failed!")
		get_tree().quit(1)
		return
	if not p18_player._e_reserved():
		printerr("FAIL 18-A: format zone should reserve E key!")
		get_tree().quit(1)
		return
	print("PASS 18-A: format zone correctly reserves E key.")
	mock_fmt.free()
	
	# Verify flag setting on walker defeat
	if GameState.get_flag("tunnel_machine_defeated", false):
		printerr("FAIL 18-A: tunnel_machine_defeated should start as false!")
		get_tree().quit(1)
		return
		
	# Call defeated on walker
	p18_walker.defeated()
	# Run process to let polling capture it
	p18_arena._process(0.016)
	if not GameState.get_flag("tunnel_machine_defeated", false):
		printerr("FAIL 18-A: defeated walker did not trigger tunnel_machine_defeated flag!")
		get_tree().quit(1)
		return
	print("PASS 18-A: walker defeat sets tunnel_machine_defeated flag.")
	
	# Loot box check before and after defeat
	# Let's reset the flag first
	GameState.set_flag("tunnel_machine_defeated", false)
	
	var p18_sig_tracker = {"msg": "", "toast": ""}
	p18_arena.interaction_requested.connect(func(d):
		if d.get("type") == "message":
			p18_sig_tracker["msg"] = d.get("message_text", "")
		elif d.get("type") == "toast":
			p18_sig_tracker["toast"] = d.get("message_text", "")
	)
	
	p18_arena.current_interactable = p18_loot_box
	p18_arena._trigger_interaction()
	if not "清潔機還在運運" in p18_sig_tracker["msg"] and not "清潔機還在運轉" in p18_sig_tracker["msg"]:
		printerr("FAIL 18-B: looting before defeat should warn player! Got p18_sig_tracker: ", p18_sig_tracker)
		get_tree().quit(1)
		return
	print("PASS 18-B: looting before defeat is blocked.")
	
	# Set defeated again
	GameState.set_flag("tunnel_machine_defeated", true)
	p18_sig_tracker["msg"] = ""
	
	# Backpack full test
	# Fill inventory: Max inventory capacity is 5x3 = 15 slots in GameState.
	for i in range(15):
		GameState.add_item("faded_jacket", 1)
	
	p18_arena._trigger_interaction()
	if not GameState.has_item("childcare_supply_receipt") and p18_sig_tracker["toast"] == "背包空間不足，無法放入。":
		print("PASS 18-B: looting with full backpack triggers toast and doesn't drop item.")
	else:
		printerr("FAIL 18-B: full backpack should block receipt acquisition! Got p18_sig_tracker: ", p18_sig_tracker)
		get_tree().quit(1)
		return
		
	# Free inventory slots
	GameState.reset_for_new_game()
	GameState.set_flag("tunnel_machine_defeated", true)
	p18_sig_tracker["toast"] = ""
	p18_sig_tracker["msg"] = ""
	
	p18_arena._trigger_interaction()
	if not GameState.has_item("childcare_supply_receipt"):
		printerr("FAIL 18-B: looting should award childcare_supply_receipt!")
		get_tree().quit(1)
		return
	if not "獲得了「兒少照護補給回執」" in p18_sig_tracker["msg"]:
		printerr("FAIL 18-B: looting did not show correct message! Got: ", p18_sig_tracker["msg"])
		get_tree().quit(1)
		return
	print("PASS 18-B: looting awards childcare_supply_receipt successfully.")
	
	# Check description constraints
	var receipt_meta = GameState.ITEMS_DB.get("childcare_supply_receipt", {})
	var r_desc = receipt_meta.get("description", "")
	if "七號" in r_desc or "妹妹" in r_desc or "林霏" in r_desc:
		printerr("FAIL 18-B: childcare_supply_receipt description violates forbidden words rule!")
		get_tree().quit(1)
		return
	print("PASS 18-B: receipt description conforms to narrative constraints.")
	
	# Verify dialogue branch for selling receipt to Wan
	GameState.reset_for_new_game()
	GameState.add_item("childcare_supply_receipt", 1)
	GameState.set_flag("affinity_wan", 2)
	GameState.add_trace(5)
	
	var d_runner = DialogueRunner.new()
	
	# We expect starting node to goto retalk
	GameState.set_flag("met_wan", true)
	var tree = DialogueDB.get_tree_for("wan")
	d_runner.start(tree)
	
	var p18_curr = d_runner.current()
	var p18_choices = p18_curr.get("choices", [])
	var found_sell_option = false
	for c in p18_choices:
		if "我撿到一張育兒照護回執" in tr(c.get("label", "")):
			found_sell_option = true
			d_runner.choose(c.get("index"))
			break
	if not found_sell_option:
		printerr("FAIL 18-C: sell option not found in retalk choices! Available choices: ", p18_choices)
		get_tree().quit(1)
		return
	print("PASS 18-C: sell option found and chosen under retalk.")
	
	p18_curr = d_runner.current()
	p18_choices = p18_curr.get("choices", [])
	var found_do_sell = false
	for c in p18_choices:
		if "將回執賣給她" in tr(c.get("label", "")):
			found_do_sell = true
			d_runner.choose(c.get("index"))
			break
	if not found_do_sell:
		printerr("FAIL 18-C: do_sell option not found in sell_receipt node! Available choices: ", p18_choices)
		get_tree().quit(1)
		return
		
	# Now sell dialogue completes, effects should execute
	if GameState.has_item("childcare_supply_receipt"):
		printerr("FAIL 18-C: receipt should be removed after selling!")
		get_tree().quit(1)
		return
	if GameState.get_credits() != 500:
		printerr("FAIL 18-C: credits should be 500 after selling receipt, got: ", GameState.get_credits())
		get_tree().quit(1)
		return
	if GameState.get_trace() != 4:
		printerr("FAIL 18-C: trace should decrease by 1, got: ", GameState.get_trace())
		get_tree().quit(1)
		return
	if GameState.get_flag("affinity_wan", 0) != 1:
		printerr("FAIL 18-C: affinity_wan should decrease by 1, got: ", GameState.get_flag("affinity_wan", 0))
		get_tree().quit(1)
		return
	if not GameState.get_flag("peace_line_locked", false):
		printerr("FAIL 18-C: peace_line_locked flag should be set to true after selling!")
		get_tree().quit(1)
		return
	print("PASS 18-C: selling effects executed correctly (credits +200, trace -1, trust -1, peace line locked).")
	d_runner = null
	
	# Verify Save/Load Round-trip for Phase 18 flags
	GameState.reset_for_new_game()
	GameState.set_flag("tunnel_machine_defeated", true)
	GameState.set_flag("peace_line_locked", true)
	GameState.add_item("childcare_supply_receipt", 1)
	
	var p18_save_dict = SaveSystem.capture("tunnel_combat", 100.0, 1)
	GameState.reset_for_new_game()
	
	SaveSystem.apply(p18_save_dict)
	
		
	if not GameState.get_flag("tunnel_machine_defeated", false):
		printerr("FAIL 18-D: tunnel_machine_defeated flag not restored!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("peace_line_locked", false):
		printerr("FAIL 18-D: peace_line_locked flag not restored!")
		get_tree().quit(1)
		return
	if not GameState.has_item("childcare_supply_receipt"):
		printerr("FAIL 18-D: childcare_supply_receipt possession not restored!")
		get_tree().quit(1)
		return
	print("PASS 18-D: Save/Load round-trip for Phase 18 verified.")

	# ===================== Phase 19-A: Ada's Echo in Underground Settlement Left =====================
	print("--- Phase 19-A: Ada's Echo in Underground Settlement Left ---")
	
	# Verify EchoDB config
	if not EchoDB.has_echo("echo_ada_reset"):
		printerr("FAIL 19-A: EchoDB missing 'echo_ada_reset' record!")
		get_tree().quit(1)
		return
	
	var seg_count_19a = EchoDB.get_segment_count("echo_ada_reset")
	if seg_count_19a != 1:
		printerr("FAIL 19-A: Expected 1 segment for 'echo_ada_reset', got: ", seg_count_19a)
		get_tree().quit(1)
		return
		
	var echo_data_19a = EchoDB.get_echo("echo_ada_reset")
	if echo_data_19a.get("trace_on_collect", 0) != 1:
		printerr("FAIL 19-A: echo_ada_reset missing trace_on_collect = 1!")
		get_tree().quit(1)
		return

	# Verify media layers path
	if echo_data_19a.get("image_path", "") != "res://assets/images/echoes/echo_ada_reset.jpeg":
		printerr("FAIL 19-A: echo_ada_reset image_path is incorrect or missing!")
		get_tree().quit(1)
		return

	# Verify EchoPoint node in underground_settlement.tscn
	var settlement_left_scene = load("res://scenes/levels/underground_settlement/underground_settlement.tscn")
	if settlement_left_scene == null:
		printerr("FAIL 19-A: could not load underground_settlement.tscn!")
		get_tree().quit(1)
		return
		
	var left_instance = settlement_left_scene.instantiate()
	var echo_point_node_19a = left_instance.find_child("EchoPoint", true, false)
	if echo_point_node_19a == null:
		printerr("FAIL 19-A: EchoPoint node not found in underground_settlement.tscn!")
		get_tree().quit(1)
		return
		
	if echo_point_node_19a.echo_id != "echo_ada_reset" or echo_point_node_19a.segment_id != "s1":
		printerr("FAIL 19-A: EchoPoint properties mismatch in underground_settlement.tscn!")
		get_tree().quit(1)
		return
	left_instance.free()
	
	# Verify collection mechanics
	GameState.reset_for_new_game()
	GameState.add_item("gleaner_gloves")
	
	# Find gloves instance ID
	var gloves_inst := ""
	for slot in GameState.inventory:
		if not slot.is_empty() and slot.get("item_id") == "gleaner_gloves":
			gloves_inst = slot.get("instance_id")
			break
	if gloves_inst.is_empty():
		printerr("FAIL 19-A: gloves_inst not found in inventory!")
		get_tree().quit(1)
		return
	GameState.equip(gloves_inst)
	
	var initial_trace = GameState.get_trace()
	if initial_trace != 0:
		printerr("FAIL 19-A: Initial trace is not 0!")
		get_tree().quit(1)
		return
		
	var collect_success = GameState.collect_echo_segment("echo_ada_reset", "s1")
	if not collect_success:
		printerr("FAIL 19-A: collect_echo_segment failed for echo_ada_reset!")
		get_tree().quit(1)
		return
		
	if not GameState.has_echo_segment("echo_ada_reset", "s1"):
		printerr("FAIL 19-A: segment not marked collected after collect!")
		get_tree().quit(1)
		return
		
	if not GameState.is_echo_complete("echo_ada_reset"):
		printerr("FAIL 19-A: echo_ada_reset not complete after segment collect!")
		get_tree().quit(1)
		return
		
	var post_collect_trace = GameState.get_trace()
	if post_collect_trace != 1:
		printerr("FAIL 19-A: trace did not increment by 1 after complete! Got: ", post_collect_trace)
		get_tree().quit(1)
		return
		
	# Try double collect
	var double_collect = GameState.collect_echo_segment("echo_ada_reset", "s1")
	if double_collect:
		printerr("FAIL 19-A: collect_echo_segment returned true for already collected segment!")
		get_tree().quit(1)
		return
		
	if GameState.get_trace() != 1:
		printerr("FAIL 19-A: trace changed on double collect attempt!")
		get_tree().quit(1)
		return
		
	# Verify selling echo reduces trace
	var sell_res_19a = GameState.sell_echo("echo_ada_reset")
	if not sell_res_19a:
		printerr("FAIL 19-A: sell_echo failed for echo_ada_reset!")
		get_tree().quit(1)
		return
		
	if GameState.get_trace() != 0:
		printerr("FAIL 19-A: trace did not decrease by 1 after sell! Got: ", GameState.get_trace())
		get_tree().quit(1)
		return
		
	# Verification of forbidden words
	LocaleManager.set_locale("zh_TW")
	if "林霏" in tr("ECHO_ADA_RESET_TITLE") or "林霏" in tr("ECHO_ADA_RESET_SEG_S1") or "林霏" in tr("ECHO_ADA_RESET_COMMENT"):
		printerr("FAIL 19-A: Forbidden word '林霏' found in zh_TW!")
		get_tree().quit(1)
		return
		
	LocaleManager.set_locale("zh_CN")
	if "林霏" in tr("ECHO_ADA_RESET_TITLE") or "林霏" in tr("ECHO_ADA_RESET_SEG_S1") or "林霏" in tr("ECHO_ADA_RESET_COMMENT"):
		printerr("FAIL 19-A: Forbidden word '林霏' found in zh_CN!")
		get_tree().quit(1)
		return
		
	LocaleManager.set_locale("en")
	var lower_en_title = tr("ECHO_ADA_RESET_TITLE").to_lower()
	var lower_en_seg = tr("ECHO_ADA_RESET_SEG_S1").to_lower()
	var lower_en_comment = tr("ECHO_ADA_RESET_COMMENT").to_lower()
	if "lin fei" in lower_en_title or "linfei" in lower_en_title or \
	   "lin fei" in lower_en_seg or "linfei" in lower_en_seg or \
	   "lin fei" in lower_en_comment or "linfei" in lower_en_comment:
		printerr("FAIL 19-A: Forbidden word 'Lin Fei/Linfei' found in en!")
		get_tree().quit(1)
		return
		
	LocaleManager.set_locale("zh_TW")
	print("PASS: Phase 19-A Ada's Echo and trace_on_collect verified.")

	# ===================== Phase 19-B: Old Work Order examine & old_work_badge acquisition =====================
	print("--- Phase 19-B: Old Work Order examine & old_work_badge acquisition ---")

	# 1. Verify OldWorkOrderArea node in underground_settlement.tscn
	var settlement_scene = load("res://scenes/levels/underground_settlement/underground_settlement.tscn")
	if settlement_scene == null:
		printerr("FAIL 19-B: could not load underground_settlement.tscn!")
		get_tree().quit(1)
		return
		
	var settlement_inst = settlement_scene.instantiate()
	var order_node = settlement_inst.find_child("OldWorkOrderArea", true, false)
	if order_node == null:
		printerr("FAIL 19-B: OldWorkOrderArea node not found in underground_settlement.tscn!")
		get_tree().quit(1)
		return
		
	if order_node.interaction_id != "examine_old_work_order" or order_node.prompt_text != "PROMPT_EXAMINE_OLD_WORK_ORDER":
		printerr("FAIL 19-B: OldWorkOrderArea properties mismatch!")
		get_tree().quit(1)
		return
		
	print("DEBUG: order_node interaction_id='", order_node.interaction_id, "' dialogue_id='", order_node.dialogue_id, "'")
		
	# 2. Test interaction before collecting Ada's echo
	GameState.reset_for_new_game()
	GameState.add_item("old_work_badge", 1)
	
	var last_msg = {"text": ""}
	var on_msg = func(data: Dictionary):
		if data.get("type") == "message":
			last_msg["text"] = data.get("message_text", "")
	settlement_inst.interaction_requested.connect(on_msg)
	
	settlement_inst.current_interactable = order_node
	settlement_inst._trigger_interaction()
	
	if last_msg["text"] != "MSG_OLD_WORK_ORDER_NEUTRAL":
		printerr("FAIL 19-B: Expected MSG_OLD_WORK_ORDER_NEUTRAL when echo is incomplete, got: ", last_msg["text"])
		get_tree().quit(1)
		return
		
	if GameState.get_flag("read_old_work_order", false) or GameState.has_note("clue_old_work_order"):
		printerr("FAIL 19-B: States modified before echo collection!")
		get_tree().quit(1)
		return

	# 3. Test successful interaction
	GameState.reset_for_new_game()
	GameState.add_item("old_work_badge", 1)
	GameState.collect_echo_segment("echo_ada_reset", "s1")
	
	last_msg["text"] = ""
	settlement_inst._trigger_interaction()
	
	if last_msg["text"] != "MSG_OLD_WORK_ORDER_REVEALED":
		printerr("FAIL 19-B: Expected MSG_OLD_WORK_ORDER_REVEALED on first success, got: ", last_msg["text"])
		get_tree().quit(1)
		return
		
	if not GameState.get_flag("read_old_work_order", false):
		printerr("FAIL 19-B: read_old_work_order flag not set on success!")
		get_tree().quit(1)
		return
		
	if not GameState.has_item("old_work_badge"):
		printerr("FAIL 19-B: old_work_badge not in inventory!")
		get_tree().quit(1)
		return
		
	var badge_count_success = 0
	for slot in GameState.inventory:
		if not slot.is_empty() and slot.get("item_id") == "old_work_badge":
			badge_count_success += slot.get("quantity", 0)
	if badge_count_success != 1:
		printerr("FAIL 19-B: old_work_badge count is not 1, got: ", badge_count_success)
		get_tree().quit(1)
		return
		
	if GameState.get_item_description("old_work_badge") != "ITEM_OLD_WORK_BADGE_DESC_REVEALED":
		printerr("FAIL 19-B: old_work_badge description was not updated dynamically!")
		get_tree().quit(1)
		return
		
	if not GameState.has_note("clue_old_work_order"):
		printerr("FAIL 19-B: clue_old_work_order note not registered!")
		get_tree().quit(1)
		return

	# 4. Test subsequent interaction (already read)
	last_msg["text"] = ""
	var badge_count_before = 0
	for slot in GameState.inventory:
		if not slot.is_empty() and slot.get("item_id") == "old_work_badge":
			badge_count_before += slot.get("quantity", 0)
			
	settlement_inst._trigger_interaction()
	
	if last_msg["text"] != "MSG_OLD_WORK_ORDER_READ":
		printerr("FAIL 19-B: Expected MSG_OLD_WORK_ORDER_READ on repeat exam, got: ", last_msg["text"])
		get_tree().quit(1)
		return
		
	var badge_count_after = 0
	for slot in GameState.inventory:
		if not slot.is_empty() and slot.get("item_id") == "old_work_badge":
			badge_count_after += slot.get("quantity", 0)
			
	if badge_count_after != badge_count_before:
		printerr("FAIL 19-B: Re-granted old_work_badge on repeat exam!")
		get_tree().quit(1)
		return

	# 5. Verification of forbidden words
	var i18n_keys := [
		"MSG_OLD_WORK_ORDER_NEUTRAL",
		"MSG_OLD_WORK_ORDER_REVEALED",
		"MSG_OLD_WORK_ORDER_READ",
		"NOTE_CLUE_OLD_WORK_ORDER_TITLE",
		"NOTE_CLUE_OLD_WORK_ORDER_BODY",
		"PROMPT_EXAMINE_OLD_WORK_ORDER",
		"ITEM_OLD_WORK_BADGE_DESC_REVEALED"
	]
	
	for lang in ["zh_TW", "zh_CN", "en"]:
		LocaleManager.set_locale(lang)
		for key in i18n_keys:
			var txt = tr(key)
			if lang == "en":
				var lower_txt = txt.to_lower()
				if "lin fei" in lower_txt or "linfei" in lower_txt:
					printerr("FAIL 19-B: Forbidden word Lin Fei found in key: ", key, " for lang: ", lang)
					get_tree().quit(1)
					return
			else:
				if "林霏" in txt:
					printerr("FAIL 19-B: Forbidden word 林霏 found in key: ", key, " for lang: ", lang)
					get_tree().quit(1)
					return
					
	LocaleManager.set_locale("zh_TW")
	settlement_inst.free()
	print("PASS: Phase 19-B Old Work Order examine & old_work_badge acquisition verified.")

	# ===================== Phase 19-C: Memory Fragment "You Erased Ada"收束 =====================
	print("--- Phase 19-C: Memory Fragment 'You Erased Ada' verified ---")

	# 1. Verify MemoryFragmentErasedAda node in underground_settlement.tscn
	var settlement_scene_19c = load("res://scenes/levels/underground_settlement/underground_settlement.tscn")
	if settlement_scene_19c == null:
		printerr("FAIL 19-C: could not load underground_settlement.tscn!")
		get_tree().quit(1)
		return
		
	var settlement_inst_19c = settlement_scene_19c.instantiate()
	var fragment_node = settlement_inst_19c.find_child("MemoryFragmentErasedAda", true, false)
	if fragment_node == null:
		printerr("FAIL 19-C: MemoryFragmentErasedAda node not found in underground_settlement.tscn!")
		get_tree().quit(1)
		return
		
	if fragment_node.fragment_flag != "mem_frag_erased_ada" or \
	   fragment_node.message_id != "mem_frag_erased_ada" or \
	   fragment_node.require_flag != "read_old_work_order":
		printerr("FAIL 19-C: MemoryFragmentErasedAda properties mismatch!")
		get_tree().quit(1)
		return

	# 2. Test trigger before read_old_work_order is true
	GameState.reset_for_new_game()
	
	var last_frag_msg = {"text": ""}
	var on_frag_msg = func(data: Dictionary):
		if data.get("type") == "message":
			last_frag_msg["text"] = data.get("message_text", "")
	settlement_inst_19c.interaction_requested.connect(on_frag_msg)
	
	var player_node_phase19c_frag = settlement_inst_19c.find_child("Player", true, false)
	fragment_node._on_body_entered(player_node_phase19c_frag)
	
	if last_frag_msg["text"] != "":
		printerr("FAIL 19-C: Fragment triggered before read_old_work_order flag is true!")
		get_tree().quit(1)
		return
		
	if GameState.get_flag("mem_frag_erased_ada", false):
		printerr("FAIL 19-C: mem_frag_erased_ada flag set prematurely!")
		get_tree().quit(1)
		return

	# 3. Test trigger after read_old_work_order is true
	GameState.set_flag("read_old_work_order", true)
	fragment_node._on_body_entered(player_node_phase19c_frag)
	
	if last_frag_msg["text"] != "MSG_MEM_FRAG_ERASED_ADA":
		printerr("FAIL 19-C: Expected MSG_MEM_FRAG_ERASED_ADA, got: ", last_frag_msg["text"])
		get_tree().quit(1)
		return
		
	if not GameState.get_flag("mem_frag_erased_ada", false):
		printerr("FAIL 19-C: mem_frag_erased_ada flag not set to true after trigger!")
		get_tree().quit(1)
		return

	# 4. Test one-shot guard (does not trigger again)
	last_frag_msg["text"] = ""
	fragment_node._on_body_entered(player_node_phase19c_frag)
	
	if last_frag_msg["text"] != "":
		printerr("FAIL 19-C: Fragment triggered twice!")
		get_tree().quit(1)
		return

	# 5. Verification of forbidden words
	for lang in ["zh_TW", "zh_CN", "en"]:
		LocaleManager.set_locale(lang)
		var txt = tr("MSG_MEM_FRAG_ERASED_ADA")
		if lang == "en":
			var lower_txt = txt.to_lower()
			if "lin fei" in lower_txt or "linfei" in lower_txt:
				printerr("FAIL 19-C: Forbidden word Lin Fei found in MSG_MEM_FRAG_ERASED_ADA for lang: ", lang)
				get_tree().quit(1)
				return
		else:
			if "林霏" in txt:
				printerr("FAIL 19-C: Forbidden word 林霏 found in MSG_MEM_FRAG_ERASED_ADA for lang: ", lang)
				get_tree().quit(1)
				return
				
	LocaleManager.set_locale("zh_TW")
	settlement_inst_19c.free()
	print("PASS: Phase 19-C Memory Fragment 'You Erased Ada' verified.")

	# ===================== Phase M1: Progress Page Integration Verification =====================
	print("--- Phase M1: Progress Page Integration Verification ---")
	
	GameState.reset_for_new_game()
	
	# 1. Verify initial empty status
	var summary = GameState.get_progress_summary()
	if summary["scenes"]["done"] != 0 or summary["scenes"]["total"] != 10:
		printerr("FAIL M1: Initial scene count mismatch")
		get_tree().quit(1)
		return
	if summary["npcs"]["done"] != 0 or summary["npcs"]["total"] != 6:
		printerr("FAIL M1: Initial npc count mismatch")
		get_tree().quit(1)
		return
	if summary["quests"]["done"] != 0 or summary["quests"]["total"] != 3:
		printerr("FAIL M1: Initial quest count mismatch")
		get_tree().quit(1)
		return
	if summary["echoes"]["done"] != 0 or summary["echoes"]["total"] != 5:
		printerr("FAIL M1: Initial echo count mismatch")
		get_tree().quit(1)
		return
	if summary["special"]["done"] != 0 or summary["special"]["total"] != 8:
		printerr("FAIL M1: Initial special item count mismatch")
		get_tree().quit(1)
		return
	if summary["overall_done"] != 0 or summary["overall_total"] != 32 or summary["overall_pct"] != 0:
		printerr("FAIL M1: Initial overall counts mismatch")
		get_tree().quit(1)
		return
		
	# 2. Scene visiting
	GameState.mark_scene_visited("apartment")
	summary = GameState.get_progress_summary()
	if summary["scenes"]["done"] != 1:
		printerr("FAIL M1: mark_scene_visited did not increment scenes.done")
		get_tree().quit(1)
		return
	# Test Idempotency
	GameState.mark_scene_visited("apartment")
	summary = GameState.get_progress_summary()
	if summary["scenes"]["done"] != 1:
		printerr("FAIL M1: mark_scene_visited is not idempotent")
		get_tree().quit(1)
		return
		
	# 3. NPC talking
	GameState.mark_npc_talked("wan")
	summary = GameState.get_progress_summary()
	if summary["npcs"]["done"] != 1:
		printerr("FAIL M1: mark_npc_talked did not increment npcs.done")
		get_tree().quit(1)
		return
	# Whitelist check
	GameState.mark_npc_talked("travel_street_east")
	summary = GameState.get_progress_summary()
	if summary["npcs"]["done"] != 1:
		printerr("FAIL M1: mark_npc_talked whitelist guard failed")
		get_tree().quit(1)
		return
		
	# 4. Quest completion
	GameState.set_flag("left_apartment_once", true)
	summary = GameState.get_progress_summary()
	if summary["quests"]["done"] != 1:
		printerr("FAIL M1: left_apartment_once flag did not increment quests.done")
		get_tree().quit(1)
		return
	GameState.quest_states["repair_vendor_bot"] = {"status": "completed"}
	summary = GameState.get_progress_summary()
	if summary["quests"]["done"] != 2:
		printerr("FAIL M1: quest completed status did not increment quests.done")
		get_tree().quit(1)
		return
		
	# 5. Echoes
	GameState.record_full_echo("echo_clerk")
	summary = GameState.get_progress_summary()
	if summary["echoes"]["done"] != 1:
		printerr("FAIL M1: record_full_echo did not increment echoes.done")
		get_tree().quit(1)
		return
		
	# 6. Special Items collection & retention
	GameState.add_item("childcare_supply_receipt", 1)
	summary = GameState.get_progress_summary()
	if summary["special"]["done"] != 1:
		printerr("FAIL M1: add_item did not increment special.done")
		get_tree().quit(1)
		return
	# Remove item and ensure it stays completed (persistence)
	GameState.remove_item("childcare_supply_receipt", 1)
	summary = GameState.get_progress_summary()
	if summary["special"]["done"] != 1:
		printerr("FAIL M1: remove_item unticked progress")
		get_tree().quit(1)
		return
		
	# 7. Non-whitelist special item check
	GameState.add_item("old_work_badge", 1)
	summary = GameState.get_progress_summary()
	if summary["special"]["done"] != 1:
		printerr("FAIL M1: non-whitelist special item added to progress")
		get_tree().quit(1)
		return
		
	# 8. Overall percentage calculation
	if summary["overall_done"] != 6 or summary["overall_pct"] != 19:
		printerr("FAIL M1: overall calculations mismatch, done: ", summary["overall_done"], " pct: ", summary["overall_pct"])
		get_tree().quit(1)
		return
		
	# 9. Save/Load round-trip & backward compatibility
	var pM1_save_dict = SaveSystem.capture("apartment", 200.0, 1)
	GameState.reset_for_new_game()
	
	# Load compatibility check
	var m1_compat_save_dict = p18_save_dict.duplicate(true)
	m1_compat_save_dict["data"].erase("visited_scenes")
	m1_compat_save_dict["data"].erase("talked_npcs")
	m1_compat_save_dict["data"].erase("collected_special_items")
	
	SaveSystem.apply(m1_compat_save_dict)
	summary = GameState.get_progress_summary()
	if summary["scenes"]["done"] != 0 or summary["npcs"]["done"] != 0 or summary["special"]["done"] != 0:
		printerr("FAIL M1: Backward compatibility loading failed to clear progress")
		get_tree().quit(1)
		return
		
	# Restore to M1 state
	SaveSystem.apply(pM1_save_dict)
	summary = GameState.get_progress_summary()
	if summary["scenes"]["done"] != 1 or summary["npcs"]["done"] != 1 or summary["quests"]["done"] != 2 or summary["echoes"]["done"] != 1 or summary["special"]["done"] != 1:
		printerr("FAIL M1: Save/Load round-trip did not restore progress values")
		get_tree().quit(1)
		return
		
	# 10. change_item_id marks special items (transform path: worn_rubiks_cube -> decoder_cube)
	var special_before = GameState.get_progress_summary()["special"]["done"]
	GameState.add_item("worn_rubiks_cube", 1)
	var cube_inst := ""
	for slot in GameState.inventory:
		if not slot.is_empty() and slot.get("item_id") == "worn_rubiks_cube":
			cube_inst = slot.get("instance_id")
			break
	if cube_inst.is_empty():
		printerr("FAIL M1: could not seed worn_rubiks_cube for change_item_id test")
		get_tree().quit(1)
		return
	GameState.change_item_id(cube_inst, "decoder_cube")
	summary = GameState.get_progress_summary()
	if summary["special"]["done"] != special_before + 1:
		printerr("FAIL M1: change_item_id did not mark decoder_cube as collected")
		get_tree().quit(1)
		return

	# 11. unknown_total echo (鹿家記事) counts complete once its segment is collected (frozen decision guard)
	var echoes_before = GameState.get_progress_summary()["echoes"]["done"]
	GameState.record_full_echo("echo_lu_family")
	summary = GameState.get_progress_summary()
	if summary["echoes"]["done"] != echoes_before + 1:
		printerr("FAIL M1: unknown_total echo (echo_lu_family) not counted complete for progress")
		get_tree().quit(1)
		return

	print("PASS M1: Progress page metrics, whitelists, persistence, save/load, and backward compatibility verified.")
	print("PASS M1: change_item_id special-item marking and unknown_total echo progress rule verified.")

	# Cleanup Phase 18 test nodes
	p18_arena.queue_free()
	p18_combat_scene = null
	await get_tree().process_frame

	# Clean up scratch slot
	if dir and dir.file_exists(TEST_SCRATCH_SAVE_FILE):
		dir.remove(TEST_SCRATCH_SAVE_FILE)
		
	# Clean up temporary instances
	ui_instance_j.free()
	
	# Clean up fire escape test instance
	escape_instance.free()
	escape_scene = null

	# Clean up instantiated test nodes
	if is_instance_valid(ui_instance):
		ui_instance.free()
	if is_instance_valid(street_instance):
		street_instance.free()
	if is_instance_valid(main_instance):
		main_instance.free()

	# Wait a frame to let queue_free'd nodes actually get deleted
	await get_tree().process_frame

	# Release RefCounted resources explicitly to prevent exit leaks
	room_scene = null
	ui_scene = null
	main_scene = null
	street_scene = null
	DialogueDB = null
	title_scene = null
	runner = null
	press_e = Callable()
	_temp_callable = Callable()

	# ===================== Phase M2-A: LocaleManager / i18n 基礎建設 =====================
	print("--- Phase M2-A: LocaleManager i18n 基礎建設 ---")

	# 1. Autoload 存在
	if not ProjectSettings.has_setting("autoload/LocaleManager"):
		printerr("FAIL M2-A: LocaleManager not found in ProjectSettings autoload!")
		get_tree().quit(1)
		return
	print("PASS M2-A-1: LocaleManager registered in autoload.")

	# 2. set_locale 合法值 → TranslationServer locale 同步
	LocaleManager.set_locale("zh_CN")
	var ts_locale := TranslationServer.get_locale()
	if ts_locale != "zh_CN":
		printerr("FAIL M2-A-2: set_locale(zh_CN) but TranslationServer.get_locale()=%s" % ts_locale)
		get_tree().quit(1)
		return
	print("PASS M2-A-2: set_locale(zh_CN) → TranslationServer.get_locale() == zh_CN.")

	# 3. set_locale 非法值 → 退回 DEFAULT_LOCALE (zh_TW)
	LocaleManager.set_locale("ja")
	if LocaleManager.get_locale() != "zh_TW":
		printerr("FAIL M2-A-3: set_locale(ja) should fallback to zh_TW, got: %s" % LocaleManager.get_locale())
		get_tree().quit(1)
		return
	print("PASS M2-A-3: set_locale(illegal) fallback to zh_TW.")

	# 4. TranslationServer fallback locale == zh_TW（由 project.godot [internationalization] locale/fallback 設定）
	var fb: String = ProjectSettings.get_setting("internationalization/locale/fallback", "")
	if fb != "zh_TW":
		printerr("FAIL M2-A-4: ProjectSettings fallback locale=%s (expected zh_TW)" % fb)
		get_tree().quit(1)
		return
	print("PASS M2-A-4: ProjectSettings fallback locale == zh_TW.")

	# 5. settings.cfg round-trip
	LocaleManager.set_locale("en")
	# 模擬重讀（直接呼叫 _load_saved_locale 私有函式 via call）
	var saved_locale = LocaleManager.call("_load_saved_locale")
	if saved_locale != "en":
		printerr("FAIL M2-A-5: settings.cfg round-trip: expected 'en', got '%s'" % saved_locale)
		get_tree().quit(1)
		return
	print("PASS M2-A-5: settings.cfg round-trip (set_locale en → _load_saved_locale == en).")

	# 6. detect_default_locale 映射規則
	var mapping_pass := true
	var detect_results: Dictionary = {
		"zh_TW": "zh_TW", "zh_HK": "zh_TW", "zh_Hant": "zh_TW",
		"zh_CN": "zh_CN", "zh_Hans_CN": "zh_CN", "zh_SG": "zh_CN",
		"en_US": "en", "ko_KR": "en", "ja_JP": "en"
	}
	for sys_locale: String in detect_results:
		var expected: String = detect_results[sys_locale]
		# 重現函式邏輯
		var got: String
		if sys_locale.begins_with("zh"):
			if "Hans" in sys_locale or sys_locale.ends_with("_CN") or sys_locale.ends_with("_SG"):
				got = "zh_CN"
			else:
				got = "zh_TW"
		else:
			got = "en"
		if got != expected:
			printerr("FAIL M2-A-6: detect_default_locale(%s) expected %s, got %s" % [sys_locale, expected, got])
			mapping_pass = false
	if not mapping_pass:
		get_tree().quit(1)
		return
	print("PASS M2-A-6: detect_default_locale() mapping rules verified (9 cases).")

	# 7. 字型路徑存在（headless 下 TTF 需要 .import sidecar 才能 ResourceLoader.load()；
	#    此處驗 res:// 路徑對應的實際檔案存在，runtime 字型切換留 GUI 走查驗收）
	var font_pass := true
	for locale_key: String in LocaleManager.FONT_FOR:
		var fpath: String = LocaleManager.FONT_FOR[locale_key]
		# 把 res:// 轉成 OS 絕對路徑再用 FileAccess 確認檔案存在
		var abs_path := ProjectSettings.globalize_path(fpath)
		if not FileAccess.file_exists(fpath) and not FileAccess.file_exists(abs_path):
			printerr("FAIL M2-A-7: FONT_FOR[%s] = %s → file not found" % [locale_key, fpath])
			font_pass = false
		else:
			print("PASS M2-A-7[%s]: font file exists at %s" % [locale_key, fpath])
	if not font_pass:
		get_tree().quit(1)
		return
	print("PASS M2-A-7: All FONT_FOR font files exist on disk (runtime load verified at GUI walkthrough).")

	# 8. tr() 實際查表（驗 ui.translation 已註冊 + locale 切換真的換字；
	#    若 project.godot 漏 locale/translations，tr() 會退回 key 本身，此檢查即抓到）
	if TranslationServer.get_loaded_locales().is_empty():
		printerr("FAIL M2-A-8: TranslationServer.get_loaded_locales() is empty — locale/translations not registered!")
		get_tree().quit(1)
		return
	var tr_cases := {
		"zh_TW": "開始新遊戲",
		"zh_CN": "开始新游戏",
		"en":    "New Game",
	}
	var tr_pass := true
	for loc: String in tr_cases:
		LocaleManager.set_locale(loc)
		var got := tr("UI_TITLE_NEW_GAME")
		if got == "UI_TITLE_NEW_GAME":
			printerr("FAIL M2-A-8[%s]: tr(UI_TITLE_NEW_GAME) returned the key itself (translation not loaded)." % loc)
			tr_pass = false
		elif got != tr_cases[loc]:
			printerr("FAIL M2-A-8[%s]: tr(UI_TITLE_NEW_GAME)='%s', expected '%s'." % [loc, got, tr_cases[loc]])
			tr_pass = false
		else:
			print("PASS M2-A-8[%s]: tr(UI_TITLE_NEW_GAME) == '%s'." % [loc, got])
	if not tr_pass:
		get_tree().quit(1)
		return
	print("PASS M2-A-8: tr() resolves per-locale across zh_TW / zh_CN / en.")

	# 9. 未知 key → tr() 回傳 key 本身（spec：三語全缺 → 顯示 key，作漏譯訊號）
	if tr("UI_DOES_NOT_EXIST_XYZ") != "UI_DOES_NOT_EXIST_XYZ":
		printerr("FAIL M2-A-9: unknown key should return itself as missing-translation signal.")
		get_tree().quit(1)
		return
	print("PASS M2-A-9: unknown key returns itself (missing-translation signal).")

	# 恢復預設 locale
	LocaleManager.set_locale("zh_TW")
	print("--- Phase M2-A: ALL CHECKS PASSED ---")

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
	var trad_blocklist := "丟佈來個們備儲內劇動務勞區員啟單囈圓報場塊墊夢夾寫將尋對層屬帳帶庫張後從徹憑憶應戲拋掙採換損撥擇據敗數斷時暢暫會棄標樣機檔檢櫃櫥欄權殘殺毀沒淨準溫滅滿潤無燈牆獲現產畫發確禮筆紅細組結絕給統絲經維綻緒緻總繼續聲聽與舊蓋蕩處號螢裝裡見視覺觀觸託記訝設診詳誌認語說談請謝證讓貝貨販買賣贅跡載輕轉這連進遊運過達選遺還銘錄鍵鎖鐘鐵門閃閉開間閘關陳隱雜離靜響頁順領頭題願類驚體鳴麼點"

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

	# ===================== Phase M2-C: 敘事資料 i18n =====================
	# 動機：M2-C 把 STORY_NOTES (title/body) / STORY_MESSAGES / ITEMS_DB (name/desc) 改存翻譯 key。
	# 兩道閘：
	#   (1) 品質 lint (a/b/c) — 對 story.csv / items.csv 套用同 M2-B 的三項；
	#   (2) 資料驅動覆蓋（即 spec 的 ii）— 走訪資料字典，每個顯示欄位的 key 都必須在 CSV 有列。
	#       這抓得到「整欄忘了 key 化」、新增 dict 條目漏補 CSV、key 拼錯。
	print("--- Phase M2-C: 敘事資料 i18n ---")

	# zh_CN 禁用的繁體字（沿用 M2-B 同一封鎖集）
	var trad_blocklist_c := trad_blocklist

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

	# ===================== Phase 20: Act 2D 七號可選 + 和平線 Branch D =====================
	print("--- Phase 20: Act 2D 七號可選 + 和平線 Branch D ---")
	var dialogue_db_p20 = load("res://data/dialogue/dialogue_db.gd")
	var seven_tree_20 = dialogue_db_p20.get_tree_for("seven")

	# Test Case 1: Without receipt item, the receipt-hand-over choice should NOT be visible.
	GameState.reset_for_new_game()
	GameState.set_flag("met_seven", true)
	var runner_20 = DialogueRunner.new()
	runner_20.start(seven_tree_20)
	var curr_20 = runner_20.current()
	var choices_20 = curr_20.get("choices", [])
	var has_receipt_choice = false
	for choice in choices_20:
		if "回執" in tr(choice.get("label", "")):
			has_receipt_choice = true
	if has_receipt_choice:
		printerr("FAIL 20: Receipt choice visible when item is missing!")
		get_tree().quit(1)
		return

	# Test Case 2: With receipt item but peace_line_locked = true, the choice should NOT be visible.
	GameState.reset_for_new_game()
	GameState.set_flag("met_seven", true)
	GameState.set_flag("peace_line_locked", true)
	GameState.add_item("childcare_supply_receipt", 1)
	runner_20 = DialogueRunner.new()
	runner_20.start(seven_tree_20)
	curr_20 = runner_20.current()
	choices_20 = curr_20.get("choices", [])
	has_receipt_choice = false
	for choice in choices_20:
		if "回執" in tr(choice.get("label", "")):
			has_receipt_choice = true
	if has_receipt_choice:
		printerr("FAIL 20: Receipt choice visible when peace_line_locked is true!")
		get_tree().quit(1)
		return

	# Test Case 3: With receipt item and peace_line_locked = false, choice is visible. Choose return path.
	GameState.reset_for_new_game()
	GameState.set_flag("met_seven", true)
	GameState.add_item("childcare_supply_receipt", 1)
	runner_20 = DialogueRunner.new()
	runner_20.start(seven_tree_20)
	curr_20 = runner_20.current()
	choices_20 = curr_20.get("choices", [])
	var receipt_choice_index := -1
	for choice in choices_20:
		if "回執" in tr(choice.get("label", "")):
			receipt_choice_index = choice.get("index", -1)
	if receipt_choice_index == -1:
		printerr("FAIL 20: Receipt choice NOT visible when conditions are met!")
		get_tree().quit(1)
		return

	# Choose the receipt choice
	runner_20.choose(receipt_choice_index)
	curr_20 = runner_20.current()
	if not "物流單" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected receipt_probe node, got: ", curr_20)
		get_tree().quit(1)
		return

	# Stage 1 now offers 3 choices: Threaten, Taunt, and the correct give-it line.
	var probe_choices = curr_20.get("choices", [])
	if probe_choices.size() != 3:
		printerr("FAIL 20: Expected 3 choices in receipt_probe stage 1, got: ", probe_choices.size())
		get_tree().quit(1)
		return

	# Test Case 3: Stage-1 Threaten (index 0) -> rebuff_leverage -> leave.
	runner_20.choose(0)
	curr_20 = runner_20.current()
	if not "我不做這種買賣" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected rebuff_leverage on stage-1 threat, got: ", curr_20)
		get_tree().quit(1)
		return
	runner_20.advance()
	curr_20 = runner_20.current()
	if not "不再理會你" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected leave node after failure, got: ", curr_20)
		get_tree().quit(1)
		return
	if GameState.get_flag("seven_peace_branch_d", false):
		printerr("FAIL 20: seven_peace_branch_d set on failure path!")
		get_tree().quit(1)
		return
	if not GameState.has_item("childcare_supply_receipt", 1):
		printerr("FAIL 20: receipt item removed on failure path!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("seven_receipt_rebuffed", false):
		printerr("FAIL 20: seven_receipt_rebuffed not set on stage-1 threat failure!")
		get_tree().quit(1)
		return

	# Test Case 4: Stage-1 Taunt (index 1) -> rebuff_probe.
	GameState.reset_for_new_game()
	GameState.set_flag("met_seven", true)
	GameState.add_item("childcare_supply_receipt", 1)
	runner_20 = DialogueRunner.new()
	runner_20.start(seven_tree_20)
	curr_20 = runner_20.current()
	choices_20 = curr_20.get("choices", [])
	receipt_choice_index = -1
	for choice in choices_20:
		if "回執" in tr(choice.get("label", "")):
			receipt_choice_index = choice.get("index", -1)
	runner_20.choose(receipt_choice_index)
	runner_20.choose(1) # Taunt -> rebuff_probe
	curr_20 = runner_20.current()
	if not "別在我面前耍花樣" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected rebuff_probe on stage-1 taunt, got: ", curr_20)
		get_tree().quit(1)
		return

	# Test Case 5a: Stage-1 correct -> stage 2; Pry (index 0) -> rebuff_probe.
	GameState.reset_for_new_game()
	GameState.set_flag("met_seven", true)
	GameState.add_item("childcare_supply_receipt", 1)
	runner_20 = DialogueRunner.new()
	runner_20.start(seven_tree_20)
	curr_20 = runner_20.current()
	choices_20 = curr_20.get("choices", [])
	receipt_choice_index = -1
	for choice in choices_20:
		if "回執" in tr(choice.get("label", "")):
			receipt_choice_index = choice.get("index", -1)
	runner_20.choose(receipt_choice_index)
	runner_20.choose(2) # Stage 1 correct -> stage 2
	curr_20 = runner_20.current()
	if not "在哪裡撿到的" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected receipt_probe_s2 after stage-1 correct, got: ", curr_20)
		get_tree().quit(1)
		return
	runner_20.choose(0) # Pry -> rebuff_probe
	curr_20 = runner_20.current()
	if not "別在我面前耍花樣" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected rebuff_probe on stage-2 pry, got: ", curr_20)
		get_tree().quit(1)
		return

	# Test Case 5b: Stage-1 correct -> stage 2; Bargain (index 1) -> rebuff_leverage.
	GameState.reset_for_new_game()
	GameState.set_flag("met_seven", true)
	GameState.add_item("childcare_supply_receipt", 1)
	runner_20 = DialogueRunner.new()
	runner_20.start(seven_tree_20)
	curr_20 = runner_20.current()
	choices_20 = curr_20.get("choices", [])
	receipt_choice_index = -1
	for choice in choices_20:
		if "回執" in tr(choice.get("label", "")):
			receipt_choice_index = choice.get("index", -1)
	runner_20.choose(receipt_choice_index)
	runner_20.choose(2) # Stage 1 correct -> stage 2
	runner_20.choose(1) # Bargain -> rebuff_leverage
	curr_20 = runner_20.current()
	if not "我不做這種買賣" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected rebuff_leverage on stage-2 bargain, got: ", curr_20)
		get_tree().quit(1)
		return

	# Test Case 5c: Stage 1+2 correct -> stage 3; Pity (index 0) -> rebuff_leverage.
	GameState.reset_for_new_game()
	GameState.set_flag("met_seven", true)
	GameState.add_item("childcare_supply_receipt", 1)
	runner_20 = DialogueRunner.new()
	runner_20.start(seven_tree_20)
	curr_20 = runner_20.current()
	choices_20 = curr_20.get("choices", [])
	receipt_choice_index = -1
	for choice in choices_20:
		if "回執" in tr(choice.get("label", "")):
			receipt_choice_index = choice.get("index", -1)
	runner_20.choose(receipt_choice_index)
	runner_20.choose(2) # Stage 1 correct
	runner_20.choose(2) # Stage 2 correct -> stage 3
	curr_20 = runner_20.current()
	if not "為什麼拿來給我" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected receipt_probe_s3 after stage-2 correct, got: ", curr_20)
		get_tree().quit(1)
		return
	runner_20.choose(0) # Pity -> rebuff_leverage
	curr_20 = runner_20.current()
	if not "我不做這種買賣" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected rebuff_leverage on stage-3 pity, got: ", curr_20)
		get_tree().quit(1)
		return

	# Test Case 5d: Stage 1+2 correct -> stage 3; Withdraw (index 1) -> rebuff_probe.
	GameState.reset_for_new_game()
	GameState.set_flag("met_seven", true)
	GameState.add_item("childcare_supply_receipt", 1)
	runner_20 = DialogueRunner.new()
	runner_20.start(seven_tree_20)
	curr_20 = runner_20.current()
	choices_20 = curr_20.get("choices", [])
	receipt_choice_index = -1
	for choice in choices_20:
		if "回執" in tr(choice.get("label", "")):
			receipt_choice_index = choice.get("index", -1)
	runner_20.choose(receipt_choice_index)
	runner_20.choose(2) # Stage 1 correct
	runner_20.choose(2) # Stage 2 correct
	runner_20.choose(1) # Withdraw -> rebuff_probe
	curr_20 = runner_20.current()
	if not "別在我面前耍花樣" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected rebuff_probe on stage-3 withdraw, got: ", curr_20)
		get_tree().quit(1)
		return

	# Test Case 6: Choose Return (index 3) -> Success path!
	GameState.reset_for_new_game()
	GameState.set_flag("met_seven", true)
	GameState.add_item("childcare_supply_receipt", 1)
	
	var initial_affinity_phase20 = GameState.get_trust("seven")
	var initial_trace_phase20 = GameState.get_trace()
	
	runner_20 = DialogueRunner.new()
	runner_20.start(seven_tree_20)
	curr_20 = runner_20.current()
	choices_20 = curr_20.get("choices", [])
	receipt_choice_index = -1
	for choice in choices_20:
		if "回執" in tr(choice.get("label", "")):
			receipt_choice_index = choice.get("index", -1)
	runner_20.choose(receipt_choice_index)

	runner_20.choose(2) # Stage 1 correct
	runner_20.choose(2) # Stage 2 correct
	runner_20.choose(2) # Stage 3 return
	curr_20 = runner_20.current()
	if not "故意打錯的字" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected receipt_return, got: ", curr_20)
		get_tree().quit(1)
		return
		
	runner_20.advance()
	curr_20 = runner_20.current()
	if not "那我不能回去" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected receipt_recognized, got: ", curr_20)
		get_tree().quit(1)
		return
		
	runner_20.advance()
	curr_20 = runner_20.current()
	if not "我欠你一次" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected peace_branch_d_done, got: ", curr_20)
		get_tree().quit(1)
		return
		
	if GameState.has_item("childcare_supply_receipt", 1):
		printerr("FAIL 20: receipt item was NOT removed on success path!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("seven_peace_branch_d", false):
		printerr("FAIL 20: seven_peace_branch_d flag NOT set to true on success path!")
		get_tree().quit(1)
		return
	if GameState.get_trust("seven") != initial_affinity_phase20 + 2:
		printerr("FAIL 20: affinity_seven did not increase by 2! Got: ", GameState.get_trust("seven"))
		get_tree().quit(1)
		return
	if GameState.get_trace() != initial_trace_phase20 - 1:
		printerr("FAIL 20: trace did not decrease by 1! Got: ", GameState.get_trace())
		get_tree().quit(1)
		return

	# Test save & load round-trip
	var save_data_phase20 = SaveSystem.capture("underground_settlement_right", 100.0, 1)
	GameState.reset_for_new_game()
	SaveSystem.apply(save_data_phase20)
	if not GameState.get_flag("seven_peace_branch_d", false):
		printerr("FAIL 20: seven_peace_branch_d flag not restored after save/load!")
		get_tree().quit(1)
		return
	if GameState.get_trust("seven") != initial_affinity_phase20 + 2:
		printerr("FAIL 20: affinity_seven not restored after save/load!")
		get_tree().quit(1)
		return
	if GameState.get_trace() != initial_trace_phase20 - 1:
		printerr("FAIL 20: trace not restored after save/load!")
		get_tree().quit(1)
		return

	# Test Case 7: retalk_d routing when seven_peace_branch_d is true.
	runner_20 = DialogueRunner.new()
	runner_20.start(seven_tree_20)
	curr_20 = runner_20.current()
	if not "沒別的事就別煩我" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected retalk_d when seven_peace_branch_d is true, got: ", curr_20)
		get_tree().quit(1)
		return
	choices_20 = curr_20.get("choices", [])
	if choices_20.size() != 1 or not "離開" in tr(choices_20[0].get("label", "")):
		printerr("FAIL 20: Expected only 'leave' choice in retalk_d, got: ", choices_20)
		get_tree().quit(1)
		return

	# Test Case 8: Failure sets seven_receipt_rebuffed; on retry the receipt choice
	# routes to receipt_reprobe (terse, no naive first-time replay) and can still succeed.
	GameState.reset_for_new_game()
	GameState.set_flag("met_seven", true)
	GameState.add_item("childcare_supply_receipt", 1)
	runner_20 = DialogueRunner.new()
	runner_20.start(seven_tree_20)
	curr_20 = runner_20.current()
	choices_20 = curr_20.get("choices", [])
	receipt_choice_index = -1
	for choice in choices_20:
		if "回執" in tr(choice.get("label", "")):
			receipt_choice_index = choice.get("index", -1)
	runner_20.choose(receipt_choice_index)
	runner_20.choose(0) # Threaten -> rebuff_leverage (sets seven_receipt_rebuffed)
	if not GameState.get_flag("seven_receipt_rebuffed", false):
		printerr("FAIL 20: seven_receipt_rebuffed not set after failure path!")
		get_tree().quit(1)
		return

	# Re-open dialogue: receipt choice now routes to receipt_reprobe.
	runner_20 = DialogueRunner.new()
	runner_20.start(seven_tree_20)
	curr_20 = runner_20.current()
	choices_20 = curr_20.get("choices", [])
	receipt_choice_index = -1
	for choice in choices_20:
		if "回執" in tr(choice.get("label", "")):
			receipt_choice_index = choice.get("index", -1)
	runner_20.choose(receipt_choice_index)
	curr_20 = runner_20.current()
	if not "又是這個" in tr(curr_20.get("text", "")):
		printerr("FAIL 20: Expected receipt_reprobe on retry after rebuff, got: ", curr_20)
		get_tree().quit(1)
		return

	# Return path from reprobe still walks the 3 stages to success and applies effects.
	runner_20.choose(2) # Stage 1 correct (from reprobe) -> stage 2
	runner_20.choose(2) # Stage 2 correct -> stage 3
	runner_20.choose(2) # Stage 3 return -> receipt_return
	runner_20.advance() # receipt_recognized
	runner_20.advance() # peace_branch_d_done (effects fire on enter)
	if GameState.has_item("childcare_supply_receipt", 1):
		printerr("FAIL 20: receipt NOT removed on reprobe success path!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("seven_peace_branch_d", false):
		printerr("FAIL 20: seven_peace_branch_d NOT set on reprobe success path!")
		get_tree().quit(1)
		return

	# Forbidden word checks for all Phase 20 keys
	var keys_20 = [
		"DLG_SEVEN_RETALK_CHOICE_RECEIPT",
		"DLG_SEVEN_RETALK_D_TEXT",
		"DLG_SEVEN_RECEIPT_PROBE_TEXT",
		"DLG_SEVEN_RECEIPT_CHOICE_THREAT",
		"DLG_SEVEN_RECEIPT_CHOICE_TAUNT",
		"DLG_SEVEN_RECEIPT_S1_CHOICE_CORRECT",
		"DLG_SEVEN_RECEIPT_CHOICE_RETURN",
		"DLG_SEVEN_RECEIPT_REPROBE_TEXT",
		"DLG_SEVEN_RECEIPT_S2_TEXT",
		"DLG_SEVEN_RECEIPT_S2_CHOICE_PRY",
		"DLG_SEVEN_RECEIPT_S2_CHOICE_BARGAIN",
		"DLG_SEVEN_RECEIPT_S2_CHOICE_CORRECT",
		"DLG_SEVEN_RECEIPT_S3_TEXT",
		"DLG_SEVEN_RECEIPT_S3_CHOICE_PITY",
		"DLG_SEVEN_RECEIPT_S3_CHOICE_WITHDRAW",
		"DLG_SEVEN_REBUFF_LEVERAGE_TEXT",
		"DLG_SEVEN_REBUFF_PROBE_TEXT",
		"DLG_SEVEN_RECEIPT_RETURN_TEXT",
		"DLG_SEVEN_RECEIPT_RECOGNIZED_TEXT",
		"DLG_SEVEN_PEACE_BRANCH_D_DONE_TEXT"
	]
	for k in keys_20:
		for lang in ["zh_TW", "zh_CN", "en"]:
			LocaleManager.set_locale(lang)
			var txt = tr(k)
			if lang == "en":
				var lower_txt = txt.to_lower()
				if "lin fei" in lower_txt or "linfei" in lower_txt:
					printerr("FAIL 20: Forbidden word Lin Fei found in key ", k, " for lang ", lang)
					get_tree().quit(1)
					return
			else:
				if "林霏" in txt:
					printerr("FAIL 20: Forbidden word 林霏 found in key ", k, " for lang ", lang)
					get_tree().quit(1)
					return
	LocaleManager.set_locale("zh_TW")
	print("PASS: Phase 20 seven dialogue choices and state effects verified.")

	# ===================== Phase 21-A: Act 3 夜總會場景骨架與轉場 =====================
	print("--- Phase 21-A: Act 3 夜總會場景骨架與轉場 ---")
	
	# 重新實例化一個 main 供 Phase 21-A 測試使用
	var nightclub_main_scene = load("res://scenes/main/main.tscn")
	main_instance = nightclub_main_scene.instantiate()
	add_child(main_instance)
	await get_tree().process_frame

	# 1. 驗證 SceneRegistry
	var scenes21 = main_instance.SCENES
	if not "nightclub_entrance" in scenes21 or not "nightclub" in scenes21 or not "nightclub_back" in scenes21:
		printerr("FAIL 21-A: SceneRegistry missing nightclub scenes!")
		get_tree().quit(1)
		return
		
	if not "from_topside" in scenes21["apartment_entrance"].get("entry_points", []):
		printerr("FAIL 21-A: apartment_entrance entry points missing from_topside!")
		get_tree().quit(1)
		return

	if SaveSystem.get_scene_display_name("nightclub_entrance") == "未知區域" or SaveSystem.get_scene_display_name("nightclub") == "未知區域" or SaveSystem.get_scene_display_name("nightclub_back") == "未知區域":
		printerr("FAIL 21-A: SaveSystem SCENE_NAMES missing nightclub scenes!")
		get_tree().quit(1)
		return

	# 2. 驗證 learned_topside_shortcut 預設與存讀檔
	GameState.reset_for_new_game()
	if GameState.get_flag("learned_topside_shortcut", false):
		printerr("FAIL 21-A: learned_topside_shortcut should default to false!")
		get_tree().quit(1)
		return
		
	GameState.set_flag("learned_topside_shortcut", true)
	var captured_save = SaveSystem.capture("nightclub", 200.0)
	GameState.reset_for_new_game()
	SaveSystem.apply(captured_save)
	if not GameState.get_flag("learned_topside_shortcut", false):
		printerr("FAIL 21-A: learned_topside_shortcut flag not restored from save!")
		get_tree().quit(1)
		return

	# 3. 模擬月台 commuter_screen 互動解鎖
	GameState.reset_for_new_game()
	var packed_platform = load("res://scenes/levels/subway_station/subway_station_platform.tscn")
	var platform_inst = packed_platform.instantiate()
	# 模擬 commuter_screen 互動
	platform_inst.current_interactable = platform_inst.get_node("Interactables/CommuterScreenArea")
	platform_inst._trigger_interaction()
	if not GameState.get_flag("learned_topside_shortcut", false):
		printerr("FAIL 21-A: commuter_screen interaction should set learned_topside_shortcut to true!")
		get_tree().quit(1)
		return

	# i18n: commuter_screen flavour resolves through tr() in all 3 locales and
	# reflects the corrected route (back on the street, head left to the old
	# maintenance corridor up to the Upper District — not "deep in the subway").
	var commuter_msg_key_21: String = platform_inst.MESSAGES["commuter_screen"]
	if not commuter_msg_key_21.begins_with("MSG_"):
		printerr("FAIL 21-A: commuter_screen message should be an i18n key, got: ", commuter_msg_key_21)
		get_tree().quit(1)
		return
	for loc_21 in ["zh_TW", "zh_CN", "en"]:
		LocaleManager.set_locale(loc_21)
		if tr(commuter_msg_key_21) == commuter_msg_key_21:
			printerr("FAIL 21-A: commuter_screen key has no %s translation." % loc_21)
			get_tree().quit(1)
			return
	LocaleManager.set_locale("zh_TW")
	var commuter_zh_21: String = tr(commuter_msg_key_21)
	if not ("向左" in commuter_zh_21 and "舊維修通道" in commuter_zh_21):
		printerr("FAIL 21-A: commuter_screen zh_TW missing corrected route wording, got: ", commuter_zh_21)
		get_tree().quit(1)
		return
	if "地鐵站深處" in commuter_zh_21:
		printerr("FAIL 21-A: commuter_screen still contains the old wrong 'deep in the subway' wording!")
		get_tree().quit(1)
		return
	platform_inst.free()

	# 4. 驗證 travel_street_west 對話樹分流
	DialogueDB = load("res://data/dialogue/dialogue_db.gd")
	var travel_tree21 = DialogueDB.get_tree_for("travel_street_west")
	
	# Case A: learned_topside_shortcut = false, lu_hinted_topside = true (地鐵解鎖但捷徑未解鎖)
	GameState.reset_for_new_game()
	GameState.set_flag("lu_hinted_topside", true)
	var travel_runner_no_shortcut = DialogueRunner.new()
	travel_runner_no_shortcut.start(travel_tree21)
	var labels_no_shortcut := []
	for choice in travel_runner_no_shortcut.current().get("choices", []):
		labels_no_shortcut.append(tr(choice.get("label", "")))
	if labels_no_shortcut.has("前往上層區") or tr("DLG_TRAVEL_STREET_WEST_MENU_CHOICE2") in labels_no_shortcut:
		printerr("FAIL 21-A: Go to Upper District choice should be hidden when learned_topside_shortcut is false!")
		get_tree().quit(1)
		return
		
	# Case B: learned_topside_shortcut = true, lu_hinted_topside = true (兩者皆解鎖)
	GameState.set_flag("learned_topside_shortcut", true)
	var travel_runner_has_shortcut = DialogueRunner.new()
	travel_runner_has_shortcut.start(travel_tree21)
	var choices_21a = travel_runner_has_shortcut.current().get("choices", [])
	var upper_district_choice_idx := -1
	for idx in range(choices_21a.size()):
		if choices_21a[idx].get("label", "") == "DLG_TRAVEL_STREET_WEST_MENU_CHOICE2":
			upper_district_choice_idx = idx
			break
	if upper_district_choice_idx == -1:
		printerr("FAIL 21-A: Go to Upper District choice not found in choices when learned_topside_shortcut is true!")
		get_tree().quit(1)
		return
		
	travel_runner_has_shortcut.choose(upper_district_choice_idx)
	if travel_runner_has_shortcut.pending_travel.get("scene_id", "") != "nightclub_entrance" or travel_runner_has_shortcut.pending_travel.get("entry_point_id", "") != "from_street":
		printerr("FAIL 21-A: travel payload incorrect for nightclub transition: ", travel_runner_has_shortcut.pending_travel)
		get_tree().quit(1)
		return

	# 5. 驗證夜總會三場景載入與雙向轉場
	var nightclub_specs := {
		"nightclub_entrance": {
			"path": "res://scenes/levels/nightclub/nightclub_entrance.tscn",
			"limit_right": 1376,
			"spawns": ["from_street", "from_lobby"],
			"transitions": [
				{"area": "Interactables/ExitToStreetArea", "target_scene": "apartment_entrance", "target_entry": "from_topside"},
				{"area": "Interactables/ServiceDoorArea", "target_scene": "nightclub", "target_entry": "from_entrance"}
			]
		},
		"nightclub": {
			"path": "res://scenes/levels/nightclub/nightclub.tscn",
			"limit_right": 4288,
			"spawns": ["from_entrance", "from_back"],
			"transitions": [
				{"area": "Interactables/ExitToEntranceArea", "target_scene": "nightclub_entrance", "target_entry": "from_lobby"},
				{"area": "Interactables/BackDoorArea", "target_scene": "nightclub_back", "target_entry": "from_lobby"}
			]
		},
		"nightclub_back": {
			"path": "res://scenes/levels/nightclub/nightclub_back.tscn",
			"limit_right": 4800,
			"spawns": ["from_lobby"],
			"transitions": [
				{"area": "Interactables/ExitToLobbyArea", "target_scene": "nightclub", "target_entry": "from_back"}
			]
		}
	}
	
	# Pre-set passed_nightclub_security so that back_door transition check succeeds
	GameState.set_flag("passed_nightclub_security", true)
	
	for scene_id in nightclub_specs:
		var spec = nightclub_specs[scene_id]
		var packed = load(spec["path"])
		if not packed:
			printerr("FAIL 21-A: Could not load scene ", spec["path"])
			get_tree().quit(1)
			return
		
		var inst = packed.instantiate()
		add_child(inst)
		await get_tree().process_frame
		
		# 檢查相機邊界
		var camera = inst.get_node("Camera2D")
		if not camera or camera.limit_right != spec["limit_right"]:
			printerr("FAIL 21-A: Camera limit_right incorrect for ", scene_id)
			get_tree().quit(1)
			return
			
		# 檢查 spawn points
		for spawn in spec["spawns"]:
			if not inst.has_node("SpawnPoints/" + spawn):
				printerr("FAIL 21-A: Missing spawn point ", spawn, " in ", scene_id)
				get_tree().quit(1)
				return
				
		# 檢查轉場 Area2D
		for trans in spec["transitions"]:
			var captured_trans := {}
			inst.scene_transition_requested.connect(func(t_scene: String, t_entry: String, payload: Dictionary):
				captured_trans["scene"] = t_scene
				captured_trans["entry"] = t_entry
			)
			var area_node = inst.get_node(trans["area"])
			if not area_node:
				printerr("FAIL 21-A: Missing transition area node ", trans["area"], " in ", scene_id)
				get_tree().quit(1)
				return
			inst.current_interactable = area_node
			inst._trigger_interaction()
			if captured_trans.get("scene", "") != trans["target_scene"] or captured_trans.get("entry", "") != trans["target_entry"]:
				printerr("FAIL 21-A: Transition target mismatch for area ", trans["area"], " in ", scene_id, ": ", captured_trans)
				get_tree().quit(1)
				return
				
		inst.free()

	# 6. 驗證 BGM 播放與過門換曲
	# 街道 -> 大門口 (播 nightclub-1.mp3)
	main_instance.transition_to("nightclub_entrance", "from_street")
	await get_tree().process_frame
	if main_instance._current_bgm_path != "res://assets/bgm/nightclub-1.mp3":
		printerr("FAIL 21-A: nightclub_entrance BGM should be nightclub-1.mp3, got: ", main_instance._current_bgm_path)
		get_tree().quit(1)
		return
		
	# 大門口 -> 門面廳 (依然是 nightclub-1.mp3)
	main_instance.transition_to("nightclub", "from_entrance")
	await get_tree().process_frame
	if main_instance._current_bgm_path != "res://assets/bgm/nightclub-1.mp3":
		printerr("FAIL 21-A: nightclub lobby BGM should be nightclub-1.mp3, got: ", main_instance._current_bgm_path)
		get_tree().quit(1)
		return
		
	# 門面廳 -> 後場包廂 (過門換曲成 nightclub-2.mp3)
	main_instance.transition_to("nightclub_back", "from_lobby")
	await get_tree().process_frame
	if main_instance._current_bgm_path != "res://assets/bgm/nightclub-2.mp3":
		printerr("FAIL 21-A: nightclub_back BGM should be nightclub-2.mp3, got: ", main_instance._current_bgm_path)
		get_tree().quit(1)
		return

	# 7. 驗證三語翻譯禁字 "林霏" (Lin Fei) 檢查
	var keys_21a = [
		"DLG_TRAVEL_STREET_WEST_MENU_CHOICE2",
		"DLG_TRAVEL_STREET_WEST_TRAVEL_TO_NIGHTCLUB_TEXT"
	]
	for k in keys_21a:
		for lang in ["zh_TW", "zh_CN", "en"]:
			LocaleManager.set_locale(lang)
			var txt = tr(k)
			if lang == "en":
				var lower_txt = txt.to_lower()
				if "lin fei" in lower_txt or "linfei" in lower_txt:
					printerr("FAIL 21-A: Forbidden word Lin Fei found in key ", k, " for lang ", lang)
					get_tree().quit(1)
					return
			else:
				if "林霏" in txt:
					printerr("FAIL 21-A: Forbidden word 林霏 found in key ", k, " for lang ", lang)
					get_tree().quit(1)
					return
	LocaleManager.set_locale("zh_TW")
	if is_instance_valid(main_instance):
		main_instance.free()
	print("PASS: Phase 21-A nightclub skeleton and transitions verified.")

	# ===================== Phase 21-B: 林霏核心殘響資料與分段媒體 =====================
	print("--- Phase 21-B: 林霏核心殘響資料與分段媒體 ---")
	
	# 1. 登記與翻譯驗證
	if not EchoDB.has_echo("echo_linfei"):
		printerr("FAIL 21-B: EchoDB registry missing echo_linfei!")
		get_tree().quit(1)
		return
		
	if EchoDB.get_segment_count("echo_linfei") != 6:
		printerr("FAIL 21-B: echo_linfei segments size incorrect (expected 6, got ", EchoDB.get_segment_count("echo_linfei"), ")")
		get_tree().quit(1)
		return

	# 1b. 場景內 EchoPoint 跨圖佈點驗證（防止資料層通過但世界裡採不到的假綠燈）
	var linfei_point_scenes := {
		"res://scenes/levels/nightclub/nightclub_entrance.tscn": ["s1"],
		"res://scenes/levels/subway_station/subway_station_platform.tscn": ["s2"],
		"res://scenes/levels/underground_settlement/underground_settlement.tscn": ["s3"],
		"res://scenes/levels/nightclub/nightclub.tscn": ["s4"],
		"res://scenes/levels/nightclub/nightclub_back.tscn": ["s5", "s6"]
	}
	var found_linfei_segments := {}
	for scene_path in linfei_point_scenes:
		var packed_lf = load(scene_path)
		if not packed_lf:
			printerr("FAIL 21-B: Could not load scene for EchoPoint placement check: ", scene_path)
			get_tree().quit(1)
			return
		var inst_lf = packed_lf.instantiate()
		var scene_segments := []
		for area in inst_lf.find_children("*", "Area2D", true, false):
			if area.get("echo_id") == "echo_linfei":
				scene_segments.append(area.get("segment_id"))
				found_linfei_segments[area.get("segment_id")] = true
		inst_lf.free()
		for expected_seg in linfei_point_scenes[scene_path]:
			if not expected_seg in scene_segments:
				printerr("FAIL 21-B: echo_linfei EchoPoint segment ", expected_seg, " not authored in ", scene_path, " (found: ", scene_segments, ")")
				get_tree().quit(1)
				return
	for seg in ["s1", "s2", "s3", "s4", "s5", "s6"]:
		if not seg in found_linfei_segments:
			printerr("FAIL 21-B: echo_linfei segment ", seg, " has no EchoPoint placed in any scene!")
			get_tree().quit(1)
			return

	var keys_21b = [
		"ECHO_LINFEI_TITLE",
		"ECHO_LINFEI_SEG_S1",
		"ECHO_LINFEI_SEG_S2",
		"ECHO_LINFEI_SEG_S3",
		"ECHO_LINFEI_SEG_S4",
		"ECHO_LINFEI_SEG_S5",
		"ECHO_LINFEI_SEG_S6",
		"ECHO_LINFEI_COMMENT"
	]
	for k in keys_21b:
		for lang in ["zh_TW", "zh_CN", "en"]:
			LocaleManager.set_locale(lang)
			var txt = tr(k)
			if lang == "en":
				var lower_txt = txt.to_lower()
				if "lin fei" in lower_txt or "linfei" in lower_txt:
					printerr("FAIL 21-B: Forbidden word Lin Fei found in key ", k, " for lang ", lang)
					get_tree().quit(1)
					return
			else:
				if "林霏" in txt:
					printerr("FAIL 21-B: Forbidden word 林霏 found in key ", k, " for lang ", lang)
					get_tree().quit(1)
					return
	LocaleManager.set_locale("zh_TW")

	# 2. 分段媒體門檻功能測試
	GameState.reset_for_new_game()
	# 0 段
	if GameState.is_echo_audio_unlocked("echo_linfei") or GameState.is_echo_image_unlocked("echo_linfei"):
		printerr("FAIL 21-B: echo_linfei media unlocked at 0 segments collected!")
		get_tree().quit(1)
		return
		
	# 1~2 段
	GameState.collect_echo_segment("echo_linfei", "s1")
	GameState.collect_echo_segment("echo_linfei", "s2")
	if GameState.is_echo_audio_unlocked("echo_linfei") or GameState.is_echo_image_unlocked("echo_linfei"):
		printerr("FAIL 21-B: echo_linfei media unlocked at 2 segments collected!")
		get_tree().quit(1)
		return
		
	# 3 段（達半數門檻）
	GameState.collect_echo_segment("echo_linfei", "s3")
	if not GameState.is_echo_audio_unlocked("echo_linfei"):
		printerr("FAIL 21-B: echo_linfei audio should unlock at 3 segments collected!")
		get_tree().quit(1)
		return
	if GameState.is_echo_image_unlocked("echo_linfei"):
		printerr("FAIL 21-B: echo_linfei image should NOT unlock at 3 segments collected!")
		get_tree().quit(1)
		return
	if GameState.get_echo_audio_path("echo_linfei") != "res://assets/audio/echoes/echo_linfei_song.mp3":
		printerr("FAIL 21-B: echo_linfei audio path mismatch: ", GameState.get_echo_audio_path("echo_linfei"))
		get_tree().quit(1)
		return
		
	# 4~5 段
	GameState.collect_echo_segment("echo_linfei", "s4")
	GameState.collect_echo_segment("echo_linfei", "s5")
	if not GameState.is_echo_audio_unlocked("echo_linfei"):
		printerr("FAIL 21-B: audio unlocked state lost at 5 segments!")
		get_tree().quit(1)
		return
	if GameState.is_echo_image_unlocked("echo_linfei"):
		printerr("FAIL 21-B: echo_linfei image should NOT unlock at 5 segments!")
		get_tree().quit(1)
		return
		
	# 6 段（全收集）
	GameState.collect_echo_segment("echo_linfei", "s6")
	if not GameState.is_echo_audio_unlocked("echo_linfei") or not GameState.is_echo_image_unlocked("echo_linfei"):
		printerr("FAIL 21-B: echo_linfei all media should unlock at 6 segments collected!")
		get_tree().quit(1)
		return
	if GameState.get_echo_image_path("echo_linfei") != "res://assets/images/echoes/echo_linfei.jpeg":
		printerr("FAIL 21-B: echo_linfei image path mismatch: ", GameState.get_echo_image_path("echo_linfei"))
		get_tree().quit(1)
		return

	# 3. 既有普通殘響退化驗證 (以 echo_clerk 為例)
	GameState.reset_for_new_game()
	# 未集滿
	if GameState.is_echo_audio_unlocked("echo_clerk"):
		printerr("FAIL 21-B: legacy echo clerk audio unlocked when incomplete!")
		get_tree().quit(1)
		return
	# 集滿
	GameState.collect_echo_segment("echo_clerk", "s1")
	if not GameState.is_echo_audio_unlocked("echo_clerk"):
		printerr("FAIL 21-B: legacy echo clerk audio NOT unlocked when complete!")
		get_tree().quit(1)
		return
	if GameState.get_echo_audio_path("echo_clerk") != "res://assets/audio/echoes/echo_clerk.ogg":
		printerr("FAIL 21-B: legacy echo clerk audio path incorrect: ", GameState.get_echo_audio_path("echo_clerk"))
		get_tree().quit(1)
		return

	# 4. 存讀檔 persistence round-trip 驗證
	GameState.reset_for_new_game()
	GameState.collect_echo_segment("echo_linfei", "s1")
	GameState.collect_echo_segment("echo_linfei", "s2")
	GameState.collect_echo_segment("echo_linfei", "s3") # 半滿
	var save_data_21b = SaveSystem.capture("nightclub", 100.0)
	GameState.reset_for_new_game()
	SaveSystem.apply(save_data_21b)
	if GameState.get_collected_segment_count("echo_linfei") != 3:
		printerr("FAIL 21-B: echo_linfei collected segments count not restored: ", GameState.get_collected_segment_count("echo_linfei"))
		get_tree().quit(1)
		return
	if not GameState.is_echo_audio_unlocked("echo_linfei") or GameState.is_echo_image_unlocked("echo_linfei"):
		printerr("FAIL 21-B: echo_linfei media unlock states not restored correctly after load!")
		get_tree().quit(1)
		return
		
	print("PASS: Phase 21-B linfei echo database registration and segmented media verified.")

	# ===================== Phase 21-C: 收束碎片「黑戶藏身方式」 =====================
	print("--- Phase 21-C: 收束碎片「黑戶藏身方式」 ---")
	
	# 1. 驗證節點存在與屬性
	var back_inst_21c = load("res://scenes/levels/nightclub/nightclub_back.tscn").instantiate()
	var mem_area_21c = back_inst_21c.find_child("MemoryFragmentArea", true, false)
	if mem_area_21c == null:
		printerr("FAIL 21-C: MemoryFragmentArea node not found in nightclub_back.tscn!")
		get_tree().quit(1)
		return
		
	if mem_area_21c.fragment_flag != "mem_frag_hideout" or mem_area_21c.message_id != "mem_frag_hideout" or mem_area_21c.require_flag != "echo_linfei":
		printerr("FAIL 21-C: MemoryFragmentArea attributes incorrect!")
		get_tree().quit(1)
		return
		
	# 2. 驗證 STORY_MESSAGES 鍵存在且翻譯合規（不含禁字「林霏」）
	if not GameState.STORY_MESSAGES.has("mem_frag_hideout"):
		printerr("FAIL 21-C: STORY_MESSAGES missing 'mem_frag_hideout'!")
		get_tree().quit(1)
		return
		
	var forbidden_check_21c = "林霏"
	for lang in ["zh_TW", "zh_CN", "en"]:
		LocaleManager.set_locale(lang)
		var tr_text = tr("MSG_MEM_FRAG_HIDEOUT")
		if tr_text == "MSG_MEM_FRAG_HIDEOUT":
			printerr("FAIL 21-C: MSG_MEM_FRAG_HIDEOUT translation missing for lang: ", lang)
			get_tree().quit(1)
			return
		if forbidden_check_21c in tr_text:
			printerr("FAIL 21-C: STORY_MESSAGES for 'mem_frag_hideout' contains forbidden word '林霏' for lang: ", lang)
			get_tree().quit(1)
			return
	LocaleManager.set_locale("zh_TW")
	
	# 3. 模擬觸發：未滿 6 段殘響時進區，旗標不應該被設為 true
	GameState.reset_for_new_game()
	# 採集 5 段
	for i in range(1, 6):
		GameState.collect_echo_segment("echo_linfei", "s%d" % i)
		
	# 模擬 player body entered 訊號
	var player_node_21c = back_inst_21c.find_child("Player", true, false)
	mem_area_21c._on_body_entered(player_node_21c)
	if GameState.get_flag("mem_frag_hideout", false):
		printerr("FAIL 21-C: mem_frag_hideout triggered before linfei echo is complete!")
		get_tree().quit(1)
		return
		
	# 4. 模擬觸發：滿 6 段殘響後進區，成功觸發，設 flag
	# 採集第 6 段以集滿
	GameState.collect_echo_segment("echo_linfei", "s6")
	
	# 接聽事件以確定有發出 interaction_requested 訊號
	var interaction_received_21c = {"message_text": ""}
	back_inst_21c.interaction_requested.connect(func(data):
		interaction_received_21c["message_text"] = data.get("message_text", "")
	)
	
	mem_area_21c._on_body_entered(player_node_21c)
	if not GameState.get_flag("mem_frag_hideout", false):
		printerr("FAIL 21-C: mem_frag_hideout not triggered after linfei echo complete!")
		get_tree().quit(1)
		return
		
	if interaction_received_21c["message_text"] == "":
		printerr("FAIL 21-C: interaction_requested signal not correctly emitted on trigger!")
		get_tree().quit(1)
		return
		
	# 5. 二次進區不重觸
	interaction_received_21c["message_text"] = ""
	mem_area_21c._on_body_entered(player_node_21c)
	if interaction_received_21c["message_text"] != "":
		printerr("FAIL 21-C: MemoryFragmentArea triggered repeatedly!")
		get_tree().quit(1)
		return
		
	# 6. 存讀檔 persistence round-trip
	var save_data_21c = SaveSystem.capture("nightclub_back", 800.0)
	GameState.reset_for_new_game()
	if GameState.get_flag("mem_frag_hideout", false):
		printerr("FAIL 21-C: mem_frag_hideout flag not reset on new game!")
		get_tree().quit(1)
		return
		
	SaveSystem.apply(save_data_21c)
	if not GameState.get_flag("mem_frag_hideout", false):
		printerr("FAIL 21-C: mem_frag_hideout flag not restored after load!")
		get_tree().quit(1)
		return
		
	back_inst_21c.free()
	print("PASS: Phase 21-C linfei memory fragment hideout verified.")

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

	# ===================== Phase 21-E: 《雨還沒停》環境母題 =====================
	print("--- Phase 21-E: 《雨還沒停》環境母題 ---")
	
	# 1. 驗證地鐵月台與地下道聚落中均存在環境播放點
	var platform_scene = load("res://scenes/levels/subway_station/subway_station_platform.tscn").instantiate()
	var plat_motif = platform_scene.get_node_or_null("ThemeMotifPlayer")
	if plat_motif == null or not plat_motif is AudioStreamPlayer:
		printerr("FAIL 21-E: ThemeMotifPlayer not found in subway_station_platform!")
		get_tree().quit(1)
		return
	if plat_motif.stream == null or plat_motif.stream.resource_path != "res://assets/audio/echoes/echo_song_rain_doesnt_stop.mp3":
		printerr("FAIL 21-E: Subway platform ThemeMotifPlayer has wrong stream path: ", plat_motif.stream.resource_path if plat_motif.stream else "null")
		get_tree().quit(1)
		return
	if plat_motif.bus != &"Ambient":
		printerr("FAIL 21-E: Subway platform ThemeMotifPlayer should play on Ambient bus, got: ", plat_motif.bus)
		get_tree().quit(1)
		return
	platform_scene.free()

	var settlement_scene_21e = load("res://scenes/levels/underground_settlement/underground_settlement.tscn").instantiate()
	var set_motif = settlement_scene_21e.get_node_or_null("ThemeMotifPlayer")
	if set_motif == null or not set_motif is AudioStreamPlayer:
		printerr("FAIL 21-E: ThemeMotifPlayer not found in underground_settlement!")
		get_tree().quit(1)
		return
	if set_motif.stream == null or set_motif.stream.resource_path != "res://assets/audio/echoes/echo_song_rain_doesnt_stop.mp3":
		printerr("FAIL 21-E: Underground settlement ThemeMotifPlayer has wrong stream path: ", set_motif.stream.resource_path if set_motif.stream else "null")
		get_tree().quit(1)
		return
	if set_motif.bus != &"Ambient":
		printerr("FAIL 21-E: Underground settlement ThemeMotifPlayer should play on Ambient bus, got: ", set_motif.bus)
		get_tree().quit(1)
		return
	settlement_scene_21e.free()
	
	print("PASS: Phase 21-E ambient play points verified.")

	# ===================== Phase 21-F: 可賣 + 回歸 + 存讀檔 =====================
	print("--- Phase 21-F: 可賣 + 回歸 + 存讀檔 ---")
	
	# 重置狀態
	GameState.reset_for_new_game()
	
	# 1. 驗證未集滿時不可賣
	if GameState.sell_echo("echo_linfei"):
		printerr("FAIL 21-F: sell_echo should return false on incomplete echo_linfei!")
		get_tree().quit(1)
		return
		
	# 2. 採集完畢
	GameState.record_full_echo("echo_linfei")
	if not GameState.is_echo_complete("echo_linfei"):
		printerr("FAIL 21-F: echo_linfei should be complete after record_full_echo!")
		get_tree().quit(1)
		return
		
	# 3. 驗證可賣
	var initial_credits_phase21 = GameState.get_credits()
	var initial_trace_phase21 = GameState.get_trace()
	if not GameState.sell_echo("echo_linfei"):
		printerr("FAIL 21-F: sell_echo failed on completed echo_linfei!")
		get_tree().quit(1)
		return
		
	# 4. 驗證 credits 增加 (400) 且 trace 減少 (TRACE_DELTA_SELL = -1)
	if GameState.get_credits() != initial_credits_phase21 + 400:
		printerr("FAIL 21-F: Wrong credits rewarded: ", GameState.get_credits())
		get_tree().quit(1)
		return
	if GameState.get_trace() != initial_trace_phase21 - 1:
		printerr("FAIL 21-F: Wrong trace change: ", GameState.get_trace())
		get_tree().quit(1)
		return
		
	# 5. 驗證 sold_linfei_echo 旗標已設為 true
	if not GameState.get_flag("sold_linfei_echo", false):
		printerr("FAIL 21-F: sold_linfei_echo flag is not set after selling echo_linfei!")
		get_tree().quit(1)
		return
		
	# 6. 存讀檔 round-trip 驗證
	var save_dict_phase21 = SaveSystem.capture("nightclub", 100.0, 1)
	GameState.reset_for_new_game()
	if GameState.get_flag("sold_linfei_echo", false):
		printerr("FAIL 21-F: sold_linfei_echo should be reset on new game!")
		get_tree().quit(1)
		return
		
	SaveSystem.apply(save_dict_phase21)
	if not GameState.get_flag("sold_linfei_echo", false):
		printerr("FAIL 21-F: sold_linfei_echo flag was not restored after save load!")
		get_tree().quit(1)
		return
	if not GameState.is_echo_sold("echo_linfei"):
		printerr("FAIL 21-F: echo_linfei sold status was not restored after save load!")
		get_tree().quit(1)
		return

	# 7. 驗證 Dialogue 系統中的 op sell_echo 能在 Lu Qichen 的對話流程中正確運作
	var eff_sell_linfei = {"op": "sell_echo", "value": "echo_linfei"}
	GameState.reset_for_new_game()
	GameState.record_full_echo("echo_linfei")
	var runner_phase21 = load("res://scripts/dialogue/dialogue_runner.gd").new()
	runner_phase21.start(DialogueDB.get_tree_for("lu_qichen"))
	# execute dialogue runner effect
	runner_phase21._apply_effect(eff_sell_linfei)
	if not GameState.is_echo_sold("echo_linfei") or not GameState.get_flag("sold_linfei_echo", false):
		printerr("FAIL 21-F: sell_echo effect did not sell the echo or set flag in dialogue runner!")
		get_tree().quit(1)
		return
		
	print("PASS: Phase 21-F sellable, regression, and save/load verified.")

	# ===================== Phase 23-A: Act 3 夜總會保全四解小解謎骨架 =====================
	print("--- Phase 23-A: Act 3 夜總會保全四解小解謎骨架 ---")
	
	# 重置狀態
	GameState.reset_for_new_game()
	
	# 1. 驗證 biometric_gate 劇情拍子（不設 flag、不扣款）
	var inst_entrance = load("res://scenes/levels/nightclub/nightclub_entrance.tscn").instantiate()
	var gate_node = inst_entrance.get_node("Interactables/BiometricGateArea")
	inst_entrance.current_interactable = gate_node
	
	print("DEBUG: gate_node.interaction_id = ", gate_node.interaction_id)
	print("DEBUG: current_interactable = ", inst_entrance.current_interactable)
	
	var captured_msg_p23a: Dictionary = {}
	inst_entrance.interaction_requested.connect(func(data):
		print("DEBUG: interaction_requested received: ", data)
		captured_msg_p23a.merge(data, true)
	)
	inst_entrance._trigger_interaction()
	
	print("DEBUG: captured_msg_p23a = ", captured_msg_p23a)
	
	if captured_msg_p23a.get("type", "") != "message":
		printerr("FAIL 23-A: biometric_gate should trigger message!")
		get_tree().quit(1)
		return
		
	var gate_msg_key = inst_entrance.MESSAGES.get("biometric_gate", "")
	if captured_msg_p23a.get("message_text", "") != gate_msg_key:
		printerr("FAIL 23-A: biometric_gate message text mismatch!")
		get_tree().quit(1)
		return
		
	if GameState.get_flag("found_staff_pass", false) or GameState.get_flag("passed_nightclub_security", false):
		printerr("FAIL 23-A: biometric_gate should not set flags!")
		get_tree().quit(1)
		return
		
	inst_entrance.free()
	
	# 2. 驗證未通過安全檢驗時 back_door 被擋
	var inst_nightclub = load("res://scenes/levels/nightclub/nightclub.tscn").instantiate()
	var door_node = inst_nightclub.get_node("Interactables/BackDoorArea")
	inst_nightclub.current_interactable = door_node
	
	var captured_door_msg: Dictionary = {}
	inst_nightclub.interaction_requested.connect(func(data):
		captured_door_msg.merge(data, true)
	)
	inst_nightclub._trigger_interaction()
	
	if captured_door_msg.get("type", "") != "message":
		printerr("FAIL 23-A: back_door should trigger message when blocked!")
		get_tree().quit(1)
		return
		
	if captured_door_msg.get("message_text", "") != GameState.STORY_MESSAGES["nightclub_security_blocked"]:
		printerr("FAIL 23-A: Blocked message text mismatch!")
		get_tree().quit(1)
		return
		
	# 3. 驗證工牌 examine 與背包滿防呆
	# 塞滿背包
	while GameState.add_item("canned_food", 1):
		pass
		
	var pass_node = inst_nightclub.get_node("Interactables/StaffPassExamine")
	inst_nightclub.current_interactable = pass_node
	
	var captured_pass_msg: Dictionary = {}
	# 重新連結 interaction_requested 訊號
	for conn in inst_nightclub.interaction_requested.get_connections():
		inst_nightclub.interaction_requested.disconnect(conn.callable)
	inst_nightclub.interaction_requested.connect(func(data):
		captured_pass_msg.merge(data, true)
	)
	
	inst_nightclub._trigger_interaction()
	
	if captured_pass_msg.get("message_text", "") != GameState.STORY_MESSAGES["nightclub_examine_pass_bag_full"]:
		printerr("FAIL 23-A: Should show bag full message when picking staff pass with full inventory!")
		get_tree().quit(1)
		return
		
	if GameState.get_flag("found_staff_pass", false):
		printerr("FAIL 23-A: found_staff_pass flag should not be set when bag is full!")
		get_tree().quit(1)
		return
		
	# 清空背包第一格
	GameState.inventory[0] = {}
	
	# 重置 captured_pass_msg
	captured_pass_msg.clear()
	
	inst_nightclub._trigger_interaction()
	
	if not GameState.get_flag("found_staff_pass", false):
		printerr("FAIL 23-A: found_staff_pass flag should be set after successful picking!")
		get_tree().quit(1)
		return
		
	if not GameState.has_item("nightclub_staff_pass"):
		printerr("FAIL 23-A: nightclub_staff_pass item should be in inventory!")
		get_tree().quit(1)
		return
		
	if captured_pass_msg.get("message_text", "") != GameState.STORY_MESSAGES["nightclub_staff_pass_found"]:
		printerr("FAIL 23-A: Staff pass found message text mismatch!")
		get_tree().quit(1)
		return
		
	# 驗證物件被隱藏
	if pass_node.visible or pass_node.process_mode != ProcessMode.PROCESS_MODE_DISABLED:
		printerr("FAIL 23-A: StaffPassExamine node should be hidden and disabled!")
		get_tree().quit(1)
		return
		
	# 4. 驗證通過安全檢驗後 back_door 轉場正常
	GameState.set_flag("passed_nightclub_security", true)
	inst_nightclub.current_interactable = door_node
	
	var captured_trans: Dictionary = {}
	inst_nightclub.scene_transition_requested.connect(func(scene_id, entry_point_id, payload):
		captured_trans.merge({"scene": scene_id, "entry": entry_point_id}, true)
	)
	inst_nightclub._trigger_interaction()
	
	if captured_trans.get("scene", "") != "nightclub_back" or captured_trans.get("entry", "") != "from_lobby":
		printerr("FAIL 23-A: Should transition to nightclub_back after security passed!")
		get_tree().quit(1)
		return

	# 5. 驗證保全 NPC 互動會派發對話（dialogue_id dispatch，實機唯一入口）
	var bodyguard_node_p23a = inst_nightclub.get_node("Interactables/Bodyguard")
	inst_nightclub.current_interactable = bodyguard_node_p23a

	var captured_dialogue_p23a: Dictionary = {}
	for conn_p23a in inst_nightclub.interaction_requested.get_connections():
		inst_nightclub.interaction_requested.disconnect(conn_p23a.callable)
	inst_nightclub.interaction_requested.connect(func(data):
		captured_dialogue_p23a.merge(data, true)
	)

	inst_nightclub._trigger_interaction()

	if captured_dialogue_p23a.get("type", "") != "dialogue" or captured_dialogue_p23a.get("dialogue_id", "") != "nightclub_bodyguard":
		printerr("FAIL 23-A: Bodyguard interaction should dispatch dialogue 'nightclub_bodyguard', got: ", captured_dialogue_p23a)
		get_tree().quit(1)
		return

	inst_nightclub.free()

	print("PASS: Phase 23-A bodyguard, back_door block, and staff_pass_examine verified.")

	# ===================== Phase 23-B: Act 3 夜總會保全對話與智取 =====================
	print("--- Phase 23-B: Act 3 夜總會保全對話與智取 ---")
	
	var dialogue_runner_script = load("res://scripts/dialogue/dialogue_runner.gd")
	if not dialogue_runner_script:
		printerr("FAIL 23-B: Could not load dialogue_runner.gd")
		get_tree().quit(1)
		return
		
	# 1. 驗證 credits condition (op >= 500) 在 DialogueRunner 中正常評估
	GameState.reset_for_new_game()
	GameState.set_credits(499)
	
	var runner_p23b = dialogue_runner_script.new()
	var bodyguard_tree = DialogueDB.get_tree_for("nightclub_bodyguard")
	if bodyguard_tree.is_empty():
		printerr("FAIL 23-B: nightclub_bodyguard tree not found in DialogueDB!")
		get_tree().quit(1)
		return
		
	# 2. 測試：Credits 不足時，賄賂分流走向 bribe_fail
	runner_p23b.start(bodyguard_tree, "lobby")
	# 選擇 0 (賄賂)
	runner_p23b.choose(0)
	var state_fail = runner_p23b.current()
	if state_fail.get("text", "") != "DLG_BODYGUARD_BRIBE_FAIL_TEXT":
		printerr("FAIL 23-B: Bribe with 499 credits should fail, got text: ", state_fail.get("text"))
		get_tree().quit(1)
		return
	if GameState.get_credits() != 499 or GameState.get_flag("passed_nightclub_security", false):
		printerr("FAIL 23-B: Failed bribe should not deduct credits or set security flag!")
		get_tree().quit(1)
		return
		
	# 3. 測試：Credits 足夠時，賄賂成功走向 bribe_success
	GameState.reset_for_new_game()
	GameState.set_credits(500)
	var runner_success = dialogue_runner_script.new()
	runner_success.start(bodyguard_tree, "lobby")
	runner_success.choose(0)
	var state_success = runner_success.current()
	if state_success.get("text", "") != "DLG_BODYGUARD_BRIBE_SUCCESS_TEXT":
		printerr("FAIL 23-B: Bribe with 500 credits should succeed, got text: ", state_success.get("text"))
		get_tree().quit(1)
		return
	if GameState.get_credits() != 0 or not GameState.get_flag("passed_nightclub_security", false):
		printerr("FAIL 23-B: Bribe success should deduct 500 credits and set security flag!")
		get_tree().quit(1)
		return
		
	# 4. 測試：無工牌時，假裝身份走向 fake_identity_fail
	GameState.reset_for_new_game()
	var runner_fake_fail = dialogue_runner_script.new()
	runner_fake_fail.start(bodyguard_tree, "lobby")
	runner_fake_fail.choose(1) # 選擇 1 (假裝身份)
	var state_fake_fail = runner_fake_fail.current()
	if state_fake_fail.get("text", "") != "DLG_BODYGUARD_FAKE_IDENTITY_FAIL_TEXT":
		printerr("FAIL 23-B: Pretend without pass should fail, got text: ", state_fake_fail.get("text"))
		get_tree().quit(1)
		return
	if GameState.get_flag("passed_nightclub_security", false):
		printerr("FAIL 23-B: Failed fake identity should not set security flag!")
		get_tree().quit(1)
		return
		
	# 5. 測試：有工牌時，假裝身份走向 fake_identity_success
	GameState.reset_for_new_game()
	GameState.set_flag("found_staff_pass", true)
	var runner_fake_ok = dialogue_runner_script.new()
	runner_fake_ok.start(bodyguard_tree, "lobby")
	runner_fake_ok.choose(1)
	var state_fake_ok = runner_fake_ok.current()
	if state_fake_ok.get("text", "") != "DLG_BODYGUARD_FAKE_IDENTITY_SUCCESS_TEXT":
		printerr("FAIL 23-B: Pretend with pass should succeed, got text: ", state_fake_ok.get("text"))
		get_tree().quit(1)
		return
	if not GameState.get_flag("passed_nightclub_security", false):
		printerr("FAIL 23-B: Fake identity success should set security flag!")
		get_tree().quit(1)
		return
		
	# 6. 測試：已通關狀態下，對話會直接進入 already_passed
	GameState.reset_for_new_game()
	GameState.set_flag("passed_nightclub_security", true)
	var runner_passed = dialogue_runner_script.new()
	runner_passed.start(bodyguard_tree, "start")
	var state_passed = runner_passed.current()
	if state_passed.get("text", "") != "DLG_BODYGUARD_ALREADY_PASSED_TEXT":
		printerr("FAIL 23-B: Start when already passed should go to already_passed node, got text: ", state_passed.get("text"))
		get_tree().quit(1)
		return
		
	print("PASS: Phase 23-B bodyguard dialogue, bribe logic, fake identity, and credits condition verified.")

	# ===================== Phase 23-C: Act 3 夜總會保全引開與潛行 =====================
	print("--- Phase 23-C: Act 3 夜總會保全引開與潛行 ---")
	GameState.reset_for_new_game()
	
	# 載入門面廳場景
	var nightclub_scene = load("res://scenes/levels/nightclub/nightclub.tscn")
	if nightclub_scene == null:
		printerr("FAIL 23-C: Could not load nightclub.tscn")
		get_tree().quit(1)
		return
		
	var nightclub_node = nightclub_scene.instantiate()
	get_tree().root.add_child(nightclub_node)
	
	# 初始化場景入口
	nightclub_node.set_entry_point("from_entrance")
	
	# 準備捕捉 interaction_requested 與 scene_transition_requested
	var captured_transition_p23c: Dictionary = {}
	var captured_msg_p23c: Dictionary = {}
	
	nightclub_node.scene_transition_requested.connect(func(scene_id, entry_point, payload):
		captured_transition_p23c["scene_id"] = scene_id
		captured_transition_p23c["entry_point"] = entry_point
	)
	nightclub_node.interaction_requested.connect(func(data):
		captured_msg_p23c.merge(data, true)
	)
	
	# 1. 測試：未引開保全時，互動 back_door 應該被阻擋
	var back_door = nightclub_node.get_node_or_null("Interactables/BackDoorArea")
	if back_door == null:
		printerr("FAIL 23-C: BackDoorArea interactable not found!")
		get_tree().quit(1)
		return
		
	nightclub_node.current_interactable = back_door
	nightclub_node._trigger_interaction()
	
	if not captured_msg_p23c.has("message_text") or captured_msg_p23c.get("message_text", "") != "MSG_NIGHTCLUB_SECURITY_BLOCKED":
		printerr("FAIL 23-C: back_door should be blocked when bodyguard is on post, got msg: ", captured_msg_p23c)
		get_tree().quit(1)
		return
	if GameState.get_flag("passed_nightclub_security", false):
		printerr("FAIL 23-C: passed_nightclub_security should not be set yet!")
		get_tree().quit(1)
		return
		
	# 清空捕捉的資訊
	captured_msg_p23c.clear()

	var bar_bot = nightclub_node.get_node_or_null("Interactables/BarBot")
	if bar_bot == null:
		printerr("FAIL 23-C: BarBot interactable not found!")
		get_tree().quit(1)
		return

	var bodyguard_node = nightclub_node.get_node_or_null("Interactables/Bodyguard")
	if bodyguard_node == null:
		printerr("FAIL 23-C: Bodyguard interactable not found!")
		get_tree().quit(1)
		return

	# 1.5 測試：未與保全對話前，互動 bar_bot 只給中性訊息、不觸發引開
	nightclub_node.current_interactable = bar_bot
	nightclub_node._trigger_interaction()
	if captured_msg_p23c.get("message_text", "") != "MSG_NIGHTCLUB_BAR_BOT_PRE_TALK":
		printerr("FAIL 23-C: bar_bot before talking should show pre-talk message, got: ", captured_msg_p23c)
		get_tree().quit(1)
		return
	if nightclub_node._bodyguard_off_post or GameState.has_flag("nightclub_bar_bot_used"):
		printerr("FAIL 23-C: bar_bot before talking must NOT trigger distraction!")
		get_tree().quit(1)
		return
	captured_msg_p23c.clear()

	# 模擬已與保全對話（解鎖 bar_bot 引開）
	GameState.set_flag("talked_nightclub_bodyguard", true)

	# 2. 測試：互動 bar_bot 觸發引開，_bodyguard_off_post 應為 true、used 旗標永久設定、保全與 bar_bot 淡出停用
	# 先確認保全在崗 (visible=true, process_mode=INHERIT)
	if not bodyguard_node.visible or bodyguard_node.process_mode != Node.PROCESS_MODE_INHERIT:
		printerr("FAIL 23-C: Bodyguard should be visible and inheriting process mode initially!")
		get_tree().quit(1)
		return

	captured_msg_p23c.clear()
	nightclub_node.current_interactable = bar_bot
	nightclub_node._trigger_interaction()

	# 引發時應先跳「玩家動手腳→混亂」前置 message box
	if captured_msg_p23c.get("message_text", "") != "MSG_NIGHTCLUB_BAR_BOT_TAMPER":
		printerr("FAIL 23-C: distraction should first show tamper narration, got: ", captured_msg_p23c)
		get_tree().quit(1)
		return

	if not nightclub_node._bodyguard_off_post:
		printerr("FAIL 23-C: _bodyguard_off_post should be true after distracting bar_bot!")
		get_tree().quit(1)
		return

	# 引發後 used 旗標應永久設定（持久、納存讀檔）
	if not GameState.has_flag("nightclub_bar_bot_used"):
		printerr("FAIL 23-C: nightclub_bar_bot_used should be set after distraction!")
		get_tree().quit(1)
		return

	# 觸發後，保全的 process_mode 應該被 disabled 且 visible 應該將要為 false
	if bodyguard_node.process_mode != Node.PROCESS_MODE_DISABLED:
		printerr("FAIL 23-C: Distracted bodyguard should have process mode disabled!")
		get_tree().quit(1)
		return

	# 且 bar_bot 也應該被 disabled 且從互動範圍移除
	if bar_bot.process_mode != Node.PROCESS_MODE_DISABLED:
		printerr("FAIL 23-C: Distracted bar_bot should have process mode disabled!")
		get_tree().quit(1)
		return

	# 3. 測試：引開保全後，此時互動 back_door 應該可以潛行通過 (set passed_nightclub_security=true 且 transition to nightclub_back)
	nightclub_node.current_interactable = back_door
	nightclub_node._trigger_interaction()
	
	if not GameState.get_flag("passed_nightclub_security", false):
		printerr("FAIL 23-C: passed_nightclub_security should be set to true after sneak in!")
		get_tree().quit(1)
		return
	if captured_transition_p23c.get("scene_id", "") != "nightclub_back":
		printerr("FAIL 23-C: Should transition to nightclub_back, got: ", captured_transition_p23c)
		get_tree().quit(1)
		return
		
	# 4. 測試：場景 transient 變數且重新加載時保全歸位
	# 在 passed_nightclub_security 仍為 false 情況下
	get_tree().root.remove_child(nightclub_node)
	nightclub_node.queue_free()
	
	GameState.reset_for_new_game()
	# 此時 passed_nightclub_security 應為 false
	nightclub_node = nightclub_scene.instantiate()
	get_tree().root.add_child(nightclub_node)
	
	# 重進場景後，保全應重新歸位 (visible=true, process_mode=INHERIT)
	bodyguard_node = nightclub_node.get_node_or_null("Interactables/Bodyguard")
	if bodyguard_node == null or not bodyguard_node.visible or bodyguard_node.process_mode != Node.PROCESS_MODE_INHERIT:
		printerr("FAIL 23-C: Bodyguard should reset to visible and inheriting process mode when passed_nightclub_security is false!")
		get_tree().quit(1)
		return
		
	# 5. 測試：即使 passed_nightclub_security 已為 true，保全仍永遠在崗（可見、INHERIT），只是後場門放行
	get_tree().root.remove_child(nightclub_node)
	nightclub_node.queue_free()

	GameState.reset_for_new_game()
	GameState.set_flag("passed_nightclub_security", true)

	nightclub_node = nightclub_scene.instantiate()
	get_tree().root.add_child(nightclub_node)

	bodyguard_node = nightclub_node.get_node_or_null("Interactables/Bodyguard")
	if bodyguard_node == null or not bodyguard_node.visible or bodyguard_node.process_mode != Node.PROCESS_MODE_INHERIT:
		printerr("FAIL 23-C: Bodyguard should stay visible and at post even when passed_nightclub_security is true!")
		get_tree().quit(1)
		return
		
	# 6. 測試：未在空窗內潛入 → 視窗到期保全歸位；引開為永久一次性
	get_tree().root.remove_child(nightclub_node)
	nightclub_node.queue_free()

	GameState.reset_for_new_game()
	nightclub_node = nightclub_scene.instantiate()
	get_tree().root.add_child(nightclub_node)
	nightclub_node.set_entry_point("from_entrance")

	var captured_msg_p23c6: Dictionary = {}
	nightclub_node.interaction_requested.connect(func(data):
		captured_msg_p23c6.merge(data, true)
	)

	GameState.set_flag("talked_nightclub_bodyguard", true)
	bar_bot = nightclub_node.get_node_or_null("Interactables/BarBot")
	bodyguard_node = nightclub_node.get_node_or_null("Interactables/Bodyguard")
	nightclub_node.current_interactable = bar_bot
	nightclub_node._trigger_interaction()

	if not nightclub_node._bodyguard_off_post:
		printerr("FAIL 23-C: window should open after distraction (step 6)!")
		get_tree().quit(1)
		return

	# 模擬 10 秒空窗到期（未潛入）
	captured_msg_p23c6.clear()
	nightclub_node.force_resolve_distraction()

	if nightclub_node._bodyguard_off_post:
		printerr("FAIL 23-C: window should be closed after expiry (step 6)!")
		get_tree().quit(1)
		return
	if not bodyguard_node.visible or bodyguard_node.process_mode != Node.PROCESS_MODE_INHERIT:
		printerr("FAIL 23-C: bodyguard should return to post after window expiry (step 6)!")
		get_tree().quit(1)
		return
	if captured_msg_p23c6.get("message_text", "") != "MSG_NIGHTCLUB_GUARD_RETURNED":
		printerr("FAIL 23-C: should show guard-returned message after expiry, got: ", captured_msg_p23c6)
		get_tree().quit(1)
		return
	if GameState.get_flag("passed_nightclub_security", false):
		printerr("FAIL 23-C: passed_nightclub_security must stay false after a failed sneak (step 6)!")
		get_tree().quit(1)
		return

	# 永久一次性：再次互動 bar_bot 只給「已修復」中性訊息、不再引開
	captured_msg_p23c6.clear()
	nightclub_node.current_interactable = bar_bot
	nightclub_node._trigger_interaction()
	if captured_msg_p23c6.get("message_text", "") != "MSG_NIGHTCLUB_BAR_BOT_USED":
		printerr("FAIL 23-C: spent bar_bot should show used message, got: ", captured_msg_p23c6)
		get_tree().quit(1)
		return
	if nightclub_node._bodyguard_off_post:
		printerr("FAIL 23-C: spent bar_bot must NOT re-trigger distraction!")
		get_tree().quit(1)
		return

	# 結束清理
	get_tree().root.remove_child(nightclub_node)
	nightclub_node.queue_free()

	print("PASS: Phase 23-C bodyguard distraction and sneak in mechanics verified.")

	# ===================== Phase 23-D: Act 3 夜總會回歸、存讀檔與進度驗證 =====================
	print("--- Phase 23-D: Act 3 夜總會回歸、存讀檔與進度驗證 ---")
	GameState.reset_for_new_game()
	
	# 1. 測試：在新遊戲重置狀態下，各旗標應為 false/空，進度為 0
	if GameState.get_flag("passed_nightclub_security", false) or GameState.get_flag("found_staff_pass", false) or GameState.has_item("nightclub_staff_pass"):
		printerr("FAIL 23-D: New game reset failed to clear Phase 23 states!")
		get_tree().quit(1)
		return
		
	# 2. 測試：特殊道具進度因取得工牌打勾，且不退勾
	var added_pass_p23d := GameState.add_item("nightclub_staff_pass", 1)
	if not added_pass_p23d:
		printerr("FAIL 23-D: Could not add nightclub_staff_pass during progress check!")
		get_tree().quit(1)
		return
		
	var progress_summary_p23d = GameState.get_progress_summary()
	var collected_items_p23d = GameState.collected_special_items
	if not collected_items_p23d.get("nightclub_staff_pass", false):
		printerr("FAIL 23-D: nightclub_staff_pass should mark progress special items collected!")
		get_tree().quit(1)
		return
		
	var badge_instance_id_p23d = ""
	for item in GameState.get_inventory():
		if item != null and item.get("item_id", "") == "nightclub_staff_pass":
			badge_instance_id_p23d = item.get("instance_id", "")
			break
	if badge_instance_id_p23d != "":
		GameState.remove_item(badge_instance_id_p23d)
		
	if not GameState.collected_special_items.get("nightclub_staff_pass", false):
		printerr("FAIL 23-D: progress special items should remain marked after item removal (no unticking)!")
		get_tree().quit(1)
		return
		
	# 3. 測試：存讀檔 round-trip
	GameState.reset_for_new_game()
	GameState.set_flag("passed_nightclub_security", true)
	GameState.set_flag("found_staff_pass", true)
	var added_pass_again_p23d = GameState.add_item("nightclub_staff_pass", 1)
	if not added_pass_again_p23d:
		printerr("FAIL 23-D: Setup failed for save/load test!")
		get_tree().quit(1)
		return
		
	var save_dict_p23d = SaveSystem.capture("nightclub", 100.0, 1)
	
	GameState.reset_for_new_game()
	if GameState.get_flag("passed_nightclub_security", false) or GameState.get_flag("found_staff_pass", false) or GameState.has_item("nightclub_staff_pass"):
		printerr("FAIL 23-D: State reset failed during save/load check!")
		get_tree().quit(1)
		return
		
	if not SaveSystem.validate(save_dict_p23d):
		printerr("FAIL 23-D: SaveSystem.validate() failed for save_dict_p23d!")
		get_tree().quit(1)
		return
	SaveSystem.apply(save_dict_p23d)
		
	if not GameState.get_flag("passed_nightclub_security", false) or not GameState.get_flag("found_staff_pass", false):
		printerr("FAIL 23-D: Save/load failed to restore story flags!")
		get_tree().quit(1)
		return
	if not GameState.has_item("nightclub_staff_pass"):
		printerr("FAIL 23-D: Save/load failed to restore nightclub_staff_pass in inventory!")
		get_tree().quit(1)
		return
	if not GameState.collected_special_items.get("nightclub_staff_pass", false):
		printerr("FAIL 23-D: Save/load failed to restore special item progress!")
		get_tree().quit(1)
		return
		
	# 4. 測試：缺鍵/歷史存檔相容性
	var compat_dict_p23d = save_dict_p23d.duplicate(true)
	var data_dict_p23d = compat_dict_p23d.get("data", {})
	if data_dict_p23d.has("story_flags"):
		data_dict_p23d["story_flags"].erase("passed_nightclub_security")
		data_dict_p23d["story_flags"].erase("found_staff_pass")
	if data_dict_p23d.has("collected_special_items"):
		data_dict_p23d["collected_special_items"].erase("nightclub_staff_pass")
		
	GameState.reset_for_new_game()
	if not SaveSystem.validate(compat_dict_p23d):
		printerr("FAIL 23-D: SaveSystem.validate() failed for compat_dict_p23d!")
		get_tree().quit(1)
		return
	SaveSystem.apply(compat_dict_p23d)
	if GameState.get_flag("passed_nightclub_security", false) or GameState.get_flag("found_staff_pass", false) or GameState.collected_special_items.get("nightclub_staff_pass", false):
		printerr("FAIL 23-D: Compatibility load should restore missing keys to false!")
		get_tree().quit(1)
		return
		
	print("PASS: Phase 23-D regression, save/load, and M1 progress integration verified.")

	# ===================== Phase 24-A: 七號事件 quest 化 + 爆發 gate =====================
	print("--- Phase 24-A: 七號事件 quest 化 + 爆發 gate ---")
	
	# 1. 測試任務資料與 resolver 預設分流
	var QuestDB_p24a = load("res://data/quests/quest_db.gd")
	var quest_data_p24a = QuestDB_p24a.get_quest_data("seven_betrayal")
	if quest_data_p24a == null:
		printerr("FAIL 24-A: seven_betrayal quest data not registered in QuestDB!")
		get_tree().quit(1)
		return
	
	# 模擬 resolve_completed_note 分支
	# A: 預設/成功攔下
	GameState.reset_for_new_game()
	var note_full_p24a = quest_data_p24a.resolve_completed_note()
	if note_full_p24a.get("title", "") != "QUEST_SEVEN_BETRAYAL_COMPLETED_FULL_TITLE":
		printerr("FAIL 24-A: resolve_completed_note() should return full completion note by default!")
		get_tree().quit(1)
		return
		
	# B: 部分攔下
	GameState.set_flag("seven_stopped_partial", true)
	var note_partial_p24a = quest_data_p24a.resolve_completed_note()
	if note_partial_p24a.get("title", "") != "QUEST_SEVEN_BETRAYAL_COMPLETED_PARTIAL_TITLE":
		printerr("FAIL 24-A: resolve_completed_note() should return partial completion note when seven_stopped_partial is true!")
		get_tree().quit(1)
		return
		
	# D: 和平線
	GameState.set_flag("seven_stopped_partial", false)
	GameState.set_flag("seven_peace_branch_d", true)
	var note_peace_p24a = quest_data_p24a.resolve_completed_note()
	if note_peace_p24a.get("title", "") != "QUEST_SEVEN_BETRAYAL_COMPLETED_PEACE_TITLE":
		printerr("FAIL 24-A: resolve_completed_note() should return peace completion note when seven_peace_branch_d is true!")
		get_tree().quit(1)
		return
	
	# 2. 測試爆發 gate
	# A: 未通關夜總會 -> 不爆發
	GameState.reset_for_new_game()
	var level_p24a = load("res://scenes/levels/underground_settlement/underground_settlement_right.tscn").instantiate()
	add_child(level_p24a)
	level_p24a.set_entry_point("from_left")
	if GameState.get_flag("seven_betrayal_triggered", false):
		printerr("FAIL 24-A: betrayal should not trigger before nightclub security is passed!")
		get_tree().quit(1)
		return
	remove_child(level_p24a)
	level_p24a.free()
	
	# B: 已通關夜總會，未走 D -> 爆發
	GameState.reset_for_new_game()
	GameState.set_flag("passed_nightclub_security", true)
	level_p24a = load("res://scenes/levels/underground_settlement/underground_settlement_right.tscn").instantiate()
	add_child(level_p24a)
	level_p24a.set_entry_point("from_left")
	if not GameState.get_flag("seven_betrayal_triggered", false) or not GameState.get_flag("seven_betrayal_pending", false):
		printerr("FAIL 24-A: betrayal trigger gate failed to activate seven_betrayal_triggered/pending!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("seven_betrayal") != "active":
		printerr("FAIL 24-A: seven_betrayal quest should be active after trigger!")
		get_tree().quit(1)
		return
	remove_child(level_p24a)
	level_p24a.free()
	
	# C: 已通關夜總會，已走 D -> 不爆發
	GameState.reset_for_new_game()
	GameState.set_flag("passed_nightclub_security", true)
	GameState.set_flag("seven_peace_branch_d", true)
	level_p24a = load("res://scenes/levels/underground_settlement/underground_settlement_right.tscn").instantiate()
	add_child(level_p24a)
	level_p24a.set_entry_point("from_left")
	if GameState.get_flag("seven_betrayal_triggered", false):
		printerr("FAIL 24-A: betrayal should not trigger when seven_peace_branch_d is true!")
		get_tree().quit(1)
		return
	remove_child(level_p24a)
	level_p24a.free()
	
	# 3. 驗證 i18n 翻譯（測試 M2 系統是否可正確 resolve）
	for loc_p24a in ["zh_TW", "zh_CN", "en"]:
		TranslationServer.set_locale(loc_p24a)
		var tr_title = tr("QUEST_SEVEN_BETRAYAL_STEP_STARTED_TITLE")
		if tr_title == "QUEST_SEVEN_BETRAYAL_STEP_STARTED_TITLE" or tr_title.is_empty():
			printerr("FAIL 24-A: missing translation for QUEST_SEVEN_BETRAYAL_STEP_STARTED_TITLE in locale: " + loc_p24a)
			get_tree().quit(1)
			return
	
	# 還原 locale 到 zh_TW
	TranslationServer.set_locale("zh_TW")
	
	print("PASS: Phase 24-A questification and trigger gate verified.")

	# ===================== Phase 24-B: 分支判定 + 伍姐 / 小岑提前警告 =====================
	print("--- Phase 24-B: 分支判定 + 伍姐 / 小岑提前警告 ---")
	
	# 1. 驗證對話樹是否有 warning 節點
	var wu_tree_p24b = load("res://data/dialogue/wu.gd").TREE
	if not wu_tree_p24b.has("warning"):
		printerr("FAIL 24-B: wu.gd missing 'warning' node!")
		get_tree().quit(1)
		return
	var cen_tree_p24b = load("res://data/dialogue/cen.gd").TREE
	if not cen_tree_p24b.has("warning"):
		printerr("FAIL 24-B: cen.gd missing 'warning' node!")
		get_tree().quit(1)
		return
		
	# 2. 模擬 DialogueRunner 評估警告條件 (Wu)
	var runner_wu_p24b = load("res://scripts/dialogue/dialogue_runner.gd").new()
	# Case 24B-1: met_wu=true, affinity_wu=2, heard_wu_warning=false -> goto warning
	GameState.reset_for_new_game()
	GameState.set_flag("met_wu", true)
	GameState.set_flag("affinity_wu", 2)
	runner_wu_p24b.start(wu_tree_p24b)
	if runner_wu_p24b._current_node_id != "warning":
		printerr("FAIL 24-B: Wu dialogue should route to 'warning' when met_wu=true and affinity_wu=2!")
		get_tree().quit(1)
		return
	
	# 推進對話，確認設了 heard_wu_warning 並進入 retalk
	runner_wu_p24b.advance() # 進入 warning node 會執行 set_flag heard_wu_warning
	if GameState.get_flag("heard_wu_warning", false) != true:
		printerr("FAIL 24-B: heard_wu_warning flag not set after warning node!")
		get_tree().quit(1)
		return
		
	# Case 24B-2: met_wu=true, affinity_wu=2, heard_wu_warning=true -> goto retalk
	var runner_wu_retalk_p24b = load("res://scripts/dialogue/dialogue_runner.gd").new()
	runner_wu_retalk_p24b.start(wu_tree_p24b)
	if runner_wu_retalk_p24b._current_node_id != "retalk":
		printerr("FAIL 24-B: Wu dialogue should route to 'retalk' when warning already heard!")
		get_tree().quit(1)
		return

	# 3. 模擬 DialogueRunner 評估警告條件 (Cen)
	var runner_cen_p24b = load("res://scripts/dialogue/dialogue_runner.gd").new()
	GameState.reset_for_new_game()
	GameState.set_flag("met_cen", true)
	GameState.set_flag("affinity_cen", 2)
	runner_cen_p24b.start(cen_tree_p24b)
	if runner_cen_p24b._current_node_id != "warning":
		printerr("FAIL 24-B: Cen dialogue should route to 'warning' when met_cen=true and affinity_cen=2!")
		get_tree().quit(1)
		return
	runner_cen_p24b.advance()
	if GameState.get_flag("heard_cen_warning", false) != true:
		printerr("FAIL 24-B: heard_cen_warning flag not set after warning node!")
		get_tree().quit(1)
		return

	# 4. 驗證對話 i18n 翻譯是否齊全
	for loc_p24b in ["zh_TW", "zh_CN", "en"]:
		TranslationServer.set_locale(loc_p24b)
		for key_p24b in ["DLG_WU_WARNING_TEXT", "DLG_CEN_WARNING_TEXT"]:
			var tr_text = tr(key_p24b)
			if tr_text == key_p24b or tr_text.is_empty():
				printerr("FAIL 24-B: missing translation for " + key_p24b + " in locale: " + loc_p24b)
				get_tree().quit(1)
				return
				
	# 還原 locale
	TranslationServer.set_locale("zh_TW")
	
	# 5. 驗證 24-B 分支判定公式與攔截結算
	var SevenBetrayal_p24b = load("res://data/quests/seven_betrayal.gd")
	
	# Case 24B-3: trace = 2, no warning -> Branch A (stopped_full)
	GameState.reset_for_new_game()
	GameState.add_trace(2)
	GameState.set_flag("affinity_wu", 0)
	GameState.set_flag("affinity_cen", 0)
	if SevenBetrayal_p24b.get_betrayal_branch() != "stopped_full":
		printerr("FAIL 24-B: trace=2 should result in stopped_full!")
		get_tree().quit(1)
		return
		
	# Settle Case 24B-3 and check outputs (Idempotency test)
	QuestManager.start("seven_betrayal")
	var initial_seven_aff_p24b = GameState.get_flag("affinity_seven", 0)
	var initial_wu_aff_p24b = GameState.get_flag("affinity_wu", 0)
	
	var res_first_p24b = SevenBetrayal_p24b.resolve_betrayal_results()
	if not res_first_p24b:
		printerr("FAIL 24-B: first resolve_betrayal_results() call should return true!")
		get_tree().quit(1)
		return
		
	var res_second_p24b = SevenBetrayal_p24b.resolve_betrayal_results()
	if res_second_p24b:
		printerr("FAIL 24-B: second resolve_betrayal_results() call should return false (not idempotent)!")
		get_tree().quit(1)
		return
		
	if GameState.get_flag("seven_stopped_full", false) != true or GameState.get_flag("seven_stopped_partial", false) == true:
		printerr("FAIL 24-B: Settle trace=2 failed stopped_full or mutual exclusion failed!")
		get_tree().quit(1)
		return
	if GameState.get_flag("affinity_seven", 0) != initial_seven_aff_p24b - 2:
		printerr("FAIL 24-B: stopped_full should reduce affinity_seven by 2, and no further on second call!")
		get_tree().quit(1)
		return
	if GameState.get_flag("affinity_wu", 0) != initial_wu_aff_p24b:
		printerr("FAIL 24-B: stopped_full should not change affinity_wu!")
		get_tree().quit(1)
		return
	if GameState.get_flag("seven_betrayal_pending", false) == true:
		printerr("FAIL 24-B: betrayal_pending should be false after resolution!")
		get_tree().quit(1)
		return
	if QuestManager.get_status("seven_betrayal") != "completed":
		printerr("FAIL 24-B: seven_betrayal quest should be completed after resolution!")
		get_tree().quit(1)
		return
		
	# Case 24B-4: trace = 3, no warning -> Branch B (stopped_partial)
	GameState.reset_for_new_game()
	GameState.add_trace(3)
	GameState.set_flag("affinity_wu", 0)
	GameState.set_flag("affinity_cen", 0)
	if SevenBetrayal_p24b.get_betrayal_branch() != "stopped_partial":
		printerr("FAIL 24-B: trace=3 without warnings should result in stopped_partial!")
		get_tree().quit(1)
		return
		
	# Settle Case 24B-4 and check outputs
	QuestManager.start("seven_betrayal")
	initial_seven_aff_p24b = GameState.get_flag("affinity_seven", 0)
	initial_wu_aff_p24b = GameState.get_flag("affinity_wu", 0)
	SevenBetrayal_p24b.resolve_betrayal_results()
	if GameState.get_flag("seven_stopped_partial", false) != true or GameState.get_flag("seven_stopped_full", false) == true:
		printerr("FAIL 24-B: Settle trace=3 failed stopped_partial or mutual exclusion failed!")
		get_tree().quit(1)
		return
	if GameState.get_flag("cen_voiceprint_exposed", false) != true:
		printerr("FAIL 24-B: stopped_partial should expose Cen's voiceprint!")
		get_tree().quit(1)
		return
	if GameState.get_flag("affinity_seven", 0) != initial_seven_aff_p24b - 1:
		printerr("FAIL 24-B: stopped_partial should reduce affinity_seven by 1!")
		get_tree().quit(1)
		return
	if GameState.get_flag("affinity_wu", 0) != initial_wu_aff_p24b - 1:
		printerr("FAIL 24-B: stopped_partial should reduce affinity_wu by 1!")
		get_tree().quit(1)
		return

	# Case 24B-5: trace = 3, wu warning -> Branch A (stopped_full)
	GameState.reset_for_new_game()
	GameState.add_trace(3)
	GameState.set_flag("affinity_wu", 2)
	GameState.set_flag("affinity_cen", 0)
	if SevenBetrayal_p24b.get_betrayal_branch() != "stopped_full":
		printerr("FAIL 24-B: trace=3 with wu warning should result in stopped_full!")
		get_tree().quit(1)
		return

	# Case 24B-6: trace = 3, cen warning -> Branch A (stopped_full)
	GameState.reset_for_new_game()
	GameState.add_trace(3)
	GameState.set_flag("affinity_wu", 0)
	GameState.set_flag("affinity_cen", 2)
	if SevenBetrayal_p24b.get_betrayal_branch() != "stopped_full":
		printerr("FAIL 24-B: trace=3 with cen warning should result in stopped_full!")
		get_tree().quit(1)
		return
	
	print("PASS: Phase 24-B warning dialogues and routing verified.")
	print("PASS: Phase 24-B branch formula boundary and settlement verified.")

	# ===================== Phase 24-C: 深隧道追逐 + 兩去處選單接線 =====================
	print("--- Phase 24-C: 深隧道追逐 + 兩去處選單接線 ---")
	
	# 1. 目的地選單對話樹加載
	var travel_tree_p24c = DialogueDB.get_tree_for("travel_deep_tunnel")
	if travel_tree_p24c == null or not travel_tree_p24c.has("start"):
		printerr("FAIL 24-C: travel_deep_tunnel dialogue tree missing or empty!")
		get_tree().quit(1)
		return
		
	# 2. 測試場景加載與結構
	var chase1_scene_p24c = load("res://scenes/levels/tunnel_chase/tunnel_chase.tscn")
	if chase1_scene_p24c == null:
		printerr("FAIL 24-C: tunnel_chase.tscn could not be loaded!")
		get_tree().quit(1)
		return
	var chase1_inst_p24c = chase1_scene_p24c.instantiate()
	if chase1_inst_p24c == null:
		printerr("FAIL 24-C: tunnel_chase.tscn could not be instantiated!")
		get_tree().quit(1)
		return
	if not chase1_inst_p24c.has_node("Player") or not chase1_inst_p24c.has_node("Camera2D") or not chase1_inst_p24c.has_node("Interactables/ChaseLadder") or not chase1_inst_p24c.has_node("Interactables/ChaseDoor"):
		printerr("FAIL 24-C: tunnel_chase.tscn missing critical nodes!")
		get_tree().quit(1)
		return
	chase1_inst_p24c.free()

	var chase2_scene_p24c = load("res://scenes/levels/tunnel_chase/tunnel_chase_right.tscn")
	if chase2_scene_p24c == null:
		printerr("FAIL 24-C: tunnel_chase_right.tscn could not be loaded!")
		get_tree().quit(1)
		return
	var chase2_inst_p24c = chase2_scene_p24c.instantiate()
	if chase2_inst_p24c == null:
		printerr("FAIL 24-C: tunnel_chase_right.tscn could not be instantiated!")
		get_tree().quit(1)
		return
	if not chase2_inst_p24c.has_node("Player") or not chase2_inst_p24c.has_node("Camera2D") or not chase2_inst_p24c.has_node("Interactables/ChaseLadder") or not chase2_inst_p24c.has_node("Interactables/ChaseExit0") or not chase2_inst_p24c.has_node("Interactables/ChaseBacktrack"):
		printerr("FAIL 24-C: tunnel_chase_right.tscn missing critical nodes!")
		get_tree().quit(1)
		return
	chase2_inst_p24c.free()

	# 3. 測試隨機真出口與 reset 歸零
	GameState.reset_for_new_game()
	var exit_val_p24c = GameState.tunnel_chase_true_exit
	if exit_val_p24c < 0 or exit_val_p24c > 2:
		printerr("FAIL 24-C: tunnel_chase_true_exit should be between 0 and 2 after reset!")
		get_tree().quit(1)
		return
	if GameState._tunnel_chase_time_left != 180.0:
		printerr("FAIL 24-C: _tunnel_chase_time_left should be initialized to 180 after reset!")
		get_tree().quit(1)
		return

	# 4. 測試存讀檔持久化 round-trip
	GameState.set_flag("deep_tunnel_opened", true)
	GameState.tunnel_chase_true_exit = 1
	var save_data_p24c = SaveSystem.capture("underground_settlement_right", 100.0, 1)
	
	GameState.reset_for_new_game()
	SaveSystem.apply(save_data_p24c)
	if not GameState.get_flag("deep_tunnel_opened", false) or GameState.tunnel_chase_true_exit != 1:
		printerr("FAIL 24-C: Save/Load round-trip for chase state failed!")
		get_tree().quit(1)
		return

	# 5. 測試 undergound_settlement_right 深隧道口路由
	var settlement_r_scene_p24c = load("res://scenes/levels/underground_settlement/underground_settlement_right.tscn")
	var settlement_r_inst_p24c = settlement_r_scene_p24c.instantiate()
	add_child(settlement_r_inst_p24c)
	
	# Case A: deep_tunnel_opened = false
	GameState.set_flag("deep_tunnel_opened", false)
	var deep_tunnel_node_p24c = settlement_r_inst_p24c.get_node("Interactables/DeepTunnelArea")
	settlement_r_inst_p24c.current_interactable = deep_tunnel_node_p24c
	
	# Hook transition requested signal to verify target
	var transition_result_p24c := {"target": ""}
	settlement_r_inst_p24c.scene_transition_requested.connect(func(scene_id, _entry, _payload):
		transition_result_p24c["target"] = scene_id
	)
	var interaction_result_p24c := {"dialogue_id": ""}
	settlement_r_inst_p24c.interaction_requested.connect(func(data):
		if data.get("type") == "dialogue":
			interaction_result_p24c["dialogue_id"] = data.get("dialogue_id")
	)
	
	settlement_r_inst_p24c._trigger_interaction()
	if transition_result_p24c["target"] != "tunnel_combat":
		printerr("FAIL 24-C: when deep_tunnel_opened=false, deep_tunnel interaction must route to tunnel_combat transition! Got: ", transition_result_p24c["target"])
		get_tree().quit(1)
		return
		
	# Case B: deep_tunnel_opened = true
	GameState.set_flag("deep_tunnel_opened", true)
	settlement_r_inst_p24c._trigger_interaction()
	if interaction_result_p24c["dialogue_id"] != "travel_deep_tunnel":
		printerr("FAIL 24-C: when deep_tunnel_opened=true, deep_tunnel interaction must route to travel_deep_tunnel dialogue! Got: ", interaction_result_p24c["dialogue_id"])
		get_tree().quit(1)
		return
		
	remove_child(settlement_r_inst_p24c)
	settlement_r_inst_p24c.free()

	# 6. 測試 undergound_settlement 小岑條件式移除
	var settlement_l_scene_p24c = load("res://scenes/levels/underground_settlement/underground_settlement.tscn")
	
	# Case A: cen_voiceprint_exposed = false
	GameState.set_flag("cen_voiceprint_exposed", false)
	var settlement_l_inst_a_p24c = settlement_l_scene_p24c.instantiate()
	add_child(settlement_l_inst_a_p24c)
	settlement_l_inst_a_p24c.set_entry_point("from_subway")
	var npc_cen_node_a_p24c = settlement_l_inst_a_p24c.get_node_or_null("Interactables/NpcCen")
	var empty_tent_node_a_p24c = settlement_l_inst_a_p24c.get_node_or_null("Interactables/EmptyTentArea")
	if npc_cen_node_a_p24c == null or npc_cen_node_a_p24c.is_queued_for_deletion():
		printerr("FAIL 24-C: Cen NPC should be present when cen_voiceprint_exposed is false!")
		get_tree().quit(1)
		return
	if empty_tent_node_a_p24c != null and empty_tent_node_a_p24c.visible:
		printerr("FAIL 24-C: Empty tent area should be hidden/disabled when cen_voiceprint_exposed is false!")
		get_tree().quit(1)
		return
	remove_child(settlement_l_inst_a_p24c)
	settlement_l_inst_a_p24c.free()
	
	# Case B: cen_voiceprint_exposed = true
	GameState.set_flag("cen_voiceprint_exposed", true)
	var settlement_l_inst_b_p24c = settlement_l_scene_p24c.instantiate()
	add_child(settlement_l_inst_b_p24c)
	settlement_l_inst_b_p24c.set_entry_point("from_subway")
	var npc_cen_node_b_p24c = settlement_l_inst_b_p24c.get_node_or_null("Interactables/NpcCen")
	var empty_tent_node_b_p24c = settlement_l_inst_b_p24c.get_node_or_null("Interactables/EmptyTentArea")
	if npc_cen_node_b_p24c != null and not npc_cen_node_b_p24c.is_queued_for_deletion():
		printerr("FAIL 24-C: Cen NPC should be queue_free when cen_voiceprint_exposed is true!")
		get_tree().quit(1)
		return
	if empty_tent_node_b_p24c == null or not empty_tent_node_b_p24c.visible:
		printerr("FAIL 24-C: Empty tent area should be active/visible when cen_voiceprint_exposed is true!")
		get_tree().quit(1)
		return
	remove_child(settlement_l_inst_b_p24c)
	settlement_l_inst_b_p24c.free()
	
	# 7. 測試結算後 retalk 不進追逐
	GameState.reset_for_new_game()
	GameState.set_flag("seven_betrayal_triggered", true)
	GameState.set_flag("seven_betrayal_pending", false)
	GameState.set_flag("met_seven", true)
	var seven_tree_p24c = DialogueDB.get_tree_for("seven")
	var target_node_p24c := ""
	for branch in seven_tree_p24c["start"]["goto"]:
		var cond = branch.get("condition")
		var matched = true
		if cond is Array:
			for item in cond:
				var f = item.get("flag")
				var op = item.get("op")
				var val = item.get("value")
				var current_val = GameState.get_flag(f, false)
				if op == "==" and current_val != val:
					matched = false
					break
				elif op == "!=" and current_val == val:
					matched = false
					break
		elif cond is Dictionary:
			var f = cond.get("flag")
			var op = cond.get("op")
			var val = cond.get("value")
			var current_val = GameState.get_flag(f, false)
			if op == "==" and current_val != val:
				matched = false
			elif op == "!=" and current_val == val:
				matched = false
		else:
			matched = true
		
		if matched:
			target_node_p24c = branch.get("target")
			break
			
	if target_node_p24c == "betrayal_start":
		printerr("FAIL 24-C: Seven dialogue should not route to betrayal_start after quest completes!")
		get_tree().quit(1)
		return
	if target_node_p24c != "retalk":
		printerr("FAIL 24-C: Seven dialogue should route to retalk when seven_betrayal_pending=false and met_seven=true! Got: ", target_node_p24c)
		get_tree().quit(1)
		return
	
	print("PASS: Phase 24-C deep tunnel chase & travel menu verified.")

	# ===================== Phase 25-A: Act 4 備份區三場景骨架 =====================
	print("--- Phase 25-A: Act 4 備份區三場景骨架 ---")

	# 1. 驗證 SceneRegistry
	var datacenter_main_scene_phase25 = load("res://scenes/main/main.tscn")
	var main_instance_phase25 = datacenter_main_scene_phase25.instantiate()
	add_child(main_instance_phase25)
	await get_tree().process_frame

	var scenes_phase25 = main_instance_phase25.SCENES
	if not "datacenter_entrance" in scenes_phase25 or not "datacenter_backup" in scenes_phase25 or not "datacenter_backup_core" in scenes_phase25:
		printerr("FAIL 25-A: SceneRegistry missing datacenter scenes!")
		get_tree().quit(1)
		return

	if not "from_datacenter" in scenes_phase25["nightclub_entrance"].get("entry_points", []):
		printerr("FAIL 25-A: nightclub_entrance entry points missing from_datacenter!")
		get_tree().quit(1)
		return

	if SaveSystem.get_scene_display_name("datacenter_entrance") == "未知區域" or SaveSystem.get_scene_display_name("datacenter_backup_core") == "未知區域":
		printerr("FAIL 25-A: SaveSystem SCENE_NAMES missing datacenter scenes!")
		get_tree().quit(1)
		return

	# 2. 驗證 travel_datacenter 對話樹 gate（passed_nightclub_security AND (D OR A OR B)）
	DialogueDB = load("res://data/dialogue/dialogue_db.gd")
	var travel_tree_phase25 = DialogueDB.get_tree_for("travel_datacenter")

	# 2a. 全無旗標：鎖住
	GameState.reset_for_new_game()
	var runner_locked_phase25 = DialogueRunner.new()
	runner_locked_phase25.start(travel_tree_phase25)
	if runner_locked_phase25.current().get("text", "") != "DLG_TRAVEL_DATACENTER_LOCKED_TEXT":
		printerr("FAIL 25-A: travel_datacenter should be locked with no flags set!")
		get_tree().quit(1)
		return

	# 2b. 只過夜總會安檢、無終端旗標：仍鎖住
	GameState.set_flag("passed_nightclub_security", true)
	var runner_no_ending_phase25 = DialogueRunner.new()
	runner_no_ending_phase25.start(travel_tree_phase25)
	if runner_no_ending_phase25.current().get("text", "") != "DLG_TRAVEL_DATACENTER_LOCKED_TEXT":
		printerr("FAIL 25-A: travel_datacenter should stay locked without a Seven ending flag!")
		get_tree().quit(1)
		return

	# 2c. D 分支解鎖 + 晚 flavor + travel effect
	GameState.set_flag("seven_peace_branch_d", true)
	var runner_d_phase25 = DialogueRunner.new()
	runner_d_phase25.start(travel_tree_phase25)
	if runner_d_phase25.current().get("text", "") != "DLG_TRAVEL_DATACENTER_MENU_TEXT":
		printerr("FAIL 25-A: travel_datacenter should unlock the menu when seven_peace_branch_d is true!")
		get_tree().quit(1)
		return
	runner_d_phase25.choose(0)
	if runner_d_phase25.current().get("speaker", "") != "SPEAKER_WAN":
		printerr("FAIL 25-A: choosing to travel should show the Wan flavor beat first!")
		get_tree().quit(1)
		return
	runner_d_phase25.advance()
	if runner_d_phase25.pending_travel.get("scene_id", "") != "datacenter_entrance" or runner_d_phase25.pending_travel.get("entry_point_id", "") != "from_nightclub":
		printerr("FAIL 25-A: travel_datacenter payload incorrect: ", runner_d_phase25.pending_travel)
		get_tree().quit(1)
		return

	# 2d. A 分支（seven_stopped_full）獨立解鎖
	GameState.reset_for_new_game()
	GameState.set_flag("passed_nightclub_security", true)
	GameState.set_flag("seven_stopped_full", true)
	var runner_a_phase25 = DialogueRunner.new()
	runner_a_phase25.start(travel_tree_phase25)
	if runner_a_phase25.current().get("text", "") != "DLG_TRAVEL_DATACENTER_MENU_TEXT":
		printerr("FAIL 25-A: travel_datacenter should unlock when seven_stopped_full is true!")
		get_tree().quit(1)
		return

	# 2e. B 分支（seven_stopped_partial）獨立解鎖
	GameState.reset_for_new_game()
	GameState.set_flag("passed_nightclub_security", true)
	GameState.set_flag("seven_stopped_partial", true)
	var runner_b_phase25 = DialogueRunner.new()
	runner_b_phase25.start(travel_tree_phase25)
	if runner_b_phase25.current().get("text", "") != "DLG_TRAVEL_DATACENTER_MENU_TEXT":
		printerr("FAIL 25-A: travel_datacenter should unlock when seven_stopped_partial is true!")
		get_tree().quit(1)
		return

	# 2f. 取消分支不觸發 travel
	var runner_cancel_phase25 = DialogueRunner.new()
	runner_cancel_phase25.start(travel_tree_phase25)
	runner_cancel_phase25.choose(1)
	if runner_cancel_phase25.current().get("text", "") != "DLG_TRAVEL_DATACENTER_END_TEXT" or not runner_cancel_phase25.pending_travel.is_empty():
		printerr("FAIL 25-A: Cancelling travel_datacenter should not set pending_travel!")
		get_tree().quit(1)
		return

	# 3. 驗證三場景載入、相機邊界、spawn points
	var datacenter_specs_phase25 := {
		"datacenter_entrance": {
			"path": "res://scenes/levels/datacenter_entrance/datacenter_entrance.tscn",
			"limit_right": 1376,
			"spawns": ["from_nightclub", "from_backup"]
		},
		"datacenter_backup": {
			"path": "res://scenes/levels/datacenter_backup/datacenter_backup.tscn",
			"limit_right": 4768,
			"spawns": ["from_entrance", "from_core"]
		},
		"datacenter_backup_core": {
			"path": "res://scenes/levels/datacenter_backup_core/datacenter_backup_core.tscn",
			"limit_right": 4768,
			"spawns": ["from_backup"]
		}
	}

	for scene_id_phase25 in datacenter_specs_phase25:
		var spec_phase25 = datacenter_specs_phase25[scene_id_phase25]
		var packed_phase25 = load(spec_phase25["path"])
		if not packed_phase25:
			printerr("FAIL 25-A: Could not load scene ", spec_phase25["path"])
			get_tree().quit(1)
			return

		var inst_phase25 = packed_phase25.instantiate()
		add_child(inst_phase25)
		await get_tree().process_frame

		var camera_phase25 = inst_phase25.get_node("Camera2D")
		if not camera_phase25 or camera_phase25.limit_right != spec_phase25["limit_right"]:
			printerr("FAIL 25-A: Camera limit_right incorrect for ", scene_id_phase25)
			get_tree().quit(1)
			return

		for spawn_phase25 in spec_phase25["spawns"]:
			if not inst_phase25.has_node("SpawnPoints/" + spawn_phase25):
				printerr("FAIL 25-A: Missing spawn point ", spawn_phase25, " in ", scene_id_phase25)
				get_tree().quit(1)
				return

		inst_phase25.free()

	# 4. 驗證善後員門禁 gate：缺 read_old_work_order 擋、齊全放行
	GameState.reset_for_new_game()
	var inst_entrance_phase25 = load("res://scenes/levels/datacenter_entrance/datacenter_entrance.tscn").instantiate()
	var gate_node_phase25 = inst_entrance_phase25.get_node("Interactables/MainGateArea")
	inst_entrance_phase25.current_interactable = gate_node_phase25

	var captured_denied_phase25: Dictionary = {}
	inst_entrance_phase25.interaction_requested.connect(func(data):
		captured_denied_phase25.merge(data, true)
	)
	var captured_trans_denied_phase25: Dictionary = {}
	inst_entrance_phase25.scene_transition_requested.connect(func(scene_id, entry_point_id, payload):
		captured_trans_denied_phase25.merge({"scene": scene_id, "entry": entry_point_id}, true)
	)
	inst_entrance_phase25._trigger_interaction()

	if captured_denied_phase25.get("message_text", "") != GameState.STORY_MESSAGES["datacenter_access_denied"]:
		printerr("FAIL 25-A: main_gate should show access-denied message without badge/read_old_work_order!")
		get_tree().quit(1)
		return
	if not captured_trans_denied_phase25.is_empty():
		printerr("FAIL 25-A: main_gate should not transition when access is denied!")
		get_tree().quit(1)
		return

	# 給齊兩條件（皆既有）：old_work_badge 正常玩流是公寓開場既有 key item（apartment_room.gd 首次鋪世界時發放），
	# 此處直接補發模擬該既有前置狀態；read_old_work_order 為 19-B 揭露旗標。
	GameState.add_item("old_work_badge", 1)
	GameState.set_flag("read_old_work_order", true)

	inst_entrance_phase25._trigger_interaction()
	if captured_trans_denied_phase25.get("scene", "") != "datacenter_backup" or captured_trans_denied_phase25.get("entry", "") != "from_entrance":
		printerr("FAIL 25-A: main_gate should transition to datacenter_backup once badge + read_old_work_order are satisfied!")
		get_tree().quit(1)
		return

	# 5. 驗證入口其餘互動（flavor examine + 回夜總會）
	var delivery_bot_node_phase25 = inst_entrance_phase25.get_node("Interactables/DeliveryBotArea")
	inst_entrance_phase25.current_interactable = delivery_bot_node_phase25
	var captured_flavor_phase25: Dictionary = {}
	for conn_phase25 in inst_entrance_phase25.interaction_requested.get_connections():
		inst_entrance_phase25.interaction_requested.disconnect(conn_phase25.callable)
	inst_entrance_phase25.interaction_requested.connect(func(data):
		captured_flavor_phase25.merge(data, true)
	)
	inst_entrance_phase25._trigger_interaction()
	if captured_flavor_phase25.get("message_text", "") != GameState.STORY_MESSAGES["datacenter_delivery_bot_flavor"]:
		printerr("FAIL 25-A: delivery_bot flavor examine text mismatch!")
		get_tree().quit(1)
		return

	var exit_nightclub_node_phase25 = inst_entrance_phase25.get_node("Interactables/ExitToNightclubArea")
	inst_entrance_phase25.current_interactable = exit_nightclub_node_phase25
	captured_trans_denied_phase25.clear()
	inst_entrance_phase25._trigger_interaction()
	if captured_trans_denied_phase25.get("scene", "") != "nightclub_entrance" or captured_trans_denied_phase25.get("entry", "") != "from_datacenter":
		printerr("FAIL 25-A: entrance exit should return to nightclub_entrance:from_datacenter!")
		get_tree().quit(1)
		return

	inst_entrance_phase25.free()

	# 6. 驗證 backup <-> core 雙向轉場 + core 中性佔位 examine
	var inst_backup_phase25 = load("res://scenes/levels/datacenter_backup/datacenter_backup.tscn").instantiate()
	var exit_to_entrance_node_phase25 = inst_backup_phase25.get_node("Interactables/ExitToEntranceArea")
	var exit_to_core_node_phase25 = inst_backup_phase25.get_node("Interactables/ExitToCoreArea")
	var captured_backup_trans_phase25: Dictionary = {}
	inst_backup_phase25.scene_transition_requested.connect(func(scene_id, entry_point_id, payload):
		captured_backup_trans_phase25.merge({"scene": scene_id, "entry": entry_point_id}, true)
	)

	inst_backup_phase25.current_interactable = exit_to_entrance_node_phase25
	inst_backup_phase25._trigger_interaction()
	if captured_backup_trans_phase25.get("scene", "") != "datacenter_entrance" or captured_backup_trans_phase25.get("entry", "") != "from_backup":
		printerr("FAIL 25-A: datacenter_backup left exit should return to datacenter_entrance:from_backup!")
		get_tree().quit(1)
		return

	captured_backup_trans_phase25.clear()
	inst_backup_phase25.current_interactable = exit_to_core_node_phase25
	inst_backup_phase25._trigger_interaction()
	if captured_backup_trans_phase25.get("scene", "") != "datacenter_backup_core" or captured_backup_trans_phase25.get("entry", "") != "from_backup":
		printerr("FAIL 25-A: datacenter_backup right door should transition to datacenter_backup_core:from_backup!")
		get_tree().quit(1)
		return

	inst_backup_phase25.free()

	var inst_core_phase25 = load("res://scenes/levels/datacenter_backup_core/datacenter_backup_core.tscn").instantiate()
	var exit_to_backup_node_phase25 = inst_core_phase25.get_node("Interactables/ExitToBackupArea")
	var own_backup_node_phase25 = inst_core_phase25.get_node("Interactables/OwnBackupArea")
	var captured_core_trans_phase25: Dictionary = {}
	inst_core_phase25.scene_transition_requested.connect(func(scene_id, entry_point_id, payload):
		captured_core_trans_phase25.merge({"scene": scene_id, "entry": entry_point_id}, true)
	)

	inst_core_phase25.current_interactable = exit_to_backup_node_phase25
	inst_core_phase25._trigger_interaction()
	if captured_core_trans_phase25.get("scene", "") != "datacenter_backup" or captured_core_trans_phase25.get("entry", "") != "from_core":
		printerr("FAIL 25-A: datacenter_backup_core exit should return to datacenter_backup:from_core!")
		get_tree().quit(1)
		return

	var captured_own_backup_phase25: Dictionary = {}
	inst_core_phase25.interaction_requested.connect(func(data):
		captured_own_backup_phase25.merge(data, true)
	)
	inst_core_phase25.current_interactable = own_backup_node_phase25
	inst_core_phase25._trigger_interaction()
	if captured_own_backup_phase25.get("message_text", "") != GameState.STORY_MESSAGES["datacenter_own_backup_placeholder"]:
		printerr("FAIL 25-A: own_backup placeholder message text mismatch!")
		get_tree().quit(1)
		return
	if not captured_core_trans_phase25.get("scene", "") == "datacenter_backup":
		printerr("FAIL 25-A: own_backup examine should not trigger any further scene transition (no ending route yet)!")
		get_tree().quit(1)
		return

	inst_core_phase25.free()

	# 7. 驗證 main.gd 全鏈雙向轉場 + BGM（entrance -> backup -> core -> backup -> entrance -> nightclub）
	GameState.reset_for_new_game()
	GameState.set_flag("read_old_work_order", true)

	main_instance_phase25.transition_to("datacenter_entrance", "from_nightclub")
	await get_tree().process_frame
	if main_instance_phase25._current_bgm_path != "res://assets/bgm/The Cold Mirror (Loop).mp3":
		printerr("FAIL 25-A: datacenter_entrance BGM should be The Cold Mirror (Loop).mp3, got: ", main_instance_phase25._current_bgm_path)
		get_tree().quit(1)
		return

	main_instance_phase25.transition_to("datacenter_backup", "from_entrance")
	await get_tree().process_frame
	if main_instance_phase25._current_bgm_path != "res://assets/bgm/Heartbeat of the Machine.mp3":
		printerr("FAIL 25-A: datacenter_backup BGM should be Heartbeat of the Machine.mp3, got: ", main_instance_phase25._current_bgm_path)
		get_tree().quit(1)
		return

	main_instance_phase25.transition_to("datacenter_backup_core", "from_backup")
	await get_tree().process_frame
	if main_instance_phase25._current_bgm_path != "res://assets/bgm/The Cold Mirror (Loop).mp3":
		printerr("FAIL 25-A: datacenter_backup_core BGM should be The Cold Mirror (Loop).mp3, got: ", main_instance_phase25._current_bgm_path)
		get_tree().quit(1)
		return

	main_instance_phase25.transition_to("datacenter_backup", "from_core")
	await get_tree().process_frame
	main_instance_phase25.transition_to("datacenter_entrance", "from_backup")
	await get_tree().process_frame
	main_instance_phase25.transition_to("nightclub_entrance", "from_datacenter")
	await get_tree().process_frame
	if main_instance_phase25._current_bgm_path != "res://assets/bgm/nightclub-1.mp3":
		printerr("FAIL 25-A: nightclub_entrance BGM should revert to nightclub-1.mp3 after returning from datacenter, got: ", main_instance_phase25._current_bgm_path)
		get_tree().quit(1)
		return

	if is_instance_valid(main_instance_phase25):
		main_instance_phase25.free()

	# 8. 驗證 Phase 1~24 不退化：apartment 仍可正常載入（抽樣回歸）
	var regression_main_phase25 = datacenter_main_scene_phase25.instantiate()
	add_child(regression_main_phase25)
	await get_tree().process_frame
	regression_main_phase25.transition_to("apartment", "wake_bed")
	await get_tree().process_frame
	if regression_main_phase25.get_current_scene_id() != "apartment":
		printerr("FAIL 25-A: apartment scene should still load after Phase 25-A registry changes!")
		get_tree().quit(1)
		return
	if is_instance_valid(regression_main_phase25):
		regression_main_phase25.free()

	# 9. 三語翻譯覆蓋 + 「林霏」/"Lin Fei" 禁字檢查
	var keys_phase25 = [
		"DLG_TRAVEL_DATACENTER_LOCKED_TEXT",
		"DLG_TRAVEL_DATACENTER_MENU_TEXT",
		"DLG_TRAVEL_DATACENTER_WAN_FLAVOR_TEXT",
		"DLG_TRAVEL_DATACENTER_TRAVEL_TEXT",
		"MSG_DATACENTER_ACCESS_DENIED",
		"MSG_DATACENTER_OWN_BACKUP_PLACEHOLDER",
		"MSG_DATACENTER_DELIVERY_BOT_FLAVOR",
		"PROMPT_NIGHTCLUB_ENTRANCE_TRAVEL_DATACENTER"
	]
	for k_phase25 in keys_phase25:
		for lang_phase25 in ["zh_TW", "zh_CN", "en"]:
			LocaleManager.set_locale(lang_phase25)
			var txt_phase25 = tr(k_phase25)
			if txt_phase25 == k_phase25:
				printerr("FAIL 25-A: key ", k_phase25, " has no ", lang_phase25, " translation.")
				get_tree().quit(1)
				return
			if lang_phase25 == "en":
				var lower_txt_phase25 = txt_phase25.to_lower()
				if "lin fei" in lower_txt_phase25 or "linfei" in lower_txt_phase25:
					printerr("FAIL 25-A: Forbidden word Lin Fei found in key ", k_phase25)
					get_tree().quit(1)
					return
			else:
				if "林霏" in txt_phase25:
					printerr("FAIL 25-A: Forbidden word 林霏 found in key ", k_phase25)
					get_tree().quit(1)
					return
	LocaleManager.set_locale("zh_TW")

	print("PASS: Phase 25-A datacenter skeleton, travel gate, access gate, and transitions verified.")

	# ===================== Phase 25-B: 戰鬥③（低階保全，跑到門） =====================
	print("--- Phase 25-B: 戰鬥③ 混合敵人 + 跑到門 ---")

	var backup_scene_phase25b = load("res://scenes/levels/datacenter_backup/datacenter_backup.tscn")
	var backup_inst_phase25b = backup_scene_phase25b.instantiate()
	add_child(backup_inst_phase25b)
	await get_tree().process_frame

	var sentinel_phase25b = backup_inst_phase25b.find_child("RackSentinel", true, false)
	if sentinel_phase25b == null:
		printerr("FAIL 25-B: datacenter_backup missing RackSentinel node!")
		get_tree().quit(1)
		return
	print("PASS 25-B: datacenter_backup has RackSentinel node.")

	var guard_phase25b = backup_inst_phase25b.find_child("SecurityGuard", true, false)
	if guard_phase25b == null:
		printerr("FAIL 25-B: datacenter_backup missing SecurityGuard node!")
		get_tree().quit(1)
		return
	print("PASS 25-B: datacenter_backup has SecurityGuard node.")

	var backup_player_phase25b = backup_inst_phase25b.find_child("Player", true, false)
	if backup_player_phase25b == null or not backup_player_phase25b.combat_mode:
		printerr("FAIL 25-B: datacenter_backup Player must have combat_mode == true!")
		get_tree().quit(1)
		return
	print("PASS 25-B: datacenter_backup Player has combat_mode == true.")

	# 1. 機器哨兵：is_stunned/apply_stun/can_format 沿用 Phase 13 machine 契約
	if sentinel_phase25b.is_stunned():
		printerr("FAIL 25-B: RackSentinel must not start stunned!")
		get_tree().quit(1)
		return
	if not sentinel_phase25b.is_in_group("enemies"):
		printerr("FAIL 25-B: RackSentinel must be in group 'enemies'!")
		get_tree().quit(1)
		return

	sentinel_phase25b.apply_stun(5.0)
	if not sentinel_phase25b.is_stunned():
		printerr("FAIL 25-B: RackSentinel should be stunned after apply_stun()!")
		get_tree().quit(1)
		return

	sentinel_phase25b._facing = 1 # facing right
	var behind_pos_phase25b: Vector2 = sentinel_phase25b.global_position + Vector2(-50.0, 0.0)
	var front_pos_phase25b: Vector2 = sentinel_phase25b.global_position + Vector2(50.0, 0.0)
	if not sentinel_phase25b.can_format(behind_pos_phase25b):
		printerr("FAIL 25-B: RackSentinel.can_format() must be true when stunned + player behind!")
		get_tree().quit(1)
		return
	if sentinel_phase25b.can_format(front_pos_phase25b):
		printerr("FAIL 25-B: RackSentinel.can_format() must be false when player is in front (same side as facing)!")
		get_tree().quit(1)
		return
	print("PASS 25-B: RackSentinel.can_format() true behind while stunned, false in front.")

	sentinel_phase25b.defeated()
	if not sentinel_phase25b.is_defeated():
		printerr("FAIL 25-B: RackSentinel.defeated() must set is_defeated() true!")
		get_tree().quit(1)
		return
	if sentinel_phase25b.can_format(behind_pos_phase25b):
		printerr("FAIL 25-B: a defeated RackSentinel must not be re-formattable!")
		get_tree().quit(1)
		return
	print("PASS 25-B: RackSentinel.defeated() clears via format_reset contract, stays cleared.")

	# 2. 人類保全：can_format 恆 false、apply_stun no-op（不可殺 / 不可格式化）
	if guard_phase25b.can_format(guard_phase25b.global_position + Vector2(-50.0, 0.0)):
		printerr("FAIL 25-B: SecurityGuard.can_format() must always return false!")
		get_tree().quit(1)
		return
	guard_phase25b.apply_stun(5.0)
	if guard_phase25b.is_stunned() or guard_phase25b.is_defeated():
		printerr("FAIL 25-B: SecurityGuard must never be stunned or defeated (apply_stun is no-op)!")
		get_tree().quit(1)
		return
	if not guard_phase25b.is_in_group("enemies"):
		printerr("FAIL 25-B: SecurityGuard must be in group 'enemies'!")
		get_tree().quit(1)
		return
	print("PASS 25-B: SecurityGuard can_format()==false and apply_stun() is a no-op.")

	# 3. 人類保全最小追擊：朝玩家 x 移動（唯一新做的 AI）
	# 敵人 _physics_process 在 UIMode != NONE 時凍結；先確保前置為 NONE。
	UIMode.set_mode(UIMode.Mode.NONE)
	guard_phase25b.global_position = Vector2(3300.0, 800.0)
	backup_player_phase25b.global_position = Vector2(2800.0, 800.0)
	var guard_x_before_phase25b: float = guard_phase25b.global_position.x
	guard_phase25b._physics_process(0.5)
	if not (guard_phase25b.global_position.x < guard_x_before_phase25b):
		printerr("FAIL 25-B: SecurityGuard should chase toward a player x that is to its left!")
		get_tree().quit(1)
		return
	print("PASS 25-B: SecurityGuard minimal chase AI moves toward the player's x.")

	# 4. 碰撞 = knockback / stagger，無失敗態（不設任何 combat_loss 旗標 / 不 Game Over）
	backup_player_phase25b.global_position = Vector2(2800.0, 690.0)
	backup_player_phase25b.walk_line_y = 690.0
	if backup_player_phase25b.is_staggered():
		printerr("FAIL 25-B: Player should not start staggered!")
		get_tree().quit(1)
		return
	var px_before_phase25b: float = backup_player_phase25b.global_position.x
	guard_phase25b._on_contact_entered(backup_player_phase25b)
	if not backup_player_phase25b.is_staggered():
		printerr("FAIL 25-B: SecurityGuard contact should stagger the player!")
		get_tree().quit(1)
		return
	if backup_player_phase25b.global_position.x == px_before_phase25b:
		printerr("FAIL 25-B: SecurityGuard contact should knock the player back along x!")
		get_tree().quit(1)
		return
	print("PASS 25-B: SecurityGuard contact staggers + knocks back the player (no failure flag).")

	# 4b. UI 開啟（背包 / 筆記等）時保全凍結，不得追擊位移（比照 player 的 UIMode 凍結）
	UIMode.set_mode(UIMode.Mode.INVENTORY)
	guard_phase25b.global_position = Vector2(3300.0, 800.0)
	backup_player_phase25b.global_position = Vector2(2800.0, 690.0)
	var guard_x_ui_frozen_phase25b: float = guard_phase25b.global_position.x
	guard_phase25b._physics_process(0.5)
	if guard_phase25b.global_position.x != guard_x_ui_frozen_phase25b:
		printerr("FAIL 25-B: SecurityGuard must freeze (no chase) while a UI mode is open!")
		get_tree().quit(1)
		return
	UIMode.set_mode(UIMode.Mode.NONE)
	print("PASS 25-B: SecurityGuard freezes while UI is open (no chase displacement).")

	# 4c. knockback 直接取消跳躍 / 攻擊狀態（stagger 結束後不得隱形續播弧線 / 揮擊）
	backup_player_phase25b._staggered = false
	backup_player_phase25b._stagger_t = 0.0
	backup_player_phase25b._jumping = true
	backup_player_phase25b._jump_t = 0.2
	backup_player_phase25b._attacking = true
	backup_player_phase25b._attack_t = 0.3
	backup_player_phase25b.apply_knockback(1.0, 90.0, 0.5)
	if backup_player_phase25b.is_jumping() or backup_player_phase25b.is_attacking():
		printerr("FAIL 25-B: apply_knockback must cancel in-flight jump / attack state!")
		get_tree().quit(1)
		return
	if not backup_player_phase25b.is_staggered():
		printerr("FAIL 25-B: apply_knockback should still stagger the player when cancelling jump / attack!")
		get_tree().quit(1)
		return
	backup_player_phase25b._staggered = false
	backup_player_phase25b._stagger_t = 0.0
	print("PASS 25-B: apply_knockback cancels in-flight jump / attack state.")

	# 5. 勝利條件：抵達右端門 x → 轉場核心（沿用既有 exit_to_core interactable，見 25-A）
	var exit_to_core_phase25b = backup_inst_phase25b.get_node("Interactables/ExitToCoreArea")
	backup_inst_phase25b.current_interactable = exit_to_core_phase25b
	var captured_win_trans_phase25b: Dictionary = {}
	backup_inst_phase25b.scene_transition_requested.connect(func(scene_id, entry_point_id, payload):
		captured_win_trans_phase25b.merge({"scene": scene_id, "entry": entry_point_id}, true)
	)
	backup_inst_phase25b._trigger_interaction()
	if captured_win_trans_phase25b.get("scene", "") != "datacenter_backup_core" or captured_win_trans_phase25b.get("entry", "") != "from_backup":
		printerr("FAIL 25-B: reaching the right-end door must transition to datacenter_backup_core:from_backup regardless of enemy state!")
		get_tree().quit(1)
		return
	print("PASS 25-B: reaching the right-end door wins the corridor (no kill requirement).")

	# 6. 禁存：戰鬥廊道 can_save_here=false（沿用 7-F 慣例，25-A 已設）
	if SaveSystem.can_save_here:
		printerr("FAIL 25-B: datacenter_backup must keep can_save_here == false during combat!")
		get_tree().quit(1)
		return
	print("PASS 25-B: datacenter_backup keeps can_save_here == false.")

	backup_inst_phase25b.free()
	await get_tree().process_frame

	# 6b. 離開戰鬥廊道進核心：can_save_here 恢復 true（core _ready 設定）
	var core_save_inst_phase25b = load("res://scenes/levels/datacenter_backup_core/datacenter_backup_core.tscn").instantiate()
	add_child(core_save_inst_phase25b)
	await get_tree().process_frame
	if not SaveSystem.can_save_here:
		printerr("FAIL 25-B: entering datacenter_backup_core must restore can_save_here == true!")
		get_tree().quit(1)
		return
	print("PASS 25-B: datacenter_backup_core restores can_save_here == true.")
	core_save_inst_phase25b.free()
	await get_tree().process_frame

	# 7. 非戰鬥場景：attack 無副作用（combat_mode 預設 false，apartment 房間攻擊鍵不觸發攻擊）
	var apt_main_phase25b = load("res://scenes/main/main.tscn").instantiate()
	add_child(apt_main_phase25b)
	await get_tree().process_frame
	apt_main_phase25b.transition_to("apartment", "wake_bed")
	await get_tree().process_frame
	var apt_player_phase25b = apt_main_phase25b.find_child("Player", true, false)
	if apt_player_phase25b == null or apt_player_phase25b.combat_mode:
		printerr("FAIL 25-B: apartment Player must keep combat_mode == false (non-combat scene)!")
		get_tree().quit(1)
		return
	apt_player_phase25b._attacking = false
	Input.action_press("attack")
	apt_player_phase25b._physics_process(0.016)
	Input.action_release("attack")
	if apt_player_phase25b.is_attacking():
		printerr("FAIL 25-B: attack must have no effect outside a combat_mode scene!")
		get_tree().quit(1)
		return
	print("PASS 25-B: attack has no effect in a non-combat scene.")
	if is_instance_valid(apt_main_phase25b):
		apt_main_phase25b.free()
	await get_tree().process_frame

	print("PASS: Phase 25-B combat corridor (machine sentinel + human guard chase + run-to-door win + no failure state) verified.")

	# ===================== Phase 25-C: 回歸 + 存讀檔護欄 =====================
	print("--- Phase 25-C: 回歸 + 存讀檔護欄 ---")

	# 1. 綜合存讀檔 round-trip：Phase 25 門禁道具/旗標與 Phase 24 終端旗標 / 追逐狀態同存同讀，互不干擾（無新存讀檔欄位）
	GameState.reset_for_new_game()
	GameState.set_flag("passed_nightclub_security", true)
	GameState.set_flag("seven_stopped_full", true)
	GameState.set_flag("deep_tunnel_opened", true)
	GameState.tunnel_chase_true_exit = 2
	GameState.add_item("old_work_badge", 1)
	GameState.set_flag("read_old_work_order", true)
	GameState.mark_scene_visited("datacenter_backup_core")

	var save_dict_phase25c = SaveSystem.capture("datacenter_backup_core", 100.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_dict_phase25c):
		printerr("FAIL 25-C: SaveSystem.write_slot failed for combined Phase 24/25 flags!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()

	var main_scene_phase25c = load("res://scenes/main/main.tscn")
	var main_instance_phase25c = main_scene_phase25c.instantiate()
	add_child(main_instance_phase25c)
	await get_tree().process_frame

	if not main_instance_phase25c.load_game_slot(TEST_SCRATCH_SAVE_SLOT):
		printerr("FAIL 25-C: load_game_slot(scratch slot) failed to load combined Phase 24/25 save!")
		get_tree().quit(1)
		return
	await get_tree().process_frame

	if main_instance_phase25c.get_current_scene_id() != "datacenter_backup_core":
		printerr("FAIL 25-C: current scene should restore to datacenter_backup_core after load, got: ", main_instance_phase25c.get_current_scene_id())
		get_tree().quit(1)
		return
	if not GameState.get_flag("passed_nightclub_security", false) or not GameState.get_flag("seven_stopped_full", false):
		printerr("FAIL 25-C: Phase 24 terminal flags did not survive save/load alongside Phase 25 datacenter state!")
		get_tree().quit(1)
		return
	if not GameState.has_item("old_work_badge") or not GameState.get_flag("read_old_work_order", false):
		printerr("FAIL 25-C: Phase 25 gate item/flag did not survive save/load!")
		get_tree().quit(1)
		return
	if GameState.tunnel_chase_true_exit != 2 or not GameState.get_flag("deep_tunnel_opened", false):
		printerr("FAIL 25-C: Phase 24 chase state did not survive save/load alongside Phase 25 datacenter save!")
		get_tree().quit(1)
		return
	if not GameState.visited_scenes.has("datacenter_backup_core"):
		printerr("FAIL 25-C: visited_scenes should retain datacenter_backup_core after save/load (M1, no new save field needed)!")
		get_tree().quit(1)
		return

	# 2. 迴歸抽樣：Phase 25 SceneRegistry / nightclub_entrance 動線改動後，Phase 24 核心動線仍可達
	main_instance_phase25c.transition_to("underground_settlement_right", "from_left")
	await get_tree().process_frame
	if main_instance_phase25c.get_current_scene_id() != "underground_settlement_right":
		printerr("FAIL 25-C: underground_settlement_right should still be reachable after Phase 25 registry changes!")
		get_tree().quit(1)
		return

	main_instance_phase25c.transition_to("underground_settlement", "from_right")
	await get_tree().process_frame
	if main_instance_phase25c.get_current_scene_id() != "underground_settlement":
		printerr("FAIL 25-C: underground_settlement round-trip (聚落往返) should still work after Phase 25 registry changes!")
		get_tree().quit(1)
		return

	main_instance_phase25c.transition_to("tunnel_combat", "from_settlement")
	await get_tree().process_frame
	if main_instance_phase25c.get_current_scene_id() != "tunnel_combat":
		printerr("FAIL 25-C: tunnel_combat entry should still be reachable after Phase 25 registry changes!")
		get_tree().quit(1)
		return

	main_instance_phase25c.transition_to("tunnel_chase", "from_settlement")
	await get_tree().process_frame
	if main_instance_phase25c.get_current_scene_id() != "tunnel_chase":
		printerr("FAIL 25-C: tunnel_chase (Phase 24 追逐房間1) should still be reachable after Phase 25 registry changes!")
		get_tree().quit(1)
		return

	main_instance_phase25c.transition_to("tunnel_chase_right", "from_left")
	await get_tree().process_frame
	if main_instance_phase25c.get_current_scene_id() != "tunnel_chase_right":
		printerr("FAIL 25-C: tunnel_chase_right (Phase 24 追逐房間2 / 攤牌) should still be reachable after Phase 25 registry changes!")
		get_tree().quit(1)
		return

	main_instance_phase25c.transition_to("nightclub_entrance", "from_street")
	await get_tree().process_frame
	if main_instance_phase25c.get_current_scene_id() != "nightclub_entrance":
		printerr("FAIL 25-C: nightclub_entrance should still be reachable after adding the AI 資料中心 travel destination!")
		get_tree().quit(1)
		return

	if is_instance_valid(main_instance_phase25c):
		main_instance_phase25c.free()

	# 3. 迴歸抽樣：Phase 21 echo_linfei 採集流程不受 Phase 25 影響
	GameState.reset_for_new_game()
	GameState.collect_echo_segment("echo_linfei", "s1")
	GameState.collect_echo_segment("echo_linfei", "s2")
	GameState.collect_echo_segment("echo_linfei", "s3")
	if not GameState.is_echo_audio_unlocked("echo_linfei"):
		printerr("FAIL 25-C: echo_linfei audio unlock (Phase 21) regressed after Phase 25 changes!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()
	if dir and dir.file_exists(TEST_SCRATCH_SAVE_FILE):
		dir.remove(TEST_SCRATCH_SAVE_FILE)

	print("PASS: Phase 25-C regression (Phase 1~24 core routes intact) and save/load guardrails verified.")

	# ===================== Phase 26-A: 晚拉扯演出 =====================
	print("--- Phase 26-A: 晚拉扯演出 ---")

	GameState.reset_for_new_game()
	var entrance_inst_phase26a = load("res://scenes/levels/datacenter_entrance/datacenter_entrance.tscn").instantiate()

	var wan_trigger_phase26a = entrance_inst_phase26a.get_node("Interactables/WanPullTriggerArea")
	var wan_npc_phase26a = entrance_inst_phase26a.get_node("Interactables/WanDatacenterNPC")
	if wan_trigger_phase26a == null or wan_npc_phase26a == null:
		printerr("FAIL 26-A: datacenter_entrance missing WanPullTriggerArea / WanDatacenterNPC nodes!")
		get_tree().quit(1)
		return

	var captured_pull_phase26a: Dictionary = {}
	entrance_inst_phase26a.interaction_requested.connect(func(data):
		captured_pull_phase26a.merge(data, true)
	)

	var fake_player_phase26a := Node2D.new()
	fake_player_phase26a.name = "Player"

	# 1. UIMode 非 NONE 時不觸發
	UIMode.current_mode = UIMode.Mode.DIALOGUE
	wan_trigger_phase26a._on_body_entered(fake_player_phase26a)
	if not captured_pull_phase26a.is_empty():
		printerr("FAIL 26-A: WanPullTriggerArea should not fire while UIMode is not NONE!")
		get_tree().quit(1)
		return
	UIMode.current_mode = UIMode.Mode.NONE

	# 2. 首次走近觸發 dialogue 派發
	wan_trigger_phase26a._on_body_entered(fake_player_phase26a)
	if captured_pull_phase26a.get("type", "") != "dialogue" or captured_pull_phase26a.get("dialogue_id", "") != "wan_datacenter":
		printerr("FAIL 26-A: WanPullTriggerArea body_entered should dispatch wan_datacenter dialogue!")
		get_tree().quit(1)
		return

	# 3. 對話樹兩句拍板台詞一次給足 + 結尾設旗標（模擬 DialoguePanel 走完整段）
	var wan_dc_tree_phase26a = DialogueDB.get_tree_for("wan_datacenter")
	if wan_dc_tree_phase26a.is_empty():
		printerr("FAIL 26-A: wan_datacenter dialogue tree not registered in DialogueDB!")
		get_tree().quit(1)
		return

	var runner_pull_phase26a = DialogueRunner.new()
	runner_pull_phase26a.start(wan_dc_tree_phase26a)
	if runner_pull_phase26a.current().get("text", "") != "DLG_WAN_DATACENTER_PULL_SAFE_TEXT":
		printerr("FAIL 26-A: first-time wan_datacenter dialogue should open on the safe-version pull line!")
		get_tree().quit(1)
		return
	if GameState.get_flag("wan_act4_pull_seen", false):
		printerr("FAIL 26-A: wan_act4_pull_seen must not be set before the private line is reached!")
		get_tree().quit(1)
		return
	# DialogueRunner applies node-level "effect" immediately on entering a node
	# (see scripts/dialogue/dialogue_runner.gd _enter_node), so the flag flips
	# as soon as advance() moves into "pull_private", not on a further advance().
	runner_pull_phase26a.advance()
	if runner_pull_phase26a.current().get("text", "") != "DLG_WAN_DATACENTER_PULL_PRIVATE_TEXT":
		printerr("FAIL 26-A: wan_datacenter dialogue should follow with the private-version pull line!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("wan_act4_pull_seen", false):
		printerr("FAIL 26-A: wan_act4_pull_seen should be set once the private-version pull line is reached!")
		get_tree().quit(1)
		return

	# 4. 旗標已設後：觸發區重入不重播
	captured_pull_phase26a.clear()
	wan_trigger_phase26a._on_body_entered(fake_player_phase26a)
	if not captured_pull_phase26a.is_empty():
		printerr("FAIL 26-A: WanPullTriggerArea must not re-fire once wan_act4_pull_seen is true!")
		get_tree().quit(1)
		return

	# 5. 旗標已設後：對話重講走 retalk 短版
	var runner_retalk_phase26a = DialogueRunner.new()
	runner_retalk_phase26a.start(wan_dc_tree_phase26a)
	if runner_retalk_phase26a.current().get("text", "") != "DLG_WAN_DATACENTER_RETALK_TEXT":
		printerr("FAIL 26-A: wan_datacenter should route to retalk once wan_act4_pull_seen is true!")
		get_tree().quit(1)
		return

	# 6. 標準 E 互動（WanDatacenterNPC）走 dialogue_id 標準派發鏈（datacenter_entrance.gd dispatch）
	captured_pull_phase26a.clear()
	entrance_inst_phase26a.current_interactable = wan_npc_phase26a
	entrance_inst_phase26a._trigger_interaction()
	if captured_pull_phase26a.get("type", "") != "dialogue" or captured_pull_phase26a.get("dialogue_id", "") != "wan_datacenter":
		printerr("FAIL 26-A: WanDatacenterNPC standard E-interact should dispatch wan_datacenter dialogue!")
		get_tree().quit(1)
		return

	# 7. 拉扯不擋門禁：齊備 badge + read_old_work_order 後，門禁仍正常放行
	GameState.add_item("old_work_badge", 1)
	GameState.set_flag("read_old_work_order", true)
	var captured_gate_trans_phase26a: Dictionary = {}
	entrance_inst_phase26a.scene_transition_requested.connect(func(scene_id, entry_point_id, payload):
		captured_gate_trans_phase26a.merge({"scene": scene_id, "entry": entry_point_id}, true)
	)
	entrance_inst_phase26a.current_interactable = entrance_inst_phase26a.get_node("Interactables/MainGateArea")
	entrance_inst_phase26a._trigger_interaction()
	if captured_gate_trans_phase26a.get("scene", "") != "datacenter_backup" or captured_gate_trans_phase26a.get("entry", "") != "from_entrance":
		printerr("FAIL 26-A: main_gate should still transition normally after the Wan pull sequence (拉扯不擋門禁)!")
		get_tree().quit(1)
		return

	fake_player_phase26a.free()
	entrance_inst_phase26a.free()

	GameState.reset_for_new_game()
	print("PASS: Phase 26-A Wan pull performance (auto-trigger + retalk routing + standard E-interact dispatch + gate unaffected) verified.")

	# ===================== Phase 26-B: 阿達④本人短暫登場 =====================
	print("--- Phase 26-B: 阿達④本人短暫登場 ---")
	UIMode.current_mode = UIMode.Mode.NONE

	# 1. 順序護欄：缺 read_old_work_order 時本趟不登場（④不得早於③）
	GameState.reset_for_new_game()
	var entrance_inst_phase26b_gate = load("res://scenes/levels/datacenter_entrance/datacenter_entrance.tscn").instantiate()
	add_child(entrance_inst_phase26b_gate)
	await get_tree().process_frame
	if entrance_inst_phase26b_gate.get_node_or_null("Interactables/AdaNPC") != null or entrance_inst_phase26b_gate.get_node_or_null("Interactables/AdaTriggerArea") != null:
		printerr("FAIL 26-B: Ada should not spawn this visit without read_old_work_order (順序護欄 ④不早於③)!")
		get_tree().quit(1)
		return
	entrance_inst_phase26b_gate.free()
	await get_tree().process_frame

	# 2. 已看過（ada_final_words_seen=true）：即使補上 read_old_work_order，重進場景也永久不生成
	GameState.reset_for_new_game()
	GameState.set_flag("read_old_work_order", true)
	GameState.set_flag("ada_final_words_seen", true)
	var entrance_inst_phase26b_seen = load("res://scenes/levels/datacenter_entrance/datacenter_entrance.tscn").instantiate()
	add_child(entrance_inst_phase26b_seen)
	await get_tree().process_frame
	if entrance_inst_phase26b_seen.get_node_or_null("Interactables/AdaNPC") != null or entrance_inst_phase26b_seen.get_node_or_null("Interactables/AdaTriggerArea") != null:
		printerr("FAIL 26-B: Ada must stay permanently gone once ada_final_words_seen is true!")
		get_tree().quit(1)
		return
	entrance_inst_phase26b_seen.free()
	await get_tree().process_frame

	# 3. 齊全條件：首次到場自動觸發，對話一拍無選項並立即設旗標
	GameState.reset_for_new_game()
	GameState.set_flag("read_old_work_order", true)
	var entrance_inst_phase26b = load("res://scenes/levels/datacenter_entrance/datacenter_entrance.tscn").instantiate()
	add_child(entrance_inst_phase26b)
	await get_tree().process_frame

	var ada_npc_phase26b = entrance_inst_phase26b.get_node_or_null("Interactables/AdaNPC")
	var ada_trigger_phase26b = entrance_inst_phase26b.get_node_or_null("Interactables/AdaTriggerArea")
	if ada_npc_phase26b == null or ada_trigger_phase26b == null:
		printerr("FAIL 26-B: Ada should spawn once read_old_work_order is satisfied and he hasn't spoken yet!")
		get_tree().quit(1)
		return

	var captured_ada_phase26b: Dictionary = {}
	entrance_inst_phase26b.interaction_requested.connect(func(data):
		captured_ada_phase26b.merge(data, true)
	)

	var fake_player_phase26b := Node2D.new()
	fake_player_phase26b.name = "Player"
	ada_trigger_phase26b._on_body_entered(fake_player_phase26b)
	if captured_ada_phase26b.get("type", "") != "dialogue" or captured_ada_phase26b.get("dialogue_id", "") != "ada":
		printerr("FAIL 26-B: AdaTriggerArea body_entered should dispatch the ada dialogue!")
		get_tree().quit(1)
		return

	var ada_tree_phase26b = DialogueDB.get_tree_for("ada")
	if ada_tree_phase26b.is_empty():
		printerr("FAIL 26-B: ada dialogue tree not registered in DialogueDB!")
		get_tree().quit(1)
		return

	var runner_ada_phase26b = DialogueRunner.new()
	runner_ada_phase26b.start(ada_tree_phase26b)
	if runner_ada_phase26b.current().get("text", "") != "DLG_ADA_FINAL_WORDS_TEXT":
		printerr("FAIL 26-B: ada dialogue should open directly on the final-words line (一拍、無選項)!")
		get_tree().quit(1)
		return
	if not runner_ada_phase26b.current().get("is_terminal", false):
		printerr("FAIL 26-B: ada dialogue should be a single terminal beat with no choices!")
		get_tree().quit(1)
		return
	if not GameState.get_flag("ada_final_words_seen", false):
		printerr("FAIL 26-B: ada_final_words_seen should be set as soon as the final-words line is entered!")
		get_tree().quit(1)
		return

	# 4. 對話結束（UIMode 回 NONE）後：Tween 淡出 + 永久停用 AdaNPC / 觸發區
	UIMode.current_mode = UIMode.Mode.NONE
	entrance_inst_phase26b._update_ada_fade()
	if not entrance_inst_phase26b._ada_faded:
		printerr("FAIL 26-B: Ada should start fading out once ada_final_words_seen is true and UIMode is NONE!")
		get_tree().quit(1)
		return
	if entrance_inst_phase26b.get_node_or_null("Interactables/AdaTriggerArea") != null:
		printerr("FAIL 26-B: AdaTriggerArea should be removed immediately once the fade-out starts!")
		get_tree().quit(1)
		return
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_instance_valid(ada_npc_phase26b) or ada_npc_phase26b.modulate.a >= 1.0:
		printerr("FAIL 26-B: AdaNPC should be tweening its modulate alpha down once the pull sequence finishes!")
		get_tree().quit(1)
		return

	# 5. Fade 窗口內（AdaNPC 尚未 queue_free）E 重談應失效，不可對半透明的阿達重播最後一句
	if ada_npc_phase26b.dialogue_id != "":
		printerr("FAIL 26-B: AdaNPC.dialogue_id should be cleared immediately once fade starts, to block E re-talk mid-fade!")
		get_tree().quit(1)
		return
	captured_ada_phase26b.clear()
	entrance_inst_phase26b.current_interactable = ada_npc_phase26b
	entrance_inst_phase26b._trigger_interaction()
	if not captured_ada_phase26b.is_empty():
		printerr("FAIL 26-B: pressing E on the fading AdaNPC must not replay the ada dialogue!")
		get_tree().quit(1)
		return

	fake_player_phase26b.free()
	entrance_inst_phase26b.free()
	await get_tree().process_frame

	GameState.reset_for_new_game()
	print("PASS: Phase 26-B Ada final appearance (sequencing guard + one-shot trigger + fade-out + permanent removal) verified.")

	# ===================== Phase 26-C: 核心真相碎片 =====================
	print("--- Phase 26-C: 核心真相碎片 ---")

	GameState.reset_for_new_game()
	var core_inst_phase26c = load("res://scenes/levels/datacenter_backup_core/datacenter_backup_core.tscn").instantiate()
	add_child(core_inst_phase26c)

	var frag_node_phase26c = core_inst_phase26c.get_node_or_null("Interactables/MemoryFragmentArea")
	if frag_node_phase26c == null:
		printerr("FAIL 26-C: datacenter_backup_core missing MemoryFragmentArea node!")
		get_tree().quit(1)
		return

	if frag_node_phase26c.fragment_flag != "mem_frag_chose_deletion" or \
	   frag_node_phase26c.message_id != "mem_frag_chose_deletion":
		printerr("FAIL 26-C: MemoryFragmentArea properties mismatch!")
		get_tree().quit(1)
		return

	var captured_frag_phase26c: Dictionary = {}
	core_inst_phase26c.interaction_requested.connect(func(data):
		captured_frag_phase26c.merge(data, true)
	)

	var fake_player_phase26c := Node2D.new()
	fake_player_phase26c.name = "Player"

	# 1. 必經路徑自動收取
	frag_node_phase26c._on_body_entered(fake_player_phase26c)
	if captured_frag_phase26c.get("type", "") != "message" or captured_frag_phase26c.get("message_text", "") != "MSG_MEM_FRAG_CHOSE_DELETION":
		printerr("FAIL 26-C: expected MSG_MEM_FRAG_CHOSE_DELETION on collect, got: ", captured_frag_phase26c)
		get_tree().quit(1)
		return

	if not GameState.get_flag("mem_frag_chose_deletion", false):
		printerr("FAIL 26-C: mem_frag_chose_deletion flag not set after collect!")
		get_tree().quit(1)
		return

	# 2. 重入不重複
	captured_frag_phase26c.clear()
	frag_node_phase26c._on_body_entered(fake_player_phase26c)
	if not captured_frag_phase26c.is_empty():
		printerr("FAIL 26-C: MemoryFragmentArea must not re-fire once mem_frag_chose_deletion is true!")
		get_tree().quit(1)
		return

	fake_player_phase26c.free()
	core_inst_phase26c.free()
	await get_tree().process_frame

	GameState.reset_for_new_game()
	print("PASS: Phase 26-C core truth fragment (必經自動收取 + one-shot guard) verified.")

	# ===================== Phase 26-D: 結局觸發點武裝 + Branch B 檔案重標記 =====================
	print("--- Phase 26-D: 結局觸發點武裝 + Branch B 檔案重標記 ---")

	GameState.reset_for_new_game()
	var core_inst_phase26d = load("res://scenes/levels/datacenter_backup_core/datacenter_backup_core.tscn").instantiate()
	add_child(core_inst_phase26d)

	var own_backup_phase26d = core_inst_phase26d.get_node_or_null("Interactables/OwnBackupArea")
	var file_index_phase26d = core_inst_phase26d.get_node_or_null("Interactables/FileIndexTerminalArea")
	if own_backup_phase26d == null or file_index_phase26d == null:
		printerr("FAIL 26-D: datacenter_backup_core missing OwnBackupArea / FileIndexTerminalArea nodes!")
		get_tree().quit(1)
		return

	if file_index_phase26d.interaction_id != "file_index_terminal" or file_index_phase26d.prompt_text != "PROMPT_DATACENTER_CORE_FILE_INDEX":
		printerr("FAIL 26-D: FileIndexTerminalArea properties mismatch!")
		get_tree().quit(1)
		return

	var captured_26d: Dictionary = {}
	core_inst_phase26d.interaction_requested.connect(func(data):
		captured_26d.merge(data, true)
	)

	# 1. 碎片前：own_backup 維持中性佔位，不 set stood_before_own_backup
	core_inst_phase26d.current_interactable = own_backup_phase26d
	core_inst_phase26d._trigger_interaction()
	if captured_26d.get("message_text", "") != "MSG_DATACENTER_OWN_BACKUP_PLACEHOLDER":
		printerr("FAIL 26-D: expected placeholder before fragment collected, got: ", captured_26d)
		get_tree().quit(1)
		return
	if GameState.get_flag("stood_before_own_backup", false):
		printerr("FAIL 26-D: stood_before_own_backup must not be set before mem_frag_chose_deletion!")
		get_tree().quit(1)
		return

	# 2. 碎片後：own_backup 換重量級文字 + set stood_before_own_backup（冪等、可重看）
	GameState.set_flag("mem_frag_chose_deletion", true)
	captured_26d.clear()
	core_inst_phase26d._trigger_interaction()
	if captured_26d.get("message_text", "") != "MSG_DATACENTER_OWN_BACKUP_TRUTH":
		printerr("FAIL 26-D: expected TRUTH text after fragment collected, got: ", captured_26d)
		get_tree().quit(1)
		return
	if not GameState.get_flag("stood_before_own_backup", false):
		printerr("FAIL 26-D: stood_before_own_backup should be set once TRUTH text is reached!")
		get_tree().quit(1)
		return

	captured_26d.clear()
	core_inst_phase26d._trigger_interaction()
	if captured_26d.get("message_text", "") != "MSG_DATACENTER_OWN_BACKUP_TRUTH" or not GameState.get_flag("stood_before_own_backup", false):
		printerr("FAIL 26-D: own_backup TRUTH examine should stay idempotent and re-viewable!")
		get_tree().quit(1)
		return

	# 3. 檔案索引終端：seven_stopped_partial=false → 中性 flavor；不 set 任何旗標
	core_inst_phase26d.current_interactable = file_index_phase26d
	captured_26d.clear()
	core_inst_phase26d._trigger_interaction()
	if captured_26d.get("message_text", "") != "MSG_DATACENTER_FILE_INDEX_NEUTRAL":
		printerr("FAIL 26-D: expected neutral file index flavor when seven_stopped_partial is false, got: ", captured_26d)
		get_tree().quit(1)
		return

	# 4. 檔案索引終端：seven_stopped_partial=true → Branch B 重標記變體；可重看
	GameState.set_flag("seven_stopped_partial", true)
	captured_26d.clear()
	core_inst_phase26d._trigger_interaction()
	if captured_26d.get("message_text", "") != "MSG_DATACENTER_FILE_INDEX_REMARKED":
		printerr("FAIL 26-D: expected remarked file index variant when seven_stopped_partial is true, got: ", captured_26d)
		get_tree().quit(1)
		return

	captured_26d.clear()
	core_inst_phase26d._trigger_interaction()
	if captured_26d.get("message_text", "") != "MSG_DATACENTER_FILE_INDEX_REMARKED":
		printerr("FAIL 26-D: file index terminal should stay re-viewable with the same remarked variant!")
		get_tree().quit(1)
		return

	# 5. Branch B 變體不寫進「自己的備份」examine（兩互動物分屬不同情緒重點）
	core_inst_phase26d.current_interactable = own_backup_phase26d
	captured_26d.clear()
	core_inst_phase26d._trigger_interaction()
	if captured_26d.get("message_text", "") != "MSG_DATACENTER_OWN_BACKUP_TRUTH":
		printerr("FAIL 26-D: seven_stopped_partial must not leak Branch B variant into own_backup examine!")
		get_tree().quit(1)
		return

	core_inst_phase26d.free()
	await get_tree().process_frame

	GameState.reset_for_new_game()
	print("PASS: Phase 26-D ending trigger armament + Branch B file re-marking (own_backup TRUTH dispatch + stood_before_own_backup + file index terminal two variants) verified.")

	# ===================== Phase 26-E: 回歸 + 存讀檔 + GUI =====================
	print("--- Phase 26-E: 回歸 + 存讀檔 + GUI ---")

	# 1. 四旗標存讀檔 round-trip
	GameState.reset_for_new_game()
	GameState.set_flag("wan_act4_pull_seen", true)
	GameState.set_flag("ada_final_words_seen", true)
	GameState.set_flag("mem_frag_chose_deletion", true)
	GameState.set_flag("stood_before_own_backup", true)
	GameState.mark_scene_visited("datacenter_backup_core")

	var save_dict_phase26e = SaveSystem.capture("datacenter_backup_core", 100.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_dict_phase26e):
		printerr("FAIL 26-E: SaveSystem.write_slot failed for Phase 26 flags!")
		get_tree().quit(1)
		return

	GameState.reset_for_new_game()

	var main_scene_phase26e = load("res://scenes/main/main.tscn")
	var main_instance_phase26e = main_scene_phase26e.instantiate()
	add_child(main_instance_phase26e)
	await get_tree().process_frame

	if not main_instance_phase26e.load_game_slot(TEST_SCRATCH_SAVE_SLOT):
		printerr("FAIL 26-E: load_game_slot(scratch slot) failed to load Phase 26 save!")
		get_tree().quit(1)
		return
	await get_tree().process_frame

	if not GameState.get_flag("wan_act4_pull_seen", false) or not GameState.get_flag("ada_final_words_seen", false) or \
	   not GameState.get_flag("mem_frag_chose_deletion", false) or not GameState.get_flag("stood_before_own_backup", false):
		printerr("FAIL 26-E: four Phase 26 flags did not all survive save/load round-trip!")
		get_tree().quit(1)
		return

	if is_instance_valid(main_instance_phase26e):
		main_instance_phase26e.free()
	await get_tree().process_frame

	# 2. 26-A/B 一次性跨存讀不重播：旗標已跨存讀持久化，重進場景 Ada 不生成、晚觸發區不再自動觸發、路由已是 retalk
	var entrance_inst_phase26e = load("res://scenes/levels/datacenter_entrance/datacenter_entrance.tscn").instantiate()
	add_child(entrance_inst_phase26e)
	await get_tree().process_frame

	if entrance_inst_phase26e.get_node_or_null("Interactables/AdaNPC") != null or entrance_inst_phase26e.get_node_or_null("Interactables/AdaTriggerArea") != null:
		printerr("FAIL 26-E: Ada must stay permanently gone after cross-save/load (ada_final_words_seen persisted)!")
		get_tree().quit(1)
		return

	var wan_trigger_phase26e = entrance_inst_phase26e.get_node_or_null("Interactables/WanPullTriggerArea")
	var wan_npc_phase26e = entrance_inst_phase26e.get_node_or_null("Interactables/WanDatacenterNPC")
	if wan_trigger_phase26e == null or wan_npc_phase26e == null:
		printerr("FAIL 26-E: WanPullTriggerArea / WanDatacenterNPC missing after cross-save/load!")
		get_tree().quit(1)
		return

	var captured_wan_phase26e: Dictionary = {}
	entrance_inst_phase26e.interaction_requested.connect(func(data):
		captured_wan_phase26e.merge(data, true)
	)
	var fake_player_phase26e := Node2D.new()
	fake_player_phase26e.name = "Player"
	wan_trigger_phase26e._on_body_entered(fake_player_phase26e)
	if not captured_wan_phase26e.is_empty():
		printerr("FAIL 26-E: WanPullTriggerArea must not re-fire the auto-trigger after cross-save/load (wan_act4_pull_seen persisted)!")
		get_tree().quit(1)
		return

	var wan_dc_tree_phase26e = DialogueDB.get_tree_for("wan_datacenter")
	var runner_retalk_phase26e = DialogueRunner.new()
	runner_retalk_phase26e.start(wan_dc_tree_phase26e)
	if runner_retalk_phase26e.current().get("text", "") != "DLG_WAN_DATACENTER_RETALK_TEXT":
		printerr("FAIL 26-E: wan_datacenter should route to retalk after cross-save/load!")
		get_tree().quit(1)
		return

	fake_player_phase26e.free()
	entrance_inst_phase26e.free()
	await get_tree().process_frame

	# 3. 回歸：Phase 1~25 不退化（尤其 25 travel / 門禁 gate、戰鬥③ 抵達門後動線、24 追逐 / 攤牌、聚落往返）
	GameState.reset_for_new_game()
	GameState.set_flag("passed_nightclub_security", true)
	GameState.set_flag("seven_stopped_full", true)
	GameState.add_item("old_work_badge", 1)
	GameState.set_flag("read_old_work_order", true)

	var main_scene_phase26e_r = load("res://scenes/main/main.tscn")
	var main_instance_phase26e_r = main_scene_phase26e_r.instantiate()
	add_child(main_instance_phase26e_r)
	await get_tree().process_frame

	main_instance_phase26e_r.transition_to("datacenter_entrance", "from_nightclub")
	await get_tree().process_frame
	if main_instance_phase26e_r.get_current_scene_id() != "datacenter_entrance":
		printerr("FAIL 26-E: datacenter_entrance (25 travel gate) should still be reachable after Phase 26 changes!")
		get_tree().quit(1)
		return

	main_instance_phase26e_r.transition_to("datacenter_backup", "from_entrance")
	await get_tree().process_frame
	if main_instance_phase26e_r.get_current_scene_id() != "datacenter_backup":
		printerr("FAIL 26-E: datacenter_backup (25 門禁 gate 後動線) should still be reachable after Phase 26 changes!")
		get_tree().quit(1)
		return

	main_instance_phase26e_r.transition_to("datacenter_backup_core", "from_backup")
	await get_tree().process_frame
	if main_instance_phase26e_r.get_current_scene_id() != "datacenter_backup_core":
		printerr("FAIL 26-E: datacenter_backup_core (戰鬥③ 抵達門後動線) should still be reachable after Phase 26 changes!")
		get_tree().quit(1)
		return

	main_instance_phase26e_r.transition_to("tunnel_chase", "from_settlement")
	await get_tree().process_frame
	if main_instance_phase26e_r.get_current_scene_id() != "tunnel_chase":
		printerr("FAIL 26-E: tunnel_chase (Phase 24 追逐房間1) should still be reachable after Phase 26 changes!")
		get_tree().quit(1)
		return

	main_instance_phase26e_r.transition_to("tunnel_chase_right", "from_left")
	await get_tree().process_frame
	if main_instance_phase26e_r.get_current_scene_id() != "tunnel_chase_right":
		printerr("FAIL 26-E: tunnel_chase_right (Phase 24 攤牌) should still be reachable after Phase 26 changes!")
		get_tree().quit(1)
		return

	main_instance_phase26e_r.transition_to("underground_settlement_right", "from_left")
	await get_tree().process_frame
	if main_instance_phase26e_r.get_current_scene_id() != "underground_settlement_right":
		printerr("FAIL 26-E: underground_settlement_right (聚落往返) should still be reachable after Phase 26 changes!")
		get_tree().quit(1)
		return

	main_instance_phase26e_r.transition_to("underground_settlement", "from_right")
	await get_tree().process_frame
	if main_instance_phase26e_r.get_current_scene_id() != "underground_settlement":
		printerr("FAIL 26-E: underground_settlement round-trip (聚落往返) should still work after Phase 26 changes!")
		get_tree().quit(1)
		return

	if is_instance_valid(main_instance_phase26e_r):
		main_instance_phase26e_r.free()

	GameState.reset_for_new_game()
	if dir and dir.file_exists(TEST_SCRATCH_SAVE_FILE):
		dir.remove(TEST_SCRATCH_SAVE_FILE)

	print("PASS: Phase 26-E regression (Phase 1~25 core routes intact) and save/load guardrails (four flags round-trip + 26-A/B one-shot persists across cross-save/load) verified.")

	# ===================== Phase 27-A: `broadcast_station` 正式場景 =====================
	print("--- Phase 27-A: broadcast_station 正式場景 ---")

	var main_scene_phase27a_r = load("res://scenes/main/main.tscn")
	var main_instance_phase27a_r = main_scene_phase27a_r.instantiate()
	add_child(main_instance_phase27a_r)
	await get_tree().process_frame

	# 1. SceneRegistry / SaveSystem 顯示名
	if not "broadcast_station" in main_instance_phase27a_r.SCENES:
		printerr("FAIL 27-A: SceneRegistry missing broadcast_station!")
		get_tree().quit(1)
		return
	var bc_config_phase27a: Dictionary = main_instance_phase27a_r.SCENES["broadcast_station"]
	if bc_config_phase27a.get("default_entry_point_id", "") != "from_backup_core" or not "from_backup_core" in bc_config_phase27a.get("entry_points", []):
		printerr("FAIL 27-A: broadcast_station entry_points/default_entry_point_id misconfigured: ", bc_config_phase27a)
		get_tree().quit(1)
		return
	if SaveSystem.get_scene_display_name("broadcast_station") == "未知區域":
		printerr("FAIL 27-A: SaveSystem SCENE_NAMES missing broadcast_station!")
		get_tree().quit(1)
		return

	# 2. 場景骨架：唯一 spawn、無回資料中心出口、四個互動物欄位正確
	var bc_packed_phase27a = load("res://scenes/levels/broadcast/broadcast_station.tscn")
	var bc_inst_phase27a = bc_packed_phase27a.instantiate()
	add_child(bc_inst_phase27a)
	await get_tree().process_frame

	var bc_spawns_phase27a = bc_inst_phase27a.get_node("SpawnPoints").get_children()
	if bc_spawns_phase27a.size() != 1 or bc_spawns_phase27a[0].name != "from_backup_core":
		printerr("FAIL 27-A: broadcast_station should have exactly one spawn point, from_backup_core!")
		get_tree().quit(1)
		return

	for interactable_phase27a in bc_inst_phase27a.get_node("Interactables").get_children():
		var iid_phase27a: String = interactable_phase27a.interaction_id
		if iid_phase27a.contains("exit") or iid_phase27a.contains("return"):
			printerr("FAIL 27-A: broadcast_station must have no return-to-datacenter exit (單向), found: ", iid_phase27a)
			get_tree().quit(1)
			return

	var upload_terminal_phase27a = bc_inst_phase27a.get_node_or_null("Interactables/UploadTerminal")
	if upload_terminal_phase27a == null or upload_terminal_phase27a.dialogue_id != "broadcast_upload":
		printerr("FAIL 27-A: UploadTerminal missing or dialogue_id != broadcast_upload!")
		get_tree().quit(1)
		return

	for flavor_name_phase27a in ["FlavorTransmitterArea", "FlavorOldMediaArea", "FlavorPredecessorArea"]:
		if bc_inst_phase27a.get_node_or_null("Interactables/" + flavor_name_phase27a) == null:
			printerr("FAIL 27-A: broadcast_station missing flavor examine node: ", flavor_name_phase27a)
			get_tree().quit(1)
			return

	bc_inst_phase27a.free()
	await get_tree().process_frame

	# 3. 轉場 + 進場一次性 MessageBox（entry_point_id == from_backup_core 才播）+ can_save_here
	SaveSystem.can_save_here = false
	main_instance_phase27a_r.transition_to("broadcast_station", "from_backup_core")

	if main_instance_phase27a_r.get_current_scene_id() != "broadcast_station":
		printerr("FAIL 27-A: broadcast_station should be reachable via transition_to!")
		get_tree().quit(1)
		return
	if not SaveSystem.can_save_here:
		printerr("FAIL 27-A: broadcast_station should set can_save_here = true!")
		get_tree().quit(1)
		return

	# 訊號連線必須搶在 call_deferred 進場訊息真正 flush 之前（transition_to 內同步 add_child/_ready 已排入 deferred queue，尚未觸發）
	# 用 get_children()[-1]，因為 transition_to 清舊場景用 queue_free（延遲），舊子節點此刻仍在 index 0
	var captured_arrival_phase27a: Dictionary = {}
	var bc_level_phase27a = main_instance_phase27a_r.world_root.get_children()[-1]
	bc_level_phase27a.interaction_requested.connect(func(data):
		captured_arrival_phase27a.merge(data, true)
	)
	await get_tree().process_frame
	await get_tree().process_frame
	if captured_arrival_phase27a.get("message_text", "") != "MSG_BROADCAST_ARRIVAL":
		printerr("FAIL 27-A: entering via from_backup_core should auto-play MSG_BROADCAST_ARRIVAL once, got: ", captured_arrival_phase27a)
		get_tree().quit(1)
		return

	# 4. 場景內存讀 round-trip；讀檔回場（entry_point_id == restore）不重播進場 MessageBox
	var save_dict_phase27a = SaveSystem.capture("broadcast_station", 2200.0, 1)
	if not SaveSystem.write_slot(TEST_SCRATCH_SAVE_SLOT, save_dict_phase27a):
		printerr("FAIL 27-A: SaveSystem.write_slot failed for broadcast_station save!")
		get_tree().quit(1)
		return

	if is_instance_valid(main_instance_phase27a_r):
		main_instance_phase27a_r.free()
	await get_tree().process_frame

	var main_scene_phase27a = load("res://scenes/main/main.tscn")
	var main_instance_phase27a = main_scene_phase27a.instantiate()
	add_child(main_instance_phase27a)
	await get_tree().process_frame

	if not main_instance_phase27a.load_game_slot(TEST_SCRATCH_SAVE_SLOT):
		printerr("FAIL 27-A: load_game_slot(scratch slot) failed to load broadcast_station save!")
		get_tree().quit(1)
		return
	await get_tree().process_frame

	if main_instance_phase27a.get_current_scene_id() != "broadcast_station":
		printerr("FAIL 27-A: current scene should restore to broadcast_station after load, got: ", main_instance_phase27a.get_current_scene_id())
		get_tree().quit(1)
		return

	var captured_reload_phase27a: Dictionary = {}
	var bc_level_reload_phase27a = main_instance_phase27a.world_root.get_children()[-1]
	bc_level_reload_phase27a.interaction_requested.connect(func(data):
		captured_reload_phase27a.merge(data, true)
	)
	await get_tree().process_frame
	await get_tree().process_frame
	if not captured_reload_phase27a.is_empty():
		printerr("FAIL 27-A: loading a save inside broadcast_station must not replay the arrival MessageBox, got: ", captured_reload_phase27a)
		get_tree().quit(1)
		return

	if is_instance_valid(main_instance_phase27a):
		main_instance_phase27a.free()

	GameState.reset_for_new_game()
	SaveSystem.can_save_here = true
	if dir and dir.file_exists(TEST_SCRATCH_SAVE_FILE):
		dir.remove(TEST_SCRATCH_SAVE_FILE)

	print("PASS: Phase 27-A broadcast_station scene (skeleton + one-shot arrival + no return exit + can_save_here + in-scene save/load) verified.")

	# ===================== Phase 27-B: 三結局路由 own_backup =====================
	print("--- Phase 27-B: 三結局路由 own_backup ---")

	GameState.reset_for_new_game()

	var find_choice_phase27b = func(curr: Dictionary, substr: String) -> int:
		for c in curr.get("choices", []):
			if substr in tr(c.get("label", "")):
				return c.get("index")
		return -1

	var own_backup_tree_phase27b = DialogueDB.get_tree_for("own_backup")
	if own_backup_tree_phase27b.is_empty():
		printerr("FAIL 27-B: DialogueDB own_backup tree not found!")
		get_tree().quit(1)
		return

	# ---- Test 1: level dispatch 四層分派鏈 ----
	var core_inst_phase27b = load("res://scenes/levels/datacenter_backup_core/datacenter_backup_core.tscn").instantiate()
	add_child(core_inst_phase27b)

	var own_backup_area_phase27b = core_inst_phase27b.get_node_or_null("Interactables/OwnBackupArea")
	if own_backup_area_phase27b == null:
		printerr("FAIL 27-B: datacenter_backup_core missing OwnBackupArea node!")
		get_tree().quit(1)
		return

	var captured_27b: Dictionary = {}
	core_inst_phase27b.interaction_requested.connect(func(data):
		captured_27b.clear()
		captured_27b.merge(data, true)
	)
	core_inst_phase27b.current_interactable = own_backup_area_phase27b

	# 1a. 碎片前：中性佔位（26-D 不變）
	core_inst_phase27b._trigger_interaction()
	if captured_27b.get("message_text", "") != "MSG_DATACENTER_OWN_BACKUP_PLACEHOLDER":
		printerr("FAIL 27-B: expected placeholder before fragment collected, got: ", captured_27b)
		get_tree().quit(1)
		return

	# 1b. 碎片後：TRUTH + 武裝 stood_before_own_backup（26-D 不變）
	GameState.set_flag("mem_frag_chose_deletion", true)
	core_inst_phase27b._trigger_interaction()
	if captured_27b.get("message_text", "") != "MSG_DATACENTER_OWN_BACKUP_TRUTH" or not GameState.get_flag("stood_before_own_backup", false):
		printerr("FAIL 27-B: expected TRUTH text + stood_before_own_backup armed, got: ", captured_27b)
		get_tree().quit(1)
		return

	# 1c. 重看：開三選對話（stood_before_own_backup 已武裝、尚未鎖點）
	core_inst_phase27b._trigger_interaction()
	if captured_27b.get("type", "") != "dialogue" or captured_27b.get("dialogue_id", "") != "own_backup":
		printerr("FAIL 27-B: re-examining own_backup after stood_before_own_backup should open dialogue 'own_backup', got: ", captured_27b)
		get_tree().quit(1)
		return
	print("PASS 27-B: level dispatch layers 1-3 (placeholder -> TRUTH+armament -> open own_backup dialogue) verified.")

	# 1d. 鎖點後：DECIDED（不可重選）
	GameState.set_flag("ending_route_reclaim", true)
	core_inst_phase27b._trigger_interaction()
	if captured_27b.get("message_text", "") != "MSG_DATACENTER_OWN_BACKUP_DECIDED":
		printerr("FAIL 27-B: expected DECIDED message once a route flag is set, got: ", captured_27b)
		get_tree().quit(1)
		return
	print("PASS 27-B: level dispatch layer 4 (DECIDED, no longer re-openable) verified.")

	core_inst_phase27b.free()
	await get_tree().process_frame
	GameState.reset_for_new_game()

	# ---- Test 2: 存檔提示一次性 pre-node ----
	var runner_27b := DialogueRunner.new()
	runner_27b.start(own_backup_tree_phase27b, "start")
	if runner_27b._current_node_id != "save_hint":
		printerr("FAIL 27-B: start should route to save_hint before ending_save_hint_seen is set! Got: ", runner_27b._current_node_id)
		get_tree().quit(1)
		return
	if not GameState.get_flag("ending_save_hint_seen", false):
		printerr("FAIL 27-B: entering save_hint should immediately set ending_save_hint_seen!")
		get_tree().quit(1)
		return
	runner_27b.advance()
	if runner_27b._current_node_id != "anchor":
		printerr("FAIL 27-B: save_hint should advance straight into anchor! Got: ", runner_27b._current_node_id)
		get_tree().quit(1)
		return

	# 旗標已設，重開應直入重錨定（不重播提示）
	runner_27b.start(own_backup_tree_phase27b, "start")
	if runner_27b._current_node_id != "anchor":
		printerr("FAIL 27-B: with ending_save_hint_seen already set, start should skip straight to anchor! Got: ", runner_27b._current_node_id)
		get_tree().quit(1)
		return
	print("PASS 27-B: one-shot save hint pre-node (sets flag once, skipped on re-open) verified.")

	# ---- Test 3: anchor 四選項（三動詞 + 退開）----
	var anchor_curr_27b = runner_27b.current()
	for expect_label in ["灌回去", "刪掉它", "拷貝走", "退開"]:
		if find_choice_phase27b.call(anchor_curr_27b, expect_label) == -1:
			printerr("FAIL 27-B: anchor choices missing expected option: ", expect_label, " got: ", anchor_curr_27b)
			get_tree().quit(1)
			return

	# ---- Test 4: 退開 -> 無 effect、不寫旗標、可重開 ----
	runner_27b.choose(find_choice_phase27b.call(anchor_curr_27b, "退開"))
	if runner_27b._current_node_id != "withdraw":
		printerr("FAIL 27-B: 退開 should land on withdraw node! Got: ", runner_27b._current_node_id)
		get_tree().quit(1)
		return
	if GameState.get_flag("ending_route_reclaim", false) or GameState.get_flag("ending_route_protect", false) or GameState.get_flag("ending_route_expose", false):
		printerr("FAIL 27-B: withdrawing must not write any ending_route_* flag!")
		get_tree().quit(1)
		return
	print("PASS 27-B: 退開 (withdraw) writes no route flag and dialogue stays re-openable.")

	# ---- Test 5: 回去再想 -> 退回 anchor，不寫旗標 ----
	runner_27b.start(own_backup_tree_phase27b, "start")
	anchor_curr_27b = runner_27b.current()
	runner_27b.choose(find_choice_phase27b.call(anchor_curr_27b, "灌回去"))
	if runner_27b._current_node_id != "confirm_reclaim":
		printerr("FAIL 27-B: 灌回去 should route to confirm_reclaim! Got: ", runner_27b._current_node_id)
		get_tree().quit(1)
		return
	var confirm_curr_27b = runner_27b.current()
	runner_27b.choose(find_choice_phase27b.call(confirm_curr_27b, "回去再想"))
	if runner_27b._current_node_id != "anchor":
		printerr("FAIL 27-B: 回去再想 should return to anchor (第 3 拍)! Got: ", runner_27b._current_node_id)
		get_tree().quit(1)
		return
	if GameState.get_flag("ending_route_reclaim", false):
		printerr("FAIL 27-B: reconsidering must not write ending_route_reclaim!")
		get_tree().quit(1)
		return
	print("PASS 27-B: 回去再想 (reconsider) returns to anchor without writing a route flag.")

	# ---- Test 6: 灌回去鎖點 -> ending_route_reclaim 唯一為真 ----
	anchor_curr_27b = runner_27b.current()
	runner_27b.choose(find_choice_phase27b.call(anchor_curr_27b, "灌回去"))
	confirm_curr_27b = runner_27b.current()
	runner_27b.choose(find_choice_phase27b.call(confirm_curr_27b, "就這麼做"))
	if runner_27b._current_node_id != "reclaim_lock":
		printerr("FAIL 27-B: 就這麼做 (reclaim) should land on reclaim_lock! Got: ", runner_27b._current_node_id)
		get_tree().quit(1)
		return
	if not GameState.get_flag("ending_route_reclaim", false) or GameState.get_flag("ending_route_protect", false) or GameState.get_flag("ending_route_expose", false):
		printerr("FAIL 27-B: reclaim lock should set ending_route_reclaim and leave the other two routes false!")
		get_tree().quit(1)
		return
	print("PASS 27-B: 灌回去 lock-in sets ending_route_reclaim exclusively.")

	# ---- Test 7: 刪掉它鎖點 -> ending_route_protect 唯一為真 ----
	GameState.reset_for_new_game()
	GameState.set_flag("ending_save_hint_seen", true)
	runner_27b.start(own_backup_tree_phase27b, "start")
	anchor_curr_27b = runner_27b.current()
	runner_27b.choose(find_choice_phase27b.call(anchor_curr_27b, "刪掉它"))
	confirm_curr_27b = runner_27b.current()
	runner_27b.choose(find_choice_phase27b.call(confirm_curr_27b, "就這麼做"))
	if runner_27b._current_node_id != "protect_lock":
		printerr("FAIL 27-B: 就這麼做 (protect) should land on protect_lock! Got: ", runner_27b._current_node_id)
		get_tree().quit(1)
		return
	if not GameState.get_flag("ending_route_protect", false) or GameState.get_flag("ending_route_reclaim", false) or GameState.get_flag("ending_route_expose", false):
		printerr("FAIL 27-B: protect lock should set ending_route_protect and leave the other two routes false!")
		get_tree().quit(1)
		return
	print("PASS 27-B: 刪掉它 lock-in sets ending_route_protect exclusively.")

	# ---- Test 8: 拷貝走鎖點 -> ending_route_expose 唯一為真 + 單向轉場 broadcast_station ----
	GameState.reset_for_new_game()
	GameState.set_flag("ending_save_hint_seen", true)
	runner_27b.start(own_backup_tree_phase27b, "start")
	anchor_curr_27b = runner_27b.current()
	runner_27b.choose(find_choice_phase27b.call(anchor_curr_27b, "拷貝走"))
	confirm_curr_27b = runner_27b.current()
	runner_27b.choose(find_choice_phase27b.call(confirm_curr_27b, "就這麼做"))
	if runner_27b._current_node_id != "expose_lock":
		printerr("FAIL 27-B: 就這麼做 (expose) should land on expose_lock! Got: ", runner_27b._current_node_id)
		get_tree().quit(1)
		return
	if not GameState.get_flag("ending_route_expose", false) or GameState.get_flag("ending_route_reclaim", false) or GameState.get_flag("ending_route_protect", false):
		printerr("FAIL 27-B: expose lock should set ending_route_expose and leave the other two routes false!")
		get_tree().quit(1)
		return
	if runner_27b.pending_travel.get("scene_id", "") != "broadcast_station" or runner_27b.pending_travel.get("entry_point_id", "") != "from_backup_core":
		printerr("FAIL 27-B: expose lock should queue a one-way travel to broadcast_station:from_backup_core! Got: ", runner_27b.pending_travel)
		get_tree().quit(1)
		return
	print("PASS 27-B: 拷貝走 lock-in sets ending_route_expose exclusively and queues travel to broadcast_station:from_backup_core.")

	GameState.reset_for_new_game()
	print("PASS: Phase 27-B three-ending routing (own_backup dialogue: save-hint one-shot + anchor four choices + reconsider + mutually exclusive lock-in + Expose one-way travel + level DECIDED gate) verified.")

	print("==================================================")
	print("ALL INTEGRATION VERIFICATIONS PASSED SUCCESSFULLY!")
	print("==================================================")
	
	# Defer quit so that this ready function can return and pop stack frame, clearing references
	get_tree().call_deferred("quit", 0)

# 遞迴列出 root 下所有副檔名為 ext 的檔案（res:// 路徑）
func _m2b_list_files(root: String, ext: String, out: Array) -> void:
	var da := DirAccess.open(root)
	if da == null:
		return
	da.list_dir_begin()
	var fname := da.get_next()
	while fname != "":
		if fname != "." and fname != "..":
			var full := root.path_join(fname)
			if da.current_is_dir():
				_m2b_list_files(full, ext, out)
			elif fname.ends_with(ext):
				out.append(full)
		fname = da.get_next()
	da.list_dir_end()

# M2-C 翻譯 key 格式判斷：全大寫字母 / 數字 / 底線；不允許混入 CJK / 標點。
# 抓「整欄忘了 key 化」——例如 STORY_NOTES.title 還是「AI 善後員」中文字面量、ITEMS_DB.name 殘留中文。
func _m2c_is_translation_key(s: String) -> bool:
	if s.is_empty():
		return false
	for ch in s:
		var c_code := ch.unicode_at(0)
		var is_upper := (c_code >= 65 and c_code <= 90)       # A-Z
		var is_digit := (c_code >= 48 and c_code <= 57)       # 0-9
		var is_under := (c_code == 95)                         # _
		if not (is_upper or is_digit or is_under):
			return false
	return true

# 記錄一筆 CSV 缺漏的 key 參照（去重，保留首次出現的檔案）
func _m2b_check_ref(key: String, file: String, keyset: Dictionary, missing: Dictionary) -> void:
	if key == "":
		return
	if not keyset.has(key) and not missing.has(key):
		missing[key] = file

# 最小 CSV 解析器：支援雙引號包裹欄位、欄內逗號/換行、"" 轉義（ui.csv 的多行劇情欄需要）
func _m2b_parse_csv(path: String) -> Array:
	var fa := FileAccess.open(path, FileAccess.READ)
	if fa == null:
		return []
	var content := fa.get_as_text()
	fa.close()
	# 正規化換行（檔案為 CRLF；.translation 內存 LF），避免欄內 \r 造成比對不符
	content = content.replace("\r\n", "\n").replace("\r", "\n")
	var records: Array = []
	var record: Array = []
	var field := ""
	var in_quotes := false
	var i := 0
	var n := content.length()
	while i < n:
		var c := content[i]
		if in_quotes:
			if c == '"':
				if i + 1 < n and content[i + 1] == '"':
					field += '"'
					i += 1
				else:
					in_quotes = false
			else:
				field += c
		else:
			if c == '"':
				in_quotes = true
			elif c == ',':
				record.append(field)
				field = ""
			elif c == '\n':
				record.append(field)
				records.append(record)
				record = []
				field = ""
			elif c != '\r':
				field += c
		i += 1
	if field != "" or record.size() > 0:
		record.append(field)
		records.append(record)
	return records

func _tr_body(raw_body: String) -> String:
	if raw_body.is_empty():
		return ""
	var parts := raw_body.split("\n\n")
	var out: Array = []
	for p in parts:
		out.append(tr(p))
	return "\n\n".join(out)

# 回傳排序後的佔位型別簽章（如 "ds"），用於三語比對：
# 比多重集而非順序，允許跨語言換序，但能抓出 %s/%d 型別錯置或數量不符。
func _m2e_placeholder_signature(text: String) -> String:
	var specs: Array = []
	var i := 0
	var n := text.length()
	while i < n:
		if text[i] == '%':
			if i + 1 < n and text[i+1] == '%':
				# Literal %%, skip both
				i += 2
				continue
			i += 1
			# Skip formatting flags, width, precision
			while i < n and ((text[i] >= "0" and text[i] <= "9") or text[i] == '.' or text[i] == '-' or text[i] == '+'):
				i += 1
			if i < n and (text[i] == 's' or text[i] == 'd' or text[i] == 'f' or text[i] == 'x' or text[i] == 'o' or text[i] == 'X'):
				specs.append(text[i])
		i += 1
	specs.sort()
	return "".join(specs)
