extends Node2D

@onready var sprites: Array[AnimatedSprite2D] = [$LeftDoor, $RightDoor]

enum DoorState { Closed, Opening, Open, Closing }

var state: DoorState = DoorState.Closed

const OPEN_DOORS_TAG = "open_doors"

func _on_open_area_area_entered(area: Area2D):
    if area.is_in_group(OPEN_DOORS_TAG):
        print("entered 2")
        if state == DoorState.Closed or state == DoorState.Closing:
            state = DoorState.Opening
            for sprite in sprites:
                sprite.play("default")
            
            for sprite in sprites:
                await sprite.animation_finished
                if state != DoorState.Opening:
                    return
                
                sprite.frame = sprite.sprite_frames.get_frame_count("default") - 1
                sprite.pause()
            
            state = DoorState.Open


func _on_open_area_area_exited(area: Area2D):
    if area.is_in_group(OPEN_DOORS_TAG):
        if state == DoorState.Open or state == DoorState.Opening:
            state = DoorState.Closing
            for sprite in sprites:
                sprite.play_backwards("default")
                
            for sprite in sprites:
                await sprite.animation_finished
                if state != DoorState.Closing:
                    return
                
                sprite.frame = 0
                sprite.pause()
            
            state = DoorState.Closed
