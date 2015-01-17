package enemies;

import luxe.Sprite;

import phoenix.Vector;
import phoenix.Texture;

import luxe.Input;

class Enemy extends Sprite {

	public function new() {
		super({
			name: 'enemy',
			name_unique: true,
			texture: texture,
			size: new Vector(23, 41),
			pos: new Vector(76, 717)
		});

		add(new AIComponent());
	}
}