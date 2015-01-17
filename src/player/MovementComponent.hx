package player;

import phoenix.Vector;
import phoenix.Texture;

import snow.input.Keycodes;

import luxe.collision.Collision;
import luxe.collision.CollisionData;
import luxe.collision.shapes.Shape;
import luxe.collision.shapes.Polygon;
import luxe.collision.ShapeDrawerLuxe;

import luxe.components.sprite.SpriteAnimation;
import luxe.Component;
import luxe.Sprite;
import luxe.Input;
import luxe.States;

import input.XBoxButtonMap;

import level.*;

import phoenix.Color;

class MovementComponent extends Component {

	//owner of this component
	var _sprite: Sprite;

	//SOMEDAY I WILL USE THIS
	var _machine: States;

	//animation component on the sprite
	var _anim: SpriteAnimation;

	//width of collider
	var colWidth: Int = 13;
	//height of collider
	var colHeight: Int = 40;
	var colHeightOffset: Float;
	var colWidthOffset: Float;
	///Internal collider representation
	var _collisionShape: Polygon;
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
	var _vMax: Vector = new Vector(8.0, 15.0); //VELOCITY 6.5

	///Acceleration on ground
	var _groundAccel: Float = 45.0;
	///Acceleration in air
	var _airAccel: Float = 15.0;
	
	///Friction on ground
	var _groudFric: Float = 60;//80;
	///Friction in air
	var _airFric: Float = 30;//6 //ACCELERATION + FRICTION

	///Jump force
	var _jumpHeight: Float = 6;//11.0;
	///Time margin to make jump after leaving ground
	var _jumpMargin: Float = 0.1; //0.05
	///Timer for jump margin
	var _jumpMarginTimer: Float = 0;

	///Gravity without friction
	var _gravNorm: Float = 20;//25;//45;
	///Gravity against an object
	var _gravSlide: Float = 4; //JUMP + GRAVITY

	///Time to cling to a wall before detaching
	var _clingTime: Float = 0.07;
	///Able to stick to a wall currently
	var _canStick: Bool = true;
	///Currently sticking to wall
	var _sticking: Bool = false; //WALL-CLING

	var _attacking: Bool = false;
	var _attackDelay: Float = 0.05;

	//percentage of screen before which pressing counts as left input
	//after counts as right input
	var _touchMoveRatio: Float = 0.3;
	//percentage of screen after which tapping counts as jump input
	var _touchJumpStart: Float = 0.7;

	//ID of the touch used for left/right movement
	var _touchMoveID: Null<Int> = null;

	var _touchJumpID: Null<Int> = null;

	//is currently using touch to move left
	var _touchMoveLeft: Bool = false;
	//is currently using touch to move left
	var _touchMoveRight: Bool = false;
	//has tapped jump portion in last frame
	var _touchJump: Bool = false;
	var _touchJumpReleased: Bool = false;

	//has pressed [jump] button on controller
	var _gamepadJump: Bool = false;
	var _gamepadJumpRelease: Bool = false;
	//is holding movement axis to the left
	var _gamepadLeft: Bool = false;
	//is holding movement axis to the right
	var _gamepadRight: Bool = false;

	var _camera: CameraComponent;
	
	public function new() {
		super({name: 'movement'});
	}

	override function init() {
		_drawer = new ShapeDrawerLuxe();

		_sprite = cast entity;
		_machine = new States({name:'machine'});
		_anim = get('anim');

		colHeightOffset = _sprite.size.y/2 - colHeight;
		colWidthOffset = -colWidth/2;
		_collisionShape = Polygon.rectangle(pos.x + colWidthOffset, pos.y + colHeightOffset, colWidth, colHeight, false); //use this in other positions

		pos.x = Luxe.screen.w / 2 - colWidth / 2;

		_camera = get('camera');
		_camera.lookPoint = _sprite.pos;

		_sprite.events.listen('attack_complete', _attackComplete);
	}

	public function getCollision(): Polygon {
		return _collisionShape;
	}

	override function update(dt: Float) {
		//cap dt
		if(dt > 1/10) dt = 1/10;

		_doMovement(dt);
		if(_attacking) {
			if(_checkFinished('attack-overhead', 6)) {
				_attackComplete({});
			}
		}
		_doCollision(dt);
	}

	#if mobile
	override function ontouchdown(e: TouchEvent) {
		//if we dont already have a movement touch id
		if(_touchMoveID == null) {
			//and its on the move not jump portion
			if(e.x <= _touchJumpStart) {
				//set the ID so we only use this touch
				_touchMoveID = e.touch_id;

				//check where we should move
				_checkTouchMove(e);
			}
		}
		//if this is a new touch, regardless of if we have an ID,
		//check if it is on the jump portion
		if(_touchJumpID == null) {
			if(e.x > _touchJumpStart) {
				_touchJump = true;
				_touchJumpID = e.touch_id;
			}
		}
	}

