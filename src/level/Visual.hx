package level;

import luxe.Sprite;
import phoenix.Vector;
import phoenix.Texture;

import phoenix.geometry.CircleGeometry;
import luxe.Input;

class Visual extends Sprite {
	var _geom: CircleGeometry;

	var _pressed: Bool = false;

	public var kill = false;

	public var art: String;

	public function new(x_: Float, y_: Float, w_: Float, h_: Float, art: String) {
		this.art = art;

		var texture = Luxe.loadTexture(art);
		texture.filter = FilterType.nearest;
		super ({
			texture: texture,
			pos: new Vector(x_ + w_/2, y_ + h_/2),
			size: new Vector(w_, h_),
			depth: -1
		});

		_geom = new CircleGeometry({
			r: 10,
			x: pos.x,
			y: pos.y,
			batcher: Luxe.renderer.batcher
		});

		_geom.depth = 10;

		toggleDebug();
	}

	public function updateDebug() {
		_geom.transform.pos.x = pos.x;
		_geom.transform.pos.y = pos.y;

		var mouse = Luxe.camera.screen_point_to_world(Luxe.mouse);
		var dist: Vector = Vector.Subtract(pos, mouse);
		if(Luxe.input.mousepressed(1)) {
			if(dist.length < 10) {
				_pressed = true;
			}
		}
		if(_pressed) {
			pos.subtract(dist);
			if(Luxe.input.keypressed(Key.period)) {
				depth++;
			}
			else if(Luxe.input.keypressed(Key.comma)) {
				depth--;
			}
			else if(Luxe.input.keypressed(Key.key_x)) {
				kill = true;
			}
		}
		if(Luxe.input.mousereleased(1)) {
			_pressed = false;
		}
	}

	public function toggleDebug() {
		_geom.visible = !_geom.visible;
	}

	public function enableDebug() {
		_geom.visible = true;
	}

	public function disableDebug() {
		_geom.visible = false;
	}

	override function destroy(?_) {
		_geom.visible = false;
		_geom.drop();
		super.destroy();
	}
}