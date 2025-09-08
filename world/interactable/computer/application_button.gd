extends Button

@export var app_scene: PackedScene
@export var window_title: String

func _pressed():
    find_parent("ComputerDesktop").open_window(window_title, app_scene.instantiate())
