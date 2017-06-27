package zen.display {
	
	import zen.display.*;
	import zen.display.*;
	import zen.materials.*;
	import zen.enums.*;
	import zen.utils.*;
	import zen.geom.*;
	import flash.geom.*;
	
	/** A 3D camera that supports perspective and orthogonal views.
	 *  Link this to a Zen3D instance to modify its viewport according to the camera position/rotation.
	 *  You can create multiple cameras but only one can be active at a time.
	 *  It internally maintains near/far planes and frustrum planes used for frustrum clipping. */
	public class ZenCamera extends ZenObject {
		
		private static const rawPlanes:Vector.<Number> = new Vector.<Number>(16, true);
		private static const vec:Vector3D = new Vector3D();
		
		private static var _inv:Matrix3D;
		
		public var activeScene:Zen3D;
		
		private const rawData:Vector.<Number> = new Vector.<Number>(16, true);
		
		private var _near:Number;
		private var _far:Number;
		private var _fieldOfView:Number;
		private var _zoom:Number;
		private var _aspect:Number;
		private var _cachedAspectRatio:Number;
		private var _view:Matrix3D;
		private var _projection:Matrix3D;
		private var _customProjection:Matrix3D;
		private var _viewProjection:Matrix3D;
		private var _viewport:Rectangle;
		private var _canvasSize:Point;
		private var _frustum:Vector.<Number>;
		public var clipRectangle:Boolean = true;
		public var orthographic:Boolean = false;
		public var fovMode:int = 0;
		
		public function ZenCamera(name:String = "", fieldOfView:Number = 75, near:Number = 1, far:Number = 5000) {
			this._frustum = new Vector.<Number>(24, true);
			super(name);
			this._near = near;
			this._far = far;
			this._view = new Matrix3D();
			this._projection = new Matrix3D();
			this._viewProjection = new Matrix3D();
			this.aspectRatio = this._aspect;
			this.fieldOfView = fieldOfView;
			this.updateProjectionMatrix();
		}
		
		public function set viewPort(rect:Rectangle):void {
			this._viewport = rect;
			this.updateProjectionMatrix();
		}
		
		public function get viewPort():Rectangle {
			return (this._viewport);
		}
		
		public function set canvasSize(rect:Point):void {
			this._canvasSize = rect;
			this.updateProjectionMatrix();
		}
		
		public function get canvasSize():Point {
			return (this._canvasSize);
		}
		
		public function getPointDir(x:Number, y:Number, outDir:Vector3D = null, outPos:Vector3D = null):Vector3D {
			if (!(outDir)) {
				outDir = new Vector3D();
			}
			var view:Rectangle = ZenUtils.scene.viewPort;
			if (!(view)) {
				return (outDir);
			}
			x = (x - view.x);
			y = (y - view.y);
			_inv = ((_inv) || (new Matrix3D()));
			_inv.copyFrom(((this._customProjection) || (this._projection)));
			_inv.invert();
			if (!(this.orthographic)) {
				outDir.x = (((x / view.width) - 0.5) * 2);
				outDir.y = (((-(y) / view.height) + 0.5) * 2);
				outDir.z = 1;
				M3D.transformVector(_inv, outDir, outDir);
				outDir.x = (outDir.x * outDir.z);
				outDir.y = (outDir.y * outDir.z);
				M3D.deltaTransformVector(world, outDir, outDir);
				if (outPos) {
					getPosition(false, outPos);
				}
				outDir.normalize();
			} else {
				this.projection.copyRawDataTo(this.rawData);
				outPos.x = ((((x / view.width) - 0.5) * 2) / this.rawData[0]);
				outPos.y = ((((-(y) / view.height) + 0.5) * 2) / this.rawData[5]);
				outPos.z = 0;
				M3D.transformVector(world, outPos, outPos);
				outDir.x = 0;
				outDir.y = 0;
				outDir.z = 1;
				M3D.transformVector(_inv, outDir, outDir);
				M3D.deltaTransformVector(world, outDir, outDir);
			}
			return (outDir);
		}
		
		public function updateProjectionMatrix():void {
			var w:Number;
			var h:Number;
			var x:Number;
			var y:Number;
			if (this._customProjection) {
				ZenUtils.proj.copyFrom(this._customProjection);
				this.calculatePlanes();
				dirty = true;
				return;
			}
			var n:Number = this._near;
			var f:Number = this._far;
			var a:Number = this._aspect;
			var s:Zen3D = ((this.scene) || (ZenUtils.scene));
			if (this.viewPort) {
				w = this.viewPort.width;
				h = this.viewPort.height;
			} else {
				if (((s) && (s.viewPort))) {
					w = s.viewPort.width;
					h = s.viewPort.height;
				}
			}
			if (this.fovMode == CameraFovMode.HORIZONTAL) {
				if (isNaN(a)) {
					a = (w / h);
				}
				y = ((1 / this._zoom) * a);
				x = (y / a);
			} else {
				if (isNaN(a)) {
					a = (h / w);
				}
				x = ((1 / this._zoom) * a);
				y = (x / a);
			}
			this._cachedAspectRatio = a;
			this.rawData[0] = x;
			this.rawData[5] = y;
			this.rawData[10] = (f / (n - f));
			this.rawData[11] = -1;
			this.rawData[14] = ((f * n) / (n - f));
			if (this._viewport) {
				if (this._canvasSize) {
					w = this._canvasSize.x;
					h = this._canvasSize.y;
				} else {
					if (((s) && (s.viewPort))) {
						w = s.viewPort.width;
						h = s.viewPort.height;
					}
				}
				this.rawData[0] = (x / (w / this._viewport.width));
				this.rawData[5] = (y / (h / this._viewport.height));
				this.rawData[8] = ((1 - (this._viewport.width / w)) - ((this._viewport.x / w) * 2));
				this.rawData[9] = ((-1 + (this._viewport.height / h)) + ((this._viewport.y / h) * 2));
			}
			this._projection.copyRawDataFrom(this.rawData);
			this._projection.prependScale(1, 1, -1);
			dirty = true;
			ZenUtils.proj.copyFrom(this._projection);
			this.calculatePlanes();
		}
		
		private function calculatePlanes():void {
			var im:Number;
			ZenUtils.proj.copyRawDataTo(rawPlanes, 0, false);
			this._frustum[0] = (rawPlanes[3] - rawPlanes[0]);
			this._frustum[1] = 0;
			this._frustum[2] = -1;
			this._frustum[3] = 0;
			this._frustum[4] = (rawPlanes[3] + rawPlanes[0]);
			this._frustum[5] = 0;
			this._frustum[6] = -1;
			this._frustum[7] = 0;
			this._frustum[8] = 0;
			this._frustum[9] = (rawPlanes[7] + rawPlanes[5]);
			this._frustum[10] = -1;
			this._frustum[11] = 0;
			this._frustum[12] = 0;
			this._frustum[13] = (rawPlanes[7] - rawPlanes[5]);
			this._frustum[14] = -1;
			this._frustum[15] = 0;
			this._frustum[16] = 0;
			this._frustum[17] = 0;
			this._frustum[18] = -1;
			this._frustum[19] = this._near;
			this._frustum[20] = 0;
			this._frustum[21] = 0;
			this._frustum[22] = 1;
			this._frustum[23] = -(this._far);
			var i:int;
			while (i < 16) {
				im = (1 / Math.sqrt((((this._frustum[i] * this.frustum[i]) + (this._frustum[(i + 1)] * this.frustum[(i + 1)])) + (this._frustum[(i + 2)] * this.frustum[(i + 2)]))));
				this._frustum[i] = (this._frustum[i] * im);
				this._frustum[(i + 1)] = (this._frustum[(i + 1)] * im);
				this._frustum[(i + 2)] = (this._frustum[(i + 2)] * im);
				this._frustum[(i + 3)] = (this._frustum[(i + 3)] * im);
				i = (i + 4);
			}
		}
		
		public function isSphereInView(point:Vector3D, radius:Number, viewSpace:Boolean = true):Boolean {
			var x:Number;
			var y:Number;
			var z:Number;
			if (viewSpace) {
				x = point.x;
				y = point.y;
				z = point.z;
			} else {
				M3D.transformVector(this.view, point, vec);
				x = vec.x;
				y = vec.y;
				z = vec.z;
			}
			if (((((x * this._frustum[0]) + (y * this._frustum[1])) + (z * this._frustum[2])) + this._frustum[3]) > radius) {
				return (false);
			}
			if (((((x * this._frustum[4]) + (y * this._frustum[5])) + (z * this._frustum[6])) + this._frustum[7]) > radius) {
				return (false);
			}
			if (((((x * this._frustum[16]) + (y * this._frustum[17])) + (z * this._frustum[18])) + this._frustum[19]) > radius) {
				return (false);
			}
			if (((((x * this._frustum[20]) + (y * this._frustum[21])) + (z * this._frustum[22])) + this._frustum[23]) > radius) {
				return (false);
			}
			if (((((x * this._frustum[8]) + (y * this._frustum[9])) + (z * this._frustum[10])) + this._frustum[11]) > radius) {
				return (false);
			}
			if (((((x * this._frustum[12]) + (y * this._frustum[13])) + (z * this._frustum[14])) + this._frustum[15]) > radius) {
				return (false);
			}
			return (true);
		}
		
		public function get frustum():Vector.<Number> {
			return (this._frustum);
		}
		
		public function get fieldOfView():Number {
			return (this._fieldOfView);
		}
		
		public function set fieldOfView(value:Number):void {
			this._fieldOfView = value;
			this._zoom = Math.tan((((value / 2) * Math.PI) / 180));
			this.updateProjectionMatrix();
		}
		
		public function get zoom():Number {
			return (this._zoom);
		}
		
		public function set zoom(value:Number):void {
			this._zoom = value;
			this._fieldOfView = (((Math.atan(value) * 180) / Math.PI) * 2);
			this.updateProjectionMatrix();
		}
		
		public function get near():Number {
			return (this._near);
		}
		
		public function set near(value:Number):void {
			if (value <= 0.001) {
				value = 0.001;
			}
			this._near = value;
			this.updateProjectionMatrix();
		}
		
		public function get far():Number {
			return (this._far);
		}
		
		public function set far(value:Number):void {
			this._far = value;
			this.updateProjectionMatrix();
		}
		
		public function get view():Matrix3D {
			if (((dirty) || (_dirtyInv))) {
				this._view.copyFrom(invWorld);
			}
			return (this._view);
		}
		
		public function get viewProjection():Matrix3D {
			if (((dirty) || (_dirtyInv))) {
				this._viewProjection.copyFrom(this.view);
				this._viewProjection.append(((this._customProjection) || (this._projection)));
			}
			return (this._viewProjection);
		}
		
		public function get projection():Matrix3D {
			return (((this._customProjection) || (this._projection)));
		}
		
		public function set projection(value:Matrix3D):void {
			this._customProjection = value;
		}
		
		public function get aspectRatio():Number {
			return (this._cachedAspectRatio);
		}
		
		public function set aspectRatio(value:Number):void {
			this._aspect = value;
			this.updateProjectionMatrix();
		}
		
		override public function dispose():void {
			if (((scene) && ((scene.camera == this)))) {
				scene.camera = new ZenCamera();
				scene.camera.transform.copyFrom(world);
				scene.camera.fieldOfView = this.fieldOfView;
				scene.camera.near = this.near;
				scene.camera.far = this.far;
			}
			super.dispose();
		}
		
		override public function clone():ZenObject {
			var c:ZenObject;
			var n:ZenCamera = new ZenCamera(name);
			n.copyFrom(this);
			n.near = this.near;
			n.far = this.far;
			n.fieldOfView = this.fieldOfView;
			for each (c in children) {
				if (!(c.lock)) {
					n.addChild(c.clone());
				}
			}
			return (n);
		}
		
		/** checks if the given object is fully within the 2D viewport from this camera's angle */
		public function isObjFullyInView(obj:ZenObject):Boolean {
			
			// get corner bound points of obj
			var bounds:Cube3D = obj.getBounds();
			var corners:Array = bounds.cornerPoints();
			
			// return true only if ALL the corners are onscreen
			for each (var corner:Vector3D in corners) {
				if (!activeScene.isPointOnScreen(corner, this)) {
					return false;
				}
			}
			return true;
		}
		
		/** checks if the given object is at least partly within the 2D viewport from this camera's angle */
		public function isObjInView(obj:ZenObject):Boolean {
			
			// get corner bound points of obj
			var bounds:Cube3D = obj.getBounds();
			var corners:Array = bounds.cornerPoints();
			
			// return true only if ANY of the corners are onscreen
			for each (var corner:Vector3D in corners) {
				if (activeScene.isPointOnScreen(corner, this)) {
					return true;
				}
			}
			return false;
		}
		
		/** center the camera to the given object */
		public function centerToObj(obj:ZenObject):void {
			
			var b:Cube3D = obj.getBounds();
			var center:Vector3D = b.center;
			
			// look at the obj center
			lookAt(center.x, center.y, center.z);
		
		}
		
		/** center the camera to the given object, and zoom in/out to precisely fit the object in the 2D viewport */
		public function zoomToFitObj(obj:ZenObject, preserveAngle:Boolean = true, lookAtCenter:Boolean = true):void {
			
			if (activeScene == null || activeScene.viewPort == null) {
				return;
			}
			
			var b:Cube3D = obj.getBounds();
			var center:Vector3D = b.center;
			
			// look at the obj center
			if (lookAtCenter) {
				lookAt(center.x, center.y, center.z);
			}
			
			// calc in loop
			var step:Number = b.radius / 10;
			var length:Number = step; /// the most zoomed in we can get
			for (var t:int = 0; t < 1000; t++) {
				
				// MOVE CAM BACK
				if (preserveAngle) {
					// move cam based on radius, keeping angle
					this.position = V3D.setLengthBetween(this.position, center, length);
				} else {
					// move cam to Top Front Right (TFR) based on radius
					setPosition(length, length, length);
				}
				
				// check if obj fully in view
				if (isObjFullyInView(obj)) {
					break;
				}
				length += step;
				
			}
		
		}
		
		/** set the camera to a standard view (top, front, etc) around a given object */
		public function stdViewObj(obj:ZenObject, view:int):void {
			
			var b:Cube3D = obj.getBounds();
			var center:Vector3D = b.center;
			
			// position cam to std view around obj
			position = center.add(V3D.standardView(view));
			
			// zoom to fit!
			zoomToFitObj(obj, true);
		}
		
		/** rotate the cam around an object, like rotating a 2D photo (on Z) */
		public function rotateAroundObj2D(obj:ZenObject, angle:int):void {
			
			var b:Cube3D = obj.getBounds();
			var center:Vector3D = b.center;
			
			// look at the obj center
			//lookAt(center.x, center.y, center.z);
			
			// rotate cam view like rotating a photo (on Z)
			rotateAxis(angle, getForward(), center);
		
		}
		
		/** orbit the camera around an object, either horizontally or vertically */
		public function rotateAroundObj(obj:ZenObject, horiz:Boolean, angle:int):void {
			
			var b:Cube3D = obj.getBounds();
			var center:Vector3D = b.center;
			
			// look at the obj center
			//lookAt(center.x, center.y, center.z);
			
			if (horiz) {
				rotateAxis(angle, getRight(), center);
			} else {
				rotateAxis(angle, getUp(), center);
			}
		
		}
	
	}
}

