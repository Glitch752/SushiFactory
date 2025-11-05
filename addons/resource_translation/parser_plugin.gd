@tool
extends EditorTranslationParserPlugin

## The return value should be an Array of PackedStringArrays,
## one for each extracted translatable string.
## Each entry should contain [msgid, msgctxt, msgid_plural, comment]
func _parse_file(path: String) -> Array[PackedStringArray]:
    var res: Resource = load(path)
    if not res:
        return []

    var msgids: Array[PackedStringArray] = []
    if res is ItemData:
        var item: ItemData = res as ItemData
        msgids.append(PackedStringArray([item.item_name, "", "", "Item name for item ID %s" % item.id]))
        msgids.append(PackedStringArray([item.description, "", "", "Item description for item ID %s" % item.id]))
    
    return msgids


func _get_recognized_extensions() -> PackedStringArray:
    return ["tres"]