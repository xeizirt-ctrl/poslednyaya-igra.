extends CharacterBody3D

const SPEED := 3.5
const SENS := 0.002
var camera: Camera3D
var pitch := 0.0
var gravity := 18.0
var touch_last := Vector2.ZERO
var touch_looking := false

func _ready():
    var col = CollisionShape3D.new()
    var capsule = CapsuleShape3D.new()
    capsule.radius = 0.3
    capsule.height = 1.65
    col.shape = capsule
    col.position.y = 0.82
    add_child(col)
    camera = Camera3D.new()
    camera.position = Vector3(0,1.52,0)
    camera.current = true
    add_child(camera)

func _unhandled_input(event):
    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        _look(event.relative)
    elif event is InputEventScreenTouch:
        if event.pressed:
            touch_last = event.position
            touch_looking = event.position.x > get_viewport().size.x * 0.42
        else:
            touch_looking = false
    elif event is InputEventScreenDrag and touch_looking:
        _look(event.relative * 1.3)
    elif event.is_action_pressed("interact") and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and not OS.has_feature("mobile"):
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _look(delta: Vector2):
    rotate_y(-delta.x * SENS)
    pitch = clamp(pitch - delta.y * SENS, -1.2, 1.2)
    camera.rotation.x = pitch

func _physics_process(delta):
    var v = Input.get_vector("move_left","move_right","move_forward","move_back")
    var dir = (transform.basis * Vector3(v.x,0,v.y)).normalized()
    velocity.x = dir.x * SPEED
    velocity.z = dir.z * SPEED
    if not is_on_floor():
        velocity.y -= gravity * delta
    else:
        velocity.y = 0
    move_and_slide()

func get_look_target():
    var a = camera.global_position
    var b = a + (-camera.global_transform.basis.z * 3.4)
    var q = PhysicsRayQueryParameters3D.create(a,b)
    q.exclude = [self]
    var hit = get_world_3d().direct_space_state.intersect_ray(q)
    return hit.collider if hit else null
