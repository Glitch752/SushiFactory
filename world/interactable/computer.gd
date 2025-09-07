extends "res://world/interactable/interactable.gd"

var ComputerDesktopScene = preload("res://world/interactable/computer/ComputerDesktop.tscn")

var computer_ui_open = false

func _ready():
    EmailSystem.unread_status_changed.connect(update_info_indicator)
    update_info_indicator()
    
    super._ready()

func update_info_indicator():
    if EmailSystem.has_unread_emails:
        $%InfoIndicator.visible = true
    else:
        $%InfoIndicator.visible = false

func interact():
    if computer_ui_open:
        return
    
    # Open the computer desktop UI
    var desktop = get_tree().current_scene.get_node_or_null("ComputerDesktop")

    if not desktop:
        desktop = ComputerDesktopScene.instantiate()
        get_tree().current_scene.add_child(desktop)
    else:
        desktop.visible = true
    
    computer_ui_open = true

func _unhandled_key_input(event):
    if computer_ui_open and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        var desktop = get_tree().current_scene.get_node_or_null("ComputerDesktop")
        if desktop:
            desktop.visible = false
        computer_ui_open = false

# While the ui is open, if the user clicks outside of it, close the ui
func _input(event):
    if computer_ui_open and event is InputEventMouseButton and event.pressed:
        var desktop = get_tree().current_scene.get_node_or_null("ComputerDesktop")
        if not desktop:
            return
        
        var panel = desktop.get_node_or_null("%Panel")
        if panel and not panel.get_global_rect().has_point(event.position):
            desktop.visible = false
            computer_ui_open = false

func can_interact() -> bool:
    return not computer_ui_open

func get_interact_explanation():
    return "use the computer"

func get_interactable_name():
    return "Computer"

func get_description():
    return "A computer used to manage your restaurant,\norder supplies, and communicate with your boss."
