extends Node

var CustomerScene = preload("res://world/characters/Customer.tscn");

signal order_added(data: OrderData)
signal order_removed(data: OrderData)

var customer_paths_parent: Node2D
var entrance_path: Path2D
var entrance_path_length: float

const FIRST_CUSTOMER_GAP = 50
const CUSTOMER_GAP = 20
const CUSTOMER_WALKING_SPEED = 50.0 # pixels per second

func init() -> void:
    customer_paths_parent = get_tree().get_root().get_node("Level/%CustomerPaths")
    if customer_paths_parent == null:
        push_error("Could not find CustomerPaths node in scene tree.")
    
    entrance_path = customer_paths_parent.get_node("EntrancePath")
    if entrance_path == null:
        push_error("Could not find EntrancePath node in CustomerPaths.")
    
    entrance_path_length = entrance_path.curve.get_baked_length()

var initialized = false
func begin_day():
    if not initialized:
        init()
        initialized = true
    
    # TODO

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

class CustomerData:
    var path_follower: PathFollow2D
    var order: OrderData
    var leaving: bool = false

    @warning_ignore("shadowed_variable")
    func _init(path_follower: PathFollow2D, order: OrderData):
        self.path_follower = path_follower
        self.order = order

var customers: Array[CustomerData] = []

# Temporary: when pressing O, spawn a customer.
func _input(event):
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_O:
            spawn_customer()

func spawn_customer() -> void:
    var customer = CustomerScene.instantiate()

    var pathFollower = PathFollow2D.new()
    pathFollower.rotates = false
    pathFollower.loop = false
    pathFollower.progress = 0.0

    pathFollower.add_child(customer)

    entrance_path.add_child(pathFollower)

    # Temporary
    var order = OrderData.new(120.0, PlayerInventorySingleton.load_item_data("cucumber_maki"))
    
    var customerData = CustomerData.new(pathFollower, order)
    customers.append(customerData)

    order_added.emit(order)

func _physics_process(delta):
    var target_position = entrance_path_length
    for i in range(customers.size()):
        var customerData = customers[i]
        # TODO: Leaving customers. For now, they just disappear.
        
        # if customerData.leaving:
        #     customerData.path_follower.progress += delta * 100.0
        #     if customerData.path_follower.progress >= entrance_path_length:
        #         customerData.path_follower.queue_free()
        #         customers.remove_at(i)
        #         order_removed.emit(customerData.order)
        #         continue
        # else:
        if customerData.path_follower.progress < target_position:
            customerData.path_follower.progress += delta * CUSTOMER_WALKING_SPEED
            if customerData.path_follower.progress > target_position:
                customerData.path_follower.progress = target_position

        # The first customer goes to the end of the path, the second customer leaves a gap
        # of FIRST_CUSTOMER_GAP, and subsequent customers leave a gap of CUSTOMER_GAP.
        target_position -= (FIRST_CUSTOMER_GAP if i == 0 else CUSTOMER_GAP)
