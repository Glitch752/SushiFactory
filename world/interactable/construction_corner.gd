extends "res://world/interactable/interactable.gd"

@export var construction_view: Node2D 

func open_construction_view():
    construction_view.show_view()

func get_interaction_data() -> InteractionData:
    return InteractionData.new(
        tr("Construction Tools"),
        tr("The tools required to renovate your restaurant space!\nInteract to enter editing mode."),
        InteractionAction.new(tr("Open editing mode"), open_construction_view)
    )
