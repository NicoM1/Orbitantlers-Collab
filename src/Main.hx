
import luxe.Input;
import luxe.AppConfig;
import luxe.Camera;
import phoenix.Vector;
import phoenix.Color;
import level.LevelEditor;
import level.LevelRect;
import luxe.Parcel;
import luxe.ParcelProgress;

//47.26 STRIPPED
class Main extends luxe.Game {

	var _defaultX: Int = 960;
	var _defaultY: Int = 640;

	var _editor: LevelEditor;

	override function config(c: AppConfig): AppConfig {
		//c.window.width = 1440;
		//c.window.width = 768;
		return c;
	}

    override function ready() {
    	_setUpCamera();
    	Luxe.renderer.clear_color = new Color(94 / 255, 92 / 255, 79 / 255);
    	Luxe.renderer.vsync = true;

    	_load();

    	_editor = new LevelEditor();
    } //ready

    function _setUpCamera() {
    	/*var scaleX = Luxe.screen.w / _defaultX;
    	var scaleY = Luxe.screen.h / _defaultY;

    	Luxe.camera.size = new Vector(Luxe.screen.w / scaleX, Luxe.screen.h / scaleY);
    	Luxe.camera.size_mode = SizeMode.fit;

    	Luxe.draw.line({
    		p0:	new Vector(0,0),
    		p1:	new Vector(0, Luxe.screen.h)
    	});
    	Luxe.draw.line({
    		p0:	new Vector(Luxe.camera.size.x,0),
    		p1:	new Vector(Luxe.camera.size.x, Luxe.screen.h)
    	});function*/
		Luxe.camera.zoom = 2.0;
    }

    function _load() {
    	var json = Luxe.loadJSON('assets/files/parcel.json');

    	var parcel = new Parcel();
    	parcel.from_json(json.json);

    	new ParcelProgress({
    		parcel: parcel,
    		background: new Color(0.3,0.3,0.3),
    		oncomplete: _assetsLoaded
    	});

    	parcel.load();
    }

    function _assetsLoaded(_) {
    	trace('loaded');
    	new Player();
    }

    override function onkeyup( e:KeyEvent ) {

        if(e.keycode == Key.escape) {
            Luxe.shutdown();
        }

    } //onkeyup

    override function update(dt:Float) {
    	_editor.update();
    } //update


} //Main
