extends Panel

@export var monster_rect: TextureRect
@export var marker_2d: Marker2D

func _start_animation() -> bool:
	print("start anim", monster_rect.position.y)
	await get_tree().create_tween().tween_property(monster_rect,
	"position",
	Vector2(monster_rect.position.x, 0),
	2).finished
	#get_tree().create_tween().tween_method(monster_rect.set_scale, monster_rect.scale, Vector2(0, 0), 2).finished
	return true

func reset_animation():
	monster_rect.position = marker_2d.position
	monster_rect.set_scale(Vector2(1,1))
