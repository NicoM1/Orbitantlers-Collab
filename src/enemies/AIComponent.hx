package enemies;

import luxe.Component;
import luxe.tween.Actuate;
import luxe.Sprite;
import phoenix.Vector;

class AIComponent extends Component {
	var _sprite: Sprite;
	var _size: Vector = new Vector();

	public function new() {
		super({
			name: 'AI'
		});
	}

	override function init() {
		_sprite = cast entity;
		entity.events.listen('get_hit', onHit);
		_size.copy_from(_sprite.size);
	}
	
	function onHit(e: Dynamic) {
		Actuate.tween(_sprite.size, 0.15, 
			{x: _sprite.size.x * 0.7, y: _sprite.size.y * 0.8})
		.ease(luxe.tween.easing.Elastic.easeOut)
		.onComplete(function() {
				Actuate.tween(_sprite.size, 0.1, 
					{x: _size.x, y: _size.y})
				.ease(luxe.tween.easing.Expo.easeIn);
		});
	}	
}