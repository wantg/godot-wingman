class_name SceneNavigationEnhancer extends RefCounted

var base_control: Control = EditorInterface.get_base_control()
var script_editor: ScriptEditor = EditorInterface.get_script_editor()
var editor_selection: EditorSelection = EditorInterface.get_selection()
var scene_selector := OptionButton.new()
var scenes_instantiate = {}

func perform():
	#add Scene selector
	var editor_selector := base_control.get_child(0).get_child(0).get_child(2)

	scene_selector.alignment = HorizontalAlignment.HORIZONTAL_ALIGNMENT_LEFT
	scene_selector.get_popup().id_pressed.connect(func(idx: int):
		var tree_item = scene_selector.get_item_metadata(idx)
		if tree_item != null:
			EditorInterface.open_scene_from_path(tree_item.get_metadata(0))
	)
	scene_selector.add_theme_font_override("font", editor_selector.get_child(0).get_theme_font("font"))
	scene_selector.add_theme_font_size_override("font_size", editor_selector.get_child(0).get_theme_font_size("font_size"))
	scene_selector.get_popup().add_theme_color_override("font_disabled_color", Color.WHITE)
	
	var scene_selector_container := HBoxContainer.new()
	scene_selector_container.add_child(scene_selector)
	# scene_selector_container.add_spacer(false).custom_minimum_size = Vector2(10, 0)
	editor_selector.add_child(scene_selector_container)
	editor_selector.move_child(scene_selector_container, 0)

	editor_selection.selection_changed.connect(init_scene_selector)

func init_scene_selector():
	scene_selector.clear()
	var scene_trees := load_scene_trees()
	
	for i in scene_trees.size():
		var data = scene_trees[i]
		var tree_item = data["tree_item"]
		var title = data["title"]
		var is_dir = tree_item.get_metadata(0).ends_with("/")
		var cls = data["class"]
		var indent = tree_item.get_metadata(0).split("/").size() - 3
		if !is_dir:
			indent += 1
		scene_selector.add_icon_item(base_control.get_theme_icon(cls, "EditorIcons"), title)
		scene_selector.get_popup().set_item_as_radio_checkable(i, false)
		scene_selector.get_popup().set_item_indent(i, indent * 2)
		scene_selector.set_item_disabled(i, is_dir)
		scene_selector.set_item_metadata(i, tree_item)
		scene_selector.set_item_tooltip(i, tree_item.get_metadata(0))

	if EditorInterface.get_edited_scene_root():
		var edited_scene_file = EditorInterface.get_edited_scene_root().scene_file_path
		for i in scene_trees.size():
			if scene_trees[i]["tree_item"].get_metadata(0) == edited_scene_file:
				scene_selector.selected = i
	else:
		scene_selector.selected = -1

func load_scene_trees() -> Array:
	var tree = EditorInterface.get_file_system_dock().get_child(3).get_child(0) as Tree
	var file_system_trees: Array[TreeItem]
	load_file_system_tree(tree.get_root().get_children()[1], file_system_trees)
	var scene_trees_exclude_empty_dir: Array[TreeItem]
	for file_system_tree in file_system_trees:
		var file_system_tree_metadata = file_system_tree.get_metadata(0)
		for j in file_system_trees:
			var j_metadata = j.get_metadata(0)
			if j_metadata.ends_with(".tscn") && j_metadata.begins_with(file_system_tree_metadata):
				scene_trees_exclude_empty_dir.push_back(file_system_tree)
				break

	var scene_trees = []
	for tree_item in scene_trees_exclude_empty_dir:
		var path: String = tree_item.get_metadata(0)
		var is_dir = path.ends_with("/")
		var title = tree_item.get_text(0)
		var cls_name := "Folder"
		if !is_dir:
			if !scenes_instantiate.has(path):
				var scene_instance = (ResourceLoader.load(path) as PackedScene).instantiate()
				scenes_instantiate[path] = {"title": scene_instance.name, "class": scene_instance.get_class()}
			var scene_data = scenes_instantiate[path]
			title = scene_data["title"]
			cls_name = scene_data["class"]
		scene_trees.push_back({"tree_item": tree_item, "title": title, "class": cls_name})

	return scene_trees

func load_file_system_tree(tree_item: TreeItem, arr: Array[TreeItem], indent: int = 0):
	var metadata = tree_item.get_metadata(0)
	if metadata.ends_with(".tscn") || metadata.ends_with("/"):
		arr.push_back(tree_item)
	for i in tree_item.get_children():
		load_file_system_tree(i, arr, indent + 1)

func get_files(path: String, ext: Variant = null) -> Array[String]:
	var dir_access = DirAccess.open(path)
	var files: Array[String] = []
	for file_name in dir_access.get_files():
		if ext == null || file_name.get_extension() == str(ext):
			files.append(path.path_join(file_name))
	for dir in dir_access.get_directories():
		files.append_array(get_files(path.path_join(dir), ext))
	return files
