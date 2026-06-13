extends Node

@onready var parent = get_parent()
@onready var healthrect = $"../StatsUI/ColorRect"
@onready var healthlabel =$"../StatsUI/HealthLabel"
@onready var ammolabel = $"../StatsUI/AmmoLabel"
@onready var prim_cont = $"../PrimaryContainer"
@onready var second_cont = $"../SecondaryContainer"
@onready var ammolabel2 = $"../StatsUI/AmmoLabel2"

const player_death = preload("res://player_death_explosion.tscn")

func hit(damage: float) -> void:
	parent.health -= damage
	if parent.health < 0:
		parent.health = 0
	if parent.health <= 0:
		var instance = player_death.instantiate()
		parent.add_child(instance)
		$"../Sprite2D".queue_free()
		$"../CollisionShape2D".queue_free()
		$"../NavigationObstacle2D".queue_free()
		parent.death()
		"""
		if not parent.WUIon:
			parent.LUIon = true
			$"../LosingUI".visible = true
			$"../LosingUI/FinalScore".text = "Kills: " + str(parent.enemy_container.kills)
			for UIElement in $"../LosingUI".get_children():
				UIElement.global_position = Vector2(get_viewport().size.x/2 - UIElement.size.x/2,get_viewport().size.y/2 - UIElement.size.y/2)
			"""
			
func _process(delta: float) -> void:
	healthrect.size.x = 400 * (parent.health / parent.max_health)
	healthrect.global_position = Vector2(50,50)
	healthlabel.text = str(parent.health) + "/" + str(parent.max_health)
	healthlabel.global_position = Vector2(50,50)
	ammolabel.text = "Bullets (LMB): " + str(parent.max_bullets - prim_cont.get_child_count())
	ammolabel.global_position = Vector2(50,50)
	ammolabel2.text = "Mines (RMB): " + str(parent.max_secondary - second_cont.get_child_count())
	ammolabel2.global_position = Vector2(50,100)
