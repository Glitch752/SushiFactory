extends Node2D

class InteractionAction:
    var name: String
    var callable: Callable
    ## The time it takes to complete this interaction, or 0 if instant.
    var time_required: float

    @warning_ignore("shadowed_variable")
    func _init(name: String, callable: Callable, time_required: float = 0.0):
        self.name = name
        self.callable = callable
        self.time_required = time_required

class InteractionData:
    ## The name of the interactable (e.g. "Rice Cooker", "Belt", etc)
    var name: String
    ## A short description of the interactable (e.g. "A rice cooker that makes rice"). Supports rich text/BBCode.
    var description: String
    
    ## The primary interaction action, or null if there is none.
    var primary_action: InteractionAction
    ## The secondary interaction action, or null if there is none.
    var secondary_action: InteractionAction

    @warning_ignore("shadowed_variable")
    func _init(name: String, description: String, primary_action: InteractionAction = null, secondary_action: InteractionAction = null):
        self.name = name
        self.description = description
        self.primary_action = primary_action
        self.secondary_action = secondary_action

func _ready():
    $InteractableContent/Area2D.add_to_group("interact_zone")

func get_interaction_data() -> InteractionData:
    push_error("get_interaction_data() not implemented for this interactable.")
    return InteractionData.new("Unknown", "This interactable has no interaction data.")
