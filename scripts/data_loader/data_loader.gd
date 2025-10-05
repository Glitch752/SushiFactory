extends Node

## Loads data. wow.

##################### Data

## A map from item ID to data.
var items: Dictionary[StringName, ItemData] = {}

## A map from machine ID to data.
var machines: Dictionary[StringName, MachineData] = {}

## A list of recipes. Sorted by priority, so higher priority recipes are first in the array.
var recipes: Array[RecipeData] = []

## A list of "constructables", which are objects used in the construction view. They're not all handled the same,
## but there's some shared information like name/description so we also use resources for them.
var constructables: Array[ConstructableData] = []

##################### Basic getters

func get_item(id: StringName) -> ItemData:
    return items.get(id, null)

func get_machine(id: StringName) -> MachineData:
    return machines.get(id, null)

func get_constructable_with_meaning(meaning: StringName):
    for constructable in constructables:
        if "meaning" in constructable and constructable.meaning == meaning:
            return constructable
    return null


##################### Recipes

func get_recipe_by_result_id(result_id: StringName) -> RecipeData:
    for recipe in recipes:
        if recipe.result.id == result_id:
            return recipe
    return null

func get_recipes_for_machine(machine: MachineData) -> Array[RecipeData]:
    var results: Array[RecipeData] = []
    for recipe in recipes:
        if recipe.machine.id == machine.id:
            results.append(recipe)
    return results

## Gets the descriptions (formatted in BBCode) of the machines an item can be used in, e.g.
## "Makes [item]tamago[/item] in [machine]frying_pan[/machine]
func get_machine_descriptions(item_id: StringName) -> Array[String]:
    var results: Array[String] = []
    for recipe in recipes:
        if recipe.has_ingredient_with_id(item_id):
            if recipe.machine.id == &"plate":
                results.append(TagHighlight.convert_custom_tags("[color=#ddd]Ingredient of [item]%s[/item][/color]" % recipe.result.id))
            else:
                results.append(TagHighlight.convert_custom_tags("[color=#ddd]Makes [item]%s[/item] using [machine]%s[/machine][/color]" % [recipe.result.id, recipe.machine.id]))
    
    return results

## Returns a dictionary mapping from ingredient item id to result item id for recipes that can be made with a single ingredient in the specified machine.
## This is useful for machines like the cutting board where you can only process one item at a time.
func get_single_input_recipes_for(machine: MachineData) -> Dictionary[StringName, StringName]:
    var results: Dictionary[StringName, StringName] = {}
    for recipe in recipes:
        if recipe.machine.id == machine.id and recipe.ingredients.size() == 1:
            results[recipe.ingredients[0].item.id] = recipe.result.id
    return results


##################### Actual resource loading

## Recursively loads all resources under data/[data_type]/**/*.tres
func recursively_load_resources(data_type: String, _type_hint: String = "") -> Array[Resource]:
    var resources: Array[Resource] = []
    var dir = DirAccess.open("res://data/%s" % data_type)
    if dir == null:
        push_error("Failed to open directory for data type: %s" % data_type)
        return resources
    
    dir.list_dir_begin()
    
    var file_name = dir.get_next()
    while file_name != "":
        if dir.current_is_dir():
            # Recurse into subdirectory
            resources += recursively_load_resources("%s/%s" % [data_type, file_name.get_file()])
        else:
            # Export builds have .remap added to the end of filenames, so strip that off if present
            if file_name.get_extension() == "remap":
                file_name = file_name.replace(".remap", "")
            
            if file_name.get_extension() == "tres":
                # print("Loading resource res://data/%s/%s" % [data_type, file_name])
                var resource = load("res://data/%s/%s" % [data_type, file_name])
                if resource != null:
                    resources.append(resource)
                else:
                    push_error("Failed to load resource: %s" % file_name)
            else:
                print("Skipping non-resource file %s" % file_name)
        
        file_name = dir.get_next()
    
    dir.list_dir_end()
    
    return resources

func _ready():
    var loaded_items = recursively_load_resources("items", "ItemData")
    for item in loaded_items:
        if item is ItemData:
            items[item.id] = item
            item.validate()
        else:
            push_error("Loaded resource is not of type ItemData: %s" % item)
    
    print("Loaded %d items" % items.size())

    var loaded_machines = recursively_load_resources("machines", "MachineData")
    for machine in loaded_machines:
        if machine is MachineData:
            machines[machine.id] = machine
        else:
            push_error("Loaded resource is not of type MachineData: %s" % machine)
    
    print("Loaded %d machines" % machines.size())

    var loaded_recipes = recursively_load_resources("recipes", "RecipeData")
    for recipe in loaded_recipes:
        if recipe is RecipeData:
            recipes.append(recipe)
        else:
            push_error("Loaded resource is not of type RecipeData: %s" % recipe)
    
    recipes.sort_custom(func(a: RecipeData, b: RecipeData):
        if a.priority > b.priority:
            return true
        if a.priority < b.priority:
            return false
        # Break ties with number of ingredients (more ingredients is higher priority)
        return a.ingredients.size() > b.ingredients.size()
    )
    
    print("Loaded and sorted %d recipes" % recipes.size())

    var loaded_constructables = recursively_load_resources("constructables", "ConstructableData")
    for constructable in loaded_constructables:
        if constructable is ConstructableData:
            constructables.append(constructable)
        else:
            push_error("Loaded resource is not of type ConstructableData: %s" % constructable)

    constructables.sort_custom(func(a: ConstructableData, b: ConstructableData):
        return a.priority > b.priority
    )
    
    print("Loaded %d constructables" % constructables.size())