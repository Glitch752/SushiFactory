extends Button

const ShaderSceneTransition = preload("res://ui/ShaderSceneTransition.tscn")
const LevelScene = preload("res://Level.tscn")

func _on_pressed():
    # heck yeah! state reset (i'm sure this is a terrible way to do this but... whatever)
    for node in get_tree().root.get_children():
        if node.has_method("_play_reset"):
            node._play_reset()

    var transition = ShaderSceneTransition.instantiate()
    get_tree().root.add_child(transition)
    await transition.wipe_to_black()

    get_tree().change_scene_to_packed(LevelScene)

    await transition.wipe_from_black()
    transition.queue_free()
