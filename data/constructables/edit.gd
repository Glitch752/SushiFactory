extends "res://data/constructable_data.gd"

func get_interaction(context: SillyConstructionContext):
    var interaction = ConstructableInteraction.new()

    interaction.editor_symbol_opacity = 0.0
    
    var zone = context.highlight_zone

    if context.highlight_object != null:
        var editable = zone and zone.get_custom_data("editable")

        if editable:
            var remove_action = InteractionAction.new("Remove", context.remove_targeted_tile, 0.2)
            var rotate_action = InteractionAction.new("Rotate", context.rotate_targeted_tile)
            interaction.interaction = InteractionData.new("Counter", "A counter. Manual machines\nmay be placed on top of it.", rotate_action, remove_action)
            interaction.color = context.colors.highlight_existing
        else:
            interaction.interaction = InteractionData.new("Tile", "A non-editable tile")
            interaction.color = context.colors.highlight_invalid
    else:
        if zone and zone.get_custom_data("editable"):
            # todo: place tiles
            interaction.color = context.colors.highlight_valid
            # placing = true
        else:
            interaction.color = context.colors.highlight_invalid

    return interaction
