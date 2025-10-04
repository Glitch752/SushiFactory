extends VBoxContainer

@onready var slot_container = $%Slots

var previous_held_item: Node2D = null

func _ready():
    PlayerInventorySingleton.items_changed.connect(_items_changed)
    
    $ItemDescription.visible = false
    $ItemDescription.modulate.a = 0
    $ItemDescription.visual_position = Vector2(0, -5)

    # Initialize all of the slots
    for child in slot_container.get_children():
        child.queue_free()

    var start_items = PlayerInventorySingleton.all_inventory_items()
    var i = 0
    for slot in start_items:
        var slot_ui = preload("res://ui/inventory/InventorySlot.tscn").instantiate()
        slot_ui.selected = PlayerInventorySingleton.held_item_index == i
        slot_ui.item = slot
        slot_container.add_child(slot_ui)
        
        i += 1
    
    if start_items.size() == 1:
        $%SwitchSlotHint.force_hide = true

func _items_changed(items: Array[Node2D], held_item_index: int):
    var i = 0
    for slot_ui in slot_container.get_children():
        slot_ui.item = items[i]
        slot_ui.selected = held_item_index == i
        
        i += 1
    
    var held_item = items[held_item_index]
    if held_item:
        $ItemDescription.description = "[b]%s[/b]\n%s" % [held_item.data.item_name, held_item.get_description()]
    else:
        $ItemDescription.description = ""

func _unhandled_input(event):
    if not InputTargetSingleton.is_active(InputTargetSingleton.InputTarget.PlayerMovement):
        return

    if event.is_action_pressed("rotate_right"):
        PlayerInventorySingleton.switch_slot(1)
        # I haven't found anything that sounds good lol
        # SoundManager.play_sound(preload("res://audio/ui/cycle_slot.wav"), 0, randf_range(0.9, 1.1))
    elif event.is_action_pressed("rotate_left"):
        PlayerInventorySingleton.switch_slot(-1)
        # SoundManager.play_sound(preload("res://audio/ui/cycle_slot.wav"), 0, randf_range(0.9, 1.1))

func _on_mouse_entered():
    if PlayerInventorySingleton.has_item():
        $ItemDescription.visible = true
        var t = create_tween()
        t.set_ignore_time_scale(true)
        t.tween_property($ItemDescription, "modulate:a", 1, 0.1)
        t.parallel().tween_property($ItemDescription, "visual_position:y", 0, 0.1)

func _on_mouse_exited():
    var t = create_tween()
    t.set_ignore_time_scale(true)
    t.tween_property($ItemDescription, "modulate:a", 0, 0.1)
    t.parallel().tween_property($ItemDescription, "visual_position:y", -5, 0.1)
    t.tween_callback(func():
        $ItemDescription.visible = false
    )
