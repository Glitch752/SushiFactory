extends Node

var CustomerScene = preload("res://world/characters/Customer.tscn")

const AutomationManager = preload("res://scripts/automation/automation_manager.gd")

signal order_added(data: OrderData)
signal customer_satisfied()
signal customer_angered()

var customer_paths_parent: Node2D
var y_sorting_tile_map: TileMapLayer

var entrance_path: Path2D
var entrance_path_length: float

var exit_path: Path2D
var exit_path_length: float

var automation_manager: AutomationManager = null

const FIRST_CUSTOMER_GAP = 30
const CUSTOMER_GAP = 20
const CUSTOMER_WALKING_SPEED = 80.0 # pixels per second

const LINE_STOP_PAUSE = 0.1

func init() -> void:
    var level = get_tree().get_root().get_node("Level")
    if level == null:
        push_error("Could not find Level node in scene tree.")
    
    automation_manager = level.get_node("AutomationManager")
    if automation_manager == null:
        push_error("Could not find AutomationManager node in Level.")
    
    automation_manager.belts_updated.connect(belts_updated)

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

var current_day_data: DayData

var initialized = false
func begin_day(day_data: DayData):
    current_day_data = day_data

    if not initialized:
        init()
        initialized = true

############### Customer spawning

var customer_spawn_timer: float = 0.0
var store_is_open: bool = false

func store_opened():
    customer_spawn_timer = current_day_data.customer_interval / 2
    store_is_open = true

    # Immediately spawn a customer since otherwise players
    # need to wait for an unreasonable amount of time on the first day
    spawn_customer()

func store_closed():
    store_is_open = false

func _process(delta):
    if store_is_open:
        var time_progression = DayManagerSingleton.elapsed_world_time(delta)

        customer_spawn_timer += time_progression
        if customer_spawn_timer >= current_day_data.customer_interval:
            customer_spawn_timer -= current_day_data.customer_interval
            spawn_customer()
    
    process_customers(delta)

############### Customer movement and orders

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
    customer_satisfied.emit()

func anger_customer(customerData: CustomerData) -> void:
    customerData.begin_leaving()
    customerData.order.dispose()
    customer_angered.emit()

    # TODO: an "angry" thought bubble above the customer or something

var customers: Array[CustomerData] = []

## Checks if all customers have left the restaurant.
func all_customers_left() -> bool:
    return customers.size() == 0

func spawn_customer() -> void:
    var customer = CustomerScene.instantiate()
    customer.global_position = entrance_path.to_global(entrance_path.curve.sample_baked(0.0, true))

    y_sorting_tile_map.add_child(customer)

    # Temporary
    var day_difficulties = current_day_data.order_difficulties
    var difficulty = day_difficulties[randi() % day_difficulties.size()]
    var item = DayManagerSingleton.get_possible_orders(difficulty).get_random_item()

    var order = OrderData.new(current_day_data.customer_patience / 60, item)
    
    var customerData = CustomerData.new(customer, order)
    customers.append(customerData)

    order_added.emit(order)

func process_customers(delta):
    var world_elapsed = DayManagerSingleton.elapsed_world_time(delta)
    for customerData in customers:
        if customerData.is_waiting():
            customerData.order.time_remaining = max(0.0, customerData.order.time_remaining - world_elapsed)

            if customerData.order.time_remaining == 0.0:
                anger_customer(customerData)

func belts_updated():
    # Check each customer to see if their order is being fulfilled
    for customerData in customers:
        if customerData.is_waiting() and automation_manager.take_item_on_plate_near(customerData.node.global_position, customerData.order.required_item_id):
            print("Satisfied customer for item ", customerData.order.required_item_id)
            satisfy_customer(customerData)

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
                customerData.node.position += direction * move_amount
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
