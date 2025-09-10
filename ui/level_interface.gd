extends Control

@onready var order_layout = $%OrderLayout

var OrderScene = preload("res://ui/Order.tscn")

func _ready():
    LevelInterfaceSingleton.money_changed.connect(update_money_display)
    DayManagerSingleton.day_changed.connect(update_day_display)
    DayManagerSingleton.time_of_day_changed.connect(update_time_display)

    # Clear the children of order layout; they're for visualizing in the editor
    for child in order_layout.get_children():
        child.queue_free()
    
    LevelInterfaceSingleton.interact_text_changed.connect(set_interact_text_shown)
    LevelInterfaceSingleton.info_description_changed.connect(set_info_description)

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

## @param new_text The new text to display, or "" to keep the current text.
func set_interact_text_shown(txt_name: String, txt_show: bool, new_text: String):
    var interact_text = $InteractText
    var child = interact_text.get_node(txt_name)
    if child:
        if new_text != "":
            child.text = new_text
        child.visible = txt_show
    else:
        push_error("No interact text with name '%s'" % txt_name)

## @param text The new text to display, or null to hide the description.
func set_info_description(text: Variant):
    if text is String and text != "":
        $%MachineInfoLabel.text = text.strip_edges()
        $MachineInfo.visible = true
    else:
        $MachineInfo.visible = false

func update_money_display(money: int):
    $%MoneyLabel.text = "$" + str(money)

func update_day_display(day: int):
    $%DayLabel.text = "Day " + str(day)

func update_time_display(time_of_day: float):
    $%TimeLabel.text = DayManagerSingleton.format_time_of_day()
    $%TimeProgress.value = time_of_day
