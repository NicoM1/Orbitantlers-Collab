package player;

import luxe.Component;
import luxe.Sprite;
import phoenix.Vector;

import luxe.Input;

class CameraComponent extends Component {

	var _camSpeedMult: Float = 2.0;

	var _lockCamera: Bool = false;
	var _camSpeed: Float = 100;

	var deadZone: Float = 500;

	public var lookPoint: Vector;

	public function new() {
		super({name: 'camera'});
	}

	override function update(dt: Float) {
		if(Luxe.input.keypressed(Key.key_c)) {
			_lockCamera = !_lockCamera;
		}

		if(!_lockCamera) {
			var dist: Vector = Vector.Subtract(lookPoint, Luxe.camera.pos);
			Luxe.camera.pos.x += (dist.x - Luxe.screen.w / 2) * dt * _camSpeedMult;
			Luxe.camera.pos.y += (dist.y - Luxe.screen.h / 2) * dt * _camSpeedMult * 2.5;		
		}
		else {
			if(Luxe.mouse.x < 10) Luxe.camera.pos.x -= dt * _camSpeed;
			if(Luxe.mouse.x > Luxe.screen.w - 10) Luxe.camera.pos.x += dt * _camSpeed;
			if(Luxe.mouse.y < 10) Luxe.camera.pos.y -= dt * _camSpeed;
			if(Luxe.mouse.y > Luxe.screen.h - 10) Luxe.camera.pos.y += dt * _camSpeed;
		}
	}

} 	