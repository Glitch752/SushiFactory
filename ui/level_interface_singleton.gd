extends Node

const InteractionData = preload("res://world/interactable/interactable.gd").InteractionData

signal interaction_data_changed(data: InteractionData)

func update_interactable(node: InteractionData):
    interaction_data_changed.emit(node)

func clear_interactable():
    interaction_data_changed.emit(null)