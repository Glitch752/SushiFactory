extends Node

const InteractionData = preload("res://world/interactable/interactable.gd").InteractionData
const InteractionAction = preload("res://world/interactable/interactable.gd").InteractionAction

signal interaction_data_changed(data: InteractionData)

var current_interaction_data: InteractionData = null
var waiting_primary_action: InteractionAction = null
var waiting_secondary_action: InteractionAction = null

func _unhandled_input(event):
    if current_interaction_data == null:
        return
    
    var primary_action = current_interaction_data.primary_action
    var secondary_action = current_interaction_data.secondary_action

    if event.is_action_pressed("interact") and primary_action != null:
        if primary_action.time_required == 0.0:
            primary_action.callable.call()
        else:
            waiting_primary_action = primary_action
            waiting_primary_action.current_time = 0.0
    elif event.is_action_pressed("secondary_interact") and secondary_action != null:
        if secondary_action.time_required == 0.0:
            secondary_action.callable.call()
        else:
            waiting_secondary_action = secondary_action
            waiting_secondary_action.current_time = 0.0
    
    elif event.is_action_released("interact") and waiting_primary_action != null:
        waiting_primary_action.current_time = 0.0
        waiting_primary_action = null
    elif event.is_action_released("secondary_interact") and waiting_secondary_action != null:
        waiting_secondary_action.current_time = 0.0
        waiting_secondary_action = null

func _physics_process(delta):
    if abs(Engine.time_scale) < 0.001:
        return
    delta = delta / Engine.time_scale

    if waiting_primary_action != null:
        waiting_primary_action.current_time += delta
        if waiting_primary_action.current_time >= waiting_primary_action.time_required:
            waiting_primary_action.callable.call()
            waiting_primary_action = null
    if waiting_secondary_action != null:
        waiting_secondary_action.current_time += delta
        if waiting_secondary_action.current_time >= waiting_secondary_action.time_required:
            waiting_secondary_action.callable.call()
            waiting_secondary_action = null

func update_interactable(data: InteractionData):
    if data == null:
        clear_interactable()
        return

    if waiting_primary_action != null:
        data.primary_action = waiting_primary_action
    if waiting_secondary_action != null:
        data.secondary_action = waiting_secondary_action

    current_interaction_data = data
    interaction_data_changed.emit(data)

func clear_interactable():
    waiting_primary_action = null
    waiting_secondary_action = null
    current_interaction_data = null
    interaction_data_changed.emit(null)
