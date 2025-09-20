## A variant of Camera2D that holds UI which will only be shown while the active viewport camera

extends Camera2D

class_name UiCamera2D

@onready var layer: CanvasLayer = $CanvasLayer

func activate_camera():
    var active_camera = get_viewport().get_camera_2d()
    if active_camera is UiCamera2D:
        active_camera.deactivate_camera()
    
    enabled = true
    _update_visibility()

func deactivate_camera():
    enabled = false
    _update_visibility()

func _ready():
    _update_visibility()

func _update_visibility():
    layer.visible = enabled
