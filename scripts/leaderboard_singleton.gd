extends Node

const SAVE_PATH = "user://leaderboard.txt"

var leaderboard_data: Array[LeaderboardEntry] = []

signal changed()

func _ready():
    leaderboard_data = _load_leaderboard()

@warning_ignore("shadowed_variable_base_class")
func add_entry(name: String, days: int, money_earned: int):
    var new_entry = LeaderboardEntry.new(name, days, money_earned)
    leaderboard_data.append(new_entry)
    leaderboard_data.sort_custom(func(a, b):
        return b.money_earned - a.money_earned
    )
    if leaderboard_data.size() > 10:
        leaderboard_data = leaderboard_data.slice(0, 10)
    _save_leaderboard(leaderboard_data)

class LeaderboardEntry:
    var name: String
    var days: int
    var money_earned: int

    @warning_ignore("shadowed_variable")
    func _init(name: String, days: int, money_earned: int):
        self.name = name
        self.days = days
        self.money_earned = money_earned

func _load_leaderboard() -> Array[LeaderboardEntry]:
    var leaderboard: Array[LeaderboardEntry] = []
    var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return leaderboard

    while not file.eof_reached():
        var line = file.get_line()
        var parts = line.split(",")
        if parts.size() != 3:
            continue
        var entry = LeaderboardEntry.new(parts[0], int(parts[1]), int(parts[2]))
        leaderboard.append(entry)

    file.close()
    return leaderboard

func _save_leaderboard(leaderboard: Array[LeaderboardEntry]) -> void:
    var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_error("Failed to open leaderboard file for writing.")
        return

    for entry in leaderboard:
        var line = "%s,%d,%d\n" % [entry.name, entry.days, entry.money_earned]
        file.store_string(line)

    file.close()

    changed.emit()
