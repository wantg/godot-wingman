@tool
extends EditorPlugin

var inspector_enhancer: InspectorEnhancer = InspectorEnhancer.new()
var scene_navigation_enhancer: SceneNavigationEnhancer = SceneNavigationEnhancer.new()
var bottom_panel_enhancer: BottomPanelEnhancer = BottomPanelEnhancer.new()

func _enter_tree() -> void:
	inspector_enhancer.perform()
	scene_navigation_enhancer.perform()
	bottom_panel_enhancer.perform(self)

func _exit_tree() -> void:
	inspector_enhancer.disable()
	scene_navigation_enhancer.disable()
	bottom_panel_enhancer.disable()
