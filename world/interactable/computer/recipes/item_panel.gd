extends PanelContainer

@export var item: ItemData

var hover_panel = preload("res://ui/stylebox/9_patch_stylebox_dark_hover.tres")
var normal_panel = preload("res://ui/stylebox/9_patch_stylebox_dark.tres")

var recipe_scene = preload("res://world/interactable/computer/recipes/OpenRecipeAppScene.tscn")

var recipe: RecipeData

func _ready():
    if not item:
        return # Probably an editor placeholder
    
    $%RecipeName.text = item.item_name
    
    $%RecipeTexture.texture = item.item_sprite
    $%RecipeTexture.tooltip_text = item.description
    
    recipe = DataLoader.get_recipe_by_result_id(item.id)

    $%RecipeName.label_settings = $%RecipeName.label_settings.duplicate()
    if recipe != null:
        $%RecipeName.label_settings.font_color = TagHighlight.ITEM_COLOR
    else:
        $%RecipeName.label_settings.font_color = TagHighlight.RAW_ITEM_COLOR

func _on_mouse_entered():
    SoundManager.play_mouse_enter()
    if recipe:
        add_theme_stylebox_override("panel", hover_panel)

func _on_mouse_exited():
    if recipe:
        add_theme_stylebox_override("panel", normal_panel)

func _gui_input(event):
    if recipe and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        SoundManager.play_pressed()

        var scene = recipe_scene.instantiate()
        scene.recipe = recipe
        find_parent("ComputerDesktop").open_window_or_focus_existing(item.item_name + " Recipe", scene)
