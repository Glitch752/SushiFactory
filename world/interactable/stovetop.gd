extends "res://world/interactable/interactable.gd"

var cooking_time_remaining = 0.0
var input_item_id = null
var current_output: ItemData = null

@onready var timer = $Timer

const COOK_TIME = 20.0

var recipes: Dictionary # input item id -> output item id

func _ready():
    recipes = DishCombinationsSingleton.get_single_input_dishes_for("frying_pan")
    set_process(false)
    super._ready()

func interact():
    if input_item_id == null:
        var held_item = PlayerInventorySingleton.remove_item()
        if held_item == null:
            return
        
        var item_id = held_item.item_data.resource_path
        if not recipes.has(item_id):
            # Not a valid recipe, return item to inventory
            PlayerInventorySingleton.try_grab_item(held_item)
            return
        
        input_item_id = item_id
        current_output = PlayerInventorySingleton.load_item_data(recipes[item_id])

        held_item.queue_free()
        cooking_time_remaining = COOK_TIME
        timer.start(cooking_time_remaining)
        set_process(true)
    
    elif cooking_time_remaining == 0 and input_item_id != null:
        var recipe = recipes[input_item_id]
        var output_id = recipe.output
        
        var output_item = PlayerInventorySingleton.create_item(load(output_id))
        PlayerInventorySingleton.try_grab_item(output_item)
        input_item_id = null
        
        _process(0)

func _process(delta):
    if input_item_id != null:
        cooking_time_remaining = max(cooking_time_remaining - delta, 0)
        if cooking_time_remaining == 0:
            set_process(false)
    
    var progress_bar: AnimatedSprite2D = $ProgressBar
    progress_bar.visible = input_item_id != null and cooking_time_remaining > 0
    
    if input_item_id != null and cooking_time_remaining > 0:
        var total_time = COOK_TIME
        var frame_count = progress_bar.sprite_frames.get_frame_count("default")
        progress_bar.frame = int((1.0 - cooking_time_remaining / total_time) * frame_count) % frame_count
    
    var output_indicator: Sprite2D = $OutputIndicator
    output_indicator.visible = input_item_id != null and cooking_time_remaining == 0

func can_interact() -> bool:
    if input_item_id == null:
        var held_item = PlayerInventorySingleton.held_item_data()
        if held_item == null:
            return false
        
        return recipes.has(held_item.id)
    elif cooking_time_remaining == 0:
        return !PlayerInventorySingleton.has_item()
    return false

func get_interact_explanation():
    if input_item_id == null:
        return "add %s to the frying pan" % PlayerInventorySingleton.held_item_data().item_name
    elif cooking_time_remaining == 0:
        return "take the %s out of the frying pan" % current_output.item_name
    return ""

func get_interactable_name():
    return "Stove top"

func get_description():
    var extra = ""
    if input_item_id != null:
        if cooking_time_remaining > 0:
            extra = "It's cooking something."
        else:
            extra = "The " + current_output.item_name + " is cooked and ready to take."
    else:
        extra = "It's empty."
    return "A stove top with a frying pan.\n" + extra
