package zen.geom {
	import flash.geom.Vector3D;
	
	import flash.geom.*;
	import zen.utils.*;
	import zen.geom.*;
	
	/** A 3D B-spline consisting of multiple knots (SplineKnot3D) */
	public class Spline3D {
		
		private static var _dir:Vector3D = new Vector3D();
		private static var _pos:Vector3D = new Vector3D();
		
		public var knots:Vector.<SplineKnot3D>;
		private var _closed:Boolean = false;
		private var _count:int;
		
		public function Spline3D() {
			this.knots = new Vector.<SplineKnot3D>();
			super();
		}
		
		public function toString():String {
			return ("[object Spline3D]");
		}
		
		public function clone():Spline3D {
			var k:SplineKnot3D;
			var n:Spline3D = new Spline3D();
			for each (k in this.knots) {
				n.knots.push((k.clone() as SplineKnot3D));
			}
			n.closed = this.closed;
			return (n);
		}
		
		public function getPoint(value:Number, out:Vector3D = null):Vector3D {
			if (value < 0) {
				value = 0;
			} else {
				if (value > 1) {
					value = 1;
				}
			}
			out = ((out) || (new Vector3D()));
			var ratio:Number = (1 / this._count);
			var index:Number = Math.floor((value / ratio));
			var k0:SplineKnot3D = this.knots[index];
			var k1:SplineKnot3D = ((((index + 1) < this.knots.length)) ? this.knots[(index + 1)] : this.knots[0]);
			this.getSegmentPoint(k0, k1, ((value / ratio) - index), out);
			return (out);
		}
		
		private function getSegmentPoint(k0:SplineKnot3D, k1:SplineKnot3D, value:Number, out:Vector3D = null):void {
			var a:Number;
			var b:Number;
			var c:Number;
			var d:Number;
			var e:Number;
			d = (value * value);
			a = (1 - value);
			e = (a * a);
			b = (e * a);
			c = (d * value);
			out.x = ((((b * k0.x) + (((3 * value) * e) * k0.outVec.x)) + (((3 * d) * a) * k1.inVec.x)) + (c * k1.x));
			out.y = ((((b * k0.y) + (((3 * value) * e) * k0.outVec.y)) + (((3 * d) * a) * k1.inVec.y)) + (c * k1.y));
			out.z = ((((b * k0.z) + (((3 * value) * e) * k0.outVec.z)) + (((3 * d) * a) * k1.inVec.z)) + (c * k1.z));
		}
		
		public function getTangent(value:Number, out:Vector3D = null):Vector3D {
			if (value < 0) {
				value = 0;
			} else {
				if (value > 1) {
					value = 1;
				}
			}
			out = ((out) || (new Vector3D()));
			var ratio:Number = (1 / this._count);
			var index:Number = Math.floor((value / ratio));
			var k0:SplineKnot3D = this.knots[index];
			var k1:SplineKnot3D = ((((index + 1) < this.knots.length)) ? this.knots[(index + 1)] : this.knots[0]);
			this.getSetgmentTangent(k0, k1, ((value / ratio) - index), out);
			return (out);
		}
		
		private function getSetgmentTangent(k0:SplineKnot3D, k1:SplineKnot3D, value:Number, out:Vector3D):void {
			if (value < 0) {
				value = 0;
			} else {
				if (value > 1) {
					value = 1;
				}
			}
			this.getSegmentPoint(k0, k1, value, _pos);
			this.getSegmentPoint(k0, k1, (value - 0.001), _dir);
			V3D.sub(_pos, _dir, out);
			out.normalize();
		}
		
		public function get closed():Boolean {
			return (this._closed);
		}
		
		public function set closed(value:Boolean):void {
			this._closed = value;
			if (value) {
				this._count = this.knots.length;
			} else {
				this._count = (this.knots.length - 1);
			}
		}
	
	}
}

