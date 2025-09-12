extends Control

enum DayEvent {
    ARRIVAL, OPENING, CLOSING
}

@export var day: int = 1
@export var event: DayEvent = DayEvent.CLOSING
@export var infoText: String = ""

@onready var dayTitle: Label = $%DayTitle;
@onready var hr: Panel = $%HR;
@onready var timeTitle: Label = $%TimeTitle;
@onready var infoRichText: RichTextLabel = $%InfoRichText;

var startHrWidth: float
var startInfoHeight: float

func _ready():
    var eventName = ""
    match event:
        DayEvent.ARRIVAL:
            eventName = "Arrival"
        DayEvent.OPENING:
            eventName = "Opening"
        DayEvent.CLOSING:
            eventName = "Closing"
    
    dayTitle.text = "Day %d - %s" % [day, eventName]
    infoRichText.text = infoText

    startHrWidth = hr.custom_minimum_size.x
    startInfoHeight = infoRichText.size.y
    animate()

    DayManagerSingleton.time_of_day_changed.connect(update_time)

func update_time(new_time: float):
    if event == DayEvent.CLOSING:
        timeTitle.text = "%s - Store closed" % DayManagerSingleton.format_time_of_day()
    elif event == DayEvent.ARRIVAL:
        timeTitle.text = "%s - Store opens in %s" % [DayManagerSingleton.format_time_of_day(), DayManagerSingleton.format_duration(9.0 - new_time)]
    else:
        timeTitle.text = "%s - Store closes in %s" % [DayManagerSingleton.format_time_of_day(), DayManagerSingleton.format_duration(17.0 - new_time)]

# func _input(ev):
#     # For debugging: on pressing 1, reaniamte
#     if ev is InputEventKey and ev.pressed:
#         if ev.keycode == KEY_1:
#             animate()

func animate():
    dayTitle.modulate.a = 0.0
    hr.custom_minimum_size.x = 0
    hr.modulate.a = 1.0
    timeTitle.modulate.a = 0.0
    infoRichText.custom_minimum_size.y = 0
    infoRichText.modulate.a = 1.0

    # Opening animation
    var tween = create_tween()
    tween.set_trans(Tween.TRANS_QUAD)

    tween.tween_interval(0.5)

    tween.tween_property(self, "position:y", 0.0, 1.0).from(self.position.y - 10)

    var main_animations = create_tween()
    main_animations.set_trans(Tween.TRANS_QUAD)
    main_animations.tween_property(dayTitle, "modulate:a", 1.0, 0.25)

    # We animate from 0 width to the starting minimum width by multiples of 8px because it snaps to our pixel grid
    var hr_tween = create_tween()
    for i in range(0, startHrWidth, 32):
        hr_tween.tween_callback(func(): hr.custom_minimum_size.x = i).set_delay(0.02)
    
    main_animations.tween_subtween(hr_tween)
    
    main_animations.tween_property(timeTitle, "modulate:a", 1.0, 0.25)

    main_animations.tween_interval(0.25)
    main_animations.tween_property(infoRichText, "custom_minimum_size:y", startInfoHeight, 0.25)
    
    tween.parallel().tween_subtween(main_animations)

    tween.tween_interval(6.0)

    # Hide all
    var fade_out_duration = 1.5
    tween.tween_property(infoRichText, "modulate:a", 0.0, fade_out_duration)
    tween.parallel().tween_property(dayTitle, "modulate:a", 0.0, fade_out_duration)
    tween.parallel().tween_property(timeTitle, "modulate:a", 0.0, fade_out_duration)
    tween.parallel().tween_property(hr, "modulate:a", 0.0, fade_out_duration)

    tween.parallel().tween_property(self, "position:y", -10.0, fade_out_duration)

    await tween.finished

    hr_tween.kill()
    main_animations.kill()

    queue_free()
