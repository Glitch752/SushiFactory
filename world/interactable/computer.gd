extends "res://world/interactable/interactable.gd"

var ComputerDesktopScene = preload("res://world/interactable/computer/ComputerDesktop.tscn")

@onready var timeScaleTween = create_tween()

var computer_ui_open: bool = false:
    set(value):
        computer_ui_open = value
        # From the Godot documentation:
        # `Note: It's recommended to keep this property above 0.0, as the game may behave unexpectedly otherwise.`
        # I originally set this to 0, but it does in fact create some weird issues.
        # Therefore, we run the game at 10% speed when in the computer to give players a bit of a pause.

        timeScaleTween.kill()
        timeScaleTween = create_tween()
        timeScaleTween.tween_property(Engine, "time_scale", 0.1 if value else 1.0, 0.25 if value else 0.05)

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


func get_interaction_data() -> InteractionData:
    var action: InteractionAction = null
    var interactable_name = "Computer"
    var desc = "A computer used to manage your restaurant,\norder supplies, and communicate with your boss."
    if not computer_ui_open:
        action = InteractionAction.new("Use Computer", interact)
    return InteractionData.new(interactable_name, desc, action)
