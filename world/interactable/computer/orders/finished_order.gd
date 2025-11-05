@tool

extends MarginContainer

@export var order_text: String = "Order Text"
@export var total_time: float = 120.0

@export var time_remaining: float = 20.0:
    set(value):
        time_remaining = clamp(value, 0, total_time)
        update()

@export var profit: int = 0:
    set(value):
        profit = value
        update()

@export var order_texture: Texture2D

@export var panel_override: StyleBox

@export var positive_profit_color: Color
@export var zero_profit_color: Color

## Gets the color for a certain time by interpolating between green, yellow, and red.
func get_time_color(t: float) -> Color:
    if t > 0.5:
        return Color.YELLOW.lerp(Color.GREEN, (t - 0.5) * 2)
    else:
        return Color.RED.lerp(Color.YELLOW, t * 2)

func _ready():
    $%TextureRect.texture = order_texture
    
    if panel_override != null:
        $%PanelContainer.add_theme_stylebox_override("panel", panel_override)

    if not Engine.is_editor_hint():
        update()

func update():
    var color = get_time_color(time_remaining / total_time)
    if time_remaining == 0.0:
        $%ItemName.text = "[b]%s[/b]\n[color=red]Customer left[/color]" % [order_text]
    else:
        $%ItemName.text = "[b]%s[/b]\n[color=#%s]%s remaining[/color]" % [
            order_text,
            color.to_html(),
            preload("res://scripts/day_manager_singleton.gd").format_duration(time_remaining)
        ]

    var profit_color = positive_profit_color if profit > 0 else zero_profit_color
    $%ItemProfit.text = "[color=#%s]+¥%s[/color]" % [profit_color.to_html(), str(profit)]
    if profit == 0:
        $%ItemProfit.text += "\n"
        $%ItemProfit.text += "[color=#ff9999]-1 reputation[/color]"
