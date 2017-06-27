package zen.input {
	import flash.events.Event;
	import zen.geom.*;
	
	/** Fired when the user interacts with a 3D object with the mouse/touchscreen */
	public class MouseEvent3D extends Event {
		
		public static const CLICK:String = "click";
		public static const MOUSE_DOWN:String = "mouseDown";
		public static const MOUSE_MOVE:String = "mouseMove";
		public static const MOUSE_OUT:String = "mouseOut";
		public static const MOUSE_OVER:String = "mouseOver";
		public static const MOUSE_UP:String = "mouseUp";
		public static const MOUSE_WHEEL:String = "mouseWheel";
		
		public var info:Intersection3D;
		
		public function MouseEvent3D(type:String, info:Intersection3D = null) {
			this.info = new Intersection3D();
			this.info = info;
			super(type);
		}
		
		override public function clone():Event {
			return (new MouseEvent3D(type, this.info));
		}
		
		override public function toString():String {
			return ((('[MouseEvent3D type="' + type) + '"]'));
		}
	
	}
}

