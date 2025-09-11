extends "res://world/interactable/interactable.gd"

var cooking_time_remaining = 0.0
var has_rice = false

@onready var timer = $Timer

const COOK_TIME = 30.0

func _ready():
    set_physics_process(false)
    super._ready()

func interact():
    if !has_rice:
        var rice = PlayerInventorySingleton.remove_item()
        rice.queue_free()

        has_rice = true
        cooking_time_remaining = COOK_TIME
        
        timer.start(cooking_time_remaining)
        set_physics_process(true)
    elif cooking_time_remaining == 0:
        var rice = PlayerInventorySingleton.create_item(PlayerInventorySingleton.load_item_data("cooked_rice"))
        PlayerInventorySingleton.try_grab_item(rice)
        has_rice = false
        _physics_process(0)

func _physics_process(delta):
    cooking_time_remaining = max(cooking_time_remaining - delta, 0)
    if cooking_time_remaining == 0:
        set_physics_process(false)
    
    var progress_bar: AnimatedSprite2D = $%ProgressBar
    progress_bar.visible = cooking_time_remaining > 0
    if cooking_time_remaining > 0:
        var frame_count = progress_bar.sprite_frames.get_frame_count("default");
        progress_bar.frame = int((1.0 - cooking_time_remaining / COOK_TIME) * frame_count) % frame_count
    
    var output_indicator: Sprite2D = $%OutputIndicator
    output_indicator.visible = cooking_time_remaining == 0 and has_rice



func get_interaction_data() -> InteractionData:
    var action: InteractionAction = null
    var interactable_name = "Rice Cooker"
    var desc = "A rice cooker.\n"
    if !has_rice:
        if PlayerInventorySingleton.holding_item("rice"):
            action = InteractionAction.new("Add Rice", interact)
            desc += "It's empty. Add rice to start cooking."
        else:
            desc += "It's empty."
    elif cooking_time_remaining > 0:
        desc += "It's cooking rice."
    elif cooking_time_remaining == 0:
        if !PlayerInventorySingleton.has_item():
            action = InteractionAction.new("Take Cooked Rice", interact)
            desc += "The rice is cooked and ready to take."
        else:
            desc += "The rice is cooked and ready to take."
    return InteractionData.new(interactable_name, desc, action)
