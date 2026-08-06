extends Node2D

const GOLF_FX = preload("res://golf_fx.tscn")

var level_started = false

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("ball"):
		body.queue_free()
		var instance = GOLF_FX.instantiate()
		add_child(instance)
		instance.emitting = true
		$GolfScored.play()

func _process(delta: float) -> void:
	if not level_started:
		level_started = true
		if $VisibleOnScreenNotifier2D.is_on_screen():
			$TrackingArrow.visible = false
		else:
			$TrackingArrow.visible = true
	var cam = get_viewport().get_camera_2d()
	if cam:
		var ang_from_center = atan2(global_position.y - cam.global_position.y, global_position.x - cam.global_position.x)
		$TrackingArrow/Container/ColorRect.rotation = ang_from_center

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	$TrackingArrow.visible = false


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	$TrackingArrow.visible = true
