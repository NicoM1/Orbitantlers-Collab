
import luxe.Input;
import luxe.AppConfig;
import luxe.Camera;
import phoenix.Vector;
import level.LevelEditor;
import level.LevelRect;

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
    	Luxe.renderer.vsync = true;
    	new Player();

    	_editor = new LevelEditor();
    } //ready

    function _setUpCamera() {
    	var scaleX = Luxe.screen.w / _defaultX;
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
    	});
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
