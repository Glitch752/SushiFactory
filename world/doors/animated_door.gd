extends Node2D

@onready var sprites: Array[AnimatedSprite2D] = [$LeftDoor, $RightDoor]

enum DoorState { Closed, Opening, Open, Closing }

var state: DoorState = DoorState.Closed

const OPEN_DOORS_TAG = "open_doors"

var opening_entities_in_range: int = 0

func _on_open_area_area_entered(area: Area2D):
    if area.is_in_group(OPEN_DOORS_TAG):
        opening_entities_in_range += 1

        if opening_entities_in_range == 1:
            try_open_door()

func try_open_door():
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
        opening_entities_in_range -= 1

        if opening_entities_in_range == 0:
            try_close_door()

func try_close_door():
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
