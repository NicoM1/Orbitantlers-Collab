package level;

import luxe.Sprite;
import phoenix.Vector;
import phoenix.Texture;

import luxe.collision.shapes.Polygon;
import luxe.collision.shapes.Shape;

import snow.input.Keycodes;
import luxe.Input;

import haxe.Json;

#if desktop
import sys.io.File;
#end

class Level {

	static public var colliders(default, null): Array<Collider>;
	var visuals: Array<Sprite>;

	var _editMode: Bool = true;

	var _selectedCount: Int = 0;

	public function new() {
		colliders = new Array<Collider>();
		visuals = new Array<Sprite>();

		parseJSON('assets/files/output.lvl');
	}

	public function update() {
		if(_editMode) {
			var safe: Bool = false;
			if(Luxe.input.mousepressed(3)) {
				_addColider(Luxe.mouse.x, Luxe.mouse.y, 32, 32);
			}
			if(Luxe.input.keydown(Key.key_q) || _selectedCount == 0) {
				if(Luxe.input.mousepressed(1)) {
					for (c in colliders) {
						if (c.mouseInside()) {
							c.toggleSelected();
							safe = true;
							if(c.selected) {
								_selectedCount++;
							}
							else {
								_selectedCount--;
							}
						}
					}
				}
			}
			if(Luxe.input.mousepressed(1) && !safe) {
				var deselect: Bool = true;
				for(c in colliders) {
					if(c.selected && c.mouseInside()) {
						deselect = false;
					}
				}

				if(deselect) {
					for (c in colliders) {
						if(c.selected) {
							_selectedCount--;
						}
						c.deselect();
					}
				}
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
		var texture = Luxe.loadTexture(art);
		texture.filter = FilterType.nearest;
		var visual = new Sprite ({
			texture: texture,
			pos: new Vector(x + w/2, y + h/2),
			size: new Vector(w, h),
			depth: -1
		});
		visuals.push(visual);
	}

	public function toggleEdit() {
		_editMode = !_editMode;
		for(c in colliders) {
			c.toggleDebug();
		}
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