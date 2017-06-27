package zen.debug {
	import zen.display.*;
	import zen.ZenCamera;
	import zen.display.*;
	
	/** Linked to a ZenCamera instance to display the camera's position and frustrum in wireframe mode */
	public class DebugCamera extends ZenCanvas {
		
		private var _camera:ZenCamera;
		private var _color:uint;
		private var _alpha:Number;
		
		public function DebugCamera(camera:ZenCamera, color:int = 0xFFCB00, alpha:Number = 1) {
			super(("debug_" + ((camera) ? camera.name : "camera")));
			this._alpha = alpha;
			this._color = color;
			this.camera = camera;
		}
		
		private function config():void {
			var sizeX:Number;
			var sizeY:Number;
			var size2X:Number;
			var size2Y:Number;
			if (!(this._camera)) {
				return;
			}
			var far:Number = this._camera.far;
			var aspectRatio:Number = ((this._camera.aspectRatio) || (1));
			clear();
			lineStyle(1, this._color, this._alpha);
			var x:Number = (1 / this._camera.projection.rawData[0]);
			var y:Number = (1 / this._camera.projection.rawData[5]);
			sizeX = (x * this._camera.near);
			sizeY = (y * this._camera.near);
			moveTo(-(sizeX), sizeY, this._camera.near);
			lineTo(sizeX, sizeY, this._camera.near);
			lineTo(sizeX, -(sizeY), this._camera.near);
			lineTo(-(sizeX), -(sizeY), this._camera.near);
			lineTo(-(sizeX), sizeY, this._camera.near);
			size2X = (x * far);
			size2Y = (y * far);
			moveTo(-(size2X), size2Y, far);
			lineTo(size2X, size2Y, far);
			lineTo(size2X, -(size2Y), far);
			lineTo(-(size2X), -(size2Y), far);
			lineTo(-(size2X), size2Y, far);
			lineStyle(1, this._color, this._alpha);
			moveTo(sizeX, sizeY, this._camera.near);
			lineTo(size2X, size2Y, far);
			moveTo(sizeX, -(sizeY), this._camera.near);
			lineTo(size2X, -(size2Y), far);
			moveTo(-(sizeX), -(sizeY), this._camera.near);
			lineTo(-(size2X), -(size2Y), far);
			moveTo(-(sizeX), sizeY, this._camera.near);
			lineTo(-(size2X), size2Y, far);
		}
		
		public function get camera():ZenCamera {
			return (this._camera);
		}
		
		public function set camera(value:ZenCamera):void {
			this._camera = value;
			this.config();
		}
	
	}
}

