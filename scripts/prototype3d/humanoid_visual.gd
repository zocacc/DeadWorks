extends Node3D
class_name HumanoidVisual

const SURVIVOR = preload("res://assets/characters/survivor_swat.glb")
const INFECTED = preload("res://assets/characters/zombie_hoodie.glb")
const RIFLE = preload("res://assets/weapons/rifle.glb")
const ANIM_PREFIX := "CharacterArmature|"

@export var zombie := false
@export_range(0.5, 2.0, 0.05) var model_scale := 1.0

var skeleton: Skeleton3D
var animation_player: AnimationPlayer
var rifle: Node3D
var muzzle: Marker3D
var _model: Node3D
var _motion := 0.0
var _attack_time := 0.0
var _hurt_time := 0.0
var _dead := false
var _recoil := 0.0
var _materials: Array[StandardMaterial3D] = []
var _colors: Array[Color] = []


func _ready() -> void:
	_model = (INFECTED if zombie else SURVIVOR).instantiate()
	add_child(_model)
	# The imported animation corrects the original up axis on the armature.
	_model.scale = Vector3.ONE * model_scale
	skeleton = _model.find_child("Skeleton3D", true, false) as Skeleton3D
	animation_player = _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if skeleton == null or animation_player == null:
		push_error("Modelo humanoide sem esqueleto ou animações")
		return
	for clip in ["Idle", "Idle_Gun", "Walk", "Run"]:
		animation_player.get_animation(ANIM_PREFIX + clip).loop_mode = Animation.LOOP_LINEAR
	_prepare_materials()
	if not zombie:
		_attach_rifle()
	_play("Idle" if zombie else "Idle_Gun")


func _prepare_materials() -> void:
	for child in skeleton.get_children():
		if not child is MeshInstance3D:
			continue
		var mesh := child as MeshInstance3D
		for surface in mesh.mesh.get_surface_count():
			var source := mesh.mesh.surface_get_material(surface) as StandardMaterial3D
			if source == null:
				continue
			var material := source.duplicate() as StandardMaterial3D
			if zombie:
				match source.resource_name:
					"Skin": material.albedo_color = Color("829285")
					"Purple": material.albedo_color = Color("464b46")
					"LightBlue": material.albedo_color = Color("3e4544")
					"White": material.albedo_color = Color("77776b")
			mesh.set_surface_override_material(surface, material)
			_materials.append(material)
			_colors.append(material.albedo_color)


func _attach_rifle() -> void:
	var grip := BoneAttachment3D.new()
	grip.name = "WeaponGrip"
	grip.bone_name = "Wrist.R"
	skeleton.add_child(grip)
	rifle = RIFLE.instantiate()
	rifle.name = "Rifle"
	grip.add_child(rifle)
	# The armature and weapon meshes both carry the source's 100x GLB scale.
	rifle.top_level = true
	_update_rifle_pose()
	muzzle = Marker3D.new()
	muzzle.name = "Muzzle"
	rifle.add_child(muzzle)
	muzzle.position = Vector3(3.55, 0.0, 0.0)


func _update_rifle_pose() -> void:
	var grip := rifle.get_parent() as BoneAttachment3D
	var body_basis := global_basis.orthonormalized()
	var recoil_offset := Vector3(0.23, 0.15, -0.35 + _recoil * 0.08)
	rifle.global_transform = Transform3D((body_basis * Basis(Vector3.UP, PI / 2.0)).scaled(Vector3.ONE * 0.22), grip.global_position + body_basis * recoil_offset)


func get_muzzle_global_position() -> Vector3:
	if muzzle != null:
		return muzzle.global_position
	return global_position + Vector3.UP * 1.35 - global_basis.z * 0.65


func set_motion(speed_ratio: float) -> void:
	_motion = clampf(speed_ratio, 0.0, 1.0)


func play_attack() -> void:
	if _dead:
		return
	_attack_time = 0.27 if not zombie else 0.68
	_play("Gun_Shoot" if not zombie else "Punch_Right", true)
	_recoil = 1.0 if not zombie else 0.0


func play_hurt() -> void:
	if _dead:
		return
	_hurt_time = 0.22
	_play("HitRecieve", true)


func play_death() -> void:
	_dead = true
	_motion = 0.0
	animation_player.speed_scale = 1.0
	_play("Death", true)


func _play(name: String, restart := false) -> void:
	if animation_player == null:
		return
	var full_name := ANIM_PREFIX + name
	if not animation_player.has_animation(full_name):
		return
	if restart or animation_player.current_animation != full_name or not animation_player.is_playing():
		animation_player.play(full_name, 0.12 if not restart else 0.04)


func _process(delta: float) -> void:
	if animation_player == null:
		return
	if _dead:
		return
	_attack_time = maxf(0.0, _attack_time - delta)
	_hurt_time = maxf(0.0, _hurt_time - delta)
	_recoil = maxf(0.0, _recoil - delta * 9.0)
	if rifle != null:
		_update_rifle_pose()
	if _attack_time <= 0.0 and _hurt_time <= 0.0:
		var locomotion := "Idle" if zombie else "Idle_Gun"
		if _motion > 0.05:
			locomotion = "Walk" if zombie or _motion <= 0.7 else "Run"
		_play(locomotion)
		animation_player.speed_scale = 0.9 + _motion * 0.4 if _motion > 0.05 else 1.0
	for index in _materials.size():
		_materials[index].albedo_color = _colors[index].lerp(Color("e28a7d"), 0.55 if _hurt_time > 0.0 else 0.0)
