class_name ItemData extends Resource

@export_category("Informações")
@export var item_name: String = ""
@export var category: String = ""
@export_multiline var description: String = ""

@export_category("Visual")
@export var icon: Texture2D

@export_category("Inventário")
@export var max_stack: int = 99

@export_category("Informativo — efeitos")
@export var energy: int = 0
@export var health: int = 0

@export_category("Informativo — venda")
## -1 oculta o preço. O valor exibido é por unidade.
@export var sell_price: int = -1
