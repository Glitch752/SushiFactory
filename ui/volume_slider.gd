@tool

extends VBoxContainer

enum AudioBus {}
@warning_ignore("enum_variable_without_default")
@export var bus: AudioBus

@onready var slider = $Slider
@onready var label = $Label

func _ready():
    var volume = AudioServer.get_bus_volume_linear(bus)
    update_label(volume)
    
    if not Engine.is_editor_hint():
        slider.value = volume
    
    slider.value_changed.connect(update_volume)

func update_volume(value: float):
    AudioServer.set_bus_volume_linear(bus, value)
    SoundManager.bus_volume_updated()
    update_label(value)

func update_label(volume: float):
    label.text = "%s volume: %d%%" % [AudioServer.get_bus_name(bus), int(round(volume * 100))]

func _validate_property(property: Dictionary):
    if property.name == "bus":
        var busNumber = AudioServer.bus_count
        var options = ""
        for i in busNumber:
            if i > 0:
                options += ","
            var busName = AudioServer.get_bus_name(i)
            options += busName
        property.hint_string = options
