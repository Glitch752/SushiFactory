extends "res://data/constructable_data.gd"

@export_group("Colors", "highlight_")
@export var highlight_existing_color: Color
@export var highlight_valid_color: Color
@export var highlight_invalid_color: Color

func get_interaction(context: SillyConstructionContext):
    var interaction = ConstructableInteraction.new()

    interaction.editor_symbol_opacity = 0.0
    
    var zone = context.highlight_zone

    if context.highlighted_tile != null:
        var editable = zone and zone.get_custom_data("editable")

        if editable:
            var remove_action = InteractionAction.new("Remove", context.remove_targeted_tile, 0.2)
            var rotate_action = InteractionAction.new("Rotate", context.rotate_targeted_tile)
            interaction.interaction = InteractionData.new("Counter", "A counter. Manual machines\nmay be placed on top of it.", rotate_action, remove_action)
            interaction.color = highlight_existing_color
        else:
            interaction.interaction = InteractionData.new("Tile", "A non-editable tile")
            interaction.color = highlight_invalid_color
    else:
        if zone and zone.get_custom_data("editable"):
            # todo: place tiles
            interaction.color = highlight_valid_color
            # placing = true
        else:
            interaction.color = highlight_invalid_color

    return interaction
