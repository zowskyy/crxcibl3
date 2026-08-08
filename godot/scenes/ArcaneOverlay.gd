extends CanvasLayer
## Full-screen Arcane painterly grade (shared across gameplay scenes).

const SHADER := preload("res://assets/shaders/arcane_grade.gdshader")

@onready var rect: ColorRect = $GradeRect


func _ready() -> void:
	layer = 90
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("intensity", 0.82)
	rect.material = mat
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
