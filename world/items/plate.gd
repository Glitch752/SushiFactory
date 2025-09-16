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

    # Add an outline of dark pixels to the texture
    # This makes white items like rice visible on the white plates. I'm not a huge fan,
    # but it's the best solution I could come up with.

    var outline_tex = Image.create(tex.get_width() + 2, tex.get_height() + 2, false, Image.FORMAT_RGBA8)
    outline_tex.blit_rect(tex, Rect2(0, 0, tex.get_width(), tex.get_height()), Vector2(1, 1))

    var outline_neighbors = [
        # We only use the cardinal direction neighbors for outlines
        Vector2(0, 1),
        Vector2(1, 0),
        # For a shadow effect instead, the first two can be commented. It doesn't look great, though.
        Vector2(0, -1),
        Vector2(-1, 0),
    ]
    for x in range(outline_tex.get_width()):
        for y in range(outline_tex.get_height()):
            var pixel = outline_tex.get_pixel(x, y)
            if pixel.a == 0.0:
                # Transparent pixel, check neighbors
                for offset in outline_neighbors:
                    var nx = x + int(offset.x) - 1
                    var ny = y + int(offset.y) - 1
                    if nx >= 0 and nx < tex.get_width() and ny >= 0 and ny < tex.get_height():
                        var neighbor_pixel = tex.get_pixel(nx, ny)
                        if neighbor_pixel.a > 0.0:
                            # Neighbor is not transparent, set this pixel to a dark color
                            outline_tex.set_pixel(x, y, Color(neighbor_pixel.r * 0.5, neighbor_pixel.g * 0.5, neighbor_pixel.b * 0.5, 1))
                            break
                # <---------^^^^^ break to here (I'm in an ascii art mood :D)

    item_sprite.texture = ImageTexture.create_from_image(outline_tex)

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
