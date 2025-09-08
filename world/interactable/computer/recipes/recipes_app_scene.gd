extends MarginContainer

var ItemPanelScene = preload("res://world/interactable/computer/recipes/ItemPanel.tscn");

func _ready():
    # These are just for previewing in development
    $%DishesGrid.get_child(0).queue_free()
    $%IngredientsGrid.get_child(0).queue_free()
    show_recipes()

func show_recipes():
    for recipe in DishCombinationsSingleton.dish_combinations:
        var panel = ItemPanelScene.instantiate()
        panel.item = recipe.result

        if recipe.machine == "plate":
            $%DishesGrid.add_child(panel)
        else:
            $%IngredientsGrid.add_child(panel)
