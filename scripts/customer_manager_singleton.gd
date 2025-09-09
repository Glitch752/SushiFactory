extends Node

var CustomerScene = preload("res://world/characters/Customer.tscn");

signal order_added(data: OrderData)
signal order_removed(data: OrderData)

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

func spawn_customer() -> void:
    var customer = CustomerScene.instantiate()
    get_tree().get_root().add_child(customer)
    
    pass

## @param order The order to add.
func add_order(order: OrderData) -> void:
    current_orders.append(order)
    order_added.emit(order)