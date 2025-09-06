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

    var time_text = ""
    if time_remaining > 60:
        time_text = str(floor(time_remaining / 60)) + ":" + str(int(floor(time_remaining)) % 60) + "s"
    else:
        time_text = str(floor(time_remaining)) + "s"
    $%ItemName.text = "[b]" + order_text + "[/b]\n[color=#" + color.to_html() + "]" + time_text + " remaining[/color]"
