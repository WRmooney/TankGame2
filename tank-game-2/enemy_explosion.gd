extends GPUParticles2D

func _ready() -> void:
	emitting = true
	var camera = get_tree().get_first_node_in_group("PlayerCamera")
	if camera:
		camera.start_shake(1, 0.3)
	
func _process(delta: float) -> void:
	if not emitting:
		queue_free()
