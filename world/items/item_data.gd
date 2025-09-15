extends Resource

class_name ItemData

## The ID of this item. Used only internally for things like recipes.
@export var id: StringName
## The player-visible name of this item.
@export var item_name: String
## The sprite used for this item, both in the world and UI.
@export var item_sprite: Texture2D
## The description of this item.
@export var description: String = ""

## A custom scene to use for this item instead of the base Item scene. Null if not required.
@export var custom_scene: PackedScene = null