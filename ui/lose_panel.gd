@tool
extends TransitionContainer

const ShaderSceneTransition = preload("res://ui/ShaderSceneTransition.tscn")

@export var days_survived: int
@export var money_earned: int
@export var customers_served: int
@export var customers_disappointed: int

func _ready():
    $%AddToLeaderboardButton.pressed.connect(func(): close(true))
    $%CancelButton.pressed.connect(func(): close(false))

    $%NameSelector.grab_focus()

    $%StatsLabel.text = tr("Your store's reputation dropped to 0.
You survived [color=#99ff88]{days_survived}[/color] days and made [color=#99ff88]¥{money_earned}[/color], serving [color=#99ff88]{customers_served}[/color] customers and disappointing [color=#ff9988]{customers_disappointed}[/color].")\
        .format({
            "days_survived": days_survived,
            "money_earned": money_earned,
            "customers_served": customers_served,
            "customers_disappointed": customers_disappointed
        })

func close(add_to_leaderboard: bool):
    if add_to_leaderboard:
        LeaderboardSingleton.add_entry($%NameSelector.current_name, days_survived, money_earned)

    InputTargetSingleton.deactivate(InputTargetSingleton.InputTarget.LoseScreen)

    var transition = ShaderSceneTransition.instantiate()
    get_tree().root.add_child(transition)
    await transition.wipe_to_black()

    # heck yeah! state reset (i'm sure this is a terrible way to do this but... whatever)
    for node in get_tree().root.get_children():
        if node.has_method("_play_reset"):
            node._play_reset()
    
    # Not sure why this can't be preloaded, but whatever
    get_tree().change_scene_to_packed(load("res://Menu.tscn"))

    await transition.wipe_from_black()
    transition.queue_free()
