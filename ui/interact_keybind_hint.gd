@tool

extends StackContainer

# TODO: Make this dynamic based on what device is currently connected

const InteractionAction = preload("res://world/interactable/interactable.gd").InteractionAction

@export var key: String = "Q":
    set(val):
        key = val
        update_defaults()
@export var placeholderText: String = "Secondary interact":
    set(val):
        placeholderText = val
        update_defaults()

@onready var keyLabel: Label = $%KeyLabel
@onready var infoText: Label = $%InfoText
@onready var progress: ProgressBar = $%TimedInteractProgress

@export var direction: LayoutDirection = LayoutDirection.LAYOUT_DIRECTION_LTR:
    set(val):
        direction = val
        update_defaults()

## If this hint isn't necessary, it won't be shown when hints are disabled in the pause menu.
@export var is_necessary: bool = true

func _ready():
    update_defaults()

func update_defaults():
    $%KeyLabel.text = key
    $%InfoText.text = placeholderText
    $%TimedInteractProgress.visible = false
    
    $%Layout.layout_direction = direction

func update(action: InteractionAction):
    if action == null:
        visible = false
        progress.visible = false
        return
    
    visible = true
    
    var nameText = action.name
    if action.time_required > 0.0:
        nameText += " (%.1fs)" % (action.time_required - action.current_time)
    infoText.text = nameText
    
    if action.time_required > 0.0:
        progress.visible = true
        progress.value = ease(action.current_time / action.time_required, -1.2)
    else:
        progress.visible = false
