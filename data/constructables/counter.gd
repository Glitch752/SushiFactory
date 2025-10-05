extends "res://data/constructables/generic.gd"

func can_build(context: SillyConstructionContext) -> bool:
    var counter_check = context.get_object_relative.call(Vector2i.DOWN)
    return (
        context.highlight_zone.get_custom_data("counters_buildable") and
        context.highlight_object == null and
        not (counter_check and counter_check.get_custom_data("meaning") != &"counter")
    )
