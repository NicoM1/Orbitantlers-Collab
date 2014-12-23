package level;

import luxe.Sprite;
import phoenix.Vector;
import phoenix.Texture;
import phoenix.geometry.RectangleGeometry;

import luxe.collision.shapes.Polygon;
import luxe.collision.Collision;

class Collider extends Polygon {

	var _geom: RectangleGeometry;

	var _lastMouse: Vector;
	var _pressed: Bool = false;

	var _w: Float;
	var _h: Float;

	public function new(x_: Float, y_: Float, w_: Float, h_: Float) {
		var rect = Polygon.rectangle(x_, y_, w_, h_, false);
		super(rect.x, rect.y, rect.vertices);

		_lastMouse = new Vector();

		_w = w_;
		_h = h_;

		_geom = new RectangleGeometry({
			x: x_,
			y: y_,
			w: w_,
			h: h_,
			batcher: Luxe.renderer.batcher
		});

		//Luxe.renderer.batcher.add(_geom);
		_geom.depth = 10;
		//toggleDebug();
	}

	public function change(x_: Float, y_: Float, ?w_: Float, ?h_: Float, offset_: Bool = true) {
		if(offset_) {
			x_ += x;
			y_ += y;
			if(w_ != null) w_ += _w;
			if(h_ != null) h_ += _h;
		}
		x = x_;
		y = y_;
		if(w_ != null) _w = w_;
		if(h_ != null) _h = h_;
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
		 		change(-delta.x, -delta.y);
		 	}
		}
		else {
			_geom.color.g = 1;
			_pressed = false;
		}
		_lastMouse.copy_from(Luxe.mouse);
	}

	function _resetVisual() {
		_geom.transform.pos.x = x;
		_geom.transform.pos.y = y;
	}

	function _mouseInside(): Bool {
		return Collision.pointInPoly(Luxe.mouse, this);
	}

	function toggleDebug() {
		_geom.visible = !_geom.visible;
	}
}