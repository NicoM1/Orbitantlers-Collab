package level;

import luxe.Sprite;
import phoenix.Vector;
import phoenix.Texture;
import phoenix.geometry.RectangleGeometry;
import phoenix.geometry.Vertex;

import luxe.collision.shapes.Polygon;
import luxe.collision.Collision;

import luxe.collision.ShapeDrawerLuxe;

import player.MovementComponent;

class Collider extends Polygon {

	var _geom: RectangleGeometry;

	var _lastMouse: Vector;
	var _moving: Bool = false;
	var _resizing: Bool = false;
	public var selected(default, null): Bool = false;

	public var w(default, null): Float;
	public var h(default, null): Float;

	var _test: ShapeDrawerLuxe;

	public var portalTarget: String = '';
	var _player: Polygon = null;

	public function new(x_: Float, y_: Float, w_: Float, h_: Float) {
		var rect = Polygon.rectangle(x_, y_, w_, h_, false);
		super(rect.x, rect.y, rect.vertices);

		_test = new ShapeDrawerLuxe();

		_lastMouse = new Vector();

		w = w_;
		h = h_;

		_geom = new RectangleGeometry({
			x: x_,
			y: y_,
			w: w_,
			h: h_,
			batcher: Luxe.renderer.batcher
		});

		_geom.depth = 10;
		//toggleDebug();

		_player = cast (Luxe.scene.entities.get('player').get('movement'), MovementComponent).getCollision();
	}

	public function select() {
		selected = true;
	}

	public function deselect() {
		selected = false;
		_moving = false;
		_resizing = false;
	}

	public function toggleSelected() {
		selected = !selected;
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
			w_ += w;
			h_ += h;
		}
		if(w_ < 15 || h_ < 15) return;
		w = w_;
		h = h_;

		//HACK SO NEW SHAPE REGISTERS
		refresh_transform();

		vertices[1].x = w;
		vertices[2].x = w;
		vertices[2].y = h; 
		vertices[3].y = h;

		_resetVisual();
	}

	public function update() {
		if(Luxe.input.mousereleased(1)) {
			_moving = false;
			_resizing = false;
		}
		_makeChanges();
	}

	public function checkPortal() {
		_geom.color.r = 0;
		if(Collision.test(this, _player) != null) {
			Level.instance.loadLevel(portalTarget);
		}
	}

	function _makeChanges() {
		if(selected) _moving = false;
		if(_moving || _resizing || selected) {
			_geom.color.g = 0;

			if(Luxe.input.mousedown(1)) {

		 		var delta = _lastMouse.subtract(Luxe.camera.screen_point_to_world(Luxe.mouse));
		 		var mousePos = Vector.Subtract(Luxe.camera.screen_point_to_world(Luxe.mouse), position);

		 		if(!_resizing && ((mousePos.x < w - 10 || mousePos.y < h - 10) || Level.instance._selectedCount > 1)) {//|| selected
		 			_moving = true;
		 			changePos(-delta.x, -delta.y);
		 		}
		 		else if (!_moving && Level.instance._selectedCount == 1) { // && !selected
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
		_lastMouse.copy_from(Luxe.camera.screen_point_to_world(Luxe.mouse));
	}

	function _resetVisual() {
		//_test.drawPolygon(this);
		_geom.transform.pos.x = x;
		_geom.transform.pos.y = y;
		_geom.vertices[1].pos.x = w;
		_geom.vertices[2].pos.x = w;
		_geom.vertices[3].pos.y = h;
		_geom.vertices[4].pos.y = h;
		_geom.vertices[3].pos.x = w;
		_geom.vertices[4].pos.x = w;
		_geom.vertices[5].pos.y = h;
		_geom.vertices[6].pos.y = h;
	}

	public function mouseInside(): Bool {
		var is = Collision.pointInPoly(Luxe.camera.screen_point_to_world(Luxe.mouse), this);

		return is;
	}

	public function toggleDebug() {
		_geom.visible = !_geom.visible;
	}

	override function destroy() {
		_geom.visible = false;
		_geom.drop();
		super.destroy();
	}
}