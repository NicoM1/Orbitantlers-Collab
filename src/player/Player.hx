package player;

import luxe.Sprite;

import phoenix.Vector;
import phoenix.Texture;

import luxe.components.sprite.SpriteAnimation;

import luxe.Input;

class Player extends Sprite {

	var _camSpeedMult: Float = 2.0;

	var _lockCamera: Bool = false;
	var _camSpeed: Float = 100;

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

		if(Luxe.input.keypressed(Key.key_c)) {
			_lockCamera = !_lockCamera;
		}

		if(!_lockCamera) {
			var dist: Vector = Vector.Subtract(pos, Luxe.camera.pos);

			Luxe.camera.pos.x += (dist.x - Luxe.screen.w / 2) * dt * _camSpeedMult;
			Luxe.camera.pos.y += (dist.y - Luxe.screen.h / 2) * dt * _camSpeedMult;
		}
		else {
			if(Luxe.mouse.x < 10) Luxe.camera.pos.x -= dt * _camSpeed;
			if(Luxe.mouse.x > Luxe.screen.w - 10) Luxe.camera.pos.x += dt * _camSpeed;
			if(Luxe.mouse.y < 10) Luxe.camera.pos.y -= dt * _camSpeed;
			if(Luxe.mouse.y > Luxe.screen.h - 10) Luxe.camera.pos.y += dt * _camSpeed;
		}
	}

	function _createAnim() {
		var animJSON = Luxe.loadJSON('assets/files/character_anim.json');
		var anim = add(new SpriteAnimation({name: 'anim'}));
		anim.add_from_json_object(animJSON.json);
		anim.play();
	}
}