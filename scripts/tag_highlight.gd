extends Node

const ITEM_COLOR = Color(0.5, 0.9, 0.5) # Light green
const RAW_ITEM_COLOR = Color(0.9, 0.5, 0.9) # Light purple
const MACHINE_COLOR = Color(1.0, 0.7, 0.5) # Light orange

var tagRegex = RegEx.new()

func _ready():
    # We love regex backreferences (and neglecting the performance problems thereof) :D
    if tagRegex.compile("\\[(item|machine)\\](.*?)\\[\\/\\1\\]") != OK:
        push_error("Failed to compile item regex")

func capitalize_item_name(item_name: String, capitalize: bool) -> String:
    if capitalize and item_name.length() > 0:
        return item_name.substr(0, 1).to_upper() + item_name.substr(1)
    return item_name.to_lower()

## Formats an item's name with its associated color in BBCode tags.
func format_item_color(item: ItemData, capitalize: bool) -> String:
    var item_dish = DishCombinationsSingleton.get_dish_by_result_id(item.id)
    if item_dish != null:
        return "[color=#" + ITEM_COLOR.to_html(false) + "]" + capitalize_item_name(item.item_name, capitalize) + "[/color]"
    else:
        return "[color=#" + RAW_ITEM_COLOR.to_html(false) + "]" + capitalize_item_name(item.item_name, capitalize) + "[/color]"

func is_capitalized(text: String) -> bool:
    if text.length() == 0:
        return false
    return text[0].to_upper() == text[0]

## Converts custom item, raw item, and machine tags to have proper BBCode formatting.
## Input tags should be in the form `[item]item_id[/item]`.
## If the item ID is capitalized, the output item name will be capitalized. e.g. `[item]tamago[/item]` -> "tamago", `[item]Tamago[/item]` -> "Tamago"
func convert_custom_tags(text: String) -> String:
    var result = text

    var tag_matches = tagRegex.search_all(result)
    for match in tag_matches:
        var full_match = match.get_string(0)
        var tag_type = match.get_string(1)

        match tag_type:
            "item":
                var item_id = match.get_string(2)
                var item_data = PlayerInventorySingleton.load_item_data(item_id.to_lower())
                if item_data != null:
                    var colored_name = format_item_color(item_data, is_capitalized(item_id))
                    result = result.replace(full_match, colored_name)
                else:
                    result = result.replace(full_match, "[color=#ff5555]Unknown item %s[/color]" % item_id)
            "machine":
                var machine_id = match.get_string(2)
                # TODO: load machine data
                # for now, we just color it
                result = result.replace(full_match, "[color=#" + MACHINE_COLOR.to_html(false) + "]" + machine_id + "[/color]")

    return result