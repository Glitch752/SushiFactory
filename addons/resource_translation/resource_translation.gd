@tool
extends EditorPlugin

var parser_plugin: EditorTranslationParserPlugin

func _enter_tree():
    parser_plugin = load("res://addons/resource_translation/parser_plugin.gd").new()
    add_translation_parser_plugin(parser_plugin)
    
    add_tool_menu_item("Resource translation: Generate POT files", generate_pot_files)

func _exit_tree():
    remove_translation_parser_plugin(parser_plugin)

    remove_tool_menu_item("Resource translation: Generate POT files")

## Recursively finds all resource paths under data/**/*.tres
func recursively_load_resources(subpath: String = "", _type_hint: String = "") -> PackedStringArray:
    var resources: PackedStringArray = []
    var dir = DirAccess.open("res://data%s" % subpath)
    if dir == null:
        push_error("Failed to open directory for subpath  %s" % subpath)
        return resources
    
    dir.list_dir_begin()
    
    var file_name = dir.get_next()
    while file_name != "":
        if dir.current_is_dir():
            # Recurse into subdirectory
            resources += recursively_load_resources("%s/%s" % [subpath, file_name.get_file()])
        else:
            if file_name.get_extension() == "tres":
                resources.append("res://data%s/%s" % [subpath, file_name])
            else:
                print("Skipping non-resource file %s" % file_name)
        
        file_name = dir.get_next()
    
    dir.list_dir_end()
    
    return resources

func generate_pot_files() -> void:
    var resources = recursively_load_resources()

    # Preserve any existing POT files that aren't under res://data and merge them with the newly discovered resources.
    var existing = ProjectSettings.get_setting("internationalization/locale/translations_pot_files", [])
    var merged: Array = []

    for p in resources:
        merged.append(p)

    for p in existing:
        if typeof(p) != TYPE_STRING:
            continue
        if p.begins_with("res://data"):
            continue
        if merged.has(p):
            continue
        merged.append(p)

    ProjectSettings.set_setting("internationalization/locale/translations_pot_files", merged)
    ProjectSettings.save()

    print_rich("[color=green]Successfully updated internationalization settings![/color]")

    var localization = EditorInterface.get_base_control().find_child("*Localization*", true, false)
    var file_dialog: EditorFileDialog = localization.get_child(5)
    file_dialog.file_selected.emit("res://localization/template.pot")

    print_rich("[color=green]Generated [b]template.pot[/b]![/color]")
