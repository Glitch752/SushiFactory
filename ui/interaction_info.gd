extends PanelContainer

const InteractionData = preload("res://world/interactable/interactable.gd").InteractionData

var data: InteractionData:
    set(value):
        data = value
        _update()

func _ready():
    visible = false

func _update():
    if data != null:
        visible = true

        $%InteractionName.text = data.name
        $%InteractionDescription.text = data.description
        
        $%PrimaryInteract.update(data.primary_action)
        $%SecondaryInteract.update(data.secondary_action)
    else:
        visible = false
