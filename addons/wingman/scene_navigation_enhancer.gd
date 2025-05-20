class_name SceneNavigationEnhancer extends RefCounted

var base_control: Control = EditorInterface.get_base_control()
var script_editor: ScriptEditor = EditorInterface.get_script_editor()
var editor_selection: EditorSelection = EditorInterface.get_selection()
var scene_selector := OptionButton.new()
var scenes = {}

func perform():
	#add Scene selector
	var editor_selector := base_control.get_child(0).get_child(0).get_child(2)

	scene_selector.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
	scene_selector.get_popup().id_pressed.connect(func(idx: int):
		var scene_file = scene_selector.get_item_metadata(idx)
		EditorInterface.open_scene_from_path(scene_file)
	)
	scene_selector.add_theme_font_override("font", editor_selector.get_child(0).get_theme_font("font"))
	scene_selector.add_theme_font_size_override("font_size", editor_selector.get_child(0).get_theme_font_size("font_size"))
	
	var scene_selector_container := HBoxContainer.new()
	scene_selector_container.add_child(scene_selector)
	# scene_selector_container.add_spacer(false).custom_minimum_size = Vector2(10, 0)
	editor_selector.add_child(scene_selector_container)
	editor_selector.move_child(scene_selector_container, 0)

	editor_selection.selection_changed.connect(init_scene_selector)
	
	# var scene_tab_bar: TabBar = base_control.get_child(0).get_child(1).get_child(1).get_child(1).find_child("*TabBar*", true, false)
	# scene_tab_bar.tab_changed.connect(init_scene_selector)

func init_scene_selector(tab: int = -1):
	load_scenes()
	scene_selector.clear()
	for i in scenes.size():
		var scene_file = scenes.keys()[i]
		var scene_name = scenes[scene_file]["name"]
		var scene_class = scenes[scene_file]["class"]
		scene_selector.add_icon_item(base_control.get_theme_icon(scene_class, "EditorIcons"), scene_name)
		scene_selector.get_popup().set_item_as_radio_checkable(i, false)
		scene_selector.set_item_metadata(i, scene_file)
		scene_selector.set_item_tooltip(i, scene_file)
	if EditorInterface.get_edited_scene_root():
		var scene_file = EditorInterface.get_edited_scene_root().scene_file_path
		scene_selector.selected = scenes.keys().find(scene_file)
	else:
		scene_selector.selected = -1
	
func load_scenes():
	var scenes_file := get_files("res://", "tscn")
	for scene_file in scenes_file:
		if !scenes.has(scene_file):
			var scene_instance = (ResourceLoader.load(scene_file) as PackedScene).instantiate()
			scenes[scene_file] = {
				"name": scene_instance.name,
				"class": scene_instance.get_class()
			}

func get_files(path: String, ext: Variant = null) -> Array[String]:
	var dir_access = DirAccess.open(path)
	var files: Array[String] = []
	for file_name in dir_access.get_files():
		if ext == null || file_name.get_extension() == str(ext):
			files.append(path.path_join(file_name))
	for dir in dir_access.get_directories():
		files.append_array(get_files(path.path_join(dir), ext))
	return files
