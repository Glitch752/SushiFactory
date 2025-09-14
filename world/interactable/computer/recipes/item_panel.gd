extends PanelContainer

@export var item: ItemData

var hover_panel = preload("res://ui/stylebox/9_patch_stylebox_dark_hover.tres")
var normal_panel = preload("res://ui/stylebox/9_patch_stylebox_dark.tres")

var recipe_scene = preload("res://world/interactable/computer/recipes/OpenRecipeAppScene.tscn")

var dish: DishCombination

const ITEM_COLOR = preload("res://world/interactable/computer/recipes/open_recipe_app_scene.gd").ITEM_COLOR
const RAW_ITEM_COLOR = preload("res://world/interactable/computer/recipes/open_recipe_app_scene.gd").RAW_ITEM_COLOR

func _ready():
    if not item:
        return # Probably an editor placeholder
    
    $%RecipeName.text = item.item_name
    
    $%RecipeTexture.texture = item.item_sprite
    $%RecipeTexture.tooltip_text = item.description
    
    dish = DishCombinationsSingleton.get_dish_by_result_id(item.id)

    $%RecipeName.label_settings = $%RecipeName.label_settings.duplicate()
    if dish != null:
        $%RecipeName.label_settings.font_color = ITEM_COLOR
    else:
        $%RecipeName.label_settings.font_color = RAW_ITEM_COLOR

func _on_mouse_entered():
    SoundManager.play_mouse_enter()
    if dish:
        add_theme_stylebox_override("panel", hover_panel)

func _on_mouse_exited():
    if dish:
        add_theme_stylebox_override("panel", normal_panel)

func _gui_input(event):
    if dish and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        SoundManager.play_pressed()

        var scene = recipe_scene.instantiate()
        scene.dish = dish
        find_parent("ComputerDesktop").open_window(item.item_name + " Recipe", scene)
