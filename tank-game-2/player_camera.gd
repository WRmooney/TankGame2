extends Camera2D

var shake_intensity: float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not $ShakeTimer.is_stopped():
		var x_offset = randi_range(-1,1) * shake_intensity
		var y_offset = randi_range(-1,1) * shake_intensity
		offset.x = x_offset
		offset.y = y_offset

func start_shake(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	$ShakeTimer.start(duration)
