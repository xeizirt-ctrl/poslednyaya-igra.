extends Node3D

var player: CharacterBody3D
var ui: CanvasLayer
var hud: Control
var story_label: Label
var prompt_label: Label
var screen_panel: Panel
var screen_label: Label
var screen_open := false
var computer_used := false
var current_mode := "room"
var elapsed := 0.0
var flicker_light: OmniLight3D
var screen_mat: StandardMaterial3D
var touch_mode := false

func _ready():
    touch_mode = OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()
    _make_environment()
    _make_room()
    _make_player()
    _make_ui()
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if not touch_mode else Input.MOUSE_MODE_VISIBLE

func _process(delta):
    elapsed += delta
    if current_mode == "room" and elapsed > 18.0 and not computer_used:
        story_label.text = "02:13\n\nМонитор сам включился.\nНа экране — папка со старыми играми."
        screen_mat.emission_energy_multiplier = 0.8 + abs(sin(elapsed * 4.0)) * 1.2
    if current_mode == "room":
        var target = player.get_look_target()
        prompt_label.visible = target != null and target.has_meta("computer") and not computer_used
    else:
        prompt_label.visible = false

func _unhandled_input(event):
    if current_mode == "room" and event.is_action_pressed("interact"):
        var target = player.get_look_target()
        if target and target.has_meta("computer"):
            _open_computer()
    if event.is_action_pressed("ui_cancel"):
        if screen_open:
            _close_game_screen()
        elif not touch_mode:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    if event is InputEventMouseButton and event.pressed and not touch_mode and current_mode == "room":
        Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _make_environment():
    var we = WorldEnvironment.new()
    var env = Environment.new()
    env.background_mode = Environment.BG_SKY
    env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    env.ambient_light_color = Color(0.25,0.27,0.38)
    env.ambient_light_energy = 0.28
    env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
    we.environment = env
    add_child(we)
    var key = DirectionalLight3D.new()
    key.rotation_degrees = Vector3(-48, -25, 0)
    key.light_color = Color(0.54,0.62,0.9)
    key.light_energy = 0.28
    add_child(key)

