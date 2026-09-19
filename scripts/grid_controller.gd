class_name GridController
extends RefCounted

var columns: int
var rows: int
var cell_size: int

func _init(p_columns: int = 18, p_rows: int = 9, p_cell_size: int = 56) -> void:
	columns = p_columns
	rows = p_rows
	cell_size = p_cell_size

func clamp_cell(cell: Vector2i) -> Vector2i:
	return Vector2i(clampi(cell.x, 0, columns - 1), clampi(cell.y, 0, rows - 1))

func neighbors(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for offset in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
		var candidate := cell + offset
		if candidate.x >= 0 and candidate.x < columns and candidate.y >= 0 and candidate.y < rows:
			result.append(candidate)
	return result
