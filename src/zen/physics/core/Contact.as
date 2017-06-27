package zen.physics.core {
	
	import zen.geom.*;
	import zen.physics.colliders.*;
	import zen.physics.geom.*;
	import zen.geom.physics.*;
	import zen.physics.*;
	import zen.utils.*;
	import flash.geom.*;
	
	public class Contact {
		
		private static var it0:Vector.<Number> = new Vector.<Number>(16, true);
		private static var it1:Vector.<Number> = new Vector.<Number>(16, true);
		
		public var collider0:Collider;
		public var collider1:Collider;
		public var parent0:Collider;
		public var parent1:Collider;
		public var posX:Number;
		public var posY:Number;
		public var posZ:Number;
		public var normalX:Number;
		public var normalY:Number;
		public var normalZ:Number;
		public var overlap:Number;
		public var depth:Number;
		public var tri:Tri3D;
		public var edge:TriEdge3D;
		private var friction:Number;
		private var restitution:Number;
		private var invMass:Number;
		private var invMass0:Number;
		private var invMass1:Number;
		private var rvn:Number;
		private var relVelX:Number;
		private var relVelY:Number;
		private var relVelZ:Number;
		private var tanX:Number;
		private var tanY:Number;
		private var tanZ:Number;
		private var r0x:Number;
		private var r0y:Number;
		private var r0z:Number;
		private var r1x:Number;
		private var r1y:Number;
		private var r1z:Number;
		private var rn0x:Number;
		private var rn0y:Number;
		private var rn0z:Number;
		private var rn1x:Number;
		private var rn1y:Number;
		private var rn1z:Number;
		private var rt0x:Number;
		private var rt0y:Number;
		private var rt0z:Number;
		private var rt1x:Number;
		private var rt1y:Number;
		private var rt1z:Number;
		private var rnI0x:Number;
		private var rnI0y:Number;
		private var rnI0z:Number;
		private var rnI1x:Number;
		private var rnI1y:Number;
		private var rnI1z:Number;
		private var rtI0x:Number;
		private var rtI0y:Number;
		private var rtI0z:Number;
		private var rtI1x:Number;
		private var rtI1y:Number;
		private var rtI1z:Number;
		private var v1:Vector3D;
		private var v0:Vector3D;
		private var a0:Vector3D;
		private var a1:Vector3D;
		private var d0:Vector3D;
		private var d1:Vector3D;
		private var normalImp:Number;
		private var tangentImp:Number;
		private var isRB0:Boolean;
		private var isRB1:Boolean;
		
		final public function preSolve():void {
			var tx:Number;
			var ty:Number;
			var tz:Number;
			this.parent0 = ((this.collider1.parent) || (this.collider1));
			this.parent1 = ((this.collider0.parent) || (this.collider0));
			if (((this.parent0.isTrigger) || (this.parent1.isTrigger))) {
				return;
			}
			this.isRB0 = this.parent0.isRigidBody;
			this.isRB1 = this.parent1.isRigidBody;
			this.invMass0 = ((this.isRB0) ? this.parent0.invMass : 0);
			this.invMass1 = ((this.isRB1) ? this.parent1.invMass : 0);
			this.invMass = (this.invMass0 + this.invMass1);
			this.v0 = this.parent0.linearVelocity;
			this.v1 = this.parent1.linearVelocity;
			this.a0 = this.parent0.angularVelocity;
			this.a1 = this.parent1.angularVelocity;
			this.d0 = this.parent0.displacement;
			this.d1 = this.parent1.displacement;
			this.r0x = (this.posX - this.parent0.position.x);
			this.r0y = (this.posY - this.parent0.position.y);
			this.r0z = (this.posZ - this.parent0.position.z);
			this.r1x = (this.posX - this.parent1.position.x);
			this.r1y = (this.posY - this.parent1.position.y);
			this.r1z = (this.posZ - this.parent1.position.z);
			this.relVelX = (((this.v1.x + (this.a1.y * this.r1z)) - (this.a1.z * this.r1y)) - ((this.v0.x + (this.a0.y * this.r0z)) - (this.a0.z * this.r0y)));
			this.relVelY = (((this.v1.y + (this.a1.z * this.r1x)) - (this.a1.x * this.r1z)) - ((this.v0.y + (this.a0.z * this.r0x)) - (this.a0.x * this.r0z)));
			this.relVelZ = (((this.v1.z + (this.a1.x * this.r1y)) - (this.a1.y * this.r1x)) - ((this.v0.z + (this.a0.x * this.r0y)) - (this.a0.y * this.r0x)));
			this.rvn = (((this.relVelX * this.normalX) + (this.relVelY * this.normalY)) + (this.relVelZ * this.normalZ));
			this.tanX = (this.relVelX - (this.normalX * this.rvn));
			this.tanY = (this.relVelY - (this.normalY * this.rvn));
			this.tanZ = (this.relVelZ - (this.normalZ * this.rvn));
			var len:Number = (((this.tanX * this.tanX) + (this.tanY * this.tanY)) + (this.tanZ * this.tanZ));
			if (len > 0.001) {
				len = (1 / Math.sqrt(len));
				this.tanX = (this.tanX * len);
				this.tanY = (this.tanY * len);
				this.tanZ = (this.tanZ * len);
			} else {
				this.tanX = ((this.normalY * this.normalX) - (this.normalZ * this.normalZ));
				this.tanY = ((-(this.normalZ) * this.normalY) - (this.normalX * this.normalX));
				this.tanZ = ((this.normalX * this.normalZ) + (this.normalY * this.normalY));
			}
			this.rn0x = ((this.r0y * this.normalZ) - (this.r0z * this.normalY));
			this.rn0y = ((this.r0z * this.normalX) - (this.r0x * this.normalZ));
			this.rn0z = ((this.r0x * this.normalY) - (this.r0y * this.normalX));
			this.rn1x = ((this.r1y * this.normalZ) - (this.r1z * this.normalY));
			this.rn1y = ((this.r1z * this.normalX) - (this.r1x * this.normalZ));
			this.rn1z = ((this.r1x * this.normalY) - (this.r1y * this.normalX));
			this.rt0x = ((this.r0y * this.tanZ) - (this.r0z * this.tanY));
			this.rt0y = ((this.r0z * this.tanX) - (this.r0x * this.tanZ));
			this.rt0z = ((this.r0x * this.tanY) - (this.r0y * this.tanX));
			this.rt1x = ((this.r1y * this.tanZ) - (this.r1z * this.tanY));
			this.rt1y = ((this.r1z * this.tanX) - (this.r1x * this.tanZ));
			this.rt1z = ((this.r1x * this.tanY) - (this.r1y * this.tanX));
			this.parent0.invInertia.copyRawDataTo(it0);
			this.parent1.invInertia.copyRawDataTo(it1);
			if (this.isRB0) {
				this.rnI0x = (((this.rn0x * it0[0]) + (this.rn0y * it0[4])) + (this.rn0z * it0[8]));
				this.rnI0y = (((this.rn0x * it0[1]) + (this.rn0y * it0[5])) + (this.rn0z * it0[9]));
				this.rnI0z = (((this.rn0x * it0[2]) + (this.rn0y * it0[6])) + (this.rn0z * it0[10]));
				this.rtI0x = (((this.rt0x * it0[0]) + (this.rt0y * it0[4])) + (this.rt0z * it0[8]));
				this.rtI0y = (((this.rt0x * it0[1]) + (this.rt0y * it0[5])) + (this.rt0z * it0[9]));
				this.rtI0z = (((this.rt0x * it0[2]) + (this.rt0y * it0[6])) + (this.rt0z * it0[10]));
			} else {
				this.rnI0x = 0;
				this.rnI0y = 0;
				this.rnI0z = 0;
				this.rtI0x = 0;
				this.rtI0y = 0;
				this.rtI0z = 0;
			}
			if (this.isRB1) {
				this.rnI1x = (((this.rn1x * it1[0]) + (this.rn1y * it1[4])) + (this.rn1z * it1[8]));
				this.rnI1y = (((this.rn1x * it1[1]) + (this.rn1y * it1[5])) + (this.rn1z * it1[9]));
				this.rnI1z = (((this.rn1x * it1[2]) + (this.rn1y * it1[6])) + (this.rn1z * it1[10]));
				this.rtI1x = (((this.rt1x * it1[0]) + (this.rt1y * it1[4])) + (this.rt1z * it1[8]));
				this.rtI1y = (((this.rt1x * it1[1]) + (this.rt1y * it1[5])) + (this.rt1z * it1[9]));
				this.rtI1z = (((this.rt1x * it1[2]) + (this.rt1y * it1[6])) + (this.rt1z * it1[10]));
			} else {
				this.rnI1x = 0;
				this.rnI1y = 0;
				this.rnI1z = 0;
				this.rtI1x = 0;
				this.rtI1y = 0;
				this.rtI1z = 0;
			}
			tx = ((this.rnI0y * this.r0z) - (this.rnI0z * this.r0y));
			ty = ((this.rnI0z * this.r0x) - (this.rnI0x * this.r0z));
			tz = ((this.rnI0x * this.r0y) - (this.rnI0y * this.r0x));
			tx = (tx + ((this.rnI1y * this.r1z) - (this.rnI1z * this.r1y)));
			ty = (ty + ((this.rnI1z * this.r1x) - (this.rnI1x * this.r1z)));
			tz = (tz + ((this.rnI1x * this.r1y) - (this.rnI1y * this.r1x)));
			this.normalImp = (((this.invMass + (tx * this.normalX)) + (ty * this.normalY)) + (tz * this.normalZ));
			tx = ((this.rtI0y * this.r0z) - (this.rtI0z * this.r0y));
			ty = ((this.rtI0z * this.r0x) - (this.rtI0x * this.r0z));
			tz = ((this.rtI0x * this.r0y) - (this.rtI0y * this.r0x));
			tx = (tx + ((this.rtI1y * this.r1z) - (this.rtI1z * this.r1y)));
			ty = (ty + ((this.rtI1z * this.r1x) - (this.rtI1x * this.r1z)));
			tz = (tz + ((this.rtI1x * this.r1y) - (this.rtI1y * this.r1x)));
			this.tangentImp = (((this.invMass + (tx * this.tanX)) + (ty * this.tanY)) + (tz * this.tanZ));
			this.friction = (this.collider0.friction * this.collider1.friction);
			this.friction = (this.friction * (this.friction * this.friction));
			if (this.collider0.restitution > this.collider1.restitution) {
				this.restitution = (this.collider0.restitution + 1);
			} else {
				this.restitution = (this.collider1.restitution + 1);
			}
			this.restitution = (1 + Math.max(this.collider0.restitution, this.collider1.restitution));
		}
		
		final public function solve():void {
			var imp:Number;
			var fx:Number;
			var fy:Number;
			var fz:Number;
			var rvx:Number;
			var rvy:Number;
			var rvz:Number;
			var dvn:Number;
			var j:Number;
			var jt:Number;
			if (((this.parent0.isTrigger) || (this.parent1.isTrigger))) {
				return;
			}
			if (((this.isRB0) || (this.isRB1))) {
				this.relVelX = (((this.v1.x + (this.a1.y * this.r1z)) - (this.a1.z * this.r1y)) - ((this.v0.x + (this.a0.y * this.r0z)) - (this.a0.z * this.r0y)));
				this.relVelY = (((this.v1.y + (this.a1.z * this.r1x)) - (this.a1.x * this.r1z)) - ((this.v0.y + (this.a0.z * this.r0x)) - (this.a0.x * this.r0z)));
				this.relVelZ = (((this.v1.z + (this.a1.x * this.r1y)) - (this.a1.y * this.r1x)) - ((this.v0.z + (this.a0.x * this.r0y)) - (this.a0.y * this.r0x)));
				this.rvn = (((this.relVelX * this.normalX) + (this.relVelY * this.normalY)) + (this.relVelZ * this.normalZ));
				j = (this.rvn + (this.overlap * -2));
				if (j < 0) {
					imp = (j / this.normalImp);
					this.a0.x = (this.a0.x + (imp * this.rnI0x));
					this.a0.y = (this.a0.y + (imp * this.rnI0y));
					this.a0.z = (this.a0.z + (imp * this.rnI0z));
					this.a1.x = (this.a1.x - (imp * this.rnI1x));
					this.a1.y = (this.a1.y - (imp * this.rnI1y));
					this.a1.z = (this.a1.z - (imp * this.rnI1z));
					imp = (imp * this.restitution);
					fx = (imp * this.normalX);
					fy = (imp * this.normalY);
					fz = (imp * this.normalZ);
					this.v0.x = (this.v0.x + (fx * this.invMass0));
					this.v0.y = (this.v0.y + (fy * this.invMass0));
					this.v0.z = (this.v0.z + (fz * this.invMass0));
					this.v1.x = (this.v1.x - (fx * this.invMass1));
					this.v1.y = (this.v1.y - (fy * this.invMass1));
					this.v1.z = (this.v1.z - (fz * this.invMass1));
					this.rvn = (((this.relVelX * this.tanX) + (this.relVelY * this.tanY)) + (this.relVelZ * this.tanZ));
					if (this.rvn > 0) {
						jt = ((this.rvn / this.tangentImp) * this.friction);
						fx = (jt * this.tanX);
						fy = (jt * this.tanY);
						fz = (jt * this.tanZ);
						this.v0.x = (this.v0.x + (fx * this.invMass0));
						this.v0.y = (this.v0.y + (fy * this.invMass0));
						this.v0.z = (this.v0.z + (fz * this.invMass0));
						this.a0.x = (this.a0.x + (jt * this.rtI0x));
						this.a0.y = (this.a0.y + (jt * this.rtI0y));
						this.a0.z = (this.a0.z + (jt * this.rtI0z));
						this.v1.x = (this.v1.x - (fx * this.invMass1));
						this.v1.y = (this.v1.y - (fy * this.invMass1));
						this.v1.z = (this.v1.z - (fz * this.invMass1));
						this.a1.x = (this.a1.x - (jt * this.rtI1x));
						this.a1.y = (this.a1.y - (jt * this.rtI1y));
						this.a1.z = (this.a1.z - (jt * this.rtI1z));
					}
				}
			}
			var im:Number = (1 / (this.parent0.invMass + this.parent1.invMass));
			rvx = (this.d1.x - this.d0.x);
			rvy = (this.d1.y - this.d0.y);
			rvz = (this.d1.z - this.d0.z);
			dvn = (((rvx * this.normalX) + (rvy * this.normalY)) + (rvz * this.normalZ));
			var ovr:Number = ((dvn - this.overlap) + ZenPhysics.allowOverlaping);
			if (ovr < 0) {
				if (!(this.parent0.isStatic)) {
					imp = ((ovr * this.parent0.invMass) * im);
					this.d0.x = (this.d0.x + (imp * this.normalX));
					this.d0.y = (this.d0.y + (imp * this.normalY));
					this.d0.z = (this.d0.z + (imp * this.normalZ));
				}
				if (!(this.parent1.isStatic)) {
					imp = ((ovr * this.parent1.invMass) * im);
					this.d1.x = (this.d1.x - (imp * this.normalX));
					this.d1.y = (this.d1.y - (imp * this.normalY));
					this.d1.z = (this.d1.z - (imp * this.normalZ));
				}
			}
		}
	
	}
}

