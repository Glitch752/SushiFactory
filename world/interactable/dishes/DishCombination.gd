extends Resource

class_name DishCombination

@export var ingredients: Array[DishIngredient]
@export var result: ItemData
@export_multiline var recipe_information: String
@export var machine: String

func has_ingredient_with_id(id: StringName) -> bool:
    for ingredient in ingredients:
        if ingredient.item.id == id:
            return true
    return false