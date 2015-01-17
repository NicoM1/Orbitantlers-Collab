package enemies;

import luxe.Component;

import luxe.collision.shapes.Shape;
import luxe.collision.shapes.Polygon;
import luxe.Sprite;

class CollisionComponent extends Component {

	var _sprite: Sprite;
	var _collider: Shape;
	
	public function new() {
		super({
			name: 'collision'
		});
	}

	override function init() {
		_sprite = cast entity;
		_collider = Polygon.rectangle(_sprite.pos.x, _sprite.pos.y,)
	}
}