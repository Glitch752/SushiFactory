extends Node

@export var dish_combinations: Array[DishCombination] = []

func get_dish_by_result_id(result_id: String) -> DishCombination:
    for dish in dish_combinations:
        if dish.result.id == result_id:
            return dish
    return null
