extends ConstructableData

@export var meaning: StringName = &""

func can_build(context: SillyConstructionContext) -> bool:
    return context.highlight_zone.get_custom_data("machines_buildable") and context.highlight_object == null

func get_interaction(context: SillyConstructionContext) -> Variant:
    var interaction = ConstructableInteraction.new()
    interaction.editor_symbol_meaning = meaning

    if can_build(context):
        interaction.color = context.colors.highlight_valid
        
        var place_action = InteractionAction.new("Place", context.place_symbol_at_target, 0.2)
        var rotate_action = InteractionAction.new("Rotate", context.rotate_highlight)
        interaction.interaction = InteractionData.new("Place %s" % name, "", rotate_action, place_action)
    else:
        interaction.color = context.colors.highlight_invalid
        interaction.editor_symbol_opacity = 0.5
    
    return interaction
