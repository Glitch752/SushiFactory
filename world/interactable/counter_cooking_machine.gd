extends "res://world/interactable/interactable.gd"

var cooking_time_remaining = 0.0
var input_item_id = null
var current_output: ItemData = null

@export var normal_texture: Texture2D
@export var active_texture: Texture2D
## e.g. stove_top; must match the `machine` fields of recipes
@export var machine_id: String

## e.g. Stove Top
@export var machine_name: String
## e.g. A stove top with a frying pan.
@export var interactable_description: String

## e.g. cooking, frying, etc
@export var action_word: String = "cooking"
## e.g. cooked, fried, etc
@export var action_word_past: String = "cooked"

@onready var sprite: Sprite2D = $%Sprite

@onready var timer = $Timer

const COOK_TIME = 20.0

var recipes: Dictionary[String, String] # input item id -> output item id

func _ready():
    recipes = DishCombinationsSingleton.get_single_input_dishes_for(machine_id)
    set_physics_process(false)
    super._ready()

func interact():
    if input_item_id == null:
        var held_item = PlayerInventorySingleton.remove_item()
        if held_item == null:
            return
        
        var item_id = held_item.data.id
        if not recipes.has(item_id):
            # Not a valid recipe, return item to inventory
            PlayerInventorySingleton.try_grab_item(held_item)
            return
        
        input_item_id = item_id
        current_output = PlayerInventorySingleton.load_item_data(recipes[item_id])

        held_item.queue_free()
        cooking_time_remaining = COOK_TIME
        timer.start(cooking_time_remaining)
        set_physics_process(true)
    
    elif cooking_time_remaining == 0 and input_item_id != null and !PlayerInventorySingleton.has_item():
        var output_item = PlayerInventorySingleton.create_item(current_output)
        PlayerInventorySingleton.try_grab_item(output_item)
        input_item_id = null
        
        _physics_process(0)

func _physics_process(delta):
    if input_item_id != null:
        cooking_time_remaining = max(cooking_time_remaining - delta, 0)
        if cooking_time_remaining == 0:
            set_physics_process(false)
    
    var progress_bar: AnimatedSprite2D = $%ProgressBar
    progress_bar.visible = input_item_id != null and cooking_time_remaining > 0

    sprite.texture = active_texture if input_item_id != null else normal_texture
    
    if input_item_id != null and cooking_time_remaining > 0:
        var total_time = COOK_TIME
        var frame_count = progress_bar.sprite_frames.get_frame_count("default")
        progress_bar.frame = int((1.0 - cooking_time_remaining / total_time) * frame_count) % frame_count
    
    var output_indicator: Sprite2D = $%OutputIndicator
    output_indicator.visible = input_item_id != null and cooking_time_remaining == 0


func get_interaction_data() -> InteractionData:
    var action: InteractionAction = null
    var desc = ""
    var interactable_name = machine_name
    if input_item_id == null:
        var held_item = PlayerInventorySingleton.held_item_data()
        if held_item and recipes.has(held_item.id):
            action = InteractionAction.new("Add %s" % held_item.item_name, interact)
            desc = "%s\nAdd %s to start %s." % [interactable_description, held_item.item_name.to_lower(), action_word]
        else:
            desc = "%s\nIt's empty." % interactable_description
    elif cooking_time_remaining > 0:
        desc = "%s\nIt's %s %s." % [interactable_description, action_word, current_output.item_name]
    elif cooking_time_remaining == 0:
        if !PlayerInventorySingleton.has_item():
            action = InteractionAction.new("Take %s" % current_output.item_name, interact)
        desc = "%s\nThe %s is %s and ready to take." % [interactable_description, current_output.item_name, action_word_past]
    return InteractionData.new(interactable_name, desc, action)
