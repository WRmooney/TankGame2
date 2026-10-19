extends Line2D

var queue: Array
@export var max_length: int


func _process(delta: float) -> void:
	var pos = get_parent().position
	queue.push_front(pos)
	if queue.size() > max_length:
		queue.pop_back()
	clear_points()
	
	for point in queue:
		add_point(point - get_parent().global_position)
