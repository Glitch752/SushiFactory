extends ConstructableData

@export var meaning: StringName = &""

func can_build(context: SillyConstructionContext) -> bool:
    var counter_check = context.get_object_relative.call(Vector2i.UP)
    return (
        context.highlight_zone.get_custom_data("machines_buildable") and
        context.highlight_object == null and
        not (counter_check and counter_check.get_custom_data("meaning") == &"counter")
    )
func can_overwrite(context: SillyConstructionContext) -> bool:
    return context.highlight_object and context.highlight_object.get_custom_data("meaning") == meaning

func get_interaction(context: SillyConstructionContext) -> Variant:
    var interaction = ConstructableInteraction.new()
    interaction.editor_symbol_meaning = meaning

    if can_overwrite(context):
        interaction.color = context.colors.highlight_existing

        var place_action = InteractionAction.new(tr("Overwrite", "Overwrite the highlighted tile"), context.place_symbol_at_target, 0.2)
        var rotate_action = InteractionAction.new(tr("Rotate", "Rotate the highlighted constructable"), context.rotate_highlight)
        interaction.interaction = InteractionData.new(tr("Place %s", "Build the constructable %s") % name, "", rotate_action, place_action)
    elif can_build(context):
        interaction.color = context.colors.highlight_valid
        
        var place_action = InteractionAction.new(tr("Place", "Build a constructable"), context.place_symbol_at_target, 0.2)
        var rotate_action = InteractionAction.new(tr("Rotate", "Rotate the highlighted constructable"), context.rotate_highlight)
        interaction.interaction = InteractionData.new(tr("Place %s", "Build the constructable %s") % name, "", rotate_action, place_action)
    else:
        interaction.color = context.colors.highlight_invalid
        interaction.editor_symbol_opacity = 0.5
    
    return interaction
