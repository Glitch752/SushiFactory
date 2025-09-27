extends Node

@export var show_bind_hints: bool = true:
    set(val):
        show_bind_hints = val
        save_to_config()

func _ready():
    load_from_config()

func load_from_config():
    var config = ConfigFile.new()
    var err = config.load("user://audio_settings.cfg")
    if err != OK:
        return
    
    for bus in AudioServer.bus_count:
        var volume = config.get_value("volumes", AudioServer.get_bus_name(bus), 0)
        AudioServer.set_bus_volume_db(bus, volume)

func save_to_config():
    var config = ConfigFile.new()
    var err = config.load("user://audio_settings.cfg")
    if err != OK and err != ERR_FILE_NOT_FOUND:
        push_error("Failed to load audio settings config for saving: %s" % err)
        return
    
    for bus in AudioServer.bus_count:
        var volume = AudioServer.get_bus_volume_db(bus)
        config.set_value("volumes", AudioServer.get_bus_name(bus), volume)
    
    err = config.save("user://audio_settings.cfg")
    if err != OK:
        push_error("Failed to save audio settings config: %s" % err)
