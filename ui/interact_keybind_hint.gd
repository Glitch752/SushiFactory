@tool

extends StackContainer

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

func _ready():
    update_defaults()

func update_defaults():
    $%KeyLabel.text = key
    $%InfoText.text = placeholderText
    $%TimedInteractProgress.visible = false

    if not Engine.is_editor_hint():
        visible = false

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
        progress.value = ease(action.current_time / action.time_required, 0.5)
    else:
        progress.visible = false
