@tool

## A container that makes all of its children take up its full size (or center or whatever based on size flags)
## and inherits the size of its largest child
## I'm not sure why this isn't in Godot by default, since I need it all the time...

extends Container

class_name StackContainer

func _notification(what):
    match what: 
        NOTIFICATION_SORT_CHILDREN:
            _sort_children()

func _sort_children():
    for child in get_children():
        if child is Control:
            fit_child_in_rect(child, Rect2(Vector2.ZERO, size))

func _get_minimum_size():
    var max_size = Vector2.ZERO
    for child in get_children():
        if child is Control and child.visible:
            var child_min_size = child.get_combined_minimum_size()
            max_size.x = max(max_size.x, child_min_size.x)
            max_size.y = max(max_size.y, child_min_size.y)
    return max_size
