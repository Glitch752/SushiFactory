extends CanvasLayer

const window_scene = preload("res://world/interactable/computer/ComputerAppWindow.tscn")

var cascade_offset = Vector2(50, 20)
const MAXIMUM_WINDOWS = 20

func open_window(window_title: String, app_scene_instance: Node) -> void:
    var mainPanel = $%Panel

    var window = window_scene.instantiate()
    window.window_title = window_title
    window.app_scene_instance = app_scene_instance
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

    # Wait for the next frame
    await get_tree().process_frame
    
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

func _input(event):
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        # Find the topmost window that contains the mouse position and bring it to the front.

        # I tried making it so if there were any overlapping windows and now it's on the top,
        # we set the event as handled so the user doesn't accidentally click something. However,
        # this felt weird in practice, so I'm leaving it out for now.

        var mouse_pos = get_viewport().get_mouse_position()
        var windows = get_tree().get_nodes_in_group("computer_windows")
        windows.reverse() # Start from the topmost window

        for window in windows:
            if window.get_global_rect().has_point(mouse_pos):
                window.move_to_front()
                break
