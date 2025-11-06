# I'm too tired to write a proper explanation for this, so just know it allows us
# to manually get around some godot weirdness with inherited scenes not tracking
# translation strings properly.

# We make up a pretend .tlstrings file format that is basically CSV where each line corresponds to
# a message ID to be translated:
# [msgid, msgctxt, msgid_plural, comment] (where all items after the first are optional)

@tool
extends EditorTranslationParserPlugin

func _get_recognized_extensions() -> PackedStringArray:
    return ["tlstrings"]

## The return value should be an Array of PackedStringArrays,
## one for each extracted translatable string.
## Each entry should contain [msgid, msgctxt, msgid_plural, comment]
## This doesn't allow escaping or commas in the items, but whatever for now
func _parse_file(path: String) -> Array[PackedStringArray]:
    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        push_warning("Could not open tlstrings file: %s" % path)
        return []
    
    var msgids: Array[PackedStringArray] = []
    var prev_comment = ""

    while not file.eof_reached():
        var line = file.get_line()

        if line.begins_with("#"):
            prev_comment = line.substr(1).strip_edges()
            continue
        
        if line.is_empty():
            prev_comment = ""
            continue

        var parts = line.split(",", true, 4)
        var entry = PackedStringArray()
        
        for part in parts:
            entry.append(part.strip_edges())
        while entry.size() < 3:
            entry.append("")
        entry.append(prev_comment)

        msgids.append(entry)

        prev_comment = ""

    return msgids
