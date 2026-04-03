class_name BottomPanelEnhancer extends RefCounted

var editor_plugin: EditorPlugin
var base_control: Control = EditorInterface.get_base_control()
var inspector: EditorInspector = EditorInterface.get_inspector()
var tile_set_editor_dock: EditorDock
var tile_map_layer_editor_dock: EditorDock
var tiles_merged_editor_dock: EditorDock = null
var simulate_select: bool

const SETTING_PATH = "addons/wingman/merge_tiles_editor"

func perform(_editor_plugin: EditorPlugin):
	editor_plugin = _editor_plugin
	if not ProjectSettings.has_setting(SETTING_PATH):
		ProjectSettings.set_setting(SETTING_PATH, false)
		ProjectSettings.set_initial_value(SETTING_PATH, false)
	
	# find TileSetEditorDock and connect signal
	tile_set_editor_dock = base_control.find_children("", "TileSetEditor", true, false)[0]
	var tile_set_item_list: ItemList = tile_set_editor_dock.find_child("*ItemList*", true, false)
	if !tile_set_item_list.is_connected("item_selected", tile_set_item_list_selected):
		tile_set_item_list.item_selected.connect(tile_set_item_list_selected)

	# find TileMapLayerEditorDock and connect signal
	tile_map_layer_editor_dock = base_control.find_children("", "TileMapLayerEditor", true, false)[0]
	var tile_map_layer_item_list: ItemList = tile_map_layer_editor_dock.find_child("*ItemList*", true, false)
	if !tile_map_layer_item_list.is_connected("item_selected", tile_map_layer_item_list_selected):
		tile_map_layer_item_list.item_selected.connect(tile_map_layer_item_list_selected)

	# Create merged tiles editor dock
	tiles_merged_editor_dock = EditorDock.new()
	tiles_merged_editor_dock.title = "Tiles"
	tiles_merged_editor_dock.default_slot = EditorDock.DOCK_SLOT_BOTTOM
	tiles_merged_editor_dock.available_layouts = EditorDock.DockLayout.DOCK_LAYOUT_HORIZONTAL | EditorDock.DockLayout.DOCK_LAYOUT_FLOATING
	tiles_merged_editor_dock.add_child(HSplitContainer.new())
	editor_plugin.add_dock(tiles_merged_editor_dock)
	
	# Listen to inspector edited object changed signal to show merged tiles editor when editing TileSet or TileMapLayer
	var editor_bottom_panel: TabContainer = base_control.find_child("@EditorBottomPanel*", true, false)
	inspector.edited_object_changed.connect(func():
		if ProjectSettings.get_setting(SETTING_PATH) == true && (inspector.get_edited_object() is TileMapLayer || inspector.get_edited_object() is TileSet):
			await Engine.get_main_loop().create_timer(0.01).timeout
			show_merged_tiles_editor()
			return
		
		editor_bottom_panel.set_tab_hidden(editor_bottom_panel.get_tab_idx_from_control(tiles_merged_editor_dock), true)
	)

	# Middle mouse button click to clear editor log
	var editor_log: EditorDock = base_control.find_children("", "EditorLog", true, false)[0]
	var editor_log_rich_text_label: RichTextLabel = editor_log.find_children("", "RichTextLabel", true, false)[0]
	editor_log_rich_text_label.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton:
			if event.button_mask == MouseButtonMask.MOUSE_BUTTON_MASK_MIDDLE:
				editor_log_rich_text_label.clear()
	)
	
func disable():
	editor_plugin.remove_dock(tiles_merged_editor_dock)
	tiles_merged_editor_dock.queue_free()

func show_merged_tiles_editor():
	var editor_bottom_panel: TabContainer = base_control.find_child("@EditorBottomPanel*", true, false)
		
	editor_bottom_panel.set_tab_hidden(editor_bottom_panel.get_tab_idx_from_control(tiles_merged_editor_dock), false)
	tiles_merged_editor_dock.visible = true

	tile_set_editor_dock.reparent(tiles_merged_editor_dock.get_child(0))
	tile_set_editor_dock.visible = true
	tile_set_editor_dock.get_parent().move_child(tile_set_editor_dock, 0)

	tile_map_layer_editor_dock.reparent(tiles_merged_editor_dock.get_child(0))
	tile_map_layer_editor_dock.visible = inspector.get_edited_object() is TileMapLayer

func tile_set_item_list_selected(idx: int):
	if simulate_select:
		simulate_select = false
		return
	var tile_set_item_list: ItemList = tile_set_editor_dock.find_child("*ItemList*", true, false)
	var tile_map_layer_item_list: ItemList = tile_map_layer_editor_dock.find_child("*ItemList*", true, false)
	if tile_map_layer_item_list.item_count > idx:
		simulate_select = true
		tile_map_layer_item_list.select(idx)
		tile_map_layer_item_list.item_selected.emit(idx)
		tile_map_layer_item_list.get_v_scroll_bar().value = tile_set_item_list.get_v_scroll_bar().value

func tile_map_layer_item_list_selected(idx: int):
	if simulate_select:
		simulate_select = false
		return
	var tile_set_item_list: ItemList = tile_set_editor_dock.find_child("*ItemList*", true, false)
	var tile_map_layer_item_list: ItemList = tile_map_layer_editor_dock.find_child("*ItemList*", true, false)
	if tile_set_item_list.item_count > idx:
		simulate_select = true
		tile_set_item_list.select(idx)
		tile_set_item_list.item_selected.emit(idx)
		tile_set_item_list.get_v_scroll_bar().value = tile_map_layer_item_list.get_v_scroll_bar().value