package zen.geom.intersects {
	import flash.geom.Vector3D;
	import flash.geom.Matrix3D;
	import zen.display.*;
	import flash.events.Event;
	import flash.utils.getTimer;
	import flash.geom.*;
	import zen.display.*;
	import zen.utils.*;
	import zen.geom.*;
	import zen.display.*;
	import zen.display.*;
	import flash.events.*;
	import flash.utils.*;
	
	public class SphereIntersect {
		
		private static const EPSILON:Number = 0.001;
		
		private static var _dir:Vector3D = new Vector3D();
		private static var _center:Vector3D = new Vector3D();
		private static var _iDir:Vector3D = new Vector3D();
		private static var _normal:Vector3D = new Vector3D();
		private static var _f:Vector3D = new Vector3D();
		private static var _o:Vector3D = new Vector3D();
		private static var _sIPoint:Vector3D = new Vector3D();
		private static var _pIPoint:Vector3D = new Vector3D();
		private static var _dist0:Number;
		private static var _dist1:Number;
		private static var _dist2:Number;
		private static var _length:Number;
		private static var _global:Matrix3D = new Matrix3D();
		private static var _planeOrigin:Vector3D = new Vector3D();
		private static var _planeNormal:Vector3D = new Vector3D();
		private static var _planeD:Number = 0;
		private static var _posOut:Vector3D = new Vector3D();
		private static var collisionDistance:Number;
		private static var collisionMesh:ZenMesh;
		private static var collisionPoly:Poly3D;
		private static var sphereIntersectionPoint:Vector3D = new Vector3D();
		private static var polyIntersectionPoint:Vector3D = new Vector3D();
		private static var _q:Vector3D = new Vector3D();
		
		private var _src:ZenObject;
		private var _radius:Number;
		private var _old:Vector3D;
		private var _safe:Vector3D;
		private var _mesh:Vector.<ZenMesh>;
		private var _pos:Vector3D;
		private var _offset:Vector3D;
		private var _inv:Matrix3D;
		private var _collided:Boolean;
		private var _collisionTime:int;
		public var data:Vector.<Intersection3D>;
		private var pull:Vector.<Intersection3D>;
		
		public function SphereIntersect(source:ZenObject, radius:Number = 1, offset:Vector3D = null) {
			this._mesh = new Vector.<ZenMesh>();
			this._pos = new Vector3D();
			this._offset = new Vector3D();
			this._inv = new Matrix3D();
			this.data = new Vector.<Intersection3D>();
			this.pull = new Vector.<Intersection3D>();
			super();
			this._src = source;
			this._radius = radius;
			this._old = source.getPosition();
			this._safe = source.getPosition();
			if (offset) {
				this._offset = offset;
			}
		}
		
		private static function raySphere(rO:Vector3D, rV:Vector3D, sO:Vector3D, sR:Number):Number {
			_q.x = (rO.x - sO.x);
			_q.y = (rO.y - sO.y);
			_q.z = (rO.z - sO.z);
			var _B:Number = _q.dotProduct(rV);
			var _C:Number = (_q.dotProduct(_q) - (sR * sR));
			var _D:Number = ((_B * _B) - _C);
			return ((((_D > 0)) ? (-(_B) - Math.sqrt(_D)) : Number.NaN));
		}
		
		public function toString():String {
			return ("[object SphereIntersect]");
		}
		
		public function addCollisionWith(pivot:ZenObject, includeChildren:Boolean = true):void {
			var mesh:ZenMesh;
			var s:ZenFace;
			var c:ZenObject;
			if ((pivot is ZenMesh)) {
				if (pivot != this._src) {
					mesh = (pivot as ZenMesh);
					if (this._mesh.indexOf(mesh) == -1) {
						for each (s in mesh.surfaces) {
							s.buildPolys();
						}
						this._mesh.push(mesh);
					}
				}
			}
			if (includeChildren) {
				for each (c in pivot.children) {
					this.addCollisionWith(c, includeChildren);
				}
			}
		}
		
		private function unloadEvent(e:Event):void {
			this.removeCollisionWith((e.target as ZenObject), false);
		}
		
		public function removeCollisionWith(pivot:ZenObject, includeChildren:Boolean = true):void {
			var mesh:ZenMesh;
			var index:int;
			var c:ZenObject;
			if ((pivot is ZenMesh)) {
				mesh = (pivot as ZenMesh);
				index = this._mesh.indexOf(mesh);
				if (index != -1) {
					this._mesh.splice(index, 1);
				}
			}
			if (includeChildren) {
				for each (c in pivot.children) {
					this.removeCollisionWith(c, includeChildren);
				}
			}
		}
		
		public function reset():void {
			this._old.x = this._src.x;
			this._old.y = this._src.y;
			this._old.z = this._src.z;
			this._safe.copyFrom(this._old);
		}
		
		public function fixed():Boolean {
			this._collisionTime = getTimer();
			this._src.setTranslation(this._offset.x, this._offset.y, this._offset.z);
			while (this.data.length) {
				this.pull.push(this.data.pop());
			}
			this.updateFixed();
			if (this._collided) {
				V3D.sub(this._old, sphereIntersectionPoint, _normal);
				_normal.normalize();
				this._src.x = (polyIntersectionPoint.x + (_normal.x * (this._radius + EPSILON)));
				this._src.y = (polyIntersectionPoint.y + (_normal.y * (this._radius + EPSILON)));
				this._src.z = (polyIntersectionPoint.z + (_normal.z * (this._radius + EPSILON)));
				this.addInfo(collisionMesh, collisionPoly, polyIntersectionPoint, _normal);
			}
			this._old.x = this._src.x;
			this._old.y = this._src.y;
			this._old.z = this._src.z;
			this._collisionTime = (getTimer() - this._collisionTime);
			this._src.setTranslation(-(this._offset.x), -(this._offset.y), -(this._offset.z));
			return (this._collided);
		}
		
		public function intersect():Boolean {
			this._collisionTime = getTimer();
			this._src.setTranslation(this._offset.x, this._offset.y, this._offset.z);
			while (this.data.length) {
				this.pull.push(this.data.pop());
			}
			this.updateFixed();
			if (this._collided) {
				V3D.sub(this._old, sphereIntersectionPoint, _normal);
				_normal.normalize();
				this.addInfo(collisionMesh, collisionPoly, polyIntersectionPoint, _normal);
			}
			this._old.x = this._src.x;
			this._old.y = this._src.y;
			this._old.z = this._src.z;
			this._collisionTime = (getTimer() - this._collisionTime);
			this._src.setTranslation(-(this._offset.x), -(this._offset.y), -(this._offset.z));
			return (this._collided);
		}
		
		public function slider(precision:int = 2):Boolean {
			var i:Intersection3D;
			var from:Vector3D;
			this._collisionTime = getTimer();
			this._src.setTranslation(this._offset.x, this._offset.y, this._offset.z);
			if (precision < 2) {
				precision = 2;
			}
			var b:Boolean;
			while (this.data.length) {
				this.pull.push(this.data.pop());
			}
			do {
				this.updateSlider();
				if (this._collided) {
					b = true;
					this._pos.x = this._src.x;
					this._pos.y = this._src.y;
					this._pos.z = this._src.z;
					V3D.sub(this._pos, sphereIntersectionPoint, _normal);
					_normal.normalize();
					_planeOrigin = polyIntersectionPoint;
					_planeNormal = _normal;
					_planeD = -(_planeNormal.dotProduct(_planeOrigin));
					from = this._src.getPosition();
					_dist0 = (((-(((((_planeNormal.x * from.x) + (_planeNormal.y * from.y)) + (_planeNormal.z * from.z)) + _planeD)) / (((_planeNormal.x * _normal.x) + (_planeNormal.y * _normal.y)) + (_planeNormal.z * _normal.z))) + this._radius) + EPSILON);
					this._src.x = (this._src.x + (_normal.x * _dist0));
					this._src.y = (this._src.y + (_normal.y * _dist0));
					this._src.z = (this._src.z + (_normal.z * _dist0));
					i = this.addInfo(collisionMesh, collisionPoly, polyIntersectionPoint, _normal);
				}
				--precision;
			} while ((((precision >= 0)) && (this._collided)));
			this._old.x = this._src.x;
			this._old.y = this._src.y;
			this._old.z = this._src.z;
			if (!(this._collided)) {
				this._safe.copyFrom(this._old);
			} else {
				this._src.setPosition(this._safe.x, this._safe.y, this._safe.z);
			}
			this._collisionTime = (getTimer() - this._collisionTime);
			this._src.setTranslation(-(this._offset.x), -(this._offset.y), -(this._offset.z));
			this._collided = b;
			return (this._collided);
		}
		
		private function updateFixed():void {
			var mesh:ZenMesh;
			var bounds:Cube3D;
			var s:ZenFace;
			var polys:Vector.<Poly3D>;
			var length:int;
			var pn:int;
			var p:Poly3D;
			this._collided = false;
			collisionDistance = Number.MAX_VALUE;
			for each (mesh in this._mesh) {
				_global = mesh.world;
				this._inv = mesh.invWorld;
				M3D.transformVector(this._inv, this._old, _o);
				M3D.transformVector(this._inv, this._src.getPosition(), _f);
				V3D.sub(_f, _o, _dir);
				_length = _dir.length;
				_dir.normalize();
				_iDir.copyFrom(_dir);
				_iDir.negate();
				bounds = mesh.bounds;
				if (bounds) {
					_center.x = ((_o.x + _f.x) * 0.5);
					_center.y = ((_o.y + _f.y) * 0.5);
					_center.z = ((_o.z + _f.z) * 0.5);
					if (Vector3D.distance(_center, bounds.center) > (((_length / 2) + this._radius) + bounds.radius)) {
						//unresolved jump
					}
				}
				for each (s in mesh.surfaces) {
					_center.x = ((_o.x + _f.x) * 0.5);
					_center.y = ((_o.y + _f.y) * 0.5);
					_center.z = ((_o.z + _f.z) * 0.5);
					if (Vector3D.distance(_center, s.bounds.center) > (((_length / 2) + this._radius) + s.bounds.radius)) {
					} else {
						polys = s.polys;
						length = s.numTriangles;
						if (length == -1) {
							length = polys.length;
						}
						pn = (s.firstIndex / 3);
						while (pn < length) {
							p = polys[pn];
							_dist1 = ((((p.normal.x * _o.x) + (p.normal.y * _o.y)) + (p.normal.z * _o.z)) + p.plane);
							_dist2 = ((((p.normal.x * _f.x) + (p.normal.y * _f.y)) + (p.normal.z * _f.z)) + p.plane);
							if ((((_dist1 > 0)) && ((_dist2 < this._radius)))) {
								_sIPoint.x = (_o.x - (p.normal.x * this._radius));
								_sIPoint.y = (_o.y - (p.normal.y * this._radius));
								_sIPoint.z = (_o.z - (p.normal.z * this._radius));
								_dist0 = (-(((((p.normal.x * _sIPoint.x) + (p.normal.y * _sIPoint.y)) + (p.normal.z * _sIPoint.z)) + p.plane)) / (((p.normal.x * _dir.x) + (p.normal.y * _dir.y)) + (p.normal.z * _dir.z)));
								_pIPoint.x = (_sIPoint.x + (_dir.x * _dist0));
								_pIPoint.y = (_sIPoint.y + (_dir.y * _dist0));
								_pIPoint.z = (_sIPoint.z + (_dir.z * _dist0));
								if (!(p.isPoint(_pIPoint.x, _pIPoint.y, _pIPoint.z))) {
									p.closetPoint(_pIPoint, _pIPoint);
									_dist0 = raySphere(_pIPoint, _iDir, _o, this._radius);
									if (_dist0 > 0) {
										_sIPoint.x = (_pIPoint.x + (_iDir.x * _dist0));
										_sIPoint.y = (_pIPoint.y + (_iDir.y * _dist0));
										_sIPoint.z = (_pIPoint.z + (_iDir.z * _dist0));
									}
								}
								if ((((((_dist0 < collisionDistance)) && ((_dist0 >= 0)))) && ((_dist0 < _length)))) {
									M3D.transformVector(_global, _sIPoint, sphereIntersectionPoint);
									M3D.transformVector(_global, _pIPoint, polyIntersectionPoint);
									this._collided = true;
									collisionDistance = _dist0;
									collisionPoly = p;
									collisionMesh = mesh;
								}
							}
							pn++;
						}
					}
				}
			}
		}
		
		private function updateSlider():void {
			var d:Number;
			var dx:Number;
			var dy:Number;
			var dz:Number;
			var mesh:ZenMesh;
			var bounds:Cube3D;
			var s:ZenFace;
			var polys:Vector.<Poly3D>;
			var length:int;
			var pn:int;
			var p:Poly3D;
			this._collided = false;
			collisionDistance = Number.MAX_VALUE;
			for each (mesh in this._mesh) {
				_global = mesh.world;
				this._inv = mesh.invWorld;
				M3D.transformVector(this._inv, this._old, _o);
				M3D.transformVector(this._inv, this._src.getPosition(true, _posOut), _f);
				V3D.sub(_f, _o, _dir);
				_length = _dir.length;
				bounds = mesh.bounds;
				if (bounds) {
					_center.x = ((_o.x + _f.x) * 0.5);
					_center.y = ((_o.y + _f.y) * 0.5);
					_center.z = ((_o.z + _f.z) * 0.5);
					if (V3D.length(_center, bounds.center) > (((_length / 2) + this._radius) + bounds.radius)) {
						//unresolved jump
					}
				}
				for each (s in mesh.surfaces) {
					_center.x = ((_o.x + _f.x) * 0.5);
					_center.y = ((_o.y + _f.y) * 0.5);
					_center.z = ((_o.z + _f.z) * 0.5);
					if (V3D.length(_center, s.bounds.center) > (((_length / 2) + this._radius) + s.bounds.radius)) {
					} else {
						polys = s.polys;
						length = s.numTriangles;
						if (length == -1) {
							length = polys.length;
						}
						length = (length + (s.firstIndex / 3));
						pn = (s.firstIndex / 3);
						for (; pn < length; pn++) {
							p = polys[pn];
							_dist0 = (-(((((p.normal.x * _f.x) + (p.normal.y * _f.y)) + (p.normal.z * _f.z)) + p.plane)) + this._radius);
							if ((((_dist0 < (_length + this._radius))) && ((_dist0 > 0)))) {
								d = (_dist0 - this._radius);
								_pIPoint.x = (_f.x + (p.normal.x * d));
								_pIPoint.y = (_f.y + (p.normal.y * d));
								_pIPoint.z = (_f.z + (p.normal.z * d));
								if (!(p.isPoint(_pIPoint.x, _pIPoint.y, _pIPoint.z))) {
									p.closetPoint(_pIPoint, _pIPoint);
									dx = (_f.x - _pIPoint.x);
									dy = (_f.y - _pIPoint.y);
									dz = (_f.z - _pIPoint.z);
									if ((((dx * dx) + (dy * dy)) + (dz * dz)) > (this._radius * this._radius)) {
										continue;
									}
									_dir.x = (_f.x - _pIPoint.x);
									_dir.y = (_f.y - _pIPoint.y);
									_dir.z = (_f.z - _pIPoint.z);
									_dir.normalize();
									_sIPoint.x = (_f.x - (_dir.x * this._radius));
									_sIPoint.y = (_f.y - (_dir.y * this._radius));
									_sIPoint.z = (_f.z - (_dir.z * this._radius));
									_dist0 = Vector3D.distance(_sIPoint, _pIPoint);
								} else {
									_sIPoint.x = (_f.x - (p.normal.x * this._radius));
									_sIPoint.y = (_f.y - (p.normal.y * this._radius));
									_sIPoint.z = (_f.z - (p.normal.z * this._radius));
								}
								if ((this._radius - _dist0) < collisionDistance) {
									M3D.transformVector(_global, _sIPoint, sphereIntersectionPoint);
									M3D.transformVector(_global, _pIPoint, polyIntersectionPoint);
									this._collided = true;
									collisionDistance = (this._radius - _dist0);
									collisionPoly = p;
									collisionMesh = mesh;
								}
							}
						}
					}
				}
			}
		}
		
		private function addInfo(mesh:ZenMesh, poly:Poly3D, point:Vector3D, normal:Vector3D):Intersection3D {
			var i:Intersection3D = ((this.pull.length) ? this.pull.pop() : new Intersection3D());
			i.mesh = mesh;
			i.poly = poly;
			i.point.copyFrom(point);
			i.normal.copyFrom(normal);
			i.u = poly.getPointU();
			i.v = poly.getPointV();
			this.data.push(i);
			return (i);
		}
		
		public function get offset():Vector3D {
			return (this._offset);
		}
		
		public function set offset(value:Vector3D):void {
			this._offset = value;
			this.reset();
		}
		
		public function get collided():Boolean {
			return (this._collided);
		}
		
		public function get collisionTime():int {
			return (this._collisionTime);
		}
		
		public function get collisionCount():int {
			return (this._mesh.length);
		}
		
		public function get radius():Number {
			return (this._radius);
		}
		
		public function set radius(value:Number):void {
			this._radius = value;
		}
		
		public function get source():ZenObject {
			return (this._src);
		}
	
	}
}

