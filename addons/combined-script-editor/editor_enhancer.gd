class_name EditorEnhancer extends RefCounted

const config_path := ".godot/plugin_config.ini"
var base_control: Control = EditorInterface.get_base_control()
var editor_main_screen: VBoxContainer = EditorInterface.get_editor_main_screen()
var script_editor: ScriptEditor = EditorInterface.get_script_editor()
var resize_panel: TextureRect
var script_editor_size: Vector2 = Vector2.ZERO
var config: Dictionary

func perform():
	# combined scene and script editor
	editor_main_screen.sort_children.connect(combine_script_editor)
	editor_main_screen.resized.connect(combine_script_editor)

	resize_panel = TextureRect.new()
	resize_panel.stretch_mode = TextureRect.StretchMode.STRETCH_KEEP_CENTERED
	resize_panel.texture = base_control.get_theme_icon("Hsize", "EditorIcons")
	resize_panel.custom_minimum_size = Vector2(20, 20)
	resize_panel.gui_input.connect(on_resize_panel_gui_input)

	script_editor.get_child(0).get_child(0).add_child(resize_panel)
	script_editor.get_child(0).get_child(0).move_child(resize_panel, 0)

	config = load_config()
	script_editor_size = config.get("script_editor_size", editor_main_screen.size / 2)
	
func combine_script_editor():
	var _2d_editor_view: VBoxContainer = editor_main_screen.get_child(0)
	var _3d_editor_view: VBoxContainer = editor_main_screen.get_child(1)
	var script_editor_view: MarginContainer = editor_main_screen.get_child(2)
	var game_view: MarginContainer = editor_main_screen.get_child(3)
	var asset_lib_view: PanelContainer = editor_main_screen.get_child(4)
	var scene_editor: VBoxContainer

	if _2d_editor_view.visible:
		scene_editor = _2d_editor_view
	elif _3d_editor_view.visible:
		scene_editor = _3d_editor_view
	else:
		resize_panel.visible = false
		if game_view.visible || asset_lib_view.visible:
			await Engine.get_main_loop().create_timer(0.001).timeout
			script_editor_view.visible = false
		return

	var editor_size = editor_main_screen.size

	var script_editor_width = clamp(
		script_editor_size.x,
		script_editor_view.get_minimum_size().x,
		editor_size.x - scene_editor.get_minimum_size().x,
	)

	scene_editor.size = Vector2(editor_size.x - script_editor_width, editor_size.y)
	script_editor_view.position = Vector2(scene_editor.size.x, scene_editor.position.y)
	script_editor_view.size = Vector2(editor_size.x - scene_editor.size.x, scene_editor.size.y)
	script_editor_view.visible = true
	resize_panel.visible = true

func on_resize_panel_gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.is_pressed():
			resize_panel.set_meta("dragging", true)
			resize_panel.set_meta("drag_start_position", event.global_position)
		elif event.is_released():
			resize_panel.set_meta("dragging", false)
			var script_editor_view: MarginContainer = editor_main_screen.get_child(2)
			script_editor_size = script_editor_view.size
			config["script_editor_size"] = script_editor_size
			save_config()
	elif event is InputEventMouseMotion:
		if resize_panel.get_meta("dragging", false):
			var drag_start_position = resize_panel.get_meta("drag_start_position")
			script_editor_size -= event.relative
			combine_script_editor()

func load_config(section = "combined_script_editor") -> Dictionary:
	var config_file := ConfigFile.new()
	config_file.load(config_path)
	var config = {}
	if config_file.has_section(section):
		for k in config_file.get_section_keys(section):
			config[k] = config_file.get_value(section, k)
	return config

func save_config(section = "combined_script_editor"):
	var config_file := ConfigFile.new()
	for k in config:
		config_file.set_value(section, k, config[k])
	config_file.save(config_path)
