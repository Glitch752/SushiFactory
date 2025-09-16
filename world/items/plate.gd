extends "res://world/items/item.gd"

var plate_recipes = DataLoader.get_recipes_for_machine(preload("res://data/machines/plate.tres"))

class ContentData:
    var item: ItemData
    var sprite: Sprite2D
    @warning_ignore("shadowed_variable")
    func _init(item: ItemData, sprite: Sprite2D):
        self.item = item
        self.sprite = sprite

var contents: Array[ContentData] = []

## If the contents of this plate satisfy a recipe, this stores the recipe that will be made
var valid_recipe: RecipeData = null

func can_add(item: ItemData) -> bool:
    return item.id != &"plate"

var rng = RandomNumberGenerator.new()

func has_item(item_id: StringName) -> bool:
    for content in contents:
        if content.item.id == item_id:
            return true
    return false

func add_to_plate(item: ItemData, visual_only: bool = false) -> void:
    var item_sprite = Sprite2D.new()

    # item_sprite.texture = item.item_sprite
    # Scale down the sprite to half its size using nearest sampling. This will lose detail, but that's the point!
    var tex = item.item_sprite.get_image()
    @warning_ignore("integer_division")
    tex.resize(tex.get_width() / 2, tex.get_height() / 2, Image.INTERPOLATE_NEAREST)
    item_sprite.texture = ImageTexture.create_from_image(tex)

    item_sprite.position = Vector2(rng.randi_range(-3, 3), rng.randi_range(-3, 1))
    
    add_child(item_sprite)
    
    if visual_only:
        return

    contents.append(ContentData.new(item, item_sprite))

    process_recipes()

func process_recipes():
    var found_ingredients: Dictionary[StringName, int] = {}
    for content in contents:
        if content.item.id in found_ingredients:
            found_ingredients[content.item.id] += 1
        else:
            found_ingredients.set(content.item.id, 1)
    
    for dish in plate_recipes:
        var all_found = true
        for ingredient in dish.ingredients:
            if !found_ingredients.has(ingredient.item.id) or found_ingredients[ingredient.item.id] < ingredient.quantity:
                all_found = false
                break
        
        if all_found:
            valid_recipe = dish
            return
    
    valid_recipe = null

# If we can make a dish, this returns the name of it. Otherwise, returns null
func can_make_recipe() -> Variant:
    if valid_recipe != null:
        return valid_recipe.result.item_name
    return null

func make_recipe():
    var dish = valid_recipe
    if dish == null:
        return
    
    for item in dish.ingredients:
        for content in contents:
            if content.item.id == item.item.id:
                remove_child(content.sprite)
                content.sprite.queue_free()
                contents.erase(content)
                break

    add_to_plate(dish.result)

func get_description():
    if contents.size() == 0:
        return "An empty plate."
    var desc = "A plate with:[ul]"
    for itemData in contents:
        desc += "\n [item]%s[/item]" % itemData.item.id
    desc += "\n[/ul]"

    if valid_recipe != null:
        desc += "\nCan make [item]%s[/item]." % valid_recipe.result.id
    
    return TagHighlight.convert_custom_tags(desc)

func get_take_sound() -> AudioStream:
    return preload("res://audio/plate_take.wav")

func get_place_sound() -> AudioStream:
    return preload("res://audio/plate_down.wav")
