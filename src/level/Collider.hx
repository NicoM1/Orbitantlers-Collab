package level;

import luxe.Sprite;
import phoenix.Vector;
import phoenix.Texture;
import phoenix.geometry.RectangleGeometry;
import phoenix.geometry.Vertex;

import luxe.collision.shapes.Polygon;
import luxe.collision.Collision;

import luxe.collision.ShapeDrawerLuxe;

class Collider extends Polygon {

	var _geom: RectangleGeometry;

	var _lastMouse: Vector;
	var _moving: Bool = false;
	var _resizing: Bool = false;

	var _w: Float;
	var _h: Float;

	var _test: ShapeDrawerLuxe;

	public function new(x_: Float, y_: Float, w_: Float, h_: Float) {
		var rect = Polygon.rectangle(x_, y_, w_, h_, false);
		super(rect.x, rect.y, rect.vertices);

		_test = new ShapeDrawerLuxe();

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

	public function changePos(x_: Float, y_: Float, offset_: Bool = true) {
		if(offset_) {
			x_ += x;
			y_ += y;
		}
		x = x_;
		y = y_;
		_resetVisual();
	}

	public function changeSize(w_: Float, h_: Float, offset_: Bool = true) {
		if(offset_) {
			w_ += _w;
			h_ += _h;
		}
		if(w_ < 15 || h_ < 15) return;
		_w = w_;
		_h = h_;

		//HACK SO NEW SHAPE REGISTERS
		refresh_transform();

		vertices[1].x = _w;
		vertices[2].x = _w;
		vertices[2].y = _h;
		vertices[3].y = _h;

		_resetVisual();
	}

	public function update() {
		_makeChanges();
	}

	function _makeChanges() {
		if(Luxe.input.mousedown(1)) {
			if(_mouseInside() || _moving || _resizing) {

		 		_geom.color.g = 0;

		 		var delta = _lastMouse.subtract(Luxe.mouse);
		 		var mousePos = Vector.Subtract(Luxe.mouse, position);

		 		if(!_resizing && (mousePos.x < _w - 10 || mousePos.y < _h - 10)) {
		 			_moving = true;
		 			changePos(-delta.x, -delta.y);
		 		}
		 		else if (!_moving) {
		 			_resizing = true;
		 			changeSize(-delta.x, -delta.y);
		 		}
		 	}
		}
		else {
			_geom.color.g = 1;
			_moving = false;
			_resizing = false;
		}
		_lastMouse.copy_from(Luxe.mouse);
	}

	function _resetVisual() {
		//_test.drawPolygon(this);
		_geom.transform.pos.x = x;
		_geom.transform.pos.y = y;
		_geom.vertices[1].pos.x = _w;
		_geom.vertices[2].pos.x = _w;
		_geom.vertices[3].pos.y = _h;
		_geom.vertices[4].pos.y = _h;
		_geom.vertices[3].pos.x = _w;
		_geom.vertices[4].pos.x = _w;
		_geom.vertices[5].pos.y = _h;
		_geom.vertices[6].pos.y = _h;
	}

	function _mouseInside(): Bool {
		var is = Collision.pointInPoly(Luxe.mouse, this);
			//Luxe.mouse.x > x &&
			//Luxe.mouse.x < x + _w &&
			//Luxe.mouse.y > y &&
			//Luxe.mouse.y < y + _h;
		return is;
	}

	function toggleDebug() {
		_geom.visible = !_geom.visible;
	}
}