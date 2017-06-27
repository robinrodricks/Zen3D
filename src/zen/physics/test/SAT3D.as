package zen.physics.test {
	import zen.geom.physics.*;
	import zen.physics.core.*;
	import zen.physics.test.*;
	import zen.physics.*;
	import zen.physics.colliders.*;
	import zen.physics.geom.*;
	import zen.utils.*;
	import zen.geom.physics.*;
	import zen.geom.*;
	import flash.geom.*;
	
	public class SAT3D {
		
		// ALL CONSTANT VALUE
		private static var EPSILON:Number = 0.0001;
		private static var infoA:AxisInfo = new AxisInfo();
		private static var infoB:AxisInfo = new AxisInfo();
		private static var pointsA:Vector.<Vector3D> = new Vector.<Vector3D>(16, true);
		private static var pointsB:Vector.<Vector3D> = new Vector.<Vector3D>(16, true);
		private static var invAxis:Vector3D = new Vector3D();
		private static var vec:Vector3D = new Vector3D();
		public static var axis:Vector3D = new Vector3D();
		private static var edge0:Vector3D = new Vector3D();
		private static var edge1:Vector3D = new Vector3D();
		private static var refPlane:Vector3D = new Vector3D();
		private static var clipPlane:Vector3D = new Vector3D();
		private static var pool:Vector.<Vector3D> = new Vector.<Vector3D>(16, true);
		
		// VALUES MAY CHANGE
		private static var points:Vector.<Vector3D> = new Vector.<Vector3D>(16, true);
		private static var numPoints:int;
		public static var collider0:IShape;
		public static var collider1:IShape;
		public static var depth:Number;
		public static var flags:uint;
		public static var swap:Boolean;
		private static var sat:SAT3D = new (SAT3D)();
		private static var poolCount:int;
		
		public function SAT3D() {
			var i:int;
			while (i < 16) {
				points[i] = new Vector3D();
				pointsA[i] = new Vector3D();
				pointsB[i] = new Vector3D();
				i++;
			}
		}
		
		public static function init(a:IShape, b:IShape):void {
			collider0 = a;
			collider1 = b;
			depth = 1000000;
			axis.x = 0;
			axis.y = 0;
			axis.z = 0;
			flags = 0;
			swap = false;
		}
		
		public static function test(testAxis:Vector3D, testFlags:uint = 0):Boolean {
			var len:Number = (((testAxis.x * testAxis.x) + (testAxis.y * testAxis.y)) + (testAxis.z * testAxis.z));
			if (len < EPSILON) {
				return (false);
			}
			if ((((len < 0.99)) || ((len > 1.01)))) {
				len = (1 / Math.sqrt(len));
				vec.x = (testAxis.x * len);
				vec.y = (testAxis.y * len);
				vec.z = (testAxis.z * len);
				testAxis = vec;
			}
			collider0.project(testAxis, infoA);
			collider1.project(testAxis, infoB);
			var m:Number = ((infoA.max - infoA.min) * 0.5);
			var s:Number = ((infoA.min + infoA.max) * 0.5);
			infoB.min = (infoB.min - m);
			infoB.max = (infoB.max + m);
			var dmin:Number = (infoB.min - s);
			var dmax:Number = (infoB.max - s);
			if ((((dmin > 0)) || ((dmax < 0)))) {
				return (true);
			}
			if (dmin < 0) {
				dmin = -(dmin);
			}
			if (dmax < dmin) {
				if (dmax < (depth - EPSILON)) {
					depth = dmax;
					axis.x = testAxis.x;
					axis.y = testAxis.y;
					axis.z = testAxis.z;
					flags = testFlags;
				}
			} else {
				if (dmin < (depth - EPSILON)) {
					depth = dmin;
					axis.x = -(testAxis.x);
					axis.y = -(testAxis.y);
					axis.z = -(testAxis.z);
					flags = testFlags;
				}
			}
			return (false);
		}
		
		public static function generateContacts(contacs:Vector.<Contact>, numContacts:int, c0:Collider = null, c1:Collider = null, transform:Matrix3D = null, normal:Vector3D = null):int {
			var countA:int;
			var countB:int;
			var p:int;
			var c:Contact;
			invAxis.x = -(axis.x);
			invAxis.y = -(axis.y);
			invAxis.z = -(axis.z);
			if (transform) {
				M3D.deltaTransformVector(transform, axis, axis);
				countA = collider0.getSupportPoints(axis, pointsA);
				countB = collider1.getSupportPoints(invAxis, pointsB);
				p = 0;
				while (p < countB) {
					M3D.transformVector(transform, pointsB[p], pointsB[p]);
					p++;
				}
			} else {
				countA = collider0.getSupportPoints(axis, pointsA);
				countB = collider1.getSupportPoints(invAxis, pointsB);
			}
			if ((((countA == 0)) || ((countB == 0)))) {
				return (numContacts);
			}
			if ((((((axis.x == 0)) && ((axis.y == 0)))) && ((axis.z == 0)))) {
				return (numContacts);
			}
			if (countA < countB) {
				contactsFaceFace(pointsA, countA, pointsB, countB);
			} else {
				contactsFaceFace(pointsB, countB, pointsA, countA);
			}
			var i:int;
			while (i < numPoints) {
				contacs[numContacts] = ((contacs[numContacts]) || (new Contact()));
				c = contacs[numContacts++];
				c.normalX = axis.x;
				c.normalY = axis.y;
				c.normalZ = axis.z;
				c.depth = depth;
				c.overlap = -(points[i].w);
				c.posX = points[i].x;
				c.posY = points[i].y;
				c.posZ = points[i].z;
				c.collider0 = ((c0) || ((collider0 as Collider)));
				c.collider1 = ((c1) || ((collider1 as Collider)));
				c.tri = (collider1 as Tri3D);
				c.edge = null;
				i++;
			}
			return (numContacts);
		}
		
		private static function contactsFaceFace(pointsA:Vector.<Vector3D>, countA:int, pointsB:Vector.<Vector3D>, countB:int):void {
			var i2:int;
			var b0:Vector3D;
			var b1:Vector3D;
			var j:int;
			var temp:Vector.<Vector3D>;
			var j2:int;
			var a0:Vector3D;
			var a1:Vector3D;
			var d0:Number;
			var d1:Number;
			var c:Vector3D;
			var t:Number;
			var p:Vector3D;
			poolCount = 0;
			edge0.x = (pointsB[2].x - pointsB[0].x);
			edge0.y = (pointsB[2].y - pointsB[0].y);
			edge0.z = (pointsB[2].z - pointsB[0].z);
			edge1.x = (pointsB[1].x - pointsB[0].x);
			edge1.y = (pointsB[1].y - pointsB[0].y);
			edge1.z = (pointsB[1].z - pointsB[0].z);
			cross(refPlane, edge1, edge0);
			refPlane.normalize();
			refPlane.w = -((((refPlane.x * pointsB[0].x) + (refPlane.y * pointsB[0].y)) + (refPlane.z * pointsB[0].z)));
			var i:int;
			while (i < countB) {
				i2 = ((i + 1) % countB);
				b0 = pointsB[i];
				b1 = pointsB[i2];
				edge0.x = (b0.x - b1.x);
				edge0.y = (b0.y - b1.y);
				edge0.z = (b0.z - b1.z);
				cross(clipPlane, refPlane, edge0);
				clipPlane.normalize();
				clipPlane.w = -((((clipPlane.x * b0.x) + (clipPlane.y * b0.y)) + (clipPlane.z * b0.z)));
				numPoints = 0;
				j = 0;
				while (j < countA) {
					j2 = ((j + 1) % countA);
					a0 = pointsA[j];
					a1 = pointsA[j2];
					d0 = ((((a0.x * clipPlane.x) + (a0.y * clipPlane.y)) + (a0.z * clipPlane.z)) + clipPlane.w);
					d1 = ((((a1.x * clipPlane.x) + (a1.y * clipPlane.y)) + (a1.z * clipPlane.z)) + clipPlane.w);
					if (d0 <= 0) {
						a0.w = d0;
						var _local19 = numPoints++;
						points[_local19] = a0;
					}
					if ((d0 * d1) < 0) {
						pool[poolCount] = ((pool[poolCount]) || (new Vector3D()));
						c = pool[poolCount++];
						t = (d0 / (d0 - d1));
						c.x = (a0.x + ((a1.x - a0.x) * t));
						c.y = (a0.y + ((a1.y - a0.y) * t));
						c.z = (a0.z + ((a1.z - a0.z) * t));
						c.w = t;
						_local19 = numPoints++;
						points[_local19] = c;
					}
					j++;
				}
				countA = numPoints;
				temp = points;
				points = pointsA;
				pointsA = temp;
				i++;
			}
			numPoints = 0;
			i = 0;
			while (i < countA) {
				p = pointsA[i];
				p.w = ((((p.x * refPlane.x) + (p.y * refPlane.y)) + (p.z * refPlane.z)) + refPlane.w);
				if (p.w > -(EPSILON)) {
				} else {
					_local19 = numPoints++;
					points[_local19] = p;
				}
				i++;
			}
		}
		
		private static function cross(out:Vector3D, a:Vector3D, b:Vector3D):void {
			out.x = ((a.y * b.z) - (a.z * b.y));
			out.y = ((a.z * b.x) - (a.x * b.z));
			out.z = ((a.x * b.y) - (a.y * b.x));
		}
	
	}
}

