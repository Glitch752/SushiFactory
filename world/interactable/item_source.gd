@tool
extends "res://world/interactable/interactable.gd"

@export var texture: Texture2D:
    set(value):
        texture = value
        if has_node("InteractableContent/Sprite2D"):
            $InteractableContent/Sprite2D.texture = texture

@export var item_data: ItemData;

@onready var interact_audio = $%InteractAudio

func _ready():
    $InteractableContent/Sprite2D.texture = texture
    if not Engine.is_editor_hint():
        super._ready()

func interact():
    var item = PlayerInventorySingleton.create_item(item_data)
    add_child(item) # For sound positioning
    PlayerInventorySingleton.try_grab_item(item)
    
    interact_audio.pitch_scale = randf_range(0.8, 1.1)
    interact_audio.play()

func get_interaction_data() -> InteractionData:
    var action: InteractionAction = null
    var interactable_name = tr("{item} Source").format({ "item": item_data.item_name })
    var desc = tr("A source of %s. You can pick one up here.") % item_data.item_name.to_lower()
    if !PlayerInventorySingleton.has_item():
        action = InteractionAction.new(tr("Pick Up {item}").format({ "item": item_data.item_name }), interact)
    return InteractionData.new(interactable_name, desc, action)
