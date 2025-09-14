extends VBoxContainer

const VolumeSliderScene = preload("res://ui/VolumeSlider.tscn")

func _ready():
    $VolumeSlider.visible = false # For development
    
    for bus in AudioServer.bus_count: # Bus 0 is the master bus
        var slider = VolumeSliderScene.instantiate()
        slider.bus = bus
        add_child(slider)
