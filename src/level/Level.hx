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
	public static var instance(get, null): Level;
	static function get_instance(): Level {
		if(_instance == null) {
			new Level();
		}
		return _instance;
	}
	static var _instance: Level;

	public var colliders(default, null): Array<EditableObject>;
	var _visuals: Array<Visual>;
	var _portals: Array<Portal>;

	var _editMode: Bool = true;
	var _visualMode: Bool = false;

	public var _selectedCount: Int = 0;
	public var _selectedVisualCount: Int = 0;

	var _brush: Sprite;

	var _artChunks: Array<VisualStruct>;
	var _portalTargets: Array<String>;
	var _currentTarget: Int = -1;

	var _selectedArt: Int = 0;

	var _wasReset: Bool = false;

	var _debugPortalText: String = '';

	public function new() {
		_instance = this;

		colliders = new Array<EditableObject>();
		_visuals = new Array<Visual>();
		_portals = new Array<Portal>();

		_loadBrushes();
		_loadLevels();

		_brush = new Sprite({
			texture: Luxe.loadTexture(_artChunks[_selectedArt].art),
			size: new Vector(_artChunks[_selectedArt].w, _artChunks[_selectedArt].h)
		});

		_brush.color.a = 0.5;
		_brush.visible = false;

		parseJSON('testarea');

		#if android
		toggleEdit();
		#end
	}

	function _loadLevels() {
		_portalTargets = new Array<String>();
		var json = Luxe.loadJSON("assets/files/levels/levels.json");
		for(i in cast (json.json.levels, Array<Dynamic>)) {
			_portalTargets.push(i.id);
		}
	}

	public function loadLevel(id: String) {
		_reset();
		parseJSON(id);
	}

	public function nextTarget(): String {
		_currentTarget++;
		if(_currentTarget >= _portalTargets.length) _currentTarget = 0;
		return _portalTargets[_currentTarget];
	}

	public function setDebugText(text: String) {
		_debugPortalText = text;
	}

	public function update() {
		if(Luxe.input.keypressed(Key.key_r)) _reset();
	
		if(_editMode) {
			Luxe.draw.text({
				text: _debugPortalText,
				immediate: true,
				pos: Luxe.camera.screen_point_to_world(new Vector(5,5))
			});

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
				if(!Luxe.input.keydown(Key.key_p)) {
					_addColider(pos.x, pos.y, 32, 32);
				}
				else {
					_addPortal(pos.x, pos.y, 32, 32, 'test2');
				}
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
					for (p in _portals) {
						if (p.mouseInside()) {
							p.toggleSelected();
							safe = true;
							if(p.selected) {
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
				for(p in _portals) {
					if(p.selected && p.mouseInside()) {
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
					for (p in _portals) {
						if(p.selected) {
							_selectedCount--;
						}
						p.deselect();
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
				c.editModeUpdate();
			}
			for (p in _portals) {
				if(p.selected && Luxe.input.keypressed(Key.key_x)) {
					_portals.remove(p);
					_selectedCount--;
					p.destroy();
					continue;
				}
				p.editModeUpdate();
			}
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
					_artChunks[_selectedArt].art,
					-1,
					false,
					false,
					0
				).enableDebug();
			}

			for(v in _visuals) {
				if(v.kill) {
					_visuals.remove(v);
					v.destroy();
					continue;
				}
				v.updateDebug();
			}
			_selectedVisualCount = 0;
		}
		_wasReset = false;
		for(p in _portals) {
			p.update();
			if(_wasReset) break;
		}
	}

	function _resetStamp() {
		_brush.texture = Luxe.loadTexture(_artChunks[_selectedArt].art);
		_brush.size.x = _artChunks[_selectedArt].w;
		_brush.size.y = _artChunks[_selectedArt].h;
	}

	public function parseJSON(path: String) {
		path = 'assets/files/levels/${path}.lvl'; 
		var json = Luxe.loadJSON(path).json;
		var map: MapStruct = cast json;

		for(v in map.visuals) {
			_addVisual(v.x, v.y, v.w, v.h, v.art, v.depth, v.flipx, v.flipy, v.rotation);
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

			for(v in map._visuals) {
				_addVisual(v.x, v.y, v.w, v.h, v.art, v.depth, v.flipx, v.flipy, v.rotation);
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
		for(v in _visuals) {
			v.destroy();
		}
		for(p in _portals) {
			p.destroy();
		}

		colliders = [];
		_visuals = [];
		_portals = [];

		_selectedCount = 0;
		_selectedVisualCount = 0;

		_wasReset = true;
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

		for(v in _visuals) {
			var vJSON: VisualStruct = {
				x: v.pos.x - v.size.x / 2, 
				y: v.pos.y - v.size.y / 2, 
				w: v.size.x,
				h: v.size.y,
				depth: v.depth,
				art: v.art,
				flipx: v.flipx,
				flipy: v.flipy,
				rotation: v.rotation_z
			};
			json.visuals.push(vJSON);
		}

		return json;
	}

	function _addColider(x: Float, y: Float, w: Float, h: Float) {
		var collider = new EditableObject(x, y, w, h);
		colliders.push(collider);
	}

	function _addPortal(x: Float, y: Float, w: Float, h: Float, target: String) {
		var portal = new Portal(x, y, w, h, target);
		_portals.push(portal);
	}

	function _addVisual(x: Float, 
						y: Float, 
						w: Float, 
						h: Float, 
						art: String, 
						depth: Float, 
						flipx: Bool, 
						flipy: Bool, 
						rotation: Float): Visual {
		var visual = new Visual(x,y,w,h,art,depth,flipx,flipy,rotation);
		_visuals.push(visual);
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
		for(v in _visuals) v.disableDebug();
		_brush.visible = false;
		_visualMode = false;
	}

	function _enableVisualMode() {
		for(v in _visuals) v.enableDebug();
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
	?depth: Float,
	?flipx: Bool,
	?flipy: Bool,
	?rotation: Float
}

typedef ColliderStruct = {
	x: Float,
	y: Float,
	w: Float,
	h: Float
}