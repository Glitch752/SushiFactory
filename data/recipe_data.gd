extends Resource

class_name RecipeData

@export var ingredients: Array[DishIngredient]
@export var result: ItemData
@export_multiline var recipe_information: String
@export var machine: MachineData

## The priority of this recipe. Higher priority recipes are preferred when multiple can be made.
@export var priority: int

func has_ingredient_with_id(id: StringName) -> bool:
    for ingredient in ingredients:
        if ingredient.item.id == id:
            return true
    return false