	override function ontouchmove(e: TouchEvent) {
		//if the touch we are tracking moves, check if the move direction has changed
		if(e.touch_id == _touchMoveID) {
			_checkTouchMove(e);
		}
	}

	override function ontouchup(e: TouchEvent) {
		//if our tracked touch leaves, default all our touch related members
		if(e.touch_id == _touchMoveID) {
			_touchMoveLeft = false;
			_touchMoveRight = false;
			_touchMoveID = null;
		}
		if(e.touch_id == _touchJumpID) {
			_touchJumpReleased = true;
			_touchJumpID = null;
		}
	}

	function _checkTouchMove(e: TouchEvent) {
		//if touch is less than ratio, touch is considered left movement
		if(e.x <= _touchMoveRatio / 2) {
			_touchMoveLeft = true;
			_touchMoveRight = false;
		}
		else {
			_touchMoveLeft = false;
			_touchMoveRight = true;
		}
	}
	#end

	override function ongamepaddown(e: GamepadEvent) {
		//if we pressed [jump] on the controller
		if(e.button == XBoxButtonMap.GAMEPAD_A) {
			_gamepadJump = true;
		}
	}

	override function ongamepadup(e: GamepadEvent) {
		//if we pressed [jump] on the controller
		if(e.button == XBoxButtonMap.GAMEPAD_A) {
			_gamepadJumpRelease = true;
		}
	}

