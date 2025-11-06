@tool
extends EditorTranslationParserPlugin

## The return value should be an Array of PackedStringArrays,
## one for each extracted translatable string.
## Each entry should contain [msgid, msgctxt, msgid_plural, comment]
func _parse_file(path: String) -> Array[PackedStringArray]:
    var res: Resource = load(path)
    if not res:
        push_warning("Resource not found: %s" % path)
        return []

    var msgids: Array[PackedStringArray] = []
    if res is ItemData:
        var item: ItemData = res as ItemData
        msgids.append(PackedStringArray([item.item_name, "", "", "Item name for %s" % str(item.id)]))
        msgids.append(PackedStringArray([item.description, "", "", "Item description for %s" % str(item.id)]))
    elif res is RecipeData:
        var recipe: RecipeData = res as RecipeData
        msgids.append(PackedStringArray([recipe.recipe_information, "", "", "Recipe information for recipe %s" % recipe.result.item_name]))
    elif res is ConstructableData:
        var machine: ConstructableData = res as ConstructableData
        msgids.append(PackedStringArray([machine.name, "", "", "Machine name for %s" % str(machine.id)]))
        msgids.append(PackedStringArray([machine.description, "", "", "Machine description for %s" % str(machine.id)]))
    elif res is MachineData:
        var machine_data: MachineData = res as MachineData
        msgids.append(PackedStringArray([machine_data.machine_name, "", "", "Machine name for %s" % str(machine_data.id)]))
    elif res is EmailSendData:
        var email_data: EmailSendData = res as EmailSendData
        msgids.append(PackedStringArray([email_data.sender, "", "", "Email sender for email \"%s\"" % email_data.subject]))
        msgids.append(PackedStringArray([email_data.subject, "", "", "Email subject for email \"%s\"" % email_data.subject]))
        msgids.append(PackedStringArray([email_data.body, "", "", "Email body for email for email \"%s\"" % email_data.subject]))
    elif res is OrderPossibilities:
        var order_data: OrderPossibilities = res as OrderPossibilities
        msgids.append(PackedStringArray([order_data.name, "", "", "Name for order possibilities \"%s\"" % order_data.name]))
    else:
        # Unknown
        push_warning("Unknown resource type %s for translation parsing: %s" % [
            res.get_script().resource_path, path
        ])

    return msgids


func _get_recognized_extensions() -> PackedStringArray:
    return ["tres"]
