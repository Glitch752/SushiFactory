extends Control

@onready var order_layout = $%OrderLayout

var OrderScene = preload("res://ui/Order.tscn")
const DayNotificationUI = preload("res://ui/DayNotificationUI.tscn")
const DayEvent = preload("res://ui/day_notification_ui.gd").DayEvent

const InteractionData = preload("res://world/interactable/interactable.gd").InteractionData
const InteractionAction = preload("res://world/interactable/interactable.gd").InteractionAction

func _ready():
    StoreStatsSingleton.money_changed.connect(update_money_display)

    DayManagerSingleton.day_changed.connect(update_day_display)
    DayManagerSingleton.time_of_day_changed.connect(update_time_display)

    # Clear the children of order layout; they're for visualizing in the editor
    for child in order_layout.get_children():
        child.queue_free()
    
    LevelInterfaceSingleton.interaction_data_changed.connect(update_interaction_info)

    LevelInterfaceSingleton.notify_day_started_ui.connect(notify_day_started)
    LevelInterfaceSingleton.notify_store_open_ui.connect(notify_store_open)
    LevelInterfaceSingleton.notify_store_closing_ui.connect(notify_store_closing)

    update_money_display(StoreStatsSingleton.current_money)
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

func update_reputation_display(reputation: int):
    $%ReputationLabel.text = "Reputation: %s/%s" % [str(reputation), str(StoreStatsSingleton.max_reputation)]

# Generates the day opening info, e.g:
# [b]Expected customer rate[/b]: [color=#ffff99]10/hr[/color]
# [b]Customer patience[/b]: [color=#ffff99]2hrs[/color]
# [b]Order difficulties[/b]: [color=#99ff88]basic[/color], [color=#ff9988]advanced[/color]
func generate_day_opening_info(day: int):
    var day_data: DayData = DayManagerSingleton.get_day_data(day)
    var customerRate = 1.0 / day_data.customer_interval
    
    var rateColor = "#ff9988" if customerRate >= 10 else "#ffff99" if customerRate >= 5 else "#99ff88"
    var info = "[b]Expected customer rate[/b]: [color=%s]%d/hr[/color]\n" % [rateColor, customerRate]

    var patienceColor = "#ff9988" if day_data.customer_patience <= 30.0 else "#ffff99" if day_data.customer_patience <= 60.0 else "#99ff88"
    info += "[b]Customer patience[/b]: [color=%s]%sm[/color]\n" % [patienceColor, int(day_data.customer_patience)]

    var difficulties = []
    for diff in day_data.order_difficulties:
        var possibleOrders = DayManagerSingleton.get_possible_orders(diff)
        difficulties.append("[color=#%s]%s[/color]" % [possibleOrders.color.to_html(), possibleOrders.name.to_lower()])
    
    info += "[b]Order difficulties[/b]: %s" % ", ".join(difficulties)
    
    return info

func notify_day_started(day: int):
    var notif = DayNotificationUI.instantiate()
    notif.day = day
    notif.event = DayEvent.ARRIVAL
    notif.infoText = generate_day_opening_info(day)

    add_child(notif)

func notify_store_open():
    var notif = DayNotificationUI.instantiate()
    notif.day = DayManagerSingleton.day
    notif.event = DayEvent.OPENING
    notif.infoText = ""

    add_child(notif)

func notify_store_closing():
    var notif = DayNotificationUI.instantiate()
    notif.day = DayManagerSingleton.day
    notif.event = DayEvent.CLOSING
    notif.infoText = ""

    add_child(notif)
