class_name EnemyTank extends CharacterBody2D

@export var maxhealth: float
@export var speed: int
@export var player: CharacterBody2D
@export var health: float
@export var turn_speed: int
@export var max_bullets: int
@export var fire_rate: float
@export var damage: float
@export var range: int
@export var bounces: int
@export var bullet_speed: float
@export var cursed_tank: bool = false
@export var color: Color

var disabled: bool = false

@export var enemy_container: Node

@onready var nav_agent:= $NavigationAgent2D as NavigationAgent2D

@onready var freezetimer = $FreezeTimer

var curses: Array[String] = []

var sees_player: bool



func _ready() -> void:
	health = maxhealth
	$Sprite2D.texture = $Sprite2D.texture.duplicate(true)
	$Sprite2D.texture.gradient.colors = [color]
	add_to_group("tanks")
	add_to_group("hurtable")
	if not cursed_tank:
		add_to_group("destroy_on_bullet_collide")
	if cursed_tank:
		apply_curses(curses)
		
func apply_curses(curses: Array[String]) -> void:
	if cursed_tank:
		curses = $ValidCursePool.filter_curses(curses)
		$CurseModifications.apply_curses(curses)

func freeze(time: float, freeze_bullets: bool = false):
	disabled = true
	if cursed_tank:
		$ct_enemy_health_component.freeze(time)
	if freeze_bullets:
		if $enemy_shooting_component/BulletContainer:
			for bullet in $enemy_shooting_component/BulletContainer.get_children():
				bullet.freeze(time)
	if freezetimer:
		freezetimer.start(time)

func activate_highlight() -> void:
	$Highlight.visible = true
	$HighlightArrow.visible = true

func hit(damage: float) -> void:
	if cursed_tank:
		$ct_enemy_health_component.hit(damage)
	else:
		$enemy_health_component.hit(damage)


func _on_freeze_timer_timeout() -> void:
	disabled = false
