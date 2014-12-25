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
	var visuals: Array<Visual>;

	var _editMode: Bool = true;
	var _visualMode: Bool = false;

	public static var _selectedCount: Int = 0;

	var _brush: Sprite;

	var _artChunks: Array<VisualStruct>;

	var _selectedArt: Int = 0;

	public function new() {
		colliders = new Array<Collider>();
		visuals = new Array<Visual>();

		_loadBrushes();

		_brush = new Sprite({
			texture: Luxe.loadTexture(_artChunks[_selectedArt].art),
			size: new Vector(_artChunks[_selectedArt].w, _artChunks[_selectedArt].h)
		});

		_brush.color.a = 0.5;
		_brush.visible = false;

		parseJSON('assets/files/output.lvl');
	}

	public function update() {
		if(_editMode) {
			if(Luxe.input.keypressed(Key.key_v)) {
				toggleEdit();
				_enableVisualMode();
				return;
			}

			if(Luxe.input.keypressed(Key.key_l)) {
				_loadJSONWeb();
			}

			var safe: Bool = false;
			if(Luxe.input.mousepressed(3)) {
				var pos = Luxe.camera.screen_point_to_world(Luxe.mouse);
				_addColider(pos.x, pos.y, 32, 32);
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

			for (c in colliders) {
				if(c.selected && Luxe.input.keypressed(Key.key_x)) {
					colliders.remove(c);
					_selectedCount--;
					c.destroy();
					continue;
				}
				c.update();
			}
			//for (c in colliders) c.update();
		}
		if(_visualMode) {
			if(Luxe.input.keypressed(Key.key_v)) {
				toggleEdit();
				_disableVisualMode();
			}

			if(Luxe.input.keypressed(Key.up)) {
				if(_selectedArt < _artChunks.length - 1) {
					_selectedArt++;
					_resetStamp();
				}
				else {
					_selectedArt = 0;
					_resetStamp();
				}
			}
			else if(Luxe.input.keypressed(Key.down)) {
				if(_selectedArt > 0) {
					_selectedArt--;
					_resetStamp();
				}
				else {
					_selectedArt = _artChunks.length - 1;
					_resetStamp();
				}
			}

			var brushPos = Luxe.camera.screen_point_to_world(Luxe.mouse);
			_brush.pos.x = brushPos.x;
			_brush.pos.y = brushPos.y;

			brushPos.subtract(new Vector(_artChunks[_selectedArt].w / 2, _artChunks[_selectedArt].h / 2));

			if(Luxe.input.mousepressed(3)) {
				_addVisual(
					Math.floor(brushPos.x), 
					Math.floor(brushPos.y), 
					_artChunks[_selectedArt].w, 
					_artChunks[_selectedArt].h,
					_artChunks[_selectedArt].art
				).enableDebug();
			}

			for(v in visuals) {
				if(v.kill) {
					visuals.remove(v);
					v.destroy();
					continue;
				}
				v.updateDebug();
			}
		}
	}

	function _resetStamp() {
		_brush.texture = Luxe.loadTexture(_artChunks[_selectedArt].art);
		_brush.size.x = _artChunks[_selectedArt].w;
		_brush.size.y = _artChunks[_selectedArt].h;
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

	function _loadJSONWeb() {
		#if web
			_reset();
			var jsonS: String = untyped __js__('window.prompt(\"Insert Level-Code\", \"paste level-code here.\")');
			var json = Json.parse(jsonS);
			trace('json', json);
			var map: MapStruct = cast json;

			for(v in map.visuals) {
				_addVisual(v.x, v.y, v.w, v.h, v.art);
			}
			for(c in map.colliders) {
				_addColider(c.x, c.y, c.w, c.h);
			}
		#end
	}

	function _reset() {
		for (c in colliders) {
			c.destroy();
		}
		for(v in visuals) {
			v.destroy();
		}

		colliders = [];
		visuals = [];
	}

	function _loadBrushes() {
		var json = Luxe.loadJSON("assets/files/brushes.json");
		_artChunks = cast json.json.brushes;
	}

	public function saveJSON(path: String) {
		trace('attempting save');
		var json = Json.stringify(_makeJSON(), '\t');

		#if desktop
			var fout = File.write(path, false);
			fout.writeString(json);
			fout.close();
		#end
		#if js
			untyped __js__('window.prompt(\"Copy to clipboard: Ctrl+C, Enter\", json)');
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

		for(v in visuals) {
			var vJSON: VisualStruct = {
				x: v.pos.x - v.size.x / 2, 
				y: v.pos.y - v.size.y / 2, 
				w: v.size.x,
				h: v.size.y,
				depth: v.depth,
				art: v.art
			};
			json.visuals.push(vJSON);
		}

		return json;
	}

	function _addColider(x: Float, y: Float, w: Float, h: Float) {
		var collider = new Collider(x, y, w, h);
		colliders.push(collider);
	}

	function _addVisual(x: Float, y: Float, w: Float, h: Float, art: String): Visual {
		var visual = new Visual(x,y,w,h,art);
		visuals.push(visual);
		return visual;
	}

	public function toggleEdit() {
		_editMode = !_editMode;
		if(_editMode) _disableVisualMode();
		for(c in colliders) {
			c.toggleDebug();
		}
	}

	function _disableVisualMode() {
		for(v in visuals) v.disableDebug();
		_brush.visible = false;
		_visualMode = false;
	}

	function _enableVisualMode() {
		for(v in visuals) v.enableDebug();
		_brush.visible = true;
		_visualMode = true;
	}
}

typedef MapStruct = {
	visuals: Array<VisualStruct>,
	colliders: Array<ColliderStruct>
}

typedef VisualStruct = {
	?x: Float,
	?y: Float,
	w: Float,
	h: Float,
	art: String,
	?depth: Float
}

typedef ColliderStruct = {
	x: Float,
	y: Float,
	w: Float,
	h: Float
}