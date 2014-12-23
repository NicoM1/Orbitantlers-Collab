package level;

import luxe.Sprite;
import phoenix.Vector;
import phoenix.Texture;

import luxe.collision.shapes.Polygon;
import luxe.collision.shapes.Shape;

import snow.input.Keycodes;

import haxe.Json;

#if desktop
import sys.io.File;
#end

class Level {

	static public var colliders(default, null): Array<Collider>;
	var visuals: Array<Sprite>;

	var _editMode: Bool = true;

	public function new() {
		colliders = new Array<Collider>();
		visuals = new Array<Sprite>();

		parseJSON('assets/files/output.lvl');
	}

	public function update() {
		if(_editMode) {
			if(Luxe.input.mousepressed(3)) {
				_addColider(Luxe.mouse.x, Luxe.mouse.y, 32, 32);
			}
			for (c in colliders) c.update();
		}
	}

	public function parseJSON(path: String) {
		var json = Luxe.loadJSON(path).json;
		var map: MapStruct = cast json;

		for(v in map.visuals) {
			_addVisual(v.x, v.y, v.w, v.h, v.art);
		}
		for(c in map.colliders) {
			_addColider(c.x, c.y, c.w, c.h);
		}
	}

	public function saveJSON(path: String) {
		#if desktop
			trace('attempting save');
			var fout = File.write(path, false);
			var json = _makeJSON();
			fout.writeString(Json.stringify(json));
			fout.close();
		#else
			trace('save only available on desktop');
		#end
	}

	function _makeJSON(): MapStruct {
		var json: MapStruct = {
			visuals: new Array<VisualStruct>(),
			colliders: new Array<ColliderStruct>()
		};

		for(c in colliders) {
			var cJSON: ColliderStruct = {
				x: c.x,
				y: c.y,
				w: c.w,
				h: c.h
			};
			json.colliders.push(cJSON);
		}

		return json;
	}

	function _addColider(x: Float, y: Float, w: Float, h: Float) {
		var collider = new Collider(x, y, w, h);
		colliders.push(collider);
	}

	function _addVisual(x: Float, y: Float, w: Float, h: Float, art: String) {
		var visual = new Sprite ({
			texture: Luxe.loadTexture(art),
			pos: new Vector(x + w/2, y + h/2),
			size: new Vector(w, h),
			depth: -1
		});
		visuals.push(visual);
	}

	function toggleEdit() {
		_editMode = !_editMode;
	}
}

typedef MapStruct = {
	visuals: Array<VisualStruct>,
	colliders: Array<ColliderStruct>
}

typedef VisualStruct = {
	x: Float,
	y: Float,
	w: Float,
	h: Float,
	art: String
}

typedef ColliderStruct = {
	x: Float,
	y: Float,
	w: Float,
	h: Float
}