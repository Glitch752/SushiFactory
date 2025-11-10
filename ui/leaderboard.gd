extends VBoxContainer

const LeaderboardRow = preload("res://ui/leaderboard/LeaderboardRow.tscn")

func _ready() -> void:
    refresh()

    LeaderboardSingleton.changed.connect(refresh)

func refresh() -> void:
    for child in $LeaderboardRows.get_children():
        child.queue_free()

    var leaderboard_data = LeaderboardSingleton.leaderboard_data
    for entry in leaderboard_data:
        var row_instance = LeaderboardRow.instantiate() as HBoxContainer
        row_instance.entry_name = entry.name
        row_instance.days = entry.days
        row_instance.money = entry.money_earned
        $LeaderboardRows.add_child(row_instance)