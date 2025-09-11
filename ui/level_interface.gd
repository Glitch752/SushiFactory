extends Control

@onready var order_layout = $%OrderLayout

var OrderScene = preload("res://ui/Order.tscn")

const InteractionData = preload("res://world/interactable/interactable.gd").InteractionData
const InteractionAction = preload("res://world/interactable/interactable.gd").InteractionAction

func _ready():
    LevelInterfaceSingleton.money_changed.connect(update_money_display)
    DayManagerSingleton.day_changed.connect(update_day_display)
    DayManagerSingleton.time_of_day_changed.connect(update_time_display)

    # Clear the children of order layout; they're for visualizing in the editor
    for child in order_layout.get_children():
        child.queue_free()
    
    LevelInterfaceSingleton.interaction_data_changed.connect(update_interaction_info)

    update_money_display(LevelInterfaceSingleton.current_money)
    update_day_display(DayManagerSingleton.day)
    update_time_display(DayManagerSingleton.time_of_day)

    CustomerManagerSingleton.order_added.connect(add_order)

func add_order(order: OrderData):
    var order_instance = OrderScene.instantiate()
    order_instance.order_text = order.order_text
    order_instance.total_time = order.total_time
    order_instance.order_texture = order.order_texture
    order_instance.time_remaining = order.time_remaining

    order.update_time.connect(func():
        if order.node and order.node.is_inside_tree():
            order.node.time_remaining = order.time_remaining
    )

    order_layout.add_child(order_instance)

    order.node = order_instance

func update_interaction_info(data: InteractionData):
    if data != null:
        $%InteractionInfo.visible = true

        $%InteractionName.text = data.name
        $%InteractionDescription.text = data.description
        
        update_interact_hint($%PrimaryInteractHint, data.primary_action)
        update_interact_hint($%SecondaryInteractHint, data.secondary_action)
    else:
        $%InteractionInfo.visible = false

func update_interact_hint(container: HBoxContainer, action: InteractionAction):
    if action != null:
        container.visible = true
        container.get_node("Label").text = action.name
    else:
        container.visible = false

func update_money_display(money: int):
    $%MoneyLabel.text = "$" + str(money)

func update_day_display(day: int):
    $%DayLabel.text = "Day " + str(day)

func update_time_display(time_of_day: float):
    $%TimeLabel.text = DayManagerSingleton.format_time_of_day()
    $%TimeProgress.value = time_of_day
