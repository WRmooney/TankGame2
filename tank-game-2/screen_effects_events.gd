extends Node

@onready var nearsight_filter = $NearSight
@onready var farsight_filter = $FarSight

func apply_nearsight() -> void:
	nearsight_filter.visible = true

func apply_farsight() -> void:
	farsight_filter.visible = true

func apply_snow() -> void:
	$SnowEffect.visible = true
	$SnowEffect/SnowParticles.process_material.emission_shape_scale.x = get_viewport().size.x / 10
	$SnowEffect/SnowParticles.process_material.emission_shape_offset.x = get_viewport().size.x / 2
	$SnowEffect/SnowParticles.amount = get_viewport().size.x / 10
	$SnowEffect/SnowParticles.emitting = true
