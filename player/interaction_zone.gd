extends Area2D

const InteractionData = preload("res://world/interactable/interactable.gd").InteractionData
const InteractionAction = preload("res://world/interactable/interactable.gd").InteractionAction

@onready var player = $".."
@onready var interaction_highlight: Sprite2D = $InteractionHighlight

@export var highlight_active_texture: Texture2D
@export var highlight_inactive_texture: Texture2D

## null if interacting with the automation map, Node2D if interacting with an Interactable
var current_interactable: Variant = null
var current_interaction_data: InteractionData = null

var automation_manager

func _ready():
    automation_manager = get_node("../../%AutomationManager")
    if automation_manager == null:
        push_error("Could not find AutomationManager node.")

func _physics_process(_delta):
    position = player.facing * 12
    
    var cell = automation_manager.get_interaction_cell(global_position)
    var automation_interact_data = automation_manager.get_interaction_data(cell)
    if automation_interact_data != null:
        current_interactable = null
        current_interaction_data = automation_interact_data
        interaction_highlight.global_position = automation_manager.get_cell_center(cell)
    elif current_interactable != null:
        current_interaction_data = current_interactable.get_interaction_data()
        interaction_highlight.global_position = current_interactable.get_node("InteractableContent").global_position
    else:
        current_interaction_data = null
    
    var active = false
    if current_interaction_data != null:
        active = current_interaction_data.primary_action != null or current_interaction_data.secondary_action != null
    interaction_highlight.texture = highlight_active_texture if active else highlight_inactive_texture
    
    interaction_highlight.visible = current_interaction_data != null
    
    LevelInterfaceSingleton.update_interactable(current_interaction_data)

func _on_area_entered(area: Area2D):
    if area.is_in_group("interact_zone"):
        current_interactable = area.get_parent().get_parent()

func _on_area_exited(area: Area2D):
    if area.is_in_group("interact_zone") and not (current_interactable is Vector2i):
        if area.get_parent().get_parent() == current_interactable:
            current_interactable = null
