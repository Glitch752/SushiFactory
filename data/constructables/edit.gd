extends "res://data/constructable_data.gd"

func get_interaction(context: SillyConstructionContext):
    var interaction = ConstructableInteraction.new()

    interaction.editor_symbol_opacity = 0.0
    
    var zone = context.highlight_zone

    if context.highlight_object != null:
        var editable = zone and zone.get_custom_data("editable")

        var highlightMeaning = context.highlight_object.get_custom_data("meaning")
        var constructable = DataLoader.get_constructable_with_meaning(highlightMeaning)

        if editable:
            var remove_action = InteractionAction.new("Remove", context.remove_targeted_tile, 0.2)
            var rotate_action = InteractionAction.new("Rotate", context.rotate_targeted_tile)
            interaction.interaction = InteractionData.new(constructable.name, constructable.description, rotate_action, remove_action)
            interaction.color = context.colors.highlight_existing
        else:
            interaction.interaction = InteractionData.new(constructable.name, "%s\n\n[color=#f77]This tile isn't editable.[/color]" % constructable.description)
            interaction.color = context.colors.highlight_invalid
    else:
        if zone and zone.get_custom_data("editable"):
            # todo: place tiles
            interaction.color = context.colors.highlight_valid
            # placing = true
        else:
            interaction.color = context.colors.highlight_invalid

    return interaction
