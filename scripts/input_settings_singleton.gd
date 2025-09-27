extends Node

signal settings_changed()

@export var show_bind_hints: bool = true:
    set(val):
        show_bind_hints = val
        save_to_config()

func _ready():
    load_from_config()

func load_from_config():
    var config = ConfigFile.new()
    var err = config.load("user://input_settings.cfg")
    if err != OK:
        return
    
    show_bind_hints = config.get_value("settings", "show_bind_hints", true)

func save_to_config():
    var config = ConfigFile.new()
    var err = config.load("user://input_settings.cfg")
    if err != OK and err != ERR_FILE_NOT_FOUND:
        push_error("Failed to load audio settings config for saving: %s" % err)
        return
    
    config.set_value("settings", "show_bind_hints", show_bind_hints)

    err = config.save("user://input_settings.cfg")
    if err != OK:
        push_error("Failed to save audio settings config: %s" % err)

    settings_changed.emit()
