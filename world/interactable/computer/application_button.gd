extends Button

const window_scene = preload("res://world/interactable/computer/ComputerAppWindow.tscn")
@export var app_scene: PackedScene
@export var window_title: String

var cascade_offset = Vector2(20, 20)

const MAXIMUM_WINDOWS = 20

func _pressed():
    var mainPanel = $%Panel

    var window = window_scene.instantiate()
    window.window_title = window_title
    window.app_scene = app_scene
    window.add_to_group("computer_windows")

    mainPanel.add_child(window)

    if get_tree().get_node_count_in_group("computer_windows") > MAXIMUM_WINDOWS:
        var oldest_window = get_tree().get_nodes_in_group("computer_windows")[0] # get_first_node_in_group just... doesn't work?
        if oldest_window:
            oldest_window.queue_free()

    window.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, 0)
    var start_pos = window.position
    window.position += cascade_offset
    cascade_offset += Vector2(50, 50)
    
    var prev_pos = window.position
    window.clamp_pos()

    if window.position != prev_pos:
        cascade_offset.x -= cascade_offset.y - 100
        cascade_offset.y = 20
        window.position = start_pos + cascade_offset
        cascade_offset += Vector2(50, 50)
        
        prev_pos = window.position
        window.clamp_pos()
        
        if window.position != prev_pos:
            cascade_offset = Vector2(20, 20)
