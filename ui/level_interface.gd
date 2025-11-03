extends Control

@onready var order_layout = $%OrderLayout

var OrderScene = preload("res://ui/Order.tscn")
const DayNotificationUI = preload("res://ui/DayNotificationUI.tscn")
const DayEvent = preload("res://ui/day_notification_ui.gd").DayEvent

const InteractionData = preload("res://world/interactable/interactable.gd").InteractionData
const InteractionAction = preload("res://world/interactable/interactable.gd").InteractionAction

func _ready():
    StoreStatsSingleton.money_changed.connect(update_money_display)
    StoreStatsSingleton.reputation_changed.connect(update_reputation_display)

    DayManagerSingleton.day_changed.connect(update_day_display)
    DayManagerSingleton.time_of_day_changed.connect(update_time_display)

    # Clear the children of order layout; they're for visualizing in the editor
    for child in order_layout.get_children():
        child.queue_free()
    
    InteractionSingleton.interaction_data_changed.connect(update_interaction_info)

    DayManagerSingleton.day_started.connect(notify_day_started)
    DayManagerSingleton.store_opened.connect(notify_store_open)
    DayManagerSingleton.store_closed.connect(notify_store_closing)

    update_money_display(StoreStatsSingleton.money)
    update_day_display(DayManagerSingleton.day)
    update_time_display(DayManagerSingleton.time_of_day)

    CustomerManagerSingleton.order_added.connect(add_order)

func add_order(order: OrderData):
    var container = TransitionContainer.new()

    var order_instance = OrderScene.instantiate()
    order_instance.order_text = order.order_text
    order_instance.total_time = order.total_time
    order_instance.order_texture = order.order_texture
    order_instance.time_remaining = order.time_remaining

    order.update_time.connect(func():
        if order.node and order.node.is_inside_tree():
            order.node.get_child(0).time_remaining = order.time_remaining
    )

    container.add_child(order_instance)
    order_layout.add_child(container)

    order.node = container

func update_interaction_info(data: InteractionData):
    if not is_visible_in_tree():
        return
    
    $%InteractionInfo.data = data

func update_money_display(money: int):
    $%MoneyLabel.text = "¥" + str(money)

func update_day_display(day: int):
    $%DayLabel.text = "Day " + str(day)

func update_time_display(time_of_day: float):
    $%TimeLabel.text = DayManagerSingleton.format_time_of_day()
    $%TimeProgress.value = time_of_day

func update_reputation_display(reputation: int):
    $%ReputationLabel.text = "Reputation: %s/%s" % [str(reputation), str(StoreStatsSingleton.max_reputation)]

func clear_existing_notifications():
    for child in get_children():
        if child.scene_file_path == DayNotificationUI.resource_path:
            child.queue_free()

func notify_day_started(day: int, _data: DayData, info_text: String):
    clear_existing_notifications()

    var notif = DayNotificationUI.instantiate()
    notif.day = day
    notif.event = DayEvent.ARRIVAL
    notif.infoText = info_text

    add_child(notif)

func notify_store_open():
    clear_existing_notifications()

    var notif = DayNotificationUI.instantiate()
    notif.day = DayManagerSingleton.day
    notif.event = DayEvent.OPENING
    notif.infoText = ""

    add_child(notif)

func notify_store_closing():
    clear_existing_notifications()

    var notif = DayNotificationUI.instantiate()
    notif.day = DayManagerSingleton.day
    notif.event = DayEvent.CLOSING
    notif.infoText = ""

    add_child(notif)
