package zen.display {
	import zen.display.*;
	import zen.animation.*;
	import zen.enums.*;
	import flash.events.*;
	import flash.geom.*;
	import zen.input.*;
	import zen.materials.*;
	import zen.physics.colliders.*;
	import zen.shaders.textures.*;
	import zen.utils.*;
	import zen.geom.*;
	import flash.display3D.*;
	import flash.utils.*;
	
	[Event(name = "animationComplete", type = "flash.events.Event")]
	[Event(name = "added", type = "flash.events.Event")]
	[Event(name = "addedToScene", type = "flash.events.Event")]
	[Event(name = "removedFromScene", type = "flash.events.Event")]
	[Event(name = "removed", type = "flash.events.Event")]
	[Event(name = "enterFrame", type = "flash.events.Event")]
	[Event(name = "exitFrame", type = "flash.events.Event")]
	[Event(name = "enterDraw", type = "flash.events.Event")]
	[Event(name = "exitDraw", type = "flash.events.Event")]
	[Event(name = "unload", type = "flash.events.Event")]
	[Event(name = "changeTransform", type = "flash.events.Event")]
	[Event(name = "enterDrag", type = "flash.events.Event")]
	[Event(name = "exitDrag", type = "flash.events.Event")]
	
	/** The base class for all 3D objects.
	   Supports transformation (position, rotation, scaling), materials,
	   animation and mouse dragging.
	
	   Similar to the DisplayObject in 2D graphics.
	 */
	public class ZenObject extends EventDispatcher {
		
		public static const ADDED_EVENT:String = "added";
		public static const REMOVED_EVENT:String = "removed";
		public static const ADDED_TO_SCENE_EVENT:String = "addedToScene";
		public static const REMOVED_FROM_SCENE_EVENT:String = "removedFromScene";
		public static const ANIMATION_COMPLETE_EVENT:String = "animationComplete";
		public static const UNLOAD_EVENT:String = "unload";
		public static const ENTER_FRAME_EVENT:String = "enterFrame";
		public static const EXIT_FRAME_EVENT:String = "exitFrame";
		public static const ENTER_DRAW_EVENT:String = "enterDraw";
		public static const EXIT_DRAW_EVENT:String = "exitDraw";
		public static const UPDATE_TRANSFORM_EVENT:String = "updateTransform";
		public static const ENTER_DRAG_EVENT:String = "enterDrag";
		public static const EXIT_DRAG_EVENT:String = "exitDrag";
		
		protected static const _enterDrawEvent:Event = new Event(ENTER_DRAW_EVENT);
		protected static const _exitDrawEvent:Event = new Event(EXIT_DRAW_EVENT);
		protected static const _enterFrameEvent:Event = new Event(ENTER_FRAME_EVENT);
		protected static const _exitFrameEvent:Event = new Event(EXIT_FRAME_EVENT);
		protected static const _updateTransformEvent:Event = new Event(UPDATE_TRANSFORM_EVENT);
		protected static const _animationCompleteEvent:Event = new Event(ANIMATION_COMPLETE_EVENT);
		
		private static var _temp0:Vector3D = new Vector3D();
		private static var _temp1:Vector3D = new Vector3D();
		private static var _temp2:Vector3D = new Vector3D();
		private static var _dragTarget:ZenObject;
		private static var _dragStartPos:Vector3D;
		private static var _dragStartDir:Vector3D;
		private static var _dragOffset:Vector3D;
		
		public var idString:String;
		public var idInt:int;
		
		public var transform:Matrix3D;
		public var name:String;
		public var userData:Object;
		public var labels:Object;
		public var dirty:Boolean = true;
		public var priority:int = 0;
		public var layer:int = 0;
		public var receiveShadows:Boolean = true;
		public var castShadows:Boolean = true;
		private var _lock:Boolean = false;
		private var _vector:Vector3D;
		private var _children:Vector.<ZenObject>;
		private var _invGlobal:Matrix3D;
		private var _parent:ZenObject;
		var _scene:Zen3D;
		var _inScene:Boolean;
		var _sortMode:int = 1;
		var _eventFlags:uint;
		var _world:Matrix3D;
		var _dirtyInv:Boolean = true;
		public var frames:Vector.<Frame3D>;
		public var animationEnabled:Boolean = true;
		public var animationSmoothMode:int = 2;
		public var blendValue:Number = 1;
		public var lastBlendFrame:Matrix3D;
		public var animationMode:int = 0;
		private var _blendFrames:Number = 0;
		private var _from:Number = 0;
		private var _to:Number = 0;
		private var _currentFrame:Number = 0;
		private var _currentLabel:Label3D;
		private var _frameSpeed:Number = 1;
		private var _isPlaying:Boolean = false;
		private var _lastFrame:Number;
		public var visible:Boolean = true;
		private var _updatable:Boolean = false;
		private var _collider:Collider;
		
		public function ZenObject(name:String = "") {
			this.transform = new Matrix3D();
			this.labels = {};
			this._children = new Vector.<ZenObject>();
			this._invGlobal = new Matrix3D();
			this._world = new Matrix3D();
			super();
			this.name = name;
		}
		
		public function remove():void {
			if (parent) {
				parent.removeChild(this);
			}
			dispose();
		}
		
		public function upload(scene:Zen3D, includeChildren:Boolean = true):void {
			var c:ZenObject;
			this._scene = scene;
			if (includeChildren) {
				for each (c in this._children) {
					c.upload(scene, includeChildren);
				}
			}
		}
		
		public function download(includeChildren:Boolean = true):void {
			var c:ZenObject;
			this._scene = null;
			if (includeChildren) {
				for each (c in this._children) {
					c.download(includeChildren);
				}
			}
		}
		
		public function copyFrom(pivot:ZenObject):void {
			var t:Frame3D;
			var i:int;
			this.transform.copyFrom(pivot.transform);
			this.userData = pivot.userData;
			this.visible = pivot.visible;
			this.animationEnabled = pivot.animationEnabled;
			this.frameSpeed = pivot.frameSpeed;
			this.frames = pivot.frames;
			this.labels = pivot.labels;
			this.layer = pivot.layer;
			this.lock = pivot.lock;
			if (pivot.collider) {
				this.collider = pivot.collider.clone();
			}
			if (((((this.frames) && (this.frames.length))) && ((this.frames[0].type == FrameType.NULL)))) {
				this.frames = this.frames.concat();
				t = new Frame3D(this.transform.rawData, FrameType.NULL);
				i = 0;
				while (i < this.frames.length) {
					this.frames[i] = t;
					i++;
				}
				this.transform = t;
			}
		}
		
		public function clone():ZenObject {
			var c:ZenObject;
			var n:ZenObject = new ZenObject(this.name);
			n.copyFrom(this);
			for each (c in this.children) {
				if (!(c.lock)) {
					n.addChild(c.clone());
				}
			}
			return (n);
		}
		
		public function cloneMaterials():void {
			this.forEach(cloneMaterialsAux, ZenMesh);
		}
		
		private function cloneMaterialsAux(mesh:ZenMesh):void {
			var s:ZenFace;
			for each (s in mesh.surfaces) {
				if (s.material) {
					s.material = s.material.clone();
				}
			}
		}
		
		public function dispose():void {
			var c:int;
			
			if (this._invGlobal == null) {
				
				throw new Error(("Object already disposed! - " + this.name));
				
				return;
			}
			this.stopDrag();
			dispatchEvent(new Event(UNLOAD_EVENT));
			var length:int = this._children.length;
			var i:int;
			while (i < length) {
				this._children[0].dispose();
				i++;
			}
			this.parent = null;
			this.stop();
			this.transform = null;
			this.userData = null;
			this.frames = null;
			this._children = null;
			this._scene = null;
			this._world = null;
			this._invGlobal = null;
			this._vector = null;
		}
		
		public function setPosition(x:Number, y:Number, z:Number, smooth:Number = 1, local:Boolean = true):void {
			_temp0.setTo(x, y, z);
			_temp0.w = 1;
			if (((!(local)) && (this._parent))) {
				this._parent.globalToLocal(_temp0, _temp0);
			}
			if (smooth == 1) {
				this.transform.copyColumnFrom(3, _temp0);
			} else {
				this.transform.copyColumnTo(3, _temp1);
				_temp1.x = (_temp1.x + ((_temp0.x - _temp1.x) * smooth));
				_temp1.y = (_temp1.y + ((_temp0.y - _temp1.y) * smooth));
				_temp1.z = (_temp1.z + ((_temp0.z - _temp1.z) * smooth));
				this.transform.copyColumnFrom(3, _temp1);
			}
			this.updateTransforms(true);
		}
		
		public function getPosition(local:Boolean = true, out:Vector3D = null):Vector3D {
			if (out == null) {
				out = new Vector3D();
			}
			if (local) {
				this.transform.copyColumnTo(3, out);
			} else {
				this.world.copyColumnTo(3, out);
			}
			return (out);
		}
		
		public function setScale(x:Number, y:Number, z:Number, smooth:Number = 1):void {
			M3D.setScale(this.transform, x, y, z, smooth);
			this.updateTransforms(true);
		}
		
		public function getScale(local:Boolean = true, out:Vector3D = null):Vector3D {
			out = M3D.getScale(((local) ? this.transform : this.world), out);
			return (out);
		}
		
		public function setRotation(x:Number, y:Number, z:Number):void {
			M3D.setRotation(this.transform, x, y, z);
			this.updateTransforms(true);
		}
		
		public function getRotation(local:Boolean = true, out:Vector3D = null):Vector3D {
			if (out == null) {
				out = new Vector3D();
			}
			out = M3D.getRotation(((local) ? this.transform : this.world), out);
			return (out);
		}
		
		public function lookAt(x:Number, y:Number, z:Number, up:Vector3D = null, smooth:Number = 1):void {
			M3D.lookAt(this.transform, x, y, z, up, smooth);
			this.updateTransforms(true);
		}
		
		public function setOrientation(dir:Vector3D, up:Vector3D = null, smooth:Number = 1):void {
			M3D.setOrientation(this.transform, dir, up, smooth);
			this.updateTransforms(true);
		}
		
		public function setNormalOrientation(normal:Vector3D, smooth:Number = 1):void {
			M3D.setNormalOrientation(this.transform, normal, smooth);
			this.updateTransforms(true);
		}
		
		public function rotateX(angle:Number, local:Boolean = true, pivotPoint:Vector3D = null):void {
			this.rotateAxis(angle, ((local) ? this.getRight(true, _temp2) : Vector3D.X_AXIS), pivotPoint);
			this.updateTransforms(true);
		}
		
		public function rotateY(angle:Number, local:Boolean = true, pivotPoint:Vector3D = null):void {
			this.rotateAxis(angle, ((local) ? this.getUp(true, _temp2) : Vector3D.Y_AXIS), pivotPoint);
			this.updateTransforms(true);
		}
		
		public function rotateZ(angle:Number, local:Boolean = true, pivotPoint:Vector3D = null):void {
			this.rotateAxis(angle, ((local) ? this.getDir(true, _temp2) : Vector3D.Z_AXIS), pivotPoint);
			this.updateTransforms(true);
		}
		
		public function rotateAxis(angle:Number, axis:Vector3D, pivotPoint:Vector3D = null):void {
			_temp0.copyFrom(axis);
			_temp0.normalize();
			if (!(pivotPoint)) {
				this.transform.copyColumnTo(3, _temp1);
				this.transform.appendRotation(angle, _temp0, _temp1);
			} else {
				this.transform.appendRotation(angle, _temp0, pivotPoint);
			}
			this.updateTransforms(true);
		}
		
		public function set scaleX(val:Number):void {
			M3D.scaleX(this.transform, val);
			this.updateTransforms(true);
		}
		
		public function set scaleY(val:Number):void {
			M3D.scaleY(this.transform, val);
			this.updateTransforms(true);
		}
		
		public function set scaleZ(val:Number):void {
			M3D.scaleZ(this.transform, val);
			this.updateTransforms(true);
		}
		
		public function get scaleX():Number {
			return (M3D.getRight(this.transform, this._vector).length);
		}
		
		public function get scaleY():Number {
			return (M3D.getUp(this.transform, this._vector).length);
		}
		
		public function get scaleZ():Number {
			return (M3D.getDir(this.transform, this._vector).length);
		}
		
		public function setTranslation(x:Number = 0, y:Number = 0, z:Number = 0, local:Boolean = true):void {
			M3D.setTranslation(this.transform, x, y, z, local);
			this.updateTransforms(true);
		}
		
		public function translateX(distance:Number, local:Boolean = true):void {
			M3D.translateX(this.transform, distance, local);
			this.updateTransforms(true);
		}
		
		public function translateY(distance:Number, local:Boolean = true):void {
			M3D.translateY(this.transform, distance, local);
			this.updateTransforms(true);
		}
		
		public function translateZ(distance:Number, local:Boolean = true):void {
			M3D.translateZ(this.transform, distance, local);
			this.updateTransforms(true);
		}
		
		public function translateAxis(distance:Number, axis:Vector3D):void {
			M3D.translateAxis(this.transform, distance, axis);
			this.updateTransforms(true);
		}
		
		public function copyTransformFrom(source:ZenObject, local:Boolean = true):void {
			if (local) {
				this.transform.copyFrom(source.transform);
			} else {
				this.world = source.world;
			}
			this.updateTransforms(true);
		}
		
		public function resetTransforms():void {
			this.transform.identity();
			this.updateTransforms(true);
		}
		
		public function get x():Number {
			this.transform.copyColumnTo(3, _temp0);
			return (_temp0.x);
		}
		
		public function set x(val:Number):void {
			this.transform.copyColumnTo(3, _temp0);
			_temp0.x = val;
			this.transform.copyColumnFrom(3, _temp0);
			this.updateTransforms(true);
		}
		
		public function get y():Number {
			this.transform.copyColumnTo(3, _temp0);
			return (_temp0.y);
		}
		
		public function set y(val:Number):void {
			this.transform.copyColumnTo(3, _temp0);
			_temp0.y = val;
			this.transform.copyColumnFrom(3, _temp0);
			this.updateTransforms(true);
		}
		
		public function get z():Number {
			this.transform.copyColumnTo(3, _temp0);
			return (_temp0.z);
		}
		
		public function set z(val:Number):void {
			this.transform.copyColumnTo(3, _temp0);
			_temp0.z = val;
			this.transform.copyColumnFrom(3, _temp0);
			this.updateTransforms(true);
		}
		
		public function getRight(local:Boolean = true, out:Vector3D = null):Vector3D {
			return (M3D.getRight(((local) ? this.transform : this.world), out));
		}
		
		public function getLeft(local:Boolean = true, out:Vector3D = null):Vector3D {
			return (M3D.getLeft(((local) ? this.transform : this.world), out));
		}
		
		public function getUp(local:Boolean = true, out:Vector3D = null):Vector3D {
			return (M3D.getUp(((local) ? this.transform : this.world), out));
		}
		
		public function getDown(local:Boolean = true, out:Vector3D = null):Vector3D {
			return (M3D.getDown(((local) ? this.transform : this.world), out));
		}
		
		public function getDir(local:Boolean = true, out:Vector3D = null):Vector3D {
			return (M3D.getDir(((local) ? this.transform : this.world), out));
		}
		
		public function getBackward(local:Boolean = true, out:Vector3D = null):Vector3D {
			return (M3D.getBackward(((local) ? this.transform : this.world), out));
		}
		
		public function getForward(local:Boolean = true, out:Vector3D = null):Vector3D {
			return getDir(local, out);
		}
		
		public function localToGlobal(point:Vector3D, out:Vector3D = null):Vector3D {
			out = ((out) || (new Vector3D()));
			M3D.transformVector(this.world, point, out);
			return (out);
		}
		
		public function localToGlobalVector(vector:Vector3D, out:Vector3D = null):Vector3D {
			out = ((out) || (new Vector3D()));
			M3D.deltaTransformVector(this.world, vector, out);
			return (out);
		}
		
		public function globalToLocal(point:Vector3D, out:Vector3D = null):Vector3D {
			if (out == null) {
				out = new Vector3D();
			}
			M3D.transformVector(this.invWorld, point, out);
			return (out);
		}
		
		public function globalToLocalVector(vector:Vector3D, out:Vector3D = null):Vector3D {
			if (out == null) {
				out = new Vector3D();
			}
			M3D.deltaTransformVector(this.invWorld, vector, out);
			return (out);
		}
		
		public function getScreenCoords(out:Vector3D = null, camera:ZenCamera = null, viewPort:Rectangle = null):Vector3D {
			if (!(out)) {
				out = new Vector3D();
			}
			if (((!(viewPort)) && (!(this.scene)))) {
				
				throw new Error("The object isn't in the scene");
				
				return null;
			}
			if (!(camera)) {
				camera = ZenUtils.camera;
			}
			if (!(viewPort)) {
				viewPort = ZenUtils.scene.viewPort;
			}
			var t:Vector3D = camera.viewProjection.transformVector(this.getPosition(false, out));
			var w2:Number = (viewPort.width * 0.5);
			var h2:Number = (viewPort.height * 0.5);
			out.x = ((((t.x / t.w) * w2) + w2) + viewPort.x);
			out.y = ((((-(t.y) / t.w) * h2) + h2) + viewPort.y);
			out.z = t.z;
			out.w = t.w;
			return (out);
		}
		
		private static var GPSC_Point:Vector3D = new Vector3D();
		
		public function getPointScreenCoords(point:Vector3D, out:Vector3D = null, camera:ZenCamera = null):Vector3D {
			M3D.transformVector(this.world, point, GPSC_Point);
			return scene.getPointScreenCoords(GPSC_Point, out, camera);
		}
		
		/** Gets the bounds of this object and all children combined */
		public function getBounds(relativeTo:ZenObject = null, includeChildren:Boolean = true, out:Cube3D = null):Cube3D {
			return getBoundsInternal(this, out, relativeTo, includeChildren);
		}
		
		private function getBoundsInternal(pivot:ZenObject, out:Cube3D = null, relativeTo:ZenObject = null, includeChildren:Boolean = true):Cube3D {
			var dx:Number;
			var dy:Number;
			var dz:Number;
			if (!(out)) {
				out = new Cube3D();
			}
			out.min.setTo(10000000, 10000000, 10000000);
			out.max.setTo(-10000000, -10000000, -10000000);
			_bounds = false;
			growBounds(((relativeTo) || (pivot)), pivot, out, includeChildren);
			if (_bounds) {
				out.length.x = (out.max.x - out.min.x);
				out.length.y = (out.max.y - out.min.y);
				out.length.z = (out.max.z - out.min.z);
				out.center.x = ((out.length.x * 0.5) + out.min.x);
				out.center.y = ((out.length.y * 0.5) + out.min.y);
				out.center.z = ((out.length.z * 0.5) + out.min.z);
				dx = (out.max.x - out.center.x);
				dy = (out.max.y - out.center.y);
				dz = (out.max.z - out.center.z);
				out.radius = Math.sqrt((((dx * dx) + (dy * dy)) + (dz * dz)));
			} else {
				out.reset();
			}
			return (out);
		}
		
		private static function growBounds(parent:ZenObject, pivot:ZenObject, out:Cube3D, includeChildren:Boolean = true):void {
			var bounds:Cube3D;
			var x:Number;
			var y:Number;
			var z:Number;
			var child:ZenObject;
			_bounds = true;
			if ((pivot is ZenMesh)) {
				bounds = ZenMesh(pivot).bounds;
			} else {
				if ((pivot is ZenSpline)) {
					bounds = ZenSpline(pivot).bounds;
				}
			}
			if (bounds) {
				_transform.copyFrom(pivot.world);
				_transform.append(parent.invWorld);
				_transform.copyColumnTo(0, _mr);
				_transform.copyColumnTo(1, _mu);
				_transform.copyColumnTo(2, _md);
				_center.x = ((bounds.max.x + bounds.min.x) * 0.5);
				_center.y = ((bounds.max.y + bounds.min.y) * 0.5);
				_center.z = ((bounds.max.z + bounds.min.z) * 0.5);
				M3D.transformVector(_transform, _center, _center);
				_length.x = (bounds.length.x * 0.5);
				_length.y = (bounds.length.y * 0.5);
				_length.z = (bounds.length.z * 0.5);
				M3D.deltaTransformVector(_transform, _length, _length);
				_mr.scaleBy((_mr.dotProduct(_length) / _mr.dotProduct(_mr)));
				V3D.abs(_mr);
				_mu.scaleBy((_mu.dotProduct(_length) / _mu.dotProduct(_mu)));
				V3D.abs(_mu);
				_md.scaleBy((_md.dotProduct(_length) / _md.dotProduct(_md)));
				V3D.abs(_md);
				x = ((_mr.x + _mu.x) + _md.x);
				y = ((_mr.y + _mu.y) + _md.y);
				z = ((_mr.z + _mu.z) + _md.z);
				if ((x + _center.x) > out.max.x) {
					out.max.x = (x + _center.x);
				}
				if ((-(x) + _center.x) < out.min.x) {
					out.min.x = (-(x) + _center.x);
				}
				if ((y + _center.y) > out.max.y) {
					out.max.y = (y + _center.y);
				}
				if ((-(y) + _center.y) < out.min.y) {
					out.min.y = (-(y) + _center.y);
				}
				if ((z + _center.z) > out.max.z) {
					out.max.z = (z + _center.z);
				}
				if ((-(z) + _center.z) < out.min.z) {
					out.min.z = (-(z) + _center.z);
				}
			} else {
				_center = pivot.world.position;
				if (_center.x > out.max.x) {
					out.max.x = _center.x;
				}
				if (_center.x < out.min.x) {
					out.min.x = _center.x;
				}
				if (_center.y > out.max.y) {
					out.max.y = _center.y;
				}
				if (_center.y < out.min.y) {
					out.min.y = _center.y;
				}
				if (_center.z > out.max.z) {
					out.max.z = _center.z;
				}
				if (_center.z < out.min.z) {
					out.min.z = _center.z;
				}
			}
			if (includeChildren) {
				for each (child in pivot.children) {
					growBounds(parent, child, out, includeChildren);
				}
			}
		}
		
		private static var _tmp:Vector3D = new Vector3D();
		private static var _mr:Vector3D = new Vector3D();
		private static var _mu:Vector3D = new Vector3D();
		private static var _md:Vector3D = new Vector3D();
		private static var _center:Vector3D = new Vector3D();
		private static var _length:Vector3D = new Vector3D();
		private static var _transform:Matrix3D = new Matrix3D();
		private static var _bounds:Boolean;
		private static var _added:Dictionary;
		
		/**
		 * Returns information about an object and its properties at the Flash output.
		 * @param	pivot	Object to be tested.
		 * @param	includeMaterials	'true' if information about the materials is to be included.
		 * @param	includeChildren	'true' if all the hierarchy is to be included.
		 */
		public function traceInfo(includeMaterials:Boolean = false, includeChildren:Boolean = true):void {
			traceChild(this, 0, includeMaterials, includeChildren);
		}
		
		private function traceChild(pivot:ZenObject, level:int = 0, includeMaterials:Boolean = true, includeChildren:Boolean = true):void {
			var mesh:ZenMesh;
			var s:ZenFace;
			var c:ZenObject;
			var str:String = "";
			var i:int;
			while (i < level) {
				str = (str + "--");
				i++;
			}
			var extra:String = "";
			if (((pivot.frames) && ((pivot.frames.length > 0)))) {
				extra = (extra + (pivot.frames.length + " frames"));
			}
			trace(((((((str + "> ") + pivot.toString()) + " name: ") + pivot.name) + " ") + extra));
			if ((((pivot is ZenMesh)) && (includeMaterials))) {
				mesh = (pivot as ZenMesh);
				for each (s in mesh.surfaces) {
					trace(((("  " + str) + "> ") + s.material), ("name:" + s.material.name));
				}
			}
			if (includeChildren) {
				for each (c in pivot.children) {
					traceChild(c, (level + 1), includeMaterials, includeChildren);
				}
			}
		}
		
		/**
		 * Positions an object using another as reference.
		 * @param	pivot	Object to be positioned.
		 * @param	x	Reference object position on the X axis.
		 * @param	y	Reference object position on the Y axis.
		 * @param	z	Reference object position on the Z axis.
		 * @param	reference	Object to be used as reference.
		 * @param	smooth	Optional interpolation value towards final transformation (0-1).
		 */
		public function setPositionWithReference(x:Number, y:Number, z:Number, reference:ZenObject, smooth:Number = 1):void {
			_tmp.x = x;
			_tmp.y = y;
			_tmp.z = z;
			reference.localToGlobal(_tmp, _tmp);
			if (this.parent) {
				this.parent.globalToLocal(_tmp, _tmp);
			}
			this.setPosition(_tmp.x, _tmp.y, _tmp.z, smooth);
		}
		
		/**
		 * Points the object direction towards a given position using a reference object. The coordinates used correspond to the local space of the 'reference' parameter.
		 * @param	pivot	pivot Object to be oriented.
		 * @param	x	Reference object position on the x axis.
		 * @param	y	Reference object position on the Y axis.
		 * @param	z	Reference object position on the Z axis.
		 * @param	reference	Object to be used as referente for "x", "y" and "z" parameters.
		 * @param	up	Vector3D corresponding to the direction of the object upper side. If omitted, the default value (0, 1, 0) will be used.
		 * @param	smooth	Optional interpolation value towards final transformation (0-1).
		 */
		public function lookAtWithReference(x:Number, y:Number, z:Number, reference:ZenObject, up:Vector3D = null, smooth:Number = 1):void {
			_tmp.x = x;
			_tmp.y = y;
			_tmp.z = z;
			reference.localToGlobal(_tmp, _tmp);
			if (this.parent) {
				this.parent.globalToLocal(_tmp, _tmp);
			}
			this.lookAt(_tmp.x, _tmp.y, _tmp.z, up, smooth);
		}
		
		/**
		 * Returns the distance between two objects. This method uses the global space of the scene.
		 * @param	pivot1	First object to be tested.
		 * @param	pivot2	Second object to be tested.
		 * @return	Distance between the two objects.
		 */
		public function getDistanceBetween(pivot2:ZenObject):Number {
			return (Vector3D.distance(this.world.position, pivot2.world.position));
		}
		
		public function startDrag(lockCenter:Boolean = false, refPlaneNormal:Vector3D = null):void {
			var pos:Vector3D;
			var dir:Vector3D;
			if (!(this.scene)) {
				
				throw new Error("The object isn't in the scene");
				
				return;
			}
			if (_dragStartPos) {
				return;
			}
			if (((_dragTarget) && (!((_dragTarget == this))))) {
				_dragTarget.stopDrag();
			}
			_dragOffset = ((_dragOffset) || (new Vector3D()));
			_dragOffset.setTo(0, 0, 0);
			_dragStartDir = ((refPlaneNormal) || (ZenUtils.camera.getDir(false)));
			_dragStartPos = this.getPosition(false);
			_dragTarget = this;
			if (!(lockCenter)) {
				this.getPosition(false, _dragOffset);
				pos = new Vector3D();
				dir = new Vector3D();
				ZenUtils.camera.getPointDir(ZenInput.mouseX, ZenInput.mouseY, dir, pos);
				_dragOffset.decrementBy(this.rayPlanePosition(_dragStartDir, _dragStartPos, pos, dir));
			}
			this.scene.addEventListener(Zen3D.UPDATE_EVENT, this.updateDragEvent, false, 0, true);
		}
		
		private function rayPlanePosition(pNormal:Vector3D, pCenter:Vector3D, rFrom:Vector3D, rDir:Vector3D):Vector3D {
			var dist:Number = (-((pNormal.dotProduct(rFrom) - pNormal.dotProduct(pCenter))) / pNormal.dotProduct(rDir));
			return (new Vector3D((rFrom.x + (rDir.x * dist)), (rFrom.y + (rDir.y * dist)), (rFrom.z + (rDir.z * dist))));
		}
		
		private function updateDragEvent(e:Event):void {
			if (_dragTarget != this) {
				return;
			}
			dispatchEvent(new Event(ENTER_DRAG_EVENT));
			var cam:ZenCamera = ZenUtils.camera;
			var pos:Vector3D = new Vector3D();
			var dir:Vector3D = new Vector3D();
			ZenUtils.camera.getPointDir(ZenInput.mouseX, ZenInput.mouseY, dir, pos);
			var p:Vector3D = this.rayPlanePosition(_dragStartDir, _dragStartPos, pos, dir);
			this.setPosition((p.x + _dragOffset.x), (p.y + _dragOffset.y), (p.z + _dragOffset.z), 1, false);
			dispatchEvent(new Event(EXIT_DRAG_EVENT));
		}
		
		public function stopDrag():void {
			if (this.scene) {
				this.scene.removeEventListener(Zen3D.UPDATE_EVENT, this.updateDragEvent);
			}
			_dragStartPos = null;
			_dragStartDir = null;
			_dragTarget = null;
		}
		
		public function get world():Matrix3D {
			if (this.dirty) {
				this.transform.copyToMatrix3D(this._world);
				if (((this._parent) && (!((this._parent == this._scene))))) {
					this._world.append(this._parent.world);
				}
				this.dirty = false;
				this._dirtyInv = true;
			}
			return (this._world);
		}
		
		public function set world(value:Matrix3D):void {
			this.transform.copyFrom(value);
			if (this.parent) {
				this.transform.append(this.parent.invWorld);
			}
			this.updateTransforms(true);
		}
		
		public function get invWorld():Matrix3D {
			if (((this._dirtyInv) || (this.dirty))) {
				this._invGlobal.copyFrom(this.world);
				this._invGlobal.invert();
				this._dirtyInv = false;
			}
			return (this._invGlobal);
		}
		
		public function updateTransforms(includeChildren:Boolean = false):void {
			var l:int;
			var i:int;
			if (((!(this.dirty)) && ((this._eventFlags & ObjectFlags.UPDATE_TRANSFORM_FLAG)))) {
				dispatchEvent(_updateTransformEvent);
			}
			if (includeChildren) {
				l = this._children.length;
				i = 0;
				while (i < l) {
					this._children[i].updateTransforms(includeChildren);
					i++;
				}
			}
			this.dirty = true;
		}
		
		public function get children():Vector.<ZenObject> {
			return (this._children);
		}
		
		public function get parent():ZenObject {
			return (this._parent);
		}
		
		public function set parent(pivot:ZenObject):void {
			var index:int;
			if (pivot == this._parent) {
				return;
			}
			if (this._parent) {
				index = this._parent.children.indexOf(this);
				if (index != -1) {
					this._parent.children.splice(index, 1);
					this.dispatchEvent(new Event(REMOVED_EVENT));
				}
			}
			this._parent = pivot;
			if (pivot) {
				pivot.children.push(this);
				this.updateTransforms(true);
				if (this._collider) {
					this._collider.parent = pivot.collider;
				}
				this.dispatchEvent(new Event(ADDED_EVENT));
			}
			if (!(this._inScene)) {
				if (pivot) {
					if ((pivot is Zen3D)) {
						this.addedToScene((pivot as Zen3D));
					} else {
						if (pivot._inScene) {
							this.addedToScene(pivot.scene);
						}
					}
				}
			} else {
				if (!(pivot)) {
					this.removedFromScene();
				} else {
					if (((!((pivot is Zen3D))) && (!(pivot._inScene)))) {
						this.removedFromScene();
					}
				}
			}
		}
		
		protected function addedToScene(scene:Zen3D):void {
			this._scene = scene;
			this._scene.insertIntoScene(this, this._updatable, (this is IDrawable), (this._eventFlags >= 64), ((this.collider) ? true : false));
			this._inScene = true;
			dispatchEvent(new Event(ADDED_TO_SCENE_EVENT));
			var length:int = this._children.length;
			var i:int;
			while (i < length) {
				this._children[i].addedToScene(this._scene);
				i++;
			}
		}
		
		protected function removedFromScene():void {
			this._scene.removeFromScene(this, true, (this is IDrawable), true, ((this.collider) ? true : false));
			this._scene = null;
			this._inScene = false;
			dispatchEvent(new Event(REMOVED_FROM_SCENE_EVENT));
			var length:int = this._children.length;
			var i:int;
			while (i < length) {
				this._children[i].removedFromScene();
				i++;
			}
		}
		
		public function addChildAt(pivot:ZenObject, index:int, useGlobalSpace:Boolean = false):ZenObject {
			this.addChild(pivot, useGlobalSpace);
			this.children.splice(this.children.indexOf(pivot), 1);
			this.children.splice(index, 0, pivot);
			return (pivot);
		}
		
		public function addChild(pivot:ZenObject, useGlobalSpace:Boolean = false):ZenObject {
			if (pivot) {
				if (pivot.parent == this) {
					return (pivot);
				}
				if (!(useGlobalSpace)) {
					pivot.parent = this;
				} else {
					pivot.world.copyToMatrix3D(pivot.transform);
					M3D.invert(this.world, this._invGlobal);
					pivot.parent = this;
					pivot.transform.append(this._invGlobal);
					pivot.updateTransforms();
				}
			}
			return (pivot);
		}
		
		public function addChildren(objects:/*ZenObject*/Array, useGlobalSpace:Boolean = false):void {
			for each (var pivot:ZenObject in objects) {
				if (pivot) {
					addChild(pivot, useGlobalSpace);
				}
			}
		}
		
		public function removeChild(pivot:ZenObject):ZenObject {
			pivot.parent = null;
			return (pivot);
		}
		
		public function removeChildren(objects:/*ZenObject*/Array):void {
			for each (var pivot:ZenObject in objects) {
				if (pivot) {
					removeChild(pivot);
				}
			}
		}
		
		public function getChildByName(name:String, startIndex:int = 0, includeChildren:Boolean = true):ZenObject {
			var child:ZenObject;
			var length:int = this._children.length;
			var i:int;
			while (i < length) {
				if ((((this._children[i].name == name))/* && ((_temp1 < 0))*/)) {
					return (this._children[i]);
				}
				i++;
			}
			if (includeChildren) {
				i = 0;
				while (i < length) {
					child = this._children[i].getChildByName(name, startIndex, includeChildren);
					if (child) {
						return (child);
					}
					i++;
				}
			}
			return (null);
		}
		
		public function getChildrenByClass(cl:Class, includeChildren:Boolean = true, out:Vector.<ZenObject> = null):Vector.<ZenObject> {
			if (!(out)) {
				out = new Vector.<ZenObject>();
			}
			var length:int = this._children.length;
			var i:int;
			while (i < length) {
				if ((this._children[i] is cl)) {
					out.push(this._children[i]);
				}
				if (includeChildren) {
					this._children[i].getChildrenByClass(cl, includeChildren, out);
				}
				i++;
			}
			return (out);
		}
		
		public function addLabel(label:Label3D, includeChildren:Boolean = true):Label3D {
			var child:ZenObject;
			if (includeChildren) {
				for each (child in this._children) {
					child.addLabel(label, includeChildren);
				}
			}
			this.labels[label.name] = label;
			return (label);
		}
		
		public function removeLabel(label:Label3D, includeChildren:Boolean = true):Label3D {
			var child:ZenObject;
			if (includeChildren) {
				for each (child in this._children) {
					child.removeLabel(label, includeChildren);
				}
			}
			delete this.labels[label.name];
			return (label);
		}
		
		public function setAnimationSmooth(mode:int = 1, includeChildren:Boolean = true):void {
			var child:ZenObject;
			this.animationSmoothMode = mode;
			if (includeChildren) {
				for each (child in this._children) {
					child.setAnimationSmooth(mode, includeChildren);
				}
			}
		}
		
		public function get frameSpeed():Number {
			return (this._frameSpeed);
		}
		
		public function set frameSpeed(value:Number):void {
			var child:ZenObject;
			this._frameSpeed = value;
			for each (child in this.children) {
				child.frameSpeed = value;
			}
		}
		
		public function get isPlaying():Boolean {
			return (this._isPlaying);
		}
		
		public function gotoAndStop(frame:Object, blendFrames:Number = 0, includeChildren:Boolean = true):void {
			var length:int;
			var i:int;
			if (includeChildren) {
				length = this._children.length;
				i = 0;
				while (i < length) {
					this._children[i].gotoAndStop(frame, blendFrames, includeChildren);
					i++;
				}
			}
			if ((frame is Label3D)) {
				this.labels[frame.name] = frame;
				frame = frame.name;
			}
			if ((((frame is String)) && (!(this.labels[frame])))) {
				return;
			}
			if (blendFrames == 0) {
				this.stop();
				this.currentFrame = (((frame is String)) ? this.labels[frame].from : (frame as Number));
			} else {
				if (((!(this.frames)) || (!(this.scene)))) {
					return;
				}
				if ((((this is ZenMesh)) && ((ZenMesh(this).modifier is ZenSkinModifier)))) {
					ZenSkinModifier(ZenMesh(this).modifier).setBlendingState((this as ZenMesh));
				}
				if (!(this.lastBlendFrame)) {
					this.lastBlendFrame = new Matrix3D();
				}
				this.lastBlendFrame.copyFrom(this.transform);
				this.animationMode = AnimationType.STOP_MODE;
				this.blendValue = 0;
				this.updatable = true;
				if (!(this._currentLabel)) {
					this._from = 0;
					this._to = this.frames.length;
				}
				this._blendFrames = blendFrames;
				this.currentFrame = (((frame is String)) ? this.labels[frame].from : (frame as Number));
				this._isPlaying = false;
			}
		}
		
		public function gotoAndPlay(frame:Object, blendFrames:Number = 0, animationMode:int = 0, includeChildren:Boolean = true):void {
			var length:int;
			var i:int;
			if (includeChildren) {
				length = this._children.length;
				i = 0;
				while (i < length) {
					this._children[i].gotoAndPlay(frame, blendFrames, animationMode, includeChildren);
					i++;
				}
			}
			if ((((frame is String)) && (!(this.labels[frame])))) {
				return;
			}
			if (((!(this.frames)) || (!(this.scene)))) {
				return;
			}
			if ((frame is Label3D)) {
				this._frameSpeed = frame.frameSpeed;
				this.labels[frame.name] = frame;
				frame = frame.name;
			}
			if (blendFrames > 0) {
				if ((((this is ZenMesh)) && ((ZenMesh(this).modifier is ZenSkinModifier)))) {
					ZenSkinModifier(ZenMesh(this).modifier).setBlendingState((this as ZenMesh));
				}
				this.blendValue = 0;
				if (!(this.lastBlendFrame)) {
					this.lastBlendFrame = new Matrix3D();
				}
				this.lastBlendFrame.copyFrom(this.transform);
			} else {
				this.blendValue = 1;
			}
			this.updatable = true;
			this.animationMode = animationMode;
			this._blendFrames = blendFrames;
			if ((frame is String)) {
				this._currentLabel = this.labels[frame];
				if (!(this._currentLabel)) {
					
					throw new Error((("Label '" + frame) + "' not found."));
					
					return;
				}
				this._from = this._currentLabel.from;
				this._to = this._currentLabel.to;
				this.currentFrame = this._from;
			} else {
				this._currentLabel = null;
				this._from = 0;
				this._to = this.frames.length;
				this.currentFrame = (frame as Number);
			}
			this._isPlaying = true;
		}
		
		public function setAnimationLabel(label:Object, animationMode:int = 0, includeChildren:Boolean = true):void {
			var length:int;
			var i:int;
			if (includeChildren) {
				length = this._children.length;
				i = 0;
				while (i < length) {
					this._children[i].setAnimationLabel(label, animationMode);
					i++;
				}
			}
			if ((((label is String)) && (!(this.labels[label])))) {
				return;
			}
			this.animationMode = animationMode;
			if ((label is Label3D)) {
				this._frameSpeed = label.frameSpeed;
				this.labels[label.name] = label;
				label = label.name;
			}
			if ((label is String)) {
				this._currentLabel = this.labels[label];
				if (!(this._currentLabel)) {
					
					throw new Error((("Label '" + label) + "' not found."));
					
					return;
				}
				this._from = this._currentLabel.from;
				this._to = this._currentLabel.to;
				this.currentFrame = this._from;
			} else {
				this._currentLabel = null;
				this._from = 0;
				this._to = this.frames.length;
				this.currentFrame = (label as Number);
			}
		}
		
		public function get currentFrame():Number {
			return (this._currentFrame);
		}
		
		public function set currentFrame(frame:Number):void {
			var f:Frame3D;
			var i:int;
			var l:int;
			var t:int;
			if (((this.frames) && (this.frames.length))) {
				if (frame < 0) {
					frame = 0;
				}
				if (frame >= this.frames.length) {
					frame = (this.frames.length - 1);
				}
				this._currentFrame = frame;
				f = this.frames[int(this._currentFrame)];
				i = this._currentFrame;
				if ((((((this._frameSpeed >= 1)) && ((i == this._currentFrame)))) || ((this.animationSmoothMode == AnimationType.SMOOTH_NONE)))) {
					this.transform.copyFrom(f);
				} else {
					l = (this._to - this._from);
					t = ((i + 1) - this._from);
					if (this.animationMode == AnimationType.LOOP_MODE) {
						t = (t % l);
					} else {
						if (this.animationMode == AnimationType.STOP_MODE) {
							if (t >= l) {
								t = (l - 1);
							}
						}
					}
					this.transform.copyFrom(this.frames[i]);
					if (this.animationSmoothMode == AnimationType.SMOOTH_NORMAL) {
						this.transform.interpolateTo(this.frames[(t + this._from)], (this._currentFrame - i));
					} else {
						M3D.interpolateTo(this.transform, this.frames[(t + this._from)], (this._currentFrame - i));
					}
				}
				if (this.blendValue != 1) {
					if (this.animationSmoothMode == AnimationType.SMOOTH_NORMAL) {
						this.transform.interpolateTo(this.lastBlendFrame, (1 - this.blendValue));
					} else {
						M3D.interpolateTo(this.transform, this.lastBlendFrame, (1 - this.blendValue));
					}
				}
				if (((!((f.callback == null))) && (!((frame == this._lastFrame))))) {
					f.callback();
				}
				if (this._lastFrame != frame) {
					this.updateTransforms(true);
				}
				this._lastFrame = frame;
			}
		}
		
		public function addFrameScript(frame:int, callback:Function):void {
			if (((this.frames) && ((frame < this.frames.length)))) {
				this.frames[frame] = (this.frames[frame].clone() as Frame3D);
				this.frames[frame].callback = callback;
			}
		}
		
		public function play(animationMode:int = 0, includeChildren:Boolean = true, resetAnimation:Boolean = true):void {
			var length:int;
			var i:int;
			if (includeChildren) {
				length = this._children.length;
				i = 0;
				while (i < length) {
					this._children[i].play(animationMode, includeChildren, resetAnimation);
					i++;
				}
			}
			if (((!(this.frames)) || (!(this.scene)))) {
				return;
			}
			this.updatable = true;
			this.animationMode = animationMode;
			if (resetAnimation) {
				this._from = 0;
				this._to = this.frames.length;
				this._currentLabel = null;
			}
			this._isPlaying = true;
		}
		
		public function stop(includeChildren:Boolean = true):void {
			var length:int;
			var i:int;
			if (includeChildren) {
				length = this._children.length;
				i = 0;
				while (i < length) {
					this._children[i].stop(includeChildren);
					i++;
				}
			}
			this._isPlaying = false;
		}
		
		public function prevFrame():void {
			if (this._frameSpeed > 0) {
				this.nextFrame();
				return;
			}
			this._currentFrame = (this._currentFrame + this._frameSpeed);
			var animComplete:Boolean;
			if (this._currentFrame < this._from) {
				if (this.animationMode == AnimationType.LOOP_MODE) {
					if ((this._eventFlags & ObjectFlags.ANIMATION_COMPLETE_FLAG)) {
						animComplete = true;
					}
					this._currentFrame = (this._currentFrame + (this._to - this._from));
				} else {
					if (this.animationMode == AnimationType.STOP_MODE) {
						if ((this._eventFlags & ObjectFlags.ANIMATION_COMPLETE_FLAG)) {
							animComplete = true;
						}
						this._currentFrame = this._from;
						this.stop();
					} else {
						if ((this._eventFlags & ObjectFlags.ANIMATION_COMPLETE_FLAG)) {
							animComplete = true;
						}
						this._currentFrame = (this._currentFrame - this._frameSpeed);
						this._frameSpeed = -(this._frameSpeed);
					}
				}
			}
			this.currentFrame = this._currentFrame;
			if (animComplete) {
				setTimeout(dispatchEvent, 1, _animationCompleteEvent);
			}
		}
		
		public function nextFrame():void {
			if (this._frameSpeed < 0) {
				this.prevFrame();
				return;
			}
			this._currentFrame = (this._currentFrame + this._frameSpeed);
			var animComplete:Boolean;
			if (this._currentFrame >= this._to) {
				if (this.animationMode == AnimationType.LOOP_MODE) {
					if ((this._eventFlags & ObjectFlags.ANIMATION_COMPLETE_FLAG)) {
						animComplete = true;
					}
					this._currentFrame = (this._currentFrame - (this._to - this._from));
				} else {
					if (this.animationMode == AnimationType.STOP_MODE) {
						if ((this._eventFlags & ObjectFlags.ANIMATION_COMPLETE_FLAG)) {
							animComplete = true;
						}
						this._currentFrame = this._to;
						this.stop();
					} else {
						if ((this._eventFlags & ObjectFlags.ANIMATION_COMPLETE_FLAG)) {
							animComplete = true;
						}
						this._currentFrame = (this._currentFrame - this._frameSpeed);
						this._frameSpeed = -(this._frameSpeed);
					}
				}
			}
			this.currentFrame = this._currentFrame;
			if (animComplete) {
				setTimeout(dispatchEvent, 1, _animationCompleteEvent);
			}
		}
		
		public function update():void {
			if ((this._eventFlags & ObjectFlags.ENTER_FRAME_FLAG)) {
				dispatchEvent(_enterFrameEvent);
			}
			if (this._isPlaying) {
				if (this._blendFrames > 0) {
					this.blendValue = (this.blendValue + (1 / this._blendFrames));
					if (this.blendValue >= 1) {
						this._blendFrames = 0;
						this.blendValue = 1;
					}
				}
				this.nextFrame();
			} else {
				if (this._blendFrames > 0) {
					this.blendValue = (this.blendValue + (1 / this._blendFrames));
					if (this.blendValue >= 1) {
						this._blendFrames = 0;
						this.blendValue = 1;
						this.stop();
					}
					if (((this.frames) && (this.frames.length))) {
						M3D.interpolateTo(this.transform, this.frames[int(this._currentFrame)], this.blendValue);
						this.updateTransforms(true);
					}
				}
			}
			if ((this._eventFlags & ObjectFlags.EXIT_FRAME_FLAG)) {
				dispatchEvent(_exitFrameEvent);
			}
		}
		
		public function show():void {
			this.visible = true;
			var length:int = this._children.length;
			var i:int;
			while (i < length) {
				this._children[i].show();
				i++;
			}
		}
		
		public function hide():void {
			this.visible = false;
			var length:int = this._children.length;
			var i:int;
			while (i < length) {
				this._children[i].hide();
				i++;
			}
		}
		
		public function get scene():Zen3D {
			return (this._scene);
		}
		
		public function setMaterial(material:ShaderMaterialBase, includeChildren:Boolean = true):void {
			var length:int;
			var i:int;
			if (includeChildren) {
				length = this._children.length;
				i = 0;
				while (i < length) {
					this._children[i].setMaterial(material, includeChildren);
					i++;
				}
			}
		}
		
		public function setShadowsProperties(cast:Boolean = false, receive:Boolean = false, includeChildren:Boolean = true):void {
			var length:int;
			var i:int;
			this.castShadows = cast;
			this.receiveShadows = receive;
			if (includeChildren) {
				length = this._children.length;
				i = 0;
				while (i < length) {
					this._children[i].setShadowsProperties(cast, receive, includeChildren);
					i++;
				}
			}
		}
		
		public function draw(includeChildren:Boolean = true, material:ShaderMaterialBase = null):void {
			var length:int;
			var i:int;
			if ((this._eventFlags & ObjectFlags.ENTER_DRAW_FLAG)) {
				dispatchEvent(_enterDrawEvent);
			}
			if (includeChildren) {
				length = this._children.length;
				i = 0;
				while (i < length) {
					this._children[i].draw(includeChildren, material);
					i++;
				}
			}
			if ((this._eventFlags & ObjectFlags.EXIT_DRAW_FLAG)) {
				dispatchEvent(_exitDrawEvent);
			}
		}
		
		public function get sortMode():int {
			return (this._sortMode);
		}
		
		public function set sortMode(value:int):void {
			this._sortMode = value;
		}
		
		public function get inView():Boolean {
			return (true);
		}
		
		public function setLayer(value:int, includeChildren:Boolean = true):void {
			var length:int;
			var i:int;
			if (((this.scene) && (!((value == this.layer))))) {
				this.scene.removeFromScene(this, false, (this is IDrawable), false);
				this.layer = value;
				this.scene.insertIntoScene(this, false, (this is IDrawable), false);
			} else {
				this.layer = value;
			}
			if (includeChildren) {
				length = this._children.length;
				i = 0;
				while (i < length) {
					this._children[i].setLayer(value, includeChildren);
					i++;
				}
			}
		}
		
		public function forEach(callback:Function, filterClass:Class = null, params:Object = null, includeChildren:Boolean = true):void {
			var c:ZenObject;
			for each (c in this._children) {
				if (!(filterClass)) {
					if (params) {
						(callback(c, params));
					} else {
						(callback(c));
					}
				} else {
					if ((c is filterClass)) {
						if (params) {
							(callback(c, params));
						} else {
							(callback(c));
						}
					}
				}
				if (includeChildren) {
					c.forEach(callback, filterClass, params, includeChildren);
				}
			}
		}
		
		public function getMaterials(includeChildren:Boolean = true, out:Vector.<ShaderMaterialBase> = null):Vector.<ShaderMaterialBase> {
			var length:int;
			var i:int;
			if (!(out)) {
				out = new Vector.<ShaderMaterialBase>();
			}
			if (includeChildren) {
				length = this._children.length;
				i = 0;
				while (i < length) {
					out = this._children[i].getMaterials(includeChildren, out);
					i++;
				}
			}
			return (out);
		}
		
		public function getTextures(includeChildren:Boolean = true, out:Vector.<ZenTexture> = null):Vector.<ZenTexture> {
			var length:int;
			var i:int;
			if (!(out)) {
				out = new Vector.<ZenTexture>();
			}
			if (includeChildren) {
				length = this._children.length;
				i = 0;
				while (i < length) {
					out = this._children[i].getTextures(includeChildren, out);
					i++;
				}
			}
			return (out);
		}
		
		public function getMaterialByName(name:String, includeChildren:Boolean = true):ShaderMaterialBase {
			var material:ShaderMaterialBase;
			if (!(includeChildren)) {
				return (null);
			}
			var length:int = this._children.length;
			var i:int;
			while (i < length) {
				material = this._children[i].getMaterialByName(name, includeChildren);
				if (material) {
					return (material);
				}
				i++;
			}
			return (null);
		}
		
		public function replaceMaterial(source:ShaderMaterialBase, replaceFor:ShaderMaterialBase, includeChildren:Boolean = true):void {
			var length:int;
			var i:int;
			if (source == replaceFor) {
				
				throw new Error("Source and replaceFor parameters are the same instances!");
				
				return;
			}
			if (includeChildren) {
				length = this._children.length;
				i = 0;
				while (i < length) {
					this._children[i].replaceMaterial(source, replaceFor, includeChildren);
					i++;
				}
			}
		}
		
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {
			var prevFlags:uint = this._eventFlags;
			switch (type) {
			case ENTER_FRAME_EVENT: 
				this._eventFlags = (this._eventFlags | ObjectFlags.ENTER_FRAME_FLAG);
				break;
			case EXIT_FRAME_EVENT: 
				this._eventFlags = (this._eventFlags | ObjectFlags.EXIT_FRAME_FLAG);
				break;
			case ENTER_DRAW_EVENT: 
				this._eventFlags = (this._eventFlags | ObjectFlags.ENTER_DRAW_FLAG);
				break;
			case EXIT_DRAW_EVENT: 
				this._eventFlags = (this._eventFlags | ObjectFlags.EXIT_DRAW_FLAG);
				break;
			case UPDATE_TRANSFORM_EVENT: 
				this._eventFlags = (this._eventFlags | ObjectFlags.UPDATE_TRANSFORM_FLAG);
				break;
			case ANIMATION_COMPLETE_EVENT: 
				this._eventFlags = (this._eventFlags | ObjectFlags.ANIMATION_COMPLETE_FLAG);
				break;
			}
			if ((this._eventFlags & 3)) {
				this.updatable = true;
			}
			super.addEventListener(type, listener, useCapture, priority, useWeakReference);
		}
		
		override public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {
			super.removeEventListener(type, listener, useCapture);
			switch (type) {
			case ENTER_FRAME_EVENT: 
				if (!(hasEventListener(type))) {
					this._eventFlags = (this._eventFlags | ObjectFlags.ENTER_FRAME_FLAG);
					this._eventFlags = (this._eventFlags - ObjectFlags.ENTER_FRAME_FLAG);
				}
				break;
			case EXIT_FRAME_EVENT: 
				if (!(hasEventListener(type))) {
					this._eventFlags = (this._eventFlags | ObjectFlags.EXIT_FRAME_FLAG);
					this._eventFlags = (this._eventFlags - ObjectFlags.EXIT_FRAME_FLAG);
				}
				break;
			case ENTER_DRAW_EVENT: 
				if (!(hasEventListener(type))) {
					this._eventFlags = (this._eventFlags | ObjectFlags.ENTER_DRAW_FLAG);
					this._eventFlags = (this._eventFlags - ObjectFlags.ENTER_DRAW_FLAG);
				}
				break;
			case EXIT_DRAW_EVENT: 
				if (!(hasEventListener(type))) {
					this._eventFlags = (this._eventFlags | ObjectFlags.EXIT_DRAW_FLAG);
					this._eventFlags = (this._eventFlags - ObjectFlags.EXIT_DRAW_FLAG);
				}
				break;
			case UPDATE_TRANSFORM_EVENT: 
				if (!(hasEventListener(type))) {
					this._eventFlags = (this._eventFlags | ObjectFlags.UPDATE_TRANSFORM_FLAG);
					this._eventFlags = (this._eventFlags - ObjectFlags.UPDATE_TRANSFORM_FLAG);
				}
				break;
			case ANIMATION_COMPLETE_EVENT: 
				if (!(hasEventListener(type))) {
					this._eventFlags = (this._eventFlags | ObjectFlags.ANIMATION_COMPLETE_FLAG);
					this._eventFlags = (this._eventFlags - ObjectFlags.ANIMATION_COMPLETE_FLAG);
				}
				break;
			}
		}
		
		public function get updatable():Boolean {
			return (this._updatable);
		}
		
		public function set updatable(value:Boolean):void {
			if (((this._lock) || ((value == this._updatable)))) {
				return;
			}
			this._updatable = value;
			if (this.scene) {
				this.scene.insertIntoScene(this, true, false, false);
			}
		}
		
		public function get lock():Boolean {
			return (this._lock);
		}
		
		public function set lock(value:Boolean):void {
			if (value != this._lock) {
				if (this.scene) {
					this.scene.removeFromScene(this, true, true, true);
				}
			}
			this._lock = value;
		}
		
		public function get currentLabel():Label3D {
			return (this._currentLabel);
		}
		
		public function get collider():Collider {
			return (this._collider);
		}
		
		public function set collider(value:Collider):void {
			var parent:ZenObject;
			var p:ZenObject;
			if (value == this._collider) {
				return;
			}
			if (this._collider) {
				this._scene.removeFromScene(this, false, false, false, true);
			}
			this._collider = value;
			if (value) {
				if (this._scene) {
					this._scene.insertIntoScene(this, false, false, false, true);
				}
			}
			if (this._collider) {
				this._collider.pivot = this;
				parent = this._parent;
				while (parent) {
					if (parent.collider) {
						this._collider.parent = parent.collider;
						break;
					}
					parent = parent.parent;
				}
				for each (p in this._children) {
					p.setParentCollider(this._collider);
				}
			}
		}
		
		private function setParentCollider(parent:Collider):void {
			var c:ZenObject;
			if (this._collider) {
				this._collider.parent = parent;
			}
			for each (c in this._children) {
				c.setParentCollider(parent);
			}
		}
		
		public function get transformData():Array {
			var pos:Vector3D = getPosition();
			var rot:Vector3D = getRotation();
			return [pos.x, pos.y, pos.z, rot.x, rot.y, rot.z];
		}
		
		public function set transformData(value:Array):void {
			setPosition(value[0], value[1], value[2]);
			setRotation(value[3], value[4], value[5]);
		}
		
		/** gets the local position of the object within the parent */
		public function get position():Vector3D {
			return getPosition();
		}
		
		/** sets the local position of the object within the parent */
		public function set position(value:Vector3D):void {
			setPosition(value.x, value.y, value.z);
		}
		
		/** gets the global position of the object (regardless of the heirarchy) */
		public function get globalPosition():Vector3D {
			return getPosition(false);
		}
		
		/** sets the global position of the object (regardless of the heirarchy) */
		public function set globalPosition(value:Vector3D):void {
			setPosition(value.x, value.y, value.z, 1, false);
		}
		
		/** gets the local rotation of the object within the parent */
		public function get rotation():Vector3D {
			return getRotation();
		}
		
		/** sets the local rotation of the object within the parent */
		public function set rotation(value:Vector3D):void {
			setRotation(value.x, value.y, value.z);
		}
		
		/** gets the global position of the object (regardless of the heirarchy) */
		public function get globalRotation():Vector3D {
			return getRotation(false);
		}
		
		/** gets the local scale of the object within the parent */
		public function get scale():Vector3D {
			return getScale();
		}
		
		/** gets the global scale of the object (regardless of the heirarchy) */
		public function get globalScale():Vector3D {
			return getScale(false);
		}
		
		/** sets the local scale of the object within the parent */
		public function set scale(value:Vector3D):void {
			setScale(value.x, value.y, value.z);
		}
		
		/**
		 * This method replaces all pivot dest animations and labels by the source ones using pivot names.
		 * Allowing to keep multiple object aniamtions synchronized and avoiding the need to append the animations for each one.
		 * @param	source	The source pivot from where the animations will be taken.
		 */
		public function setAnimations(source:ZenObject):void {
			var p:ZenObject;
			var pivot:ZenObject;
			if (this.name == source.name) {
				this.frames = source.frames;
				this.labels = source.labels;
			}
			for each (p in this.children) {
				pivot = source.getChildByName(p.name, 0, false);
				if (pivot) {
					p.setAnimations(pivot);
				}
			}
		}
		
		/**
		 * Removes all pivot animations and its labels.
		 * @param	includeChildren	'true' if all the hierarchy is to be included.
		 */
		public function removeAnimations(includeChildren:Boolean = true):void {
			var mesh:ZenMesh;
			var skin:ZenSkinModifier;
			var p:ZenObject;
			this.frames = null;
			this.labels = {};
			if ((this is ZenMesh)) {
				mesh = (this as ZenMesh);
				if ((mesh.modifier is ZenSkinModifier)) {
					skin = (mesh.modifier as ZenSkinModifier);
					skin.root.removeAnimations(includeChildren);
				}
			}
			if (includeChildren) {
				for each (p in this.children) {
					p.removeAnimations(includeChildren);
				}
			}
		}
		
		/**
		 * Add animation frames and labels to source pivot from another pivot, including children.
		 * The pivot names and hierarchy must be the same.
		 * @param	animation	The pivot that contains the animations to add to dest pivot.
		 * @param	label	Optionally, you can set a new label name to define the appened animation.
		 * @param	includeMaterials	If materials has animated parameters, they will be append.
		 */
		public function appendAnimation(animation:ZenObject, label:String = null, includeMaterials:Boolean = false):void {
			var label3D:Label3D;
			var from:int = getAnimationLength(this);
			var length:int = getAnimationLength(animation);
			if (label) {
				label3D = new Label3D(label, from, ((from + length) - 1));
			}
			_added = new Dictionary(true);
			appendAnimationAux(this, animation, label3D, from, length, includeMaterials);
			normalizeFrames(this, (from + length));
			this.play();
			_added = null;
		}
		
		private static function normalizeFrames(source:ZenObject, length:int):void {
			var p:ZenObject;
			if ((((source is ZenMesh)) && ((ZenMesh(source).modifier is ZenSkinModifier)))) {
				normalizeSkinFrames(ZenSkinModifier(ZenMesh(source).modifier).root, length);
			}
			for each (p in source.children) {
				normalizeFrames(p, length);
			}
		}
		
		private static function normalizeSkinFrames(source:ZenObject, length:int):void {
			var p:ZenObject;
			if (!(source.frames)) {
				source.frames = Vector.<Frame3D>([new Frame3D(source.transform.rawData)]);
			}
			if (source.frames.length < length) {
				while (source.frames.length < length) {
					source.frames.push(source.frames[0]);
				}
			}
			for each (p in source.children) {
				normalizeSkinFrames(p, length);
			}
		}
		
		private static function appendAnimationAux(dest:ZenObject, animation:ZenObject, label:Label3D, from:int, length:int, includeMaterials:Boolean = false):void {
			var p:ZenObject;
			var lb:*;
			var l:Label3D;
			var pivot:ZenObject = getChildByNameAux(animation, dest.name);
			if (((pivot) && (pivot.frames))) {
				if (!(dest.frames)) {
					dest.frames = new Vector.<Frame3D>();
				}
				if (!(_added[dest])) {
					_added[dest] = 1;
					dest.frames = dest.frames.concat(pivot.frames);
				}
				if (pivot.labels) {
					for (lb in pivot.labels) {
						l = pivot.labels[lb];
						dest.addLabel(new Label3D(l.name, (l.from + from), (l.to + from)));
					}
				}
			}
			if (label) {
				dest.addLabel(label, false);
			}
			if ((dest is ZenMesh)) {
				if ((ZenMesh(dest).modifier is ZenSkinModifier)) {
					if (!(dest.frames)) {
						dest.frames = new Vector.<Frame3D>();
					}
					if (dest.frames.length == 0) {
						dest.frames[0] = new Frame3D(dest.transform.rawData);
					}
					while (dest.frames.length <= ((from + length) - 1)) {
						dest.frames.push(dest.frames[0]);
					}
					ZenSkinModifier(ZenMesh(dest).modifier).totalFrames = dest.frames.length;
					appendAnimationAux(ZenSkinModifier(ZenMesh(dest).modifier).root, animation, label, from, length, includeMaterials);
				}
			}
			for each (p in dest.children) {
				appendAnimationAux(p, animation, label, from, length, includeMaterials);
			}
		}
		
		private static function getAnimationLength(animation:ZenObject, length:int = 0):int {
			var c:ZenObject;
			var l:int;
			if (((animation.frames) && ((animation.frames.length > length)))) {
				length = animation.frames.length;
			}
			for each (c in animation.children) {
				l = getAnimationLength(c, length);
				if (l > length) {
					length = l;
				}
			}
			return (length);
		}
		
		private static function getChildByNameAux(source:ZenObject, name:String):ZenObject {
			var c:ZenObject;
			var child:ZenObject;
			if (source.name == name) {
				return (source);
			}
			if ((((source is ZenMesh)) && ((ZenMesh(source).modifier is ZenSkinModifier)))) {
				child = getChildByNameAux(ZenSkinModifier(ZenMesh(source).modifier).root, name);
				if (child) {
					return (child);
				}
			}
			for each (c in source.children) {
				child = getChildByNameAux(c, name);
				if (child) {
					return (child);
				}
			}
			return (null);
		}
	
	}
}

