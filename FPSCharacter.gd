extends KinematicBody


onready var camera = $Pivot/Camera
onready var rotation_helper = $Pivot

var gravity = -30
var max_speed = 8
var mouse_sensitivity = 0.002  # radians/pixel
var jump_speed=12
var jump=false

var velocity = Vector3()

signal health_changed(health)
signal health_depleted
var health = 0

func get_input():
    jump=false
    if Input.is_action_just_pressed("jump"):
        jump=true
    var input_dir = Vector3()
    # desired move in camera direction
    if Input.is_action_pressed("move_forwards"):
        input_dir += -camera.global_transform.basis.z
    if Input.is_action_pressed("move_backwards"):
        input_dir += camera.global_transform.basis.z
    if Input.is_action_pressed("move_left"):
        input_dir += -camera.global_transform.basis.x
    if Input.is_action_pressed("move_right"):
        input_dir += camera.global_transform.basis.x
    input_dir = input_dir.normalized()
    return input_dir


func _unhandled_input(event):
    if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
        rotation_helper.rotate_x(-event.relative.y * mouse_sensitivity)
        rotate_y(-event.relative.x * mouse_sensitivity)
        rotation_helper.rotation.x = clamp(rotation_helper.rotation.x, -1.2, 1.2)

func _physics_process(delta):
    velocity.y += gravity * delta
    var desired_velocity = get_input() * max_speed

    velocity.x = desired_velocity.x
    velocity.z = desired_velocity.z
    velocity = move_and_slide(velocity, Vector3.UP, true)
    if jump and is_on_floor():
        velocity.y=jump_speed

signal experience_gained(growth_data)

# CHARACTER STATS
export(int) var max_hp = 12
export(int) var strength = 8
export(int) var magic = 8

# LEVELING SYSTEM
export (int) var level = 1

var experience = 0
var experience_total = 0
var experience_required = get_required_experience(level + 1)

func get_required_experience(level):
	return round(pow(level, 1.8) + level * 4)

func gain_experience(amount):
	experience_total += amount
	experience += amount
	var growth_data = []
	while experience >= experience_required:
		experience -= experience_required
		growth_data.append([experience_required, experience_required])
		level_up()
	growth_data.append([experience, get_required_experience(level + 1)])
	emit_signal("experience_gained", growth_data)

func level_up():
	level += 1
	experience_required = get_required_experience(level + 1)

	var stats = ['max_hp', 'strength', 'magic']
	var random_stat = stats[randi() % stats.size()]
	set(random_stat, get(random_stat) + randi() % 4)
	
	health = max_hp
	emit_signal("health_changed", health)

func _ready():
	health = max_hp
	emit_signal("health_changed", health)

func take_damage(amount):
	health -= amount
	health = max(0, health)
	emit_signal("health_changed", health)

func heal(amount):
	health += amount
	health = max(health, max_hp)
	emit_signal("health_changed", health)