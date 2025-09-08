extends ScrollContainer

@export var dish: DishCombination

# I have no clue why this doesn't work with preload(...)
var ItemPanelScene = load("res://world/interactable/computer/recipes/ItemPanel.tscn")

const ITEM_COLOR = Color(0.5, 0.9, 0.5) # Light green
const RAW_ITEM_COLOR = Color(0.9, 0.5, 0.9) # Light purple
const MACHINE_COLOR = Color(1.0, 0.7, 0.5) # Light orange

func convert_custom_colors(text: String) -> String:
    var result = text
    result = result.replace("[item]", "[color=#" + ITEM_COLOR.to_html(false) + "]")
    result = result.replace("[/item]", "[/color]")
    result = result.replace("[rawitem]", "[color=#" + RAW_ITEM_COLOR.to_html(false) + "]")
    result = result.replace("[/rawitem]", "[/color]")
    result = result.replace("[machine]", "[color=#" + MACHINE_COLOR.to_html(false) + "]")
    result = result.replace("[/machine]", "[/color]")
    return result

func _ready():
    $%RecipeName.text = dish.result.item_name
    $%RecipeTexture.texture = dish.result.item_sprite

    $%Description.text = convert_custom_colors(dish.recipe_information)

    for ingredient in dish.ingredients:
        var ingredient_entry: PanelContainer = ItemPanelScene.instantiate()
        ingredient_entry.item = ingredient.item
        ingredient_entry.size_flags_horizontal = Control.SIZE_FILL # Don't expand
        $%IngredientsContainer.add_child(ingredient_entry)
