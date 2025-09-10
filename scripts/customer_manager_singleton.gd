extends Node

var CustomerScene = preload("res://world/characters/Customer.tscn");

signal order_added(data: OrderData)

var customer_paths_parent: Node2D
var y_sorting_tile_map: TileMapLayer

var entrance_path: Path2D
var entrance_path_length: float

var exit_path: Path2D
var exit_path_length: float

const FIRST_CUSTOMER_GAP = 30
const CUSTOMER_GAP = 20
const CUSTOMER_WALKING_SPEED = 100.0 # pixels per second

const LINE_STOP_PAUSE = 0.1

func init() -> void:
    var level = get_tree().get_root().get_node("Level")
    if level == null:
        push_error("Could not find Level node in scene tree.")

    customer_paths_parent = level.get_node("%CustomerPaths")
    if customer_paths_parent == null:
        push_error("Could not find CustomerPaths node in scene tree.")
    
    y_sorting_tile_map = level.get_node("BuildingTileMap")
    if y_sorting_tile_map == null:
        push_error("Could not find BuildingTileMap node in scene tree.")
    
    entrance_path = customer_paths_parent.get_node("EntrancePath")
    if entrance_path == null:
        push_error("Could not find EntrancePath node in CustomerPaths.")
    
    exit_path = customer_paths_parent.get_node("ExitPath")
    if exit_path == null:
        push_error("Could not find ExitPath node in CustomerPaths.")
    
    entrance_path_length = entrance_path.curve.get_baked_length()
    exit_path_length = exit_path.curve.get_baked_length()

var initialized = false
func begin_day():
    if not initialized:
        init()
        initialized = true
    
    # TODO

enum CustomerState {
    ENTERING,
    STOPPED,
    WALKING_TO_LEAVE_LINE,
    LEAVING
}

class CustomerData:
    var node: Node2D
    var order: OrderData
    var state: CustomerState = CustomerState.ENTERING
    var target_progress: float = 0.0
    var stop_timer: float = 0.0

    @warning_ignore("shadowed_variable")
    func _init(node: Node2D, order: OrderData):
        self.node = node
        self.order = order
    
    func begin_leaving():
        state = CustomerState.WALKING_TO_LEAVE_LINE
        target_progress = -1.0
    
    func is_waiting():
        return state == CustomerState.ENTERING or state == CustomerState.STOPPED

## Not on the CustomerData class because... GDScript is weird.
func satisfy_customer(customerData: CustomerData) -> void:
    customerData.begin_leaving()
    customerData.order.dispose()

func anger_customer(customerData: CustomerData) -> void:
    customerData.begin_leaving()
    customerData.order.dispose()

    # TODO: Lose reputation or something idk

var customers: Array[CustomerData] = []

func _input(event):
    if event is InputEventKey and event.pressed and not event.echo:
        # Temporary: when pressing O, spawn a customer.
        if event.keycode == KEY_O:
            spawn_customer()
        elif event.keycode == KEY_P:
            # and satisfy the first waiting in line when pressing P
            for customerData in customers:
                if customerData.is_waiting():
                    satisfy_customer(customerData)
                    break

func spawn_customer() -> void:
    var customer = CustomerScene.instantiate()
    customer.global_position = entrance_path.to_global(entrance_path.curve.sample_baked(0.0, true))

    y_sorting_tile_map.add_child(customer)

    # Temporary
    var order = OrderData.new(45.0, PlayerInventorySingleton.load_item_data("cucumber_maki"))
    
    var customerData = CustomerData.new(customer, order)
    customers.append(customerData)

    order_added.emit(order)

func _process(_delta):
    for customerData in customers:
        if customerData.is_waiting():
            customerData.order.time_remaining = max(0.0, customerData.order.time_remaining - _delta)
            if customerData.order.time_remaining == 0.0:
                anger_customer(customerData)

func _physics_process(delta):
    var target_waiting_position = entrance_path_length
    # Customers to remove after the loop since we can't modify the array while iterating it
    var remove_customers: Array[CustomerData] = []
    var first_stopped_in_row = false

    for i in range(customers.size()):
        var customerData = customers[i]
        # TODO: Leaving customers.
        
        # holy stack of if statements
        if customerData.state == CustomerState.ENTERING or customerData.state == CustomerState.STOPPED:
            if customerData.target_progress < target_waiting_position:
                if customerData.state == CustomerState.STOPPED:
                    if not first_stopped_in_row:
                        first_stopped_in_row = true
                        customerData.stop_timer += delta
                        if customerData.stop_timer >= LINE_STOP_PAUSE:
                            customerData.state = CustomerState.ENTERING
                    else:
                        target_waiting_position = customerData.target_progress
                else:
                    first_stopped_in_row = false
                    customerData.target_progress += delta * CUSTOMER_WALKING_SPEED

                if customerData.target_progress >= target_waiting_position:
                    customerData.target_progress = target_waiting_position
                    customerData.state = CustomerState.STOPPED
                    customerData.stop_timer = 0.0
            
            var new_position = entrance_path.to_global(entrance_path.curve.sample_baked(customerData.target_progress, true))
            customerData.node.global_position = new_position

            # The first customer goes to the end of the path, the second customer leaves a gap
            # of FIRST_CUSTOMER_GAP, and subsequent customers leave a gap of CUSTOMER_GAP.
            target_waiting_position -= (FIRST_CUSTOMER_GAP if i == 0 else CUSTOMER_GAP)
        elif customerData.state == CustomerState.WALKING_TO_LEAVE_LINE and customerData.target_progress == -1:
            # Find the nearest point on the leaving line
            customerData.target_progress = exit_path.curve.get_closest_offset(exit_path.to_local(customerData.node.global_position))
        elif customerData.state == CustomerState.WALKING_TO_LEAVE_LINE:
            # Walk toward the target point at the walking speed. This is just linear for now, but it should probably be smoothed.
            var target_pos = exit_path.to_global(exit_path.curve.sample_baked(customerData.target_progress, true))
            var diff = target_pos - customerData.node.global_position
            var distance = diff.length()
            if distance < 1.0:
                customerData.state = CustomerState.LEAVING
            else:
                var direction = diff / distance
                var move_amount = min(distance, CUSTOMER_WALKING_SPEED * delta)
                customerData.node.global_position += direction * move_amount
        elif customerData.state == CustomerState.LEAVING:
            # Move along the exit path until offscreen, then remove the customer
            customerData.target_progress += delta * CUSTOMER_WALKING_SPEED
            
            var target_progress = min(customerData.target_progress, exit_path_length)
            var new_position = exit_path.to_global(exit_path.curve.sample_baked(target_progress, true))
            customerData.node.global_position = new_position

            if target_progress == exit_path_length:
                # Offscreen, remove the customer
                remove_customers.append(customerData)
                customerData.node.queue_free()
    
    for customerData in remove_customers:
        customers.erase(customerData)
