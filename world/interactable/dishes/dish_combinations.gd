extends Node

@export var dish_combinations: Array[DishCombination] = []

func get_dish_by_result_id(result_id: String) -> DishCombination:
    for dish in dish_combinations:
        if dish.result.id == result_id:
            return dish
    return null

func get_dishes_for_machine(macine: String) -> Array[DishCombination]:
    var results: Array[DishCombination] = []
    for dish in dish_combinations:
        if dish.machine == macine:
            results.append(dish)
    return results

## Returns a dictionary mapping from ingredient item id to result item id for dishes that can be made with a single ingredient in the specified machine.
## This is useful for machines like the cutting board where you can only process one item at a time.
func get_single_input_dishes_for(machine: String) -> Dictionary:
    var results: Dictionary = {}
    for dish in dish_combinations:
        if dish.machine == machine and dish.ingredients.size() == 1:
            results[dish.ingredients[0].item.id] = dish.result.id
    return results
