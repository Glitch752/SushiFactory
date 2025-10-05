extends Resource

class_name ConstructableData

const InteractionData = preload("res://world/interactable/interactable.gd").InteractionData
const InteractionAction = preload("res://world/interactable/interactable.gd").InteractionAction

class ConstructableInteraction:
    var editor_symbol_opacity: float = 1.0
    var editor_symbol_meaning: StringName = &""

    var color: Color = Color(1, 1, 1, 0)
    var interaction: InteractionData = null

    static func none():
        return ConstructableInteraction.new()

@export var id: StringName

@export var name: String
@export_multiline var description: String

@export var texture: Texture2D

## Higher priority
@export var priority: int = 0

class SillyConstructionContext:
    var rotate_targeted_tile: Callable
    var remove_targeted_tile: Callable
    var rotate_highlight: Callable
    var place_symbol_at_target: Callable

    var highlight_object: TileData
    var highlight_zone: TileData

    var colors: ConstructionColors

func get_interaction(_context: SillyConstructionContext) -> Variant:
    return ConstructableInteraction.none()
