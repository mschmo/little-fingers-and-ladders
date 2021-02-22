extends Area2D

const TILE_SIZE: int = 64

var _direction: Vector2 = Vector2.RIGHT

onready var tween = $Tween
onready var ray = $RayCast2D

export var speed: int = 3

func _ready():
	position = position.snapped(Vector2.ONE * TILE_SIZE)
	position += Vector2.ONE * TILE_SIZE / 2


func move(roll_value):
	# position += Vector2.RIGHT * TILE_SIZE * roll_value
	# make this smarter
	if tween.is_active():
		return

	for i in range(roll_value):
		ray.cast_to = _direction * TILE_SIZE
		ray.force_raycast_update()
		if ray.is_colliding():
			if _direction == Vector2.UP:
				_direction = Vector2.RIGHT if position.x == 32 else Vector2.LEFT
			elif _direction == Vector2.LEFT or _direction == Vector2.RIGHT:
				_direction = Vector2.UP
		move_tween(_direction)
		# this is dumb - what if it takes longer than a second to reach the wall?
		yield(get_tree().create_timer(0.5), "timeout")


func climb_ladder(steps: int):
	move_tween(Vector2.UP, steps)


func flop_direction():
	# Reverse horizontal direction
	_direction = _direction * Vector2(-1, 0)


func win_position():
	tween.connect("tween_complete", self, "timeout")
	tween.interpolate_property(self, "position",
		position, Vector2(32, 32),
		1.0/speed, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()


func move_tween(dir, steps=1):
	tween.connect("tween_complete", self, "timeout")
	tween.interpolate_property(self, "position",
		position, position + dir * TILE_SIZE * steps,
		1.0/speed, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	tween.start()
