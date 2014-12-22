package ;

import luxe.Sprite;

import phoenix.Vector;
import phoenix.Texture;

import snow.input.Keycodes;

import luxe.collision.Collision;
import luxe.collision.CollisionData;
import luxe.collision.shapes.Shape;
import luxe.collision.shapes.Polygon;
import luxe.collision.ShapeDrawerLuxe;

import luxe.components.sprite.SpriteAnimation;

import luxe.Input;

class Player extends Sprite {

	static inline var GAMEPAD_A: Int = 0;
	static inline var GAMEPAD_DEADZONE: Float = 0.3;

	///Internal collider representation
	var _collisionShape: Polygon;
	var _otherShapes: Array<Shape>;
	var _drawer: ShapeDrawerLuxe; //COLLISION

	///Velocity Multiplier
	public var m: Float = 75.0;

	///X-axis velocity
	public var vX: Float = 0.0;
	///Y-axis velocity
	public var vY: Float = 0.0;

	///X-axis-velocity accumulator
	var _cX: Float = 0.0;
	///Y-axis-velocity accumulator
	var _cY: Float = 0.0;
	
	///Maximum veloctity
	var _vMax: Vector = new Vector(6.5, 10.0); //VELOCITY

	///Acceleration on ground
	var _groundAccel: Float = 45.0;
	///Acceleration in air
	var _airAccel: Float = 15.0;
	
	///Friction on ground
	var _groudFric: Float = 80;
	///Friction in air
	var _airFric: Float = 30;//6 //ACCELERATION + FRICTION

	///Jump force
	var _jumpHeight: Float = 11.0;
	///Time margin to make jump after leaving ground
	var _jumpMargin: Float = 0.1; //0.05
	///Timer for jump margin
	var _jumpMarginTimer: Float = 0;

	///Gravity without friction
	var _gravNorm: Float = 45;
	///Gravity against an object
	var _gravSlide: Float = 4; //JUMP + GRAVITY

	///Time to cling to a wall before detaching
	var _clingTime: Float = 0.07;
	///Able to stick to a wall currently
	var _canStick: Bool = true;
	///Currently sticking to wall
	var _sticking: Bool = false; //WALL-CLING


	var _touchMoveRatio: Float = 0.3;
	var _touchJumpStart: Float = 0.7;

	var _touchMoveID: Null<Int> = null;
	var _touchMoveLeft: Bool = false;
	var _touchMoveRight: Bool = false;
	var _touchJump: Bool = false;

	var _gamepadJump: Bool = false;
	var _gamepadLeft: Bool = false;
	var _gamepadRight: Bool = false;

	var _anim: SpriteAnimation;
	
	public function new() {
		var texture = Luxe.loadTexture('assets/art/character/run_strip.png');
		texture.filter = FilterType.nearest;

		super({
			name: 'player',
			texture: texture,
			size: new Vector(37, 40)
		});

		_createAnim();

		pos.y = Luxe.camera.size.y - size.y / 2;

		_collisionShape = Polygon.rectangle(pos.x, pos.y, 13, 40);

		_setUpShapes();

		_drawer = new ShapeDrawerLuxe();

		for(o in _otherShapes) {
			_drawer.drawShape(o);
		}
	}

	function _createAnim() {
		var animJSON = Luxe.loadJSON('assets/files/character_anim.json');

		_anim = add(new SpriteAnimation({name: 'anim'}));

		_anim.add_from_json_object(animJSON.json);

		_anim.animation = 'idle';
		_anim.play();
	}

	function _setUpShapes() {
		_otherShapes = [];
		_otherShapes.push(Polygon.square(200, pos.y, size.x));
		_otherShapes.push(Polygon.square(200 + size.x, pos.y - size.y, size.x));
		_otherShapes.push(Polygon.rectangle(200 + size.x * 2, pos.y - size.y * 4, size.x, size.y * 5));
		_otherShapes.push(Polygon.rectangle(200 + size.x * 10, pos.y - size.y * 4, size.x * 5, size.y));
	}

	override function update(dt: Float) {
		//cap dt
		if(dt > 1/10) dt = 1/10;

		_doMovement(dt);
		_doCollision(dt);

		_collideScreen();
	}

