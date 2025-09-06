extends Node

var _current_money: int = 0
@export var current_money: int:
    get:
        return _current_money
    set(value):
        _current_money = value
        var interface = get_interface()
        if interface:
            interface.update_money_display(_current_money)

var _day: int = 1
@export var day: int:
    get:
        return _day
    set(value):
        _day = value
        var interface = get_interface()
        if interface:
            interface.update_day_display(_day)

func get_interface() -> Node:
    return get_tree().get_first_node_in_group("level_interface")

class OrderData:
    var order_text: String
    var order_texture: Texture2D
    var total_time: float
    var time_remaining: float
    var required_item_id: String
    var node: Node2D = null

    @warning_ignore("shadowed_variable")
    func _init(total_time: float, required_item: ItemData):
        self.order_text = required_item.item_name
        self.total_time = total_time
        self.time_remaining = total_time
        self.order_texture = required_item.item_sprite
        self.required_item_id = required_item.id

var current_orders: Array[OrderData] = []

## @param order The order to add.
func add_order(order: OrderData) -> void:
    current_orders.append(order)
    var interface = get_interface()
    if interface:
        interface.add_order(order.order_text, order.order_texture, order.total_time)

## @param new_text The new text to display, or "" to keep the current text.
func set_interact_text_shown(txt_name: String, show: bool, new_text: String):
    var interface = get_interface()
    if interface:
        interface.set_interact_text_shown(txt_name, show, new_text)

## @param new_text The new text to display, or null to hide the description.
func set_info_description(new_text: Variant):
    var interface = get_interface()
    if interface:
        interface.set_info_description(new_text)

func update_interactable(node: Node2D):
    set_interact_text_shown("Interact", true, "Press E to " + node.get_interact_explanation())
    set_info_description("[b]" + node.get_interactable_name() + "[/b]\n" + node.get_description())

func clear_interactable():
    set_interact_text_shown("Interact", false, "")
    set_info_description(null)
