package level;

import luxe.Sprite;
import phoenix.Vector;
import phoenix.Texture;

import luxe.collision.shapes.Polygon;
import luxe.collision.shapes.Shape;

import snow.input.Keycodes;

class Level {

	static public var colliders(default, null): Array<Collider>;
	var groups: Map<String, Array<Collider>>;
	var visuals: Array<Sprite>;

	var _editMode: Bool = true;

	public function new() {
		colliders = new Array<Collider>();
		visuals = new Array<Sprite>();
		groups = new Map<String, Array<Collider>>();

		_addColider(0,Luxe.screen.h - 32,32,32);
		_addColider(32,Luxe.screen.h - 64,64,64);
		_addColider(96,Luxe.screen.h - 32,32,32);
		_addColider(128,Luxe.screen.h - 64,64,64);
		_addColider(192,Luxe.screen.h - 32,64,32);

		parseJSON('assets/files/testmap.json');
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
		for(g in map.colliders) {
			for(c in g.colliders) {
				_addColider(c.x, c.y, c.w, c.h, g.id);
			}
		}
	}

	function _addColider(x: Float, y: Float, w: Float, h: Float, ?group: String) {
		var collider = new Collider(x, y, w, h);
		colliders.push(collider);
		if(group != null) {
			var addTo = groups.get(group);
			if(addTo == null) {
				addTo = new Array<Collider>();
				groups.set(group, addTo);
			}
			addTo.push(collider);
		}
	}

	function _addVisual(x: Float, y: Float, w: Float, h: Float, art: String) {
		var visual = new Sprite ({
			texture: Luxe.loadTexture(art),
			pos: new Vector(x + w/2, y + h/2),
			size: new Vector(w, h)
		});
		visuals.push(visual);
	}

	function toggleEdit() {
		_editMode = !_editMode;
	}
}

typedef MapStruct = {
	visuals: Array<VisualStruct>,
	colliders: Array<ColliderGroup>
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

typedef ColliderGroup = {
	id: String,
	colliders: Array<ColliderStruct>
}