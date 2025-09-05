extends "res://world/items/item.gd"

class ContentData:
    var item: ItemData
    var sprite: Sprite2D
    @warning_ignore("shadowed_variable")
    func _init(item: ItemData, sprite: Sprite2D):
        self.item = item
        self.sprite = sprite

var contents: Array[ContentData] = []

class DishIngredient:
    var item_id: String
    var quantity: int = 1
    @warning_ignore("shadowed_variable")
    func _init(item_id: String, quantity: int = 1):
        self.item_id = item_id
        self.quantity = quantity

class DishCombination:
    var ingredients: Array[DishIngredient]
    var result: ItemData
    @warning_ignore("shadowed_variable")
    func _init(result: ItemData, ingredients: Array[DishIngredient]):
        self.ingredients = ingredients
        self.result = result

var DISH_COMBINATIONS: Array[DishCombination] = [
    DishCombination.new(
        preload("res://world/items/salmon_nigiri_item_data.tres"),
        [
            DishIngredient.new("sliced_salmon"),
            DishIngredient.new("cooked_rice"),
        ]
    ),
    DishCombination.new(
        preload("res://world/items/cucumber_maki_item_data.tres"),
        [
            DishIngredient.new("sliced_cucumber"),
            DishIngredient.new("nori_bundle"),
            DishIngredient.new("cooked_rice"),
        ]
    )
]

func can_add(item: ItemData) -> bool:
    return item.id != "plate"

var rng = RandomNumberGenerator.new()

func add_to_plate(item: ItemData) -> void:
    print("Adding item to plate ", item.id)

    var item_sprite = Sprite2D.new()
    item_sprite.texture = item.item_sprite
    item_sprite.scale = Vector2.ONE * 0.5
    item_sprite.position = Vector2(rng.randi_range(-4, 4), rng.randi_range(-4, 4))
    
    add_child(item_sprite)
    
    contents.append(ContentData.new(item, item_sprite))

    process_dishes()

func process_dishes():
    var found_ingredients = {}
    for content in contents:
        if content.item.id in found_ingredients:
            found_ingredients[content.item.id] += 1
        else:
            found_ingredients.set(content.item.id, 1)
    
    for dish in DISH_COMBINATIONS:
        var all_found = true
        for ingredient in dish.ingredients:
            if !found_ingredients.has(ingredient.item_id) or found_ingredients[ingredient.item_id] < ingredient.quantity:
                all_found = false
                break
        
        if all_found:
            print("Made dish: ", dish.result.item_name)

            for item in dish.ingredients:
                for content in contents:
                    if content.item.id == item.item_id:
                        remove_child(content.sprite)
                        content.sprite.queue_free()
                        contents.erase(content)
                        break

            add_to_plate(dish.result)
            return

func get_description():
    if contents.size() == 0:
        return "An empty plate."
    var desc = "A plate with:[ul]"
    for data in contents:
        desc += "\n %s" % data.item.item_name
    desc += "\n[/ul]"
    return desc
