package player;

import luxe.Sprite;

import phoenix.Vector;
import phoenix.Texture;

import luxe.components.sprite.SpriteAnimation;

class Player extends Sprite {

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

	function _createAnim() {
		var animJSON = Luxe.loadJSON('assets/files/character_anim.json');
		var anim = add(new SpriteAnimation({name: 'anim'}));
		anim.add_from_json_object(animJSON.json);
		anim.play();
	}
}