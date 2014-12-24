package player;

import luxe.Sprite;

import phoenix.Vector;
import phoenix.Texture;

import luxe.components.sprite.SpriteAnimation;

class Player extends Sprite {

	var _camSpeedMult: Float = 2.0;

	public function new() {
		var texture = Luxe.loadTexture('assets/art/character/run_strip.png');
		texture.filter = FilterType.nearest;

		super({
			name: 'player',
			texture: texture,
			size: new Vector(37, 40)
		});

		_createAnim();

		add(new MovementComponent());
	}

	override function update(dt: Float) {
		var dist: Vector = Vector.Subtract(pos, Luxe.camera.pos);

		Luxe.camera.pos.x += (dist.x - Luxe.screen.w / 2) * dt * _camSpeedMult;
		Luxe.camera.pos.y += (dist.y - Luxe.screen.h / 2) * dt * _camSpeedMult;
	}

	function _createAnim() {
		var animJSON = Luxe.loadJSON('assets/files/character_anim.json');
		var anim = add(new SpriteAnimation({name: 'anim'}));
		anim.add_from_json_object(animJSON.json);
		anim.play();
	}
}