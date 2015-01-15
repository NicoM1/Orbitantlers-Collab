package level;

import luxe.Sprite;
import phoenix.Vector;
import phoenix.Texture;
import phoenix.geometry.RectangleGeometry;
import phoenix.geometry.Vertex;

import luxe.collision.shapes.Polygon;
import luxe.collision.Collision;

import luxe.collision.ShapeDrawerLuxe;

import phoenix.Color;

import player.MovementComponent;

class Portal extends EditableObject {

	public var _portalTarget: String = '';
	var _player: Polygon = null;
	
	public function new(x_: Float, y_: Float, w_: Float, h_: Float, target_: String) {
		super(x_,y_,w_,h_);
		_baseColor = new Color(0,1,1,1);
		_selectedColor = new Color(0,0.5,0.5,1);
		_portalTarget = target_;
		_player = cast (Luxe.scene.entities.get('player').get('movement'), MovementComponent).getCollision();
	}

	override function update() {
		_checkPortal();
	}

	function _checkPortal() {
		if(Collision.test(this, _player) != null) {
			Level.instance.loadLevel(_portalTarget);
		}
	}
}