	override function ontouchdown(e: TouchEvent) {
		if(_touchMoveID == null) {
			if(e.x <= _touchJumpStart) {
				_touchMoveID = e.touch_id;

				_checkTouchMove(e);
			}
		}
		if(e.x > _touchJumpStart) {
			_touchJump = true;
		}
	}

	function _checkTouchMove(e: TouchEvent) {
		if(e.x <= _touchMoveRatio / 2) {
			_touchMoveLeft = true;
			_touchMoveRight = false;
		}
		else {
			_touchMoveLeft = false;
			_touchMoveRight = true;
		}
	}

	override function ontouchmove(e: TouchEvent) {
		if(e.touch_id == _touchMoveID) {
			_checkTouchMove(e);
		}
	}

	override function ontouchup(e: TouchEvent) {
		if(e.touch_id == _touchMoveID) {
			_touchMoveLeft = false;
			_touchMoveRight = false;
			_touchMoveID = null;
		}
	}

	override function ongamepaddown(e: GamepadEvent) {
		if(e.button == GAMEPAD_A) {
			_gamepadJump = true;
		}
	}

	override function ongamepadaxis(e: GamepadEvent) {
		if(e.axis == 0) {
			if(e.value > GAMEPAD_DEADZONE) {
				_gamepadLeft = false;
				_gamepadRight = true;
			}
			else if(e.value < -GAMEPAD_DEADZONE) {
				_gamepadLeft = true;
				_gamepadRight = false;
			}
			else {
				_gamepadLeft = false;
				_gamepadRight = false;
			}
		}
	}

	function _doMovement(dt: Float) {
		//check if on a surface
		var onGround: Bool = _onGround();

		//store acceleration/friction for current situation
		var tempAccel: Float;
		var tempFric: Float;

		//check input keys
		var iLeft: Bool = Luxe.input.keydown(Keycodes.key_a) || _touchMoveLeft || _gamepadLeft;
		var iRight: Bool = Luxe.input.keydown(Keycodes.key_d) || _touchMoveRight || _gamepadRight;
		var iJump: Bool = Luxe.input.keypressed(Keycodes.space) || _touchJump || _gamepadJump;

		//test left/right collision (touching walls)
		var cLeft: Bool = _checkCollision(-1, 0);
		var cRight: Bool = _checkCollision(1, 0);

		if(onGround) {
			//set to maximum jump margin
			_jumpMarginTimer = _jumpMargin;
			//set up temp accel/friction
			tempAccel = _groundAccel;
			tempFric = _groudFric;
		} 
		else {
			//set up temp accel/friction
			tempAccel = _airAccel;
			tempFric = _airFric;
		}

		if(onGround || (!cRight && !cLeft)) {
			//reset sticking
			_canStick = true;
			_sticking = false;
		}
		else if(!onGround && _canStick && ((iRight && cLeft)||(iLeft && cRight))) {
			//stick on wall if not touching ground, easier wall jumps
			_sticking = true;
			_canStick = false;

			//after set time, reset sticking
			Luxe.timer.schedule(_clingTime, function() {
				_sticking = false;
			});
		}

		if((cLeft || cRight) && vY > 0) {
			_anim.animation = 'wallslide';
			//if sliding down a wall, apply friction
			vY = _approachValue(vY, _vMax.y, _gravSlide);
		}
		else {
			//otherwise, fall normally
			vY = _approachValue(vY, _vMax.y, _gravNorm);
		}

		if(!_sticking) {
			var doFric: Bool = true;

			if(iLeft) {
				//if pressing left and moving right, 
				//apply friction before applying velocity
				if(vX > 0) {
					vX = _approachValue(vX, 0, tempFric);
				}
				vX = _approachValue(vX, -_vMax.x, tempAccel);
				doFric = false;
				flipx = true;
			}

			if(iRight) {
				//if pressing right and moving left,  
				//apply friction before applying velocity
				if(vX < 0) {
					vX = _approachValue(vX, 0, tempFric);
				}
				vX = _approachValue(vX, _vMax.x, tempAccel);
				doFric = false;
				flipx = false;
			}

			//if no input pressed, apply friction to slow down
			if(doFric) {
				vX = _approachValue(vX, 0, tempFric);
				if(onGround) {
					_anim.animation = 'idle';
				}
			}
			else {
				//we must be moving so play run
				if(onGround && _anim.animation != 'run') {
					_anim.animation = 'run';
				}
			}
		}

		//wall jumping
		if(!onGround && iJump) {
			var didJump = false;
			if(cLeft) {
				didJump = true;
				vY = -_jumpHeight * 1.25;
				vX = _vMax.x / 1.5;
			}
			else if(cRight) {
				didJump = true;
				vY = -_jumpHeight * 1.25;
				vX = -_vMax.x / 1.5;
			}

			if(didJump) {
				_anim.animation = 'jump';
			}
		}

		//jump if on surface or just left (margin)
		if(iJump) {
			if(_jumpMarginTimer > 0) {
				vY = -_jumpHeight;
				_jumpMarginTimer = 0;
				_anim.animation = 'jump';
			}
		}

		if(!onGround && !cLeft && ! cRight && vY > 0) {
			_anim.animation = 'fall';
		}

		//count down jump margin timer
		_jumpMarginTimer -= dt;

		_touchJump = false;
		_gamepadJump = false;
	}

