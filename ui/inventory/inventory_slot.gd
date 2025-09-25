@tool

extends PanelContainer

const SELECTED_PANEL = preload("res://ui/stylebox/9_patch_stylebox.tres")
const UNSELECTED_PANEL = preload("res://ui/stylebox/9_patch_stylebox_hover.tres")

@export var selected: bool:
    set(val):
        selected = val
        _update_panel()

@export var item: Node2D:
    set(val):
        item = val
        _update_item()

func _update_panel():
    add_theme_stylebox_override("panel", SELECTED_PANEL if selected else UNSELECTED_PANEL)

func _update_item():
    if item:
        $%ItemTexture.visible = true
        $%ItemTexture.texture = item.data.item_sprite
        # $%ItemDescriptionLabel.text = item.get_description()
    else:
        $%ItemTexture.visible = false
        # $ItemDescription.visible = false
