extends PanelContainer

@export var window_title: String
@export var app_scene: PackedScene
var dragging = false

func _ready():
    $%WindowTitle.text = window_title
    $OuterContainer.add_child(app_scene.instantiate())

func _on_close_button_pressed():
    queue_free()


func _on_window_titlebar_gui_input(event):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT:
            dragging = event.pressed
            if dragging:
                get_viewport().set_input_as_handled()
                # Move ourself to the front
                get_parent().move_child(self, get_parent().get_child_count() - 1)
    elif event is InputEventMouseMotion and dragging:
        global_position += event.relative
        
        # Clamp to our parent's bounds
        clamp_pos()

func clamp_pos():
    var parent_rect = get_parent().get_global_rect()
    global_position.x = clamp(global_position.x, parent_rect.position.x, parent_rect.position.x + parent_rect.size.x - size.x)
    global_position.y = clamp(global_position.y, parent_rect.position.y, parent_rect.position.y + parent_rect.size.y - size.y)
