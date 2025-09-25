@tool

extends PanelContainer

const SELECTED_PANEL = preload("res://ui/stylebox/9_patch_stylebox.tres")
const UNSELECTED_PANEL = preload("res://ui/stylebox/9_patch_stylebox_hover.tres")

@export var selected: bool:
    set(val):
        selected = val
        _update_panel()

@export var texture: Texture2D:
    set(value):
        texture = value
        _update_texture()

func _update_panel():
    add_theme_stylebox_override("panel", SELECTED_PANEL if selected else UNSELECTED_PANEL)

func _ready():
    _update_texture()

func _update_texture():
    $%TextureRect.texture = texture
