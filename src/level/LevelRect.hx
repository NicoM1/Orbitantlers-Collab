package level;

import phoenix.geometry.RectangleGeometry;
import phoenix.Vector;

import luxe.collision.shapes.Polygon;
import luxe.collision.Collision;

class LevelRect extends Polygon {

	var _geom: RectangleGeometry;
	var _lastMouse: Vector;
	var _pressed: Bool = false;

	public function new(_x: Float, _y: Float, _w: Float, _h: Float) {
		var rect = Polygon.rectangle(_x, _y, _w, _h, false);

		super(rect.x, rect.y, rect.vertices);

		_geom = new RectangleGeometry({
			x: _x,
			y: _y,
			w: _w,
			h: _h
		});
		Luxe.renderer.batcher.add(_geom);

		_lastMouse = new Vector();
	}

	public function change(_x: Float, _y: Float, _offset: Bool = true) {
		if(_offset) {
			_x += x;
			_y += y;
		}
		trace(_x, _y);
		x = _x;
		y = _y;
		_resetVisual();
	}

	public function update() {
		_makeChanges();
	}

	function _makeChanges() {
		if(Luxe.input.mousedown(1)) {
			if(_mouseInside() || _pressed) {

				_pressed = true;
		 		_geom.color.g = 0;

		 		var delta = _lastMouse.subtract(Luxe.mouse);
		 		trace(delta);
		 		change(delta.x, delta.y);
		 	}
		}
		else {
			_geom.color.g = 1;
			_pressed = false;
		}
		_lastMouse.copy_from(Luxe.mouse);
	}

	function _mouseInside(): Bool {
		return Collision.pointInPoly(Luxe.mouse, this);
	}

	function _resetVisual() {
		_geom.transform.pos.x = x;
		_geom.transform.pos.y = y;
	}
}