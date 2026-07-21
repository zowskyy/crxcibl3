extends Node
## AnimationLoader — Slice 3.8-anim helper (static utility, not an autoload).
##
## Builds a SpriteFrames resource from a horizontal sprite sheet PNG at runtime.
## Call build_frames() to get a ready-to-use SpriteFrames, then assign it to
## an AnimatedSprite2D node.  Returns null if the file doesn't exist so callers
## can fall back to their _draw() placeholder without crashing.
##
## Sheet convention (Metal Slug–style horizontal strip):
##   • All frames for one animation on a single row.
##   • Each frame is frame_w × frame_h pixels.
##   • Sheet filename: res://assets/sprites/<character>/<anim_name>.png
##     e.g. res://assets/sprites/player/walk_right.png
##
## FPS defaults match Metal Slug playback speed (~12 fps for walk/run, 8 for idle).

const DEFAULT_FPS_WALK  := 12
const DEFAULT_FPS_IDLE  := 8
const DEFAULT_FPS_SHOOT := 12
const DEFAULT_FPS_DIE   := 10


## Build a SpriteFrames from a list of animation descriptors.
##
## anim_list entries:
##   { name, path, frame_w, frame_h, fps, loop }
##
## Returns a SpriteFrames, or null if ALL paths are missing.
static func build_frames(anim_list: Array) -> SpriteFrames:
	var sf := SpriteFrames.new()
	var any_loaded := false

	for anim: Dictionary in anim_list:
		var anim_name: String   = anim.get("name",    "idle")
		var path: String        = anim.get("path",    "")
		var frame_w: int        = anim.get("frame_w", 32)
		var frame_h: int        = anim.get("frame_h", 32)
		var fps: int            = anim.get("fps",     DEFAULT_FPS_WALK)
		var loop: bool          = anim.get("loop",    true)

		if not ResourceLoader.exists(path):
			# Sheet not imported yet — add a 1-frame dummy so the animation
			# name exists and play() doesn't error, but stays invisible.
			if not sf.has_animation(anim_name):
				sf.add_animation(anim_name)
			sf.set_animation_loop(anim_name, loop)
			sf.set_animation_speed(anim_name, fps)
			continue

		var tex := load(path) as Texture2D
		if tex == null:
			continue

		var img_w   := tex.get_width()
		var n_frames := img_w / frame_w

		if not sf.has_animation(anim_name):
			sf.add_animation(anim_name)
		sf.set_animation_loop(anim_name, loop)
		sf.set_animation_speed(anim_name, fps)

		for i in range(n_frames):
			var atlas := AtlasTexture.new()
			atlas.atlas  = tex
			atlas.region = Rect2(i * frame_w, 0, frame_w, frame_h)
			sf.add_frame(anim_name, atlas)

		any_loaded = true

	return sf if any_loaded else null


## Convenience: descriptor helpers so callers don't write raw dicts.

static func anim(name: String, path: String,
		frame_w: int, frame_h: int,
		fps: int = DEFAULT_FPS_WALK,
		loop: bool = true) -> Dictionary:
	return {
		"name":    name,
		"path":    path,
		"frame_w": frame_w,
		"frame_h": frame_h,
		"fps":     fps,
		"loop":    loop,
	}


## Standard descriptor set for the player character.
## Frame size 32×48 for a 3/4-view hero at Metal Slug scale.
static func player_anims(sprite_dir: String) -> Array:
	var w := 32; var h := 48
	return [
		anim("idle",       sprite_dir + "idle.png",       w, h, DEFAULT_FPS_IDLE,  true),
		anim("walk_right", sprite_dir + "walk_right.png", w, h, DEFAULT_FPS_WALK,  true),
		anim("walk_left",  sprite_dir + "walk_left.png",  w, h, DEFAULT_FPS_WALK,  true),
		anim("walk_up",    sprite_dir + "walk_up.png",    w, h, DEFAULT_FPS_WALK,  true),
		anim("walk_down",  sprite_dir + "walk_down.png",  w, h, DEFAULT_FPS_WALK,  true),
		anim("shoot",      sprite_dir + "shoot.png",      w, h, DEFAULT_FPS_SHOOT, false),
		anim("downed",     sprite_dir + "downed.png",     w, h, DEFAULT_FPS_DIE,   false),
	]


## Standard descriptor set for a grunt enemy. Frame 24×32.
static func enemy_anims(sprite_dir: String) -> Array:
	var w := 24; var h := 32
	return [
		anim("idle",   sprite_dir + "idle.png",   w, h, DEFAULT_FPS_IDLE,  true),
		anim("walk",   sprite_dir + "walk.png",   w, h, DEFAULT_FPS_WALK,  true),
		anim("attack", sprite_dir + "attack.png", w, h, DEFAULT_FPS_SHOOT, false),
		anim("die",    sprite_dir + "die.png",    w, h, DEFAULT_FPS_DIE,   false),
	]


## Standard descriptor set for a boss character. Frame 48×64.
static func boss_anims(sprite_dir: String) -> Array:
	var w := 48; var h := 64
	return [
		anim("idle",   sprite_dir + "idle.png",   w, h, DEFAULT_FPS_IDLE,  true),
		anim("walk",   sprite_dir + "walk.png",   w, h, DEFAULT_FPS_WALK,  true),
		anim("attack", sprite_dir + "attack.png", w, h, DEFAULT_FPS_SHOOT, false),
		anim("die",    sprite_dir + "die.png",    w, h, DEFAULT_FPS_DIE,   false),
		anim("flee",   sprite_dir + "flee.png",   w, h, DEFAULT_FPS_WALK,  false),
	]
