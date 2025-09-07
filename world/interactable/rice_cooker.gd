extends "res://world/interactable/interactable.gd"

var cooking_time_remaining = 0.0
var has_rice = false

@onready var timer = $Timer

const COOK_TIME = 30.0

func _ready():
    set_process(false)
    super._ready()

func interact():
    if !has_rice:
        var rice = PlayerInventorySingleton.remove_item()
        rice.queue_free()

        has_rice = true
        cooking_time_remaining = COOK_TIME
        
        timer.start(cooking_time_remaining)
        set_process(true)
    elif cooking_time_remaining == 0:
        var rice = PlayerInventorySingleton.create_item(load("res://world/items/cooked_rice_item_data.tres"))
        PlayerInventorySingleton.try_grab_item(rice)
        has_rice = false
        _process(0)

func _process(delta):
    cooking_time_remaining = max(cooking_time_remaining - delta, 0)
    if cooking_time_remaining == 0:
        set_process(false)
    
    var progress_bar: AnimatedSprite2D = $ProgressBar
    progress_bar.visible = cooking_time_remaining > 0
    if cooking_time_remaining > 0:
        var frame_count = progress_bar.sprite_frames.get_frame_count("default");
        progress_bar.frame = int((1.0 - cooking_time_remaining / COOK_TIME) * frame_count) % frame_count
    
    var output_indicator: Sprite2D = $OutputIndicator
    output_indicator.visible = cooking_time_remaining == 0 and has_rice


func can_interact() -> bool:
    if !has_rice:
        return PlayerInventorySingleton.holding_item("rice")
    elif cooking_time_remaining == 0:
        return !PlayerInventorySingleton.has_item()
    return false

func get_interact_explanation():
    if !has_rice:
        return "add rice to the rice cooker"
    elif cooking_time_remaining == 0:
        return "take cooked rice from the rice cooker"
    return ""

func get_interactable_name():
    return "Rice Cooker"

func get_description():
    var extra = ""
    if has_rice:
        if cooking_time_remaining > 0:
            extra = "It's cooking rice."
        else:
            extra = "The rice is cooked and ready to take."
    else:
        extra = "It's empty."
    
    return "A rice cooker.\n" + extra
