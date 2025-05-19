@tool
extends EditorPlugin

var inspector_enhancer: InspectorEnhancer = InspectorEnhancer.new()
var editor_enhancer: EditorEnhancer = EditorEnhancer.new()
var scene_navigation_enhancer: SceneNavigationEnhancer = SceneNavigationEnhancer.new()

func _enter_tree() -> void:
	inspector_enhancer.perform()
	editor_enhancer.perform()
	scene_navigation_enhancer.perform()

func _exit_tree() -> void:
	pass