	///Collide against scene and integrate velocity
	function _doCollision(dt: Float) {
		//accumulate velocity
		_cX += vX * m * dt;
		_cY += vY * m * dt;
		//round off velocity
		var vXNew = Math.round(_cX);
		var vYNew = Math.round(_cY);
		//store left over velocity
		_cX -= vXNew;
		_cY -= vYNew;

		//match collision shape to object position
		_collisionShape.x = pos.x;
		_collisionShape.y = pos.y;

		//iterate over y-velocity
		for(i in 0...Std.int(Math.abs(vYNew)) + 1) {
			//add direction to collision shape
			_collisionShape.y += _sign(vYNew);

			//test new position against scene
			var c = Collision.testShapes(_collisionShape, _otherShapes);
			if(c.length > 0) {
				vY = 0;
				break;
			}
			else {
				//if no collisions, add 1 pixel of movement to position
				pos.y += _sign(vYNew);
			}
		}

		//match collision shape to final y-position
		_collisionShape.y = pos.y;

		//iterate over x-velocity
		for(i in 0...Std.int(Math.abs(vXNew)) + 1) {
			//add direction to collision shape
			_collisionShape.x += _sign(vXNew);

			//test new position against scene
			var c = Collision.testShapes(_collisionShape, _otherShapes);
			if(c.length > 0) {
				vX = 0;
				break;
			}
			else {
				//if no collisions, add 1 pixel of movement to position
				pos.x += _sign(vXNew);
			}
		}
	}

	///Collide against screen edges
	function _collideScreen() {	
		if(pos.y + size.y / 2 > Luxe.camera.size.y) {
			vY = 0;
			pos.y = Luxe.camera.size.y - size.y / 2;
		}

		if(pos.x + size.x / 2 > Luxe.camera.size.x) {
			vX = 0;
			pos.x = Luxe.camera.size.x - size.x / 2;
		}
		else if(pos.x - size.x / 2 < 0) {
			vX = 0;
			pos.x = size.x / 2;
		}
	}

	///Returns +1/0/-1 for sign of float
	function _sign(v: Float): Int {
		if(v == 0) return 0;
		return v < 0 ? -1 : 1;
	}

	///Check if touching at base
	function _onGround(): Bool {
		if(pos.y + size.y / 2 >= Luxe.camera.size.y) {
			return true;
		}

		return _checkCollision(0, 1);
	}

	///Check collision after an offset
	function _checkCollision(offsetX: Int, offsetY: Int): Bool {
		if(pos.x + offsetX - size.x / 2 < 0) {return true;}
		if(pos.x + offsetX + size.x / 2 > Luxe.camera.size.x) {return true;}

		_collisionShape.x = pos.x + offsetX;
		_collisionShape.y = pos.y + offsetY;

		return Collision.testShapes(_collisionShape, _otherShapes).length > 0;
	}

	///Approach a value by a shift amount, affected by dt
	function _approachValue(start: Float, end: Float, shift: Float): Float {
		if (start < end) {
			return	Math.min(start + shift * Luxe.dt, end);
		}
		else {
			return Math.max(start - shift * Luxe.dt, end);
		}
	} 

	///Unsafe trace, traces or doesnt randomly, saves from overflows
	function _uTrace(v: Dynamic) {

		if(Math.random() < 0.1) trace(v);
	}
}