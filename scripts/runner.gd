extends Control

var next_stage: Callable
var player_x := 0.0
var jump_y := 0.0
var jump_v := 0.0
var obstacles := []
var distance := 0.0
var ended := false
var label: Label
var spawn_timer := 0.0

func setup(next: Callable):
    next_stage=next
    label=Label.new()
    label.position=Vector2(250,145)
    label.add_theme_font_size_override("font_size",24)
    add_child(label)
    for i in 4:
        obstacles.append(Vector2(780.0+i*280, 0.0))
    queue_redraw()

func _process(delta):
    if ended:return
    distance += delta*90
    spawn_timer += delta
    if spawn_timer>1.3:
        spawn_timer=0
        obstacles.append(Vector2(1000,0))
    for i in range(obstacles.size()-1,-1,-1):
        obstacles[i].x -= delta*350
        if obstacles[i].x < 80: obstacles.remove_at(i)
        elif obstacles[i].x < 150 and obstacles[i].x > 90 and jump_y < 48:
            _lose()
    jump_y += jump_v*delta
    if jump_y>0:
        jump_y=0
        jump_v=0
    label.text="ДИСТАНЦИЯ: %d / 900\n\nПРЫГАЙ ЧЕРЕЗ ПРЕПЯТСТВИЯ!" % int(distance)
    if distance>=900:
        ended=true
        label.text="ТЫ ДОБЕЖАЛ.\nНо за экраном что-то пробежало в обратную сторону..."
        await get_tree().create_timer(2.2).timeout
        next_stage.call()
    queue_redraw()

func _unhandled_input(event):
    if ended:return
    if event.is_action_pressed("ui_left"): player_x=max(-100,player_x-40)
    if event.is_action_pressed("ui_right"): player_x=min(100,player_x+40)
    if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_accept"):
        if jump_y==0: jump_v=-430

func _lose():
    ended=true
    label.text="ТЕНЬ ДОГНАЛА ТЕБЯ.\n\nНажми Esc и попробуй ещё раз."
    get_tree().create_timer(1.0).timeout.connect(func(): next_stage.call())

func _draw():
    draw_rect(Rect2(100,260,1000,5),Color(0.35,0.8,0.9))
    draw_rect(Rect2(145+player_x,205-jump_y,34,55),Color(0.2,0.85,1))
    for ob in obstacles:
        draw_rect(Rect2(ob.x,220,32,45),Color(0.9,0.18,0.24))
