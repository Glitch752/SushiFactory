extends Node

var playback: AudioStreamPlaybackPolyphonic

@onready var sliderDebounce: Timer = $SliderDebounce
@onready var saveVolumeDebounce: Timer = $SaveVolumeDebounce

func _enter_tree() -> void:
    get_tree().node_added.connect(_on_node_added)
    
    _load_volumes_from_config()

func _ready() -> void:
    var player: AudioStreamPlayer = $AudioStreamPlayer

    var stream = AudioStreamPolyphonic.new()
    stream.polyphony = 32
    
    player.stream = stream
    player.play()
    
    playback = player.get_stream_playback()
    
    saveVolumeDebounce.timeout.connect(_save_volumes_to_config)

func _load_volumes_from_config():
    var config = ConfigFile.new()
    var err = config.load("user://audio_settings.cfg")
    if err != OK:
        return
    
    for bus in AudioServer.bus_count:
        var volume = config.get_value("volumes", AudioServer.get_bus_name(bus), 0)
        AudioServer.set_bus_volume_db(bus, volume)

func _save_volumes_to_config():
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

func bus_volume_updated():
    saveVolumeDebounce.start()

class ValContainer:
    var val
    func _init(v):
        val = v

func _on_node_added(node: Node) -> void:
    if node is Button:
        node.mouse_entered.connect(play_mouse_enter)
        #node.mouse_exited.connect(mouse_exit)
        node.button_down.connect(play_button_down)
        node.button_up.connect(play_button_up)
    elif node is Slider:
        node.mouse_entered.connect(play_mouse_enter)
        
        var previous_value = ValContainer.new(node.value)
        node.value_changed.connect(func(v):
            if not sliderDebounce.is_stopped():
                return
            if abs(v - previous_value.val) < 0.02:
                return
            
            previous_value.val = v
            play_pressed()
            sliderDebounce.start()
        )

func play_mouse_enter() -> void:
    playback.play_stream(preload('res://audio/kenney_ui-audio/click3.ogg'), 0, -8.0, randf_range(0.9, 1.1))

#func mouse_exit() -> void:
    #playback.play_stream(preload('res://audio/kenney_ui-audio/click3.ogg'), 0, -8.0, randf_range(1.1, 1.3))

func play_pressed() -> void:
    play_button_down()

func play_button_down() -> void:
    playback.play_stream(preload('res://audio/kenney_ui-audio/click1.ogg'), 0, -5.0, randf_range(0.9, 1.1))

func play_button_up() -> void:
    playback.play_stream(preload('res://audio/kenney_ui-audio/click1.ogg'), 0, -5.0, randf_range(1.1, 1.3))
