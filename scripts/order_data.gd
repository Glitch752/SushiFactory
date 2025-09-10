extends Resource

class_name OrderData

signal update_time()

var order_text: String
var order_texture: Texture2D
var total_time: float
var time_remaining: float:
    set(value):
        time_remaining = clamp(value, 0, total_time)
        update_time.emit()

# TODO: This could be more complex but meh
var required_item_id: String
var node: CanvasItem = null

@warning_ignore("shadowed_variable")
func _init(total_time: float, required_item: ItemData):
    self.order_text = required_item.item_name
    self.total_time = total_time
    self.time_remaining = total_time
    self.order_texture = required_item.item_sprite
    self.required_item_id = required_item.id

func dispose():
    if node and node.is_inside_tree():
        node.queue_free()
    
    # we love ref counting memory leaks
    for connection in update_time.get_connections():
        update_time.disconnect(connection.callable)