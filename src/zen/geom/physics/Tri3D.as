package zen.geom.physics {
	import flash.geom.*;
	import zen.physics.test.*;
	import zen.shaders.textures.*;
	import zen.physics.core.*;
	import zen.physics.*;
	
	/** Stores information about triangles during physics collision detection. */
	public class Tri3D implements IShape {
		
		private static const c:Vector3D = new Vector3D();
		private static const v:Vector3D = new Vector3D();
		private static const Rab:Vector3D = new Vector3D();
		private static const Rbc:Vector3D = new Vector3D();
		private static const Rca:Vector3D = new Vector3D();
		
		private static var closetDistance:Number;
		
		public var n:Vector3D;
		public var e0:TriEdge3D;
		public var e1:TriEdge3D;
		public var e2:TriEdge3D;
		public var v0:LinkedVector3D;
		public var v1:LinkedVector3D;
		public var v2:LinkedVector3D;
		public var material:ShaderMaterialBase;
		public var ref:uint;
		var _axis:Number;
		var _tu1:Number;
		var _tv1:Number;
		var _tu2:Number;
		var _tv2:Number;
		var _tu0:Number;
		var _tv0:Number;
		var _alpha:Number;
		var _beta:Number;
		
		public function Tri3D(v0:LinkedVector3D, v1:LinkedVector3D, v2:LinkedVector3D) {
			this.v0 = v0;
			this.v1 = v1;
			this.v2 = v2;
			this.e0 = new TriEdge3D(v0, v1);
			this.e1 = new TriEdge3D(v1, v2);
			this.e2 = new TriEdge3D(v2, v0);
			this.e0.tri = this;
			this.e1.tri = this;
			this.e2.tri = this;
			this.n = this.e1.crossProduct(this.e2);
			this.n.normalize();
			this.n.w = -((((this.n.x * v0.x) + (this.n.y * v0.y)) + (this.n.z * v0.z)));
			var nx:Number = (((this.n.x > 0)) ? this.n.x : -(this.n.x));
			var ny:Number = (((this.n.y > 0)) ? this.n.y : -(this.n.y));
			var nz:Number = (((this.n.z > 0)) ? this.n.z : -(this.n.z));
			var max:Number = (((nx > ny)) ? (((nx > nz)) ? nx : nz) : (((ny > nz)) ? ny : nz));
			if (nx == max) {
				this._tu1 = (v1.y - v0.y);
				this._tv1 = (v1.z - v0.z);
				this._tu2 = (v2.y - v0.y);
				this._tv2 = (v2.z - v0.z);
				this._axis = 0;
			} else {
				if (ny == max) {
					this._tu1 = (v1.x - v0.x);
					this._tv1 = (v1.z - v0.z);
					this._tu2 = (v2.x - v0.x);
					this._tv2 = (v2.z - v0.z);
					this._axis = 1;
				} else {
					this._tu1 = (v1.x - v0.x);
					this._tv1 = (v1.y - v0.y);
					this._tu2 = (v2.x - v0.x);
					this._tv2 = (v2.y - v0.y);
					this._axis = 2;
				}
			}
		}
		
		[Inline]
		final public function isPoint(x:Number, y:Number, z:Number):Boolean {
			if (this._axis == 0) {
				this._tu0 = (y - this.v0.y);
				this._tv0 = (z - this.v0.z);
			} else {
				if (this._axis == 1) {
					this._tu0 = (x - this.v0.x);
					this._tv0 = (z - this.v0.z);
				} else {
					this._tu0 = (x - this.v0.x);
					this._tv0 = (y - this.v0.y);
				}
			}
			if (this._tu1 != 0) {
				this._beta = (((this._tv0 * this._tu1) - (this._tu0 * this._tv1)) / ((this._tv2 * this._tu1) - (this._tu2 * this._tv1)));
				if ((((this._beta >= 0)) && ((this._beta <= 1)))) {
					this._alpha = ((this._tu0 - (this._beta * this._tu2)) / this._tu1);
				}
			} else {
				this._beta = (this._tu0 / this._tu2);
				if ((((this._beta >= 0)) && ((this._beta <= 1)))) {
					this._alpha = ((this._tv0 - (this._beta * this._tv2)) / this._tv1);
				}
			}
			if ((((((this._alpha >= 0)) && ((this._beta >= 0)))) && (((this._alpha + this._beta) <= 1)))) {
				return (true);
			}
			return (false);
		}
		
		final private function closetPointOnEdge(a:Vector3D, b:Vector3D, p:Vector3D, out:Vector3D):void {
			c.x = (p.x - a.x);
			c.y = (p.y - a.y);
			c.z = (p.z - a.z);
			v.x = (b.x - a.x);
			v.y = (b.y - a.y);
			v.z = (b.z - a.z);
			var d:Number = (((v.x * v.x) + (v.y * v.y)) + (v.z * v.z));
			var t:Number = (((v.x * c.x) + (v.y * c.y)) + (v.z * c.z));
			if (t < 0) {
				out.x = a.x;
				out.y = a.y;
				out.z = a.z;
				return;
			}
			if (t > d) {
				out.x = b.x;
				out.y = b.y;
				out.z = b.z;
				return;
			}
			t = (t / d);
			out.x = (a.x + (v.x * t));
			out.y = (a.y + (v.y * t));
			out.z = (a.z + (v.z * t));
		}
		
		[Inline]
		final public function closetPoint(p:Vector3D, out:Vector3D):TriEdge3D {
			var edge:TriEdge3D;
			var t:Number;
			var d:Number;
			var dx:Number;
			var dy:Number;
			var dz:Number;
			c.x = (p.x - this.v0.x);
			c.y = (p.y - this.v0.y);
			c.z = (p.z - this.v0.z);
			v.x = (this.v1.x - this.v0.x);
			v.y = (this.v1.y - this.v0.y);
			v.z = (this.v1.z - this.v0.z);
			d = (((v.x * v.x) + (v.y * v.y)) + (v.z * v.z));
			t = (((v.x * c.x) + (v.y * c.y)) + (v.z * c.z));
			if (t < 0) {
				Rab.x = this.v0.x;
				Rab.y = this.v0.y;
				Rab.z = this.v0.z;
			} else {
				if (t > d) {
					Rab.x = this.v1.x;
					Rab.y = this.v1.y;
					Rab.z = this.v1.z;
				} else {
					t = (t / d);
					Rab.x = (this.v0.x + (v.x * t));
					Rab.y = (this.v0.y + (v.y * t));
					Rab.z = (this.v0.z + (v.z * t));
				}
			}
			c.x = (p.x - this.v1.x);
			c.y = (p.y - this.v1.y);
			c.z = (p.z - this.v1.z);
			v.x = (this.v2.x - this.v1.x);
			v.y = (this.v2.y - this.v1.y);
			v.z = (this.v2.z - this.v1.z);
			d = (((v.x * v.x) + (v.y * v.y)) + (v.z * v.z));
			t = (((v.x * c.x) + (v.y * c.y)) + (v.z * c.z));
			if (t < 0) {
				Rbc.x = this.v1.x;
				Rbc.y = this.v1.y;
				Rbc.z = this.v1.z;
			} else {
				if (t > d) {
					Rbc.x = this.v2.x;
					Rbc.y = this.v2.y;
					Rbc.z = this.v2.z;
				} else {
					t = (t / d);
					Rbc.x = (this.v1.x + (v.x * t));
					Rbc.y = (this.v1.y + (v.y * t));
					Rbc.z = (this.v1.z + (v.z * t));
				}
			}
			c.x = (p.x - this.v2.x);
			c.y = (p.y - this.v2.y);
			c.z = (p.z - this.v2.z);
			v.x = (this.v0.x - this.v2.x);
			v.y = (this.v0.y - this.v2.y);
			v.z = (this.v0.z - this.v2.z);
			d = (((v.x * v.x) + (v.y * v.y)) + (v.z * v.z));
			t = (((v.x * c.x) + (v.y * c.y)) + (v.z * c.z));
			if (t < 0) {
				Rca.x = this.v2.x;
				Rca.y = this.v2.y;
				Rca.z = this.v2.z;
			} else {
				if (t > d) {
					Rca.x = this.v0.x;
					Rca.y = this.v0.y;
					Rca.z = this.v0.z;
				} else {
					t = (t / d);
					Rca.x = (this.v2.x + (v.x * t));
					Rca.y = (this.v2.y + (v.y * t));
					Rca.z = (this.v2.z + (v.z * t));
				}
			}
			dx = (p.x - Rab.x);
			dy = (p.y - Rab.y);
			dz = (p.z - Rab.z);
			var dAB:Number = (((dx * dx) + (dy * dy)) + (dz * dz));
			dx = (p.x - Rbc.x);
			dy = (p.y - Rbc.y);
			dz = (p.z - Rbc.z);
			var dBC:Number = (((dx * dx) + (dy * dy)) + (dz * dz));
			dx = (p.x - Rca.x);
			dy = (p.y - Rca.y);
			dz = (p.z - Rca.z);
			var dCA:Number = (((dx * dx) + (dy * dy)) + (dz * dz));
			closetDistance = dAB;
			out.x = Rab.x;
			out.y = Rab.y;
			out.z = Rab.z;
			edge = this.e0;
			if (dBC <= closetDistance) {
				closetDistance = dBC;
				out.x = Rbc.x;
				out.y = Rbc.y;
				out.z = Rbc.z;
				edge = this.e1;
			}
			if (dCA < closetDistance) {
				closetDistance = dCA;
				out.x = Rca.x;
				out.y = Rca.y;
				out.z = Rca.z;
				edge = this.e2;
			}
			return (edge);
		}
		
		final public function project(axis:Vector3D, info:AxisInfo):void {
			var x:Number;
			var y:Number;
			var z:Number;
			x = axis.x;
			y = axis.y;
			z = axis.z;
			var dot0:Number = (((this.v0.x * x) + (this.v0.y * y)) + (this.v0.z * z));
			var dot1:Number = (((this.v1.x * x) + (this.v1.y * y)) + (this.v1.z * z));
			var dot2:Number = (((this.v2.x * x) + (this.v2.y * y)) + (this.v2.z * z));
			info.min = (((((dot0 < dot1)) && ((dot0 < dot2)))) ? dot0 : (((dot1 < dot2)) ? dot1 : dot2));
			info.max = (((((dot0 > dot1)) && ((dot0 > dot2)))) ? dot0 : (((dot1 > dot2)) ? dot1 : dot2));
		}
		
		final public function getSupportPoints(axis:Vector3D, out:Vector.<Vector3D>):int {
			var x:Number = axis.x;
			var y:Number = axis.y;
			var z:Number = axis.z;
			var min0:Number = (((x * this.v0.x) + (y * this.v0.y)) + (z * this.v0.z));
			var min1:Number = (((x * this.v1.x) + (y * this.v1.y)) + (z * this.v1.z));
			var min2:Number = (((x * this.v2.x) + (y * this.v2.y)) + (z * this.v2.z));
			var min:Number = (((((min0 < min1)) && ((min0 < min2)))) ? min0 : (((min1 < min2)) ? min1 : min2));
			Rab.copyFrom(this.v0);
			Rbc.copyFrom(this.v1);
			Rca.copyFrom(this.v2);
			min = (min + 0.001);
			var count:int;
			if (min0 <= min) {
				var _local11 = count++;
				out[_local11] = Rab;
			}
			if (min1 <= min) {
				_local11 = count++;
				out[_local11] = Rbc;
			}
			if (min2 <= min) {
				_local11 = count++;
				out[_local11] = Rca;
			}
			return (count);
		}
	
	}
}

