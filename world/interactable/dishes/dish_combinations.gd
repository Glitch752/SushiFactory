extends Node

@export var dish_combinations: Array[DishCombination] = []

func get_dish_by_result_id(result_id: StringName) -> DishCombination:
    for dish in dish_combinations:
        if dish.result.id == result_id:
            return dish
    return null

func get_dishes_for_machine(machine: String) -> Array[DishCombination]:
    var results: Array[DishCombination] = []
    for dish in dish_combinations:
        if dish.machine == machine:
            results.append(dish)
    return results

## Gets the descriptions (formatted in BBCode) of the machines an item can be used in, e.g.
## "Makes [item]tamago[/item] in [machine]frying_pan[/machine]
func get_machine_descriptions(item_id: StringName) -> Array[String]:
    var results: Array[String] = []
    for dish in dish_combinations:
        if dish.has_ingredient_with_id(item_id):
            if dish.machine == "plate":
                results.append(TagHighlight.convert_custom_tags("[color=#ddd]Ingredient of [item]%s[/item][/color]" % dish.result.id))
            else:
                results.append(TagHighlight.convert_custom_tags("[color=#ddd]Makes [item]%s[/item] using [machine]%s[/machine][/color]" % [dish.result.id, dish.machine]))
    
    return results

## Returns a dictionary mapping from ingredient item id to result item id for dishes that can be made with a single ingredient in the specified machine.
## This is useful for machines like the cutting board where you can only process one item at a time.
func get_single_input_dishes_for(machine: String) -> Dictionary[StringName, StringName]:
    var results: Dictionary[StringName, StringName] = {}
    for dish in dish_combinations:
        if dish.machine == machine and dish.ingredients.size() == 1:
            results[dish.ingredients[0].item.id] = dish.result.id
    return results
