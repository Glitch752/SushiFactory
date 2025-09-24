extends Area2D

const InteractionData = preload("res://world/interactable/interactable.gd").InteractionData
const InteractionAction = preload("res://world/interactable/interactable.gd").InteractionAction

@onready var player = $".."
@onready var interaction_highlight: Node2D = $InteractionHighlight

@export var highlight_active_color: Color
@export var highlight_inactive_color: Color

## null if interacting with the automation map, Node2D if interacting with an Interactable
var current_interactable: Variant = null
var current_interaction_data: InteractionData = null

var automation_manager = null

func _ready():
    automation_manager = get_node("../../%AutomationManager")
    if automation_manager == null:
        push_error("Could not find AutomationManager node.")

func _physics_process(_delta):
    if not InputTargetSingleton.is_active(InputTargetSingleton.InputTarget.PlayerMovement):
        return

    position = player.facing * 12
    
    var cell = automation_manager.get_interaction_cell(global_position)
    var automation_interact_data = automation_manager.get_interaction_data(cell)
    if automation_interact_data != null:
        current_interactable = null
        current_interaction_data = automation_interact_data
        interaction_highlight.interp_to(automation_manager.get_cell_center(cell))
        interaction_highlight.size = automation_manager.cell_size()
    elif current_interactable != null:
        current_interaction_data = current_interactable.get_interaction_data()
        var content = current_interactable.get_node("InteractableContent")
        interaction_highlight.interp_to(content.global_position)
        interaction_highlight.size = content.size
    else:
        current_interaction_data = null
        interaction_highlight.interp_to(null)
    
    var active = false
    if current_interaction_data != null:
        active = current_interaction_data.primary_action != null or current_interaction_data.secondary_action != null
    interaction_highlight.color_target = highlight_active_color if active else highlight_inactive_color
    
    InteractionSingleton.update_interactable(current_interaction_data)

func _on_area_entered(area: Area2D):
    if area.is_in_group("interact_zone"):
        current_interactable = area.get_parent().get_parent()

func _on_area_exited(area: Area2D):
    if area.is_in_group("interact_zone") and not (current_interactable is Vector2i):
        if area.get_parent().get_parent() == current_interactable:
            current_interactable = null
