package zen.debug {
	import zen.display.*;
	import flash.geom.Vector3D;
	import zen.geom.*;
	import zen.display.*;
	
	/** Linked to a ZenSpline instance to display the spline in wireframe mode */
	public class DebugShape extends ZenCanvas {
		
		private var _shape:ZenSpline;
		private var _steps:int;
		
		public function DebugShape(shape:ZenSpline, steps:int = 12) {
			super(("debug_" + shape.name));
			this._steps = steps;
			this.shape = shape;
		}
		
		public function get shape():ZenSpline {
			return (this._shape);
		}
		
		public function set shape(value:ZenSpline):void {
			this._shape = value;
			this.config();
		}
		
		public function get steps():int {
			return (this._steps);
		}
		
		public function set steps(value:int):void {
			this._steps = value;
			this.config();
		}
		
		private function config():void {
			var spline:Spline3D;
			var start:Vector3D;
			var length:int;
			var i:Number;
			if (!(this.shape)) {
				return;
			}
			clear();
			lineStyle(1, this.shape.color);
			var point:Vector3D = new Vector3D();
			for each (spline in this._shape.splines) {
				start = spline.getPoint(0);
				length = (spline.knots.length * this._steps);
				moveTo(start.x, start.y, start.z);
				i = (1 / length);
				while (i < 1) {
					spline.getPoint(i, point);
					lineTo(point.x, point.y, point.z);
					i = (i + (1 / length));
				}
				if (spline.closed) {
					lineTo(start.x, start.y, start.z);
				}
			}
		}
	
	}
}