	override function ongamepadaxis(e: GamepadEvent) {
		//check gamepad axis for movement, taking into account deadzones
		if(e.axis == 0) {
			if(e.value > XBoxButtonMap.GAMEPAD_DEADZONE) {
				_gamepadLeft = false;
				_gamepadRight = true;
			}
			else if(e.value < -XBoxButtonMap.GAMEPAD_DEADZONE) {
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

		_camera.lookPoint = pos.clone();
		//check if on a surface
		var onGround: Bool = _onGround();

		//store acceleration/friction for current situation
		var tempAccel: Float;
		var tempFric: Float;

		//check input keys
		var iLeft: Bool = Luxe.input.keydown(Keycodes.key_a) || Luxe.input.keydown(Keycodes.left) || _touchMoveLeft || _gamepadLeft;
		var iRight: Bool = Luxe.input.keydown(Keycodes.key_d) || Luxe.input.keydown(Keycodes.right) || _touchMoveRight || _gamepadRight;
		var iJump: Bool = Luxe.input.keypressed(Keycodes.space) || Luxe.input.keypressed(Keycodes.key_z) || Luxe.input.keypressed(Keycodes.key_j) || _touchJump || _gamepadJump;
		var iJumpReleased: Bool = Luxe.input.keyreleased(Keycodes.space) || Luxe.input.keyreleased(Keycodes.key_z) || _gamepadJumpRelease || _touchJumpReleased;
		var iAttack: Bool = Luxe.input.keypressed(Keycodes.key_x) || Luxe.input.keypressed(Keycodes.key_k); //|| _gamepadJumpRelease || _touchJumpReleased;

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

		//WALL-SLIDE//////////////////////////////////////////////////////////////////
		if(!onGround && (cLeft || cRight) && vY > 0) {
			if(cLeft) _sprite.flipx = true;
			else _sprite.flipx = false;
			//if sliding down a wall, apply friction
			vY = _approachValue(vY, _vMax.y, _gravSlide);
		}
		else {
			//otherwise, fall normally
			vY = _approachValue(vY, _vMax.y, _gravNorm);
		}
		if(!onGround && (cLeft || cRight)) {
			if(_anim.animation != 'wallslide') {
				_setAnim('wallslide');
			}
		}

		if(!_sticking) {
			var doFric: Bool = true;

			if(iLeft && !iRight) {
				//if pressing left and moving right, 
				//apply friction before applying velocity
				if(vX > 0) {
					vX = _approachValue(vX, 0, tempFric);
				}
				vX = _approachValue(vX, -_vMax.x, tempAccel);
				doFric = false;
				_sprite.flipx = true;

				if(iAttack && Math.abs(vX) > _vMax.x / 2) {
					_attackOverhead(0);
				}
			}

			if(iRight && !iLeft) {
				//if pressing right and moving left,  
				//apply friction before applying velocity
				if(vX < 0) {
					vX = _approachValue(vX, 0, tempFric);
				}
				vX = _approachValue(vX, _vMax.x, tempAccel);
				doFric = false;
				_sprite.flipx = false;

				if(iAttack && Math.abs(vX) > _vMax.x / 2) {
					_attackOverhead(0);
				}
			}

			//if no input pressed, apply friction to slow down
			if(doFric) {
				vX = _approachValue(vX, 0, tempFric);
				if(onGround) {
					//FLOOR-SLIDE////////////////////////////////////////////////////////
					if(vX != 0) {
						_setAnim('slide');
					}
					//IDLE//////////////////////////////////////////////////////////////
					else if (_anim.animation != 'idle') {
						_setAnim('idle');
					}
				}
			}
			else {	//we must be moving so play run
				//RUN//////////////////////////////////////////////////////////////
				if(onGround && _anim.animation != 'run') {
					_setAnim('run');
				}

				_camera.lookPoint.x += vX * 60;
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
				//WALL-JUMP/////////////////////////////////////////////////////////////
				_setAnim('jump');
			}
		}

		//jump if on surface or just left (margin)
		if(iJump) {
			if(_jumpMarginTimer > 0) {
				vY = -_jumpHeight;
				_jumpMarginTimer = 0;
				//JUMP////////////////////////////////////////////////////////////////
				_setAnim('jump');
			}
		}

		if (!onGround && iJumpReleased) {
			if(vY < 0) {
				vY *= 0.35;
			}
		}

		if(!onGround && !cLeft && ! cRight && vY > 0) {
			//FALL/////////////////////////////////////////////////////////////
			_setAnim('fall');
		}

		//_camera.lookPoint.y += vY * 10;

		//count down jump margin timer
		_jumpMarginTimer -= dt;

		_touchJump = false;
		_gamepadJump = false;
		_gamepadJumpRelease = false;
		_touchJumpReleased = false;
	}

	function _setAnim(anim: String) {
		if(_attacking) return;
		_anim.frame = 0;
		_anim.animation = anim;
	}

	function _attackOverhead(direction: Int) {
		if(_attacking) return;

		_setAnim('attack-overhead');
		vY = -_jumpHeight * 0.5;
		_attacking = true;
	}

	function _checkFinished(anim: String, frame: Int): Bool {
		if(_anim.animation == anim) {
			if(_anim.frame == frame) return true;
		}
		return false;
	}

	function _attackComplete(_) {
		_attacking = false;
		_setAnim('run');
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
		_collisionShape.x = pos.x + colWidthOffset;
		_collisionShape.y = pos.y + colHeightOffset;

		//iterate over y-velocity
		for(i in 0...Std.int(Math.abs(vYNew)) + 1) {
			//add direction to collision shape
			_collisionShape.y += _sign(vYNew);

			//test new position against scene
			var c = Collision.testShapes(_collisionShape, cast Level.instance.colliders);
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
		_collisionShape.y = pos.y + colHeightOffset;

		//iterate over x-velocity
		for(i in 0...Std.int(Math.abs(vXNew)) + 1) {
			//add direction to collision shape
			_collisionShape.x += _sign(vXNew);

			//test new position against scene
			var c = Collision.testShapes(_collisionShape, cast Level.instance.colliders);
			if(c.length > 0) {
				vX = 0;
				break;
			}
			else {
				//if no collisions, add 1 pixel of movement to position
				pos.x += _sign(vXNew);
			}
		}

		_collisionShape.x = pos.x + colWidthOffset;
		_collisionShape.y = pos.y + colHeightOffset;
		var finalCols = Collision.testShapes(_collisionShape, cast Level.instance.colliders);
		if(finalCols.length > 0) {
			for(fc in finalCols) {
				if(fc.separation.length > 0) {
					trace('separating');
					if(fc.separation.x < fc.separation.y) {
						trace('x');
						fc.separation.x += _sign(fc.separation.x);
					}
					else {
						trace('y');
						fc.separation.y += _sign(fc.separation.y);
					}
				}
				_collisionShape.position.add(fc.separation);
			}
		}
		pos.x = _collisionShape.x - colWidthOffset;
		pos.y = _collisionShape.y - colHeightOffset;
	}

	///Returns +1/0/-1 for sign of float
	function _sign(v: Float): Int {
		if(v == 0) return 0;
		return v < 0 ? -1 : 1;
	}

	///Check if touching at base
	function _onGround(): Bool {
		return _checkCollision(0, 1);
	}

	///Check collision after an offset
	function _checkCollision(offsetX: Int, offsetY: Int): Bool {
		_collisionShape.x = pos.x + colWidthOffset + offsetX;
		_collisionShape.y = pos.y + colHeightOffset + offsetY;

		return Collision.testShapes(_collisionShape, cast Level.instance.colliders).length > 0;
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

}