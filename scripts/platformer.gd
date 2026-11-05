extends Control

var next_stage: Callable
var px := 150.0
var py := 390.0
var vy := 0.0
var stars := [Vector2(360,350),Vector2(570,290),Vector2(800,350)]
var collected := 0
var ended := false
var label: Label

func setup(next: Callable):
    next_stage=next
    label=Label.new()
    label.position=Vector2(220,125)
    label.add_theme_font_size_override("font_size",24)
    add_child(label)
    queue_redraw()

func _process(delta):
    if ended:return
    if Input.is_action_pressed("ui_left"): px-=220*delta
    if Input.is_action_pressed("ui_right"): px+=220*delta
    if Input.is_action_just_pressed("ui_up") or Input.is_action_just_pressed("ui_accept"):
        if py>=390: vy=-520
    py+=vy*delta
    vy+=1100*delta
    if py>390: py=390; vy=0
    for i in range(stars.size()-1,-1,-1):
        if Vector2(px,py).distance_to(stars[i])<42:
            stars.remove_at(i); collected+=1
    label.text="ЗВЁЗДЫ: %d / 3\nСобери всё и дойди до двери." % collected
    if collected>=3 and px>1000:
        ended=true
        label.text="ДВЕРЬ ОТКРЫТА..."
        await get_tree().create_timer(1.8).timeout
        next_stage.call()
    px=clamp(px,70,1120)
    queue_redraw()

func _unhandled_input(event):
    if ended:return
    if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_accept"):
        if py>=390: vy=-520

func _draw():
    draw_rect(Rect2(70,445,1080,8),Color(0.35,0.8,0.9))
    draw_rect(Rect2(280,390,170,12),Color(0.4,0.6,0.8))
    draw_rect(Rect2(510,330,170,12),Color(0.4,0.6,0.8))
    draw_rect(Rect2(760,390,170,12),Color(0.4,0.6,0.8))
    for s in stars:
        draw_circle(s,12,Color(1,0.82,0.2))
    draw_rect(Rect2(px-18,py-48,36,48),Color(0.2,0.85,1))
    draw_rect(Rect2(1050,360,45,85),Color(0.8,0.15,0.2))