func _make_room():
    _box("Пол", Vector3(0,-0.15,0), Vector3(8,0.3,8), Color(0.15,0.13,0.16))
    _box("Стена задняя", Vector3(0,2,-4), Vector3(8,4,0.2), Color(0.11,0.12,0.17))
    _box("Стена левая", Vector3(-4,2,0), Vector3(0.2,4,8), Color(0.09,0.10,0.15))
    _box("Стена правая", Vector3(4,2,0), Vector3(0.2,4,8), Color(0.09,0.10,0.15))
    _box("Потолок", Vector3(0,4,0), Vector3(8,0.2,8), Color(0.07,0.07,0.10))
    var ceiling = OmniLight3D.new()
    ceiling.position = Vector3(-0.7,3.45,0.3)
    ceiling.light_color = Color(0.55,0.61,0.9)
    ceiling.light_energy = 0.55
    ceiling.omni_range = 7
    add_child(ceiling)

    # Bed
    _box("Каркас кровати", Vector3(-2.25,0.32,1.25), Vector3(2.15,0.32,3.0), Color(0.19,0.13,0.13))
    _box("Матрас", Vector3(-2.25,0.58,1.25), Vector3(2.0,0.22,2.8), Color(0.36,0.37,0.44))
    _box("Подушка", Vector3(-2.25,0.73,2.25), Vector3(1.0,0.13,0.48), Color(0.62,0.62,0.69))
    # Desk
    _box("Столешница", Vector3(1.55,1.05,-2.65), Vector3(2.8,0.16,1.15), Color(0.22,0.13,0.10))
    for x in [0.45,2.65]:
        _box("Ножка стола", Vector3(x,0.5,-2.65), Vector3(0.13,1.0,0.13), Color(0.12,0.08,0.07))
    var monitor_body = _box("Монитор", Vector3(1.55,1.92,-3.0), Vector3(1.35,0.9,0.16), Color(0.025,0.03,0.045))
    monitor_body.set_meta("computer", true)
    screen_mat = StandardMaterial3D.new()
    screen_mat.albedo_color = Color(0.015,0.13,0.18)
    screen_mat.emission_enabled = true
    screen_mat.emission = Color(0.02,0.48,0.72)
    screen_mat.emission_energy_multiplier = 1.0
    var screen_mesh = MeshInstance3D.new()
    var bm = BoxMesh.new()
    bm.size = Vector3(1.18,0.72,0.025)
    screen_mesh.mesh = bm
    screen_mesh.position = Vector3(1.55,1.93,-2.905)
    screen_mesh.material_override = screen_mat
    add_child(screen_mesh)
    _box("Подставка монитора", Vector3(1.55,1.42,-2.95), Vector3(0.13,0.32,0.13), Color(0.04,0.04,0.05))
    _box("Клавиатура", Vector3(1.55,1.17,-2.0), Vector3(0.95,0.06,0.3), Color(0.035,0.04,0.05))
    var tower = _box("Системный блок", Vector3(3.0,0.56,-2.55), Vector3(0.42,0.98,0.66), Color(0.035,0.04,0.055))
    tower.set_meta("computer", true)
    var glow = OmniLight3D.new()
    glow.position = Vector3(1.55,2.0,-2.55)
    glow.light_color = Color(0.03,0.52,0.9)
    glow.light_energy = 1.0
    glow.omni_range = 3.2
    add_child(glow)
    _box("Дверь", Vector3(-1.5,1.25,-3.88), Vector3(1.15,2.5,0.12), Color(0.17,0.09,0.085))
    _box("Старый постер", Vector3(-3.88,2.4,-1.0), Vector3(0.04,1.35,1.0), Color(0.22,0.11,0.19))
    # Hidden collectible under desk
    var disk = _box("Диск ДЕМО 1998", Vector3(2.6,0.12,-1.95), Vector3(0.25,0.035,0.25), Color(0.15,0.65,0.8))
    disk.set_meta("easter_egg", true)

func _box(label: String, pos: Vector3, size: Vector3, color: Color):
    var body = StaticBody3D.new()
    body.name = label
    body.position = pos
    var mesh = MeshInstance3D.new()
    var shape_mesh = BoxMesh.new()
    shape_mesh.size = size
    mesh.mesh = shape_mesh
    var mat = StandardMaterial3D.new()
    mat.albedo_color = color
    mat.roughness = 0.9
    mesh.material_override = mat
    body.add_child(mesh)
    var collision = CollisionShape3D.new()
    var shape = BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
    add_child(body)
    return body

func _make_player():
    player = CharacterBody3D.new()
    player.name = "Игрок"
    player.position = Vector3(0,0.1,2.6)
    player.set_script(load("res://scripts/player.gd"))
    add_child(player)

func _make_ui():
    ui = CanvasLayer.new()
    add_child(ui)
    hud = Control.new()
    hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    ui.add_child(hud)

    var top = Label.new()
    top.text = "ПОСЛЕДНЯЯ ИГРА   •   02:13"
    top.position = Vector2(24,18)
    top.add_theme_font_size_override("font_size",18)
    top.add_theme_color_override("font_color",Color(0.72,0.82,1))
    hud.add_child(top)

    story_label = Label.new()
    story_label.text = "Ты просыпаешься в своей комнате.\nКомпьютер почему-то уже включён."
    story_label.position = Vector2(24,570)
    story_label.size = Vector2(900,120)
    story_label.add_theme_font_size_override("font_size",21)
    story_label.add_theme_color_override("font_color",Color(0.86,0.88,0.96))
    hud.add_child(story_label)

    prompt_label = Label.new()
    prompt_label.text = "[E] Взаимодействовать"
    prompt_label.position = Vector2(500,625)
    prompt_label.add_theme_font_size_override("font_size",20)
    prompt_label.add_theme_color_override("font_color",Color(0.35,0.9,1))
    prompt_label.visible = false
    hud.add_child(prompt_label)

    var crosshair = Label.new()
    crosshair.text = "+"
    crosshair.set_anchors_preset(Control.PRESET_CENTER)
    crosshair.position = Vector2(-8,-18)
    crosshair.add_theme_font_size_override("font_size",24)
    hud.add_child(crosshair)

    if touch_mode:
        _add_touch_controls()

