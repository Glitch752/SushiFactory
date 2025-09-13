extends PanelContainer

@export var order_text: String = "Order Text"
@export var total_time: float = 120.0

@export var time_remaining: float = 20.0:
    set(value):
        time_remaining = clamp(value, 0, total_time)
        update()

@export var order_texture: Texture2D

## Gets the color for a certain time by interpolating between green, yellow, and red.
func get_time_color(t: float) -> Color:
    if t > 0.5:
        return Color.YELLOW.lerp(Color.GREEN, (t - 0.5) * 2)
    else:
        return Color.RED.lerp(Color.YELLOW, t * 2)

func _ready():
    $%Countdown.max_value = total_time
    $%TextureRect.texture = order_texture

    update()

func update():
    $%Countdown.value = time_remaining
    var background_stylebox = StyleBoxFlat.new()
    var color = get_time_color(time_remaining / total_time)
    background_stylebox.bg_color = color.darkened(0.5)
    $%Countdown.add_theme_stylebox_override("fill", background_stylebox)

    $%ItemName.text = "[b]%s[/b]\n[color=#%s]%s remaining[/color]" % [order_text, color.to_html(), DayManagerSingleton.format_duration(time_remaining)]
