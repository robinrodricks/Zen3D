package zen.input
{
    import flash.display.Stage;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.events.Event;
    import flash.events.*;
    import flash.display.*;

    public class ZenInput 
    {
        private static var _ups:Array;
        private static var _downs:Array;
        private static var _hits:Array;
        private static var _keyCode:int = 0;
        private static var _delta:int = 0;
        private static var _deltaMove:int = 0;
        private static var _mouseUp:int = 0;
        private static var _mouseHit:int = 0;
        private static var _mouseDown:int;
        private static var _rightMouseUp:int = 0;
        private static var _rightMouseHit:int = 0;
        private static var _rightMouseDown:int;
        private static var _middleMouseUp:int = 0;
        private static var _middleMouseHit:int = 0;
        private static var _middleMouseDown:int;
        private static var _mouseDoubleClick:int = 0;
        private static var _mouseX:Number = 0;
        private static var _mouseY:Number = 0;
        private static var _mouseXSpeed:Number = 0;
        private static var _mouseYSpeed:Number = 0;
        private static var _mouseUpdated:Boolean = true;
        private static var _stage:Stage;
        private static var _doubleClickEnabled:Boolean;
        private static var _rightClickEnabled:Boolean;
        private static var _stageX:Number = 0;
        private static var _stageY:Number = 0;
        public static var eventPhase:uint;
        public static var enableEventPhase:Boolean = true;
        private static var _currFrame:int;


        public static function initialize(stage:Stage):void
        {
            if (stage == null) {
				
                throw ("The 'stage' parameter is null");
				
				return;
            }
            _stage = stage;
            _downs = ((_downs) || (new Array()));
            _hits = ((_hits) || (new Array()));
            _ups = ((_ups) || (new Array()));
            _mouseX = _stage.mouseX;
            _mouseY = _stage.mouseY;
            _stage.addEventListener(KeyboardEvent.KEY_DOWN, keyDownEvent, false, 0, true);
            _stage.addEventListener(KeyboardEvent.KEY_UP, keyUpEvent, false, 0, true);
            _stage.addEventListener(MouseEvent.MOUSE_MOVE, mouseUpdate, false, 0, true);
            _stage.addEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelEvent, false, 0, true);
            _stage.addEventListener(MouseEvent.MOUSE_DOWN, mouseDownEvent, false, 0, true);
            _stage.addEventListener(MouseEvent.MOUSE_UP, mouseUpEvent, false, 0, true);
            _stage.addEventListener("middleMouseDown", middleMouseDownEvent, false, 0, true);
            _stage.addEventListener("middleMouseUp", middleMouseUpEvent, false, 0, true);
            _stage.addEventListener(Event.DEACTIVATE, deactivateEvent, false, 0, true);
            doubleClickEnabled = _doubleClickEnabled;
            rightClickEnabled = _rightClickEnabled;
        }

        public static function deactivate():void
        {
            if (!(_stage)){
                return;
            }
            _stage.removeEventListener(KeyboardEvent.KEY_DOWN, keyDownEvent);
            _stage.removeEventListener(KeyboardEvent.KEY_UP, keyUpEvent);
            _stage.removeEventListener(MouseEvent.MOUSE_MOVE, mouseUpdate);
            _stage.removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownEvent);
            _stage.removeEventListener(MouseEvent.MOUSE_UP, mouseUpEvent);
            _stage.removeEventListener(MouseEvent.MOUSE_WHEEL, mouseWheelEvent);
            _stage.removeEventListener(MouseEvent.DOUBLE_CLICK, mouseDoubleClickEvent);
            _stage.removeEventListener(Event.DEACTIVATE, deactivateEvent);
        }

        private static function deactivateEvent(e:Event):void
        {
            reset();
        }

        public static function dispose():void
        {
            deactivate();
            _downs = null;
            _hits = null;
            _ups = null;
            _stage = null;
        }

        private static function mouseUpdate(e:MouseEvent):void
        {
            _mouseUpdated = true;
            _stageX = e.stageX;
            _stageY = e.stageY;
        }

        public static function update():void
        {
            _currFrame++;
            if (_mouseUpdated){
                _mouseXSpeed = (_stageX - _mouseX);
                _mouseYSpeed = (_stageY - _mouseY);
                _mouseUpdated = false;
            } else {
                _mouseXSpeed = 0;
                _mouseYSpeed = 0;
            }
            _mouseX = _stageX;
            _mouseY = _stageY;
        }

        public static function reset():void
        {
            var i:int;
            while (i < 0xFF) {
                _downs[i] = 0;
                _hits[i] = 0;
                _ups[i] = 0;
                i++;
            }
            _mouseXSpeed = 0;
            _mouseYSpeed = 0;
            _mouseUp = 0;
            _mouseDown = 0;
            _mouseHit = 0;
            _rightMouseUp = 0;
            _rightMouseDown = 0;
            _rightMouseHit = 0;
            _middleMouseUp = 0;
            _middleMouseDown = 0;
            _middleMouseHit = 0;
            _mouseDoubleClick = 0;
        }

        private static function keyDownEvent(e:KeyboardEvent):void
        {
            if (!(_downs[e.keyCode])){
                _hits[e.keyCode] = (_currFrame + 1);
            }
            _downs[e.keyCode] = 1;
            _keyCode = e.keyCode;
        }

        private static function keyUpEvent(e:KeyboardEvent):void
        {
            if (!(_stage)){
                return;
            }
            _downs[e.keyCode] = 0;
            _hits[e.keyCode] = 0;
            _ups[e.keyCode] = (_currFrame + 1);
            _keyCode = 0;
        }

        private static function mouseDownEvent(e:MouseEvent):void
        {
            if (enableEventPhase){
                eventPhase = e.eventPhase;
            } else {
                eventPhase = 0;
            }
            _mouseDown = 1;
            _mouseUp = 0;
            _mouseHit = (_currFrame + 1);
            _mouseX = _stageX;
            _mouseY = _stageY;
        }

        private static function mouseWheelEvent(e:MouseEvent):void
        {
            if (enableEventPhase){
                eventPhase = e.eventPhase;
            } else {
                eventPhase = 0;
            }
            _delta = e.delta;
            _deltaMove = (_currFrame + 1);
        }

        private static function mouseUpEvent(e:MouseEvent):void
        {
            if (enableEventPhase){
                eventPhase = e.eventPhase;
            } else {
                eventPhase = 0;
            }
            _mouseDown = 0;
            _mouseUp = (_currFrame + 1);
            _mouseHit = 0;
        }

        private static function rightMouseDownEvent(e:Event):void
        {
            _rightMouseDown = 1;
            _rightMouseUp = 0;
            _rightMouseHit = (_currFrame + 1);
        }

        private static function rightMouseUpEvent(e:Event):void
        {
            _rightMouseDown = 0;
            _rightMouseUp = (_currFrame + 1);
            _rightMouseHit = 0;
        }

        private static function middleMouseDownEvent(e:Event):void
        {
            _middleMouseDown = 1;
            _middleMouseUp = 0;
            _middleMouseHit = (_currFrame + 1);
        }

        private static function middleMouseUpEvent(e:Event):void
        {
            _middleMouseDown = 0;
            _middleMouseUp = (_currFrame + 1);
            _middleMouseHit = 0;
        }

        private static function mouseDoubleClickEvent(e:MouseEvent):void
        {
            _mouseDoubleClick = (_currFrame + 1);
        }

        public static function get keyCode():int
        {
            return (_keyCode);
        }

        public static function keyDown(keyCode:int):Boolean
        {
            return (_downs[keyCode]);
        }

        public static function keyHit(keyCode:int):Boolean
        {
            return ((((_hits[keyCode] == _currFrame)) ? true : false));
        }

        public static function keyUp(keyCode:int):Boolean
        {
            return ((((_ups[keyCode] == _currFrame)) ? true : false));
        }

        public static function get mouseDoubleClick():int
        {
            return ((((_mouseDoubleClick == _currFrame)) ? 1 : 0));
        }

        public static function get delta():int
        {
            return ((((_deltaMove == _currFrame)) ? _delta : 0));
        }

        public static function set delta(value:int):void
        {
            _delta = value;
        }

        public static function get mouseYSpeed():Number
        {
            return (_mouseYSpeed);
        }

        public static function get mouseHit():int
        {
            return ((((_mouseHit == _currFrame)) ? 1 : 0));
        }

        public static function get mouseUp():int
        {
            return ((((_mouseUp == _currFrame)) ? 1 : 0));
        }

        public static function get mouseDown():int
        {
            return (_mouseDown);
        }

        public static function get rightMouseHit():int
        {
            return ((((_rightMouseHit == _currFrame)) ? 1 : 0));
        }

        public static function get rightMouseUp():int
        {
            return ((((_rightMouseUp == _currFrame)) ? 1 : 0));
        }

        public static function get rightMouseDown():int
        {
            return (_rightMouseDown);
        }

        public static function get middleMouseHit():int
        {
            return ((((_middleMouseHit == _currFrame)) ? 1 : 0));
        }

        public static function get middleMouseUp():int
        {
            return ((((_middleMouseUp == _currFrame)) ? 1 : 0));
        }

        public static function get middleMouseDown():int
        {
            return (_middleMouseDown);
        }

        public static function get mouseXSpeed():Number
        {
            return (_mouseXSpeed);
        }

        public static function get mouseY():Number
        {
            return (_mouseY);
        }

        public static function set mouseY(value:Number):void
        {
            _mouseY = value;
        }

        public static function get mouseX():Number
        {
            return (_mouseX);
        }

        public static function set mouseX(value:Number):void
        {
            _mouseX = value;
        }

        public static function get mouseMoved():Number
        {
            return (Math.abs((_mouseXSpeed + _mouseYSpeed)));
        }

        public static function get doubleClickEnabled():Boolean
        {
            return (_doubleClickEnabled);
        }

        public static function set doubleClickEnabled(value:Boolean):void
        {
            _doubleClickEnabled = value;
            _stage.doubleClickEnabled = value;
            if (value){
                _stage.addEventListener(MouseEvent.DOUBLE_CLICK, mouseDoubleClickEvent, false, 0, true);
            } else {
                _stage.removeEventListener(MouseEvent.DOUBLE_CLICK, mouseDoubleClickEvent);
            }
        }

        public static function get rightClickEnabled():Boolean
        {
            return (_doubleClickEnabled);
        }

        public static function set rightClickEnabled(value:Boolean):void
        {
            _rightClickEnabled = value;
            if (value){
                _stage.addEventListener("rightMouseDown", rightMouseDownEvent, false, 0, true);
                _stage.addEventListener("rightMouseUp", rightMouseUpEvent, false, 0, true);
            } else {
                _stage.removeEventListener("rightMouseDown", rightMouseDownEvent);
                _stage.removeEventListener("rightMouseUp", rightMouseUpEvent);
            }
        }

        public static function get downs():Array
        {
            return (_downs);
        }

        public static function get hits():Array
        {
            return (_hits);
        }

        public static function get stage():Stage
        {
            return (_stage);
        }


    }
}

