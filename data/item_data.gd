extends Resource

class_name ItemData

## The ID of this item. Should be lowercase because capitalization is used for formatting.
@export var id: StringName
## The player-visible name of this item.
@export var item_name: String:
    get:
        return tr(item_name)
## The sprite used for this item, both in the world and UI.
@export var item_sprite: Texture2D
## The description of this item.
@export_multiline var description: String = "":
    get:
        return tr(description)

## A custom scene to use for this item instead of the base Item scene. Null if not required.
@export var custom_scene: PackedScene = null

func validate():
    if id == "":
        push_error("ItemData %s must have a non-empty ID" % resource_path)
    if item_name == "":
        push_error("ItemData %s must have a non-empty name" % resource_path)
    if item_sprite == null:
        push_error("ItemData %s must have a sprite" % resource_path)