func _add_touch_controls():
    var move_box = VBoxContainer.new()
    move_box.position = Vector2(24,430)
    move_box.add_theme_constant_override("separation",5)
    hud.add_child(move_box)
    var row1 = HBoxContainer.new()
    var row2 = HBoxContainer.new()
    move_box.add_child(row1)
    move_box.add_child(row2)
    _touch_button(row1,"◀", "move_left")
    _touch_button(row1,"▲", "move_forward")
    _touch_button(row1,"▼", "move_back")
    _touch_button(row1,"▶", "move_right")
    var interact_btn = Button.new()
    interact_btn.text = "ДЕЙСТВИЕ"
    interact_btn.position = Vector2(1000,590)
    interact_btn.size = Vector2(180,70)
    interact_btn.pressed.connect(func(): _open_computer())
    hud.add_child(interact_btn)
    var look_note = Label.new()
    look_note.text = "Проводи пальцем по экрану, чтобы осмотреться"
    look_note.position = Vector2(600,670)
    look_note.add_theme_font_size_override("font_size",14)
    hud.add_child(look_note)

func _touch_button(parent: Control, caption: String, action: String):
    var b = Button.new()
    b.text = caption
    b.custom_minimum_size = Vector2(58,58)
    b.button_down.connect(func(): Input.action_press(action))
    b.button_up.connect(func(): Input.action_release(action))
    parent.add_child(b)

func _open_computer():
    if current_mode != "room":
        return
    computer_used = true
    screen_open = true
    current_mode = "computer"
    story_label.text = "Ты запускаешь старую игру.\nНа секунду экран становится чёрным..."
    _show_computer_menu()

func _show_computer_menu():
    _clear_overlay()
    var panel = _overlay_panel()
    var title = _label("CHILDHOOD.EXE", Vector2(70,45), 34, Color(0.25,0.9,1))
    panel.add_child(title)
    var desc = _label("АРХИВ ИГР  •  ДЕМО-СБОРКА 1998\n\nВыбери игру. Не выключай компьютер.", Vector2(75,110), 19)
    panel.add_child(desc)
    _menu_button(panel,"01  TETRIS.EXE",Vector2(75,205),func(): _start_tetris())
    _menu_button(panel,"02  SONIC-LIKE.EXE",Vector2(75,285),func(): _start_runner())
    _menu_button(panel,"03  MUSHROOM.EXE",Vector2(75,365),func(): _start_platformer())
    _menu_button(panel,"ВЕРНУТЬСЯ",Vector2(75,465),func(): _close_game_screen())

func _overlay_panel() -> Panel:
    var p = Panel.new()
    p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    var style = StyleBoxFlat.new()
    style.bg_color = Color(0.008,0.012,0.022,0.97)
    style.border_color = Color(0.12,0.55,0.7)
    style.set_border_width_all(2)
    p.add_theme_stylebox_override("panel",style)
    hud.add_child(p)
    return p

func _label(txt: String, pos: Vector2, size: int, color := Color(0.84,0.9,1)) -> Label:
    var l = Label.new()
    l.text = txt
    l.position = pos
    l.add_theme_font_size_override("font_size",size)
    l.add_theme_color_override("font_color",color)
    return l

func _menu_button(parent: Control, caption: String, pos: Vector2, callback: Callable):
    var b = Button.new()
    b.text = caption
    b.position = pos
    b.size = Vector2(420,58)
    b.add_theme_font_size_override("font_size",20)
    b.pressed.connect(callback)
    parent.add_child(b)

