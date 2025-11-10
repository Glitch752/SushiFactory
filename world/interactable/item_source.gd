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

func move_to_held_plate():
    var plate = PlayerInventorySingleton.held_item
    assert(plate != null and plate.data.id == &"plate" and plate.can_add(item_data))

    plate.add_to_plate(item_data)
    
    SoundManager.play_sound_at(preload("res://audio/plate_interact.wav"), $InteractableContent.global_position, 0, randf_range(0.9, 1.1))

func get_interaction_data() -> InteractionData:
    var held_item = PlayerInventorySingleton.held_item_data()

    var action: InteractionAction = null
    var interactable_name = tr("{item} Source").format({ "item": item_data.item_name })
    var desc = tr("A source of %s. You can pick one up here.") % item_data.item_name.to_lower()
    if held_item == null:
        action = InteractionAction.new(tr("Pick Up {item}").format({ "item": item_data.item_name }), interact)
    elif held_item.id == &"plate" and held_item.can_add(item_data):
        action = InteractionAction.new(tr("Put %s on the plate") % held_item.item_name, move_to_held_plate, 0.25)

    return InteractionData.new(interactable_name, desc, action)
