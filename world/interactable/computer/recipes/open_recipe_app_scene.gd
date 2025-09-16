extends MarginContainer

@export var dish: DishCombination

# I have no clue why this doesn't work with preload(...)
var ItemPanelScene = load("res://world/interactable/computer/recipes/ItemPanel.tscn")

func _ready():
    $%RecipeName.text = dish.result.item_name
    $%RecipeTexture.texture = dish.result.item_sprite

    $%Description.text = TagHighlight.convert_custom_tags(dish.recipe_information)

    for ingredient in dish.ingredients:
        var ingredient_entry: PanelContainer = ItemPanelScene.instantiate()
        ingredient_entry.item = ingredient.item
        ingredient_entry.size_flags_horizontal = Control.SIZE_FILL # Don't expand
        $%IngredientsContainer.add_child(ingredient_entry)