func _clear_overlay():
    for child in hud.get_children():
        if child is Panel:
            child.queue_free()

func _start_tetris():
    _clear_overlay()
    current_mode = "tetris"
    var panel = _overlay_panel()
    panel.add_child(_label("TETRIS.EXE",Vector2(40,20),30,Color(0.3,0.9,1)))
    panel.add_child(_label("Стрелки — двигать • ↑ — вращать • Пробел — падение",Vector2(40,65),16))
    var board_label = _label("",Vector2(470,120),22)
    board_label.name = "Board"
    panel.add_child(board_label)
    var info = _label("Собери 3 линии.\n\nПотом откроется следующая игра.",Vector2(850,160),20)
    panel.add_child(info)
    var tetris = Control.new()
    tetris.name = "TetrisLogic"
    tetris.set_script(load("res://scripts/tetris.gd"))
    tetris.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.add_child(tetris)
    tetris.call("setup",board_label,func(): _start_runner())
    _add_game_touch_controls(panel)

func _start_runner():
    _clear_overlay()
    current_mode = "runner"
    var panel = _overlay_panel()
    panel.add_child(_label("SONIC-LIKE.EXE",Vector2(40,20),30,Color(0.3,0.9,1)))
    panel.add_child(_label("A/D или ←/→ — уклонение • Пробел / ↑ — прыжок",Vector2(40,65),16))
    var runner = Control.new()
    runner.set_script(load("res://scripts/runner.gd"))
    runner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.add_child(runner)
    runner.call("setup",func(): _start_platformer())
    _add_game_touch_controls(panel)

func _start_platformer():
    _clear_overlay()
    current_mode = "platformer"
    var panel = _overlay_panel()
    panel.add_child(_label("MUSHROOM.EXE",Vector2(40,20),30,Color(0.3,0.9,1)))
    panel.add_child(_label("A/D или ←/→ — движение • Пробел / ↑ — прыжок",Vector2(40,65),16))
    var platform = Control.new()
    platform.set_script(load("res://scripts/platformer.gd"))
    platform.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.add_child(platform)
    platform.call("setup",func(): _ending())
    _add_game_touch_controls(panel)

func _ending():
    _clear_overlay()
    current_mode = "ending"
    var p = _overlay_panel()
    p.add_child(_label("ЭТО НЕ ТА ИГРА, КОТОРУЮ ТЫ ПОМНИШЬ.",Vector2(80,180),28,Color(1,0.25,0.28)))
    p.add_child(_label("На мониторе появляется новое сообщение:\n\n«Я ВИДЕЛА, КАК ТЫ ИГРАЛ. ТЕПЕРЬ МОЯ ОЧЕРЕДЬ».\n\nВ комнате за твоей спиной тихо скрипит дверь.",Vector2(80,250),21))
    _menu_button(p,"ВЕРНУТЬСЯ В КОМНАТУ",Vector2(80,440),func(): _close_game_screen())

func _close_game_screen():
    _clear_overlay()
    current_mode = "room"
    screen_open = false
    story_label.text = "Экран погас.\nНо из колонок всё ещё доносится тихое дыхание."


func _add_game_touch_controls(parent: Control):
    if not touch_mode:
        return
    var specs = [
        ["◀", "ui_left", Vector2(35,590)],
        ["▶", "ui_right", Vector2(115,590)],
        ["▼", "ui_down", Vector2(195,590)],
        ["▲", "ui_up", Vector2(275,590)],
        ["ПРЫЖОК", "ui_accept", Vector2(1010,590)]
    ]
    for spec in specs:
        var b = Button.new()
        b.text = spec[0]
        b.position = spec[2]
        b.size = Vector2(72,64) if spec[0] != "ПРЫЖОК" else Vector2(150,64)
        b.button_down.connect(func(): Input.action_press(spec[1]))
        b.button_up.connect(func(): Input.action_release(spec[1]))
        parent.add_child(b)
