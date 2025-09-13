extends Node

var playback: AudioStreamPlaybackPolyphonic

func _enter_tree() -> void:
    get_tree().node_added.connect(_on_node_added)

func _ready() -> void:
    var player: AudioStreamPlayer = $AudioStreamPlayer

    var stream = AudioStreamPolyphonic.new()
    stream.polyphony = 32
    
    player.stream = stream
    player.play()
    
    playback = player.get_stream_playback()

func _on_node_added(node: Node) -> void:
    if node is Button:
        node.mouse_entered.connect(play_mouse_enter)
        #node.mouse_exited.connect(mouse_exit)
        node.button_down.connect(play_button_down)
        node.button_up.connect(play_button_up)

func play_mouse_enter() -> void:
    playback.play_stream(preload('res://audio/kenney_ui-audio/click3.ogg'), 0, -8.0, randf_range(0.9, 1.1))

#func mouse_exit() -> void:
    #playback.play_stream(preload('res://audio/kenney_ui-audio/click3.ogg'), 0, -8.0, randf_range(1.1, 1.3))

func play_pressed() -> void:
    play_button_down()

func play_button_down() -> void:
    playback.play_stream(preload('res://audio/kenney_ui-audio/click1.ogg'), 0.3, -5.0, randf_range(0.9, 1.1))

func play_button_up() -> void:
    playback.play_stream(preload('res://audio/kenney_ui-audio/click1.ogg'), 0.3, -5.0, randf_range(1.1, 1.3))
