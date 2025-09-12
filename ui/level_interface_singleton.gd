extends Node

const InteractionData = preload("res://world/interactable/interactable.gd").InteractionData

signal interaction_data_changed(data: InteractionData)

signal notify_day_started_ui(new_day: int)
signal notify_store_open_ui()
signal notify_store_closing_ui()

func update_interactable(node: InteractionData):
    interaction_data_changed.emit(node)

func clear_interactable():
    interaction_data_changed.emit(null)

func notify_day_started(day: int):
    notify_day_started_ui.emit(day)

func notify_store_open():
    notify_store_open_ui.emit()

func notify_store_closing():
    notify_store_closing_ui.emit()