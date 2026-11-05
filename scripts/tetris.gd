extends Control

const W := 10
const H := 18
const SHAPES = [
    [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)],
    [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(3,0)],
    [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(2,1)],
    [Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)],
    [Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(1,2)]
]
var grid := []
var piece := []
var pos := Vector2i(3,0)
var board_label: Label
var advance: Callable
var lines := 0
var fall := 0.0
var finished := false

func setup(label: Label, next: Callable):
    board_label = label
    advance = next
    for y in H:
        var row=[]
        for x in W: row.append(0)
        grid.append(row)
    _new_piece()
    _draw_board()

func _process(delta):
    if finished: return
    fall += delta
    if fall > 0.55:
        fall = 0
        _move(Vector2i(0,1))

func _unhandled_input(event):
    if finished: return
    if event.is_action_pressed("ui_left"): _move(Vector2i(-1,0))
    if event.is_action_pressed("ui_right"): _move(Vector2i(1,0))
    if event.is_action_pressed("ui_down"): _move(Vector2i(0,1))
    if event.is_action_pressed("ui_up"): _rotate()
    if event.is_action_pressed("ui_accept"): 
        while _valid(pos + Vector2i(0,1),piece): pos.y += 1
        _lock()

func _new_piece():
    piece = SHAPES[randi() % SHAPES.size()].duplicate()
    pos = Vector2i(3,0)
    if not _valid(pos,piece):
        finished = true
        board_label.text = "GAME OVER\nЛинии: %d\nНажми «ВЕРНУТЬСЯ» и попробуй снова." % lines

func _valid(p: Vector2i, shape: Array) -> bool:
    for cell in shape:
        var x=p.x+cell.x
        var y=p.y+cell.y
        if x<0 or x>=W or y<0 or y>=H: return false
        if grid[y][x] != 0: return false
    return true

func _move(d: Vector2i):
    if _valid(pos+d,piece):
        pos += d
    else:
        if d.y > 0: _lock()
    _draw_board()

func _rotate():
    var rotated=[]
    for c in piece:
        rotated.append(Vector2i(-c.y,c.x))
    var min_x=99
    var min_y=99
    for c in rotated:
        min_x=min(min_x,c.x); min_y=min(min_y,c.y)
    for i in rotated.size():
        rotated[i] -= Vector2i(min_x,min_y)
    if _valid(pos,rotated): piece=rotated
    _draw_board()

func _lock():
    for c in piece:
        var x=pos.x+c.x
        var y=pos.y+c.y
        if y>=0 and y<H and x>=0 and x<W: grid[y][x]=1
    var y=H-1
    while y>=0:
        var full=true
        for x in W:
            if grid[y][x]==0: full=false
        if full:
            grid.remove_at(y)
            var row=[]
            for x in W: row.append(0)
            grid.push_front(row)
            lines += 1
        else:
            y-=1
    if lines>=3:
        finished=true
        board_label.text="ЛИНИИ СОБРАНЫ: 3\n\nЭкран моргнул.\nВ следующей игре кто-то уже ждёт тебя..."
        await get_tree().create_timer(2.0).timeout
        advance.call()
        return
    _new_piece()
    _draw_board()

func _draw_board():
    if not board_label: return
    var out="ЛИНИИ: %d / 3\n\n" % lines
    for y in H:
        for x in W:
            var occupied=grid[y][x] != 0
            if not occupied:
                for c in piece:
                    if pos.x+c.x==x and pos.y+c.y==y: occupied=true
            out += "■ " if occupied else "· "
        out += "\n"
    board_label.text=out
