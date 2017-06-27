package zen.physics.test {
	
	import zen.geom.physics.*;
	import zen.physics.core.*;
	import zen.physics.*;
	import zen.physics.colliders.*;
	
	public class SphereBox implements ICollision {
		
		private static const RX:int = 0;
		private static const RY:int = 1;
		private static const RZ:int = 2;
		private static const UX:int = 4;
		private static const UY:int = 5;
		private static const UZ:int = 6;
		private static const DX:int = 8;
		private static const DY:int = 9;
		private static const DZ:int = 10;
		private static const TX:int = 12;
		private static const TY:int = 13;
		private static const TZ:int = 14;
		
		private static var r1:Vector.<Number> = new Vector.<Number>(16, true);
		
		public function test(collider0:Collider, collider1:Collider, collisions:Vector.<Contact>, collisionCount:int):int {
			var dot0:Number;
			var dot1:Number;
			var dot2:Number;
			var dx:Number;
			var dy:Number;
			var dz:Number;
			var x1x:Number;
			var x1y:Number;
			var x1z:Number;
			var y1x:Number;
			var y1y:Number;
			var y1z:Number;
			var z1x:Number;
			var z1y:Number;
			var z1z:Number;
			var px:Number;
			var py:Number;
			var pz:Number;
			var e:Number;
			var c:Contact;
			var nx:Number;
			var ny:Number;
			var nz:Number;
			var invLen:Number;
			var s:SphereCollider = (collider0 as SphereCollider);
			var b:BoxCollider = (collider1 as BoxCollider);
			b.transform.copyRawDataTo(r1);
			var rad:Number = s.radius;
			dx = (s.position.x - b.position.x);
			dy = (s.position.y - b.position.y);
			dz = (s.position.z - b.position.z);
			x1x = r1[RX];
			x1y = r1[RY];
			x1z = r1[RZ];
			y1x = r1[UX];
			y1y = r1[UY];
			y1z = r1[UZ];
			z1x = r1[DX];
			z1y = r1[DY];
			z1z = r1[DZ];
			dot0 = (((dx * x1x) + (dy * x1y)) + (dz * x1z));
			dot1 = (((dx * y1x) + (dy * y1y)) + (dz * y1z));
			dot2 = (((dx * z1x) + (dy * z1y)) + (dz * z1z));
			var hw:Number = b.halfWidth;
			var hh:Number = b.halfHeight;
			var hd:Number = b.halfDepth;
			var len:Number = 0;
			e = (dot0 + hw);
			if (e < 0) {
				if (e < -(rad)) {
					return (collisionCount);
				}
				len = (len + (e * e));
				px = -(hw);
			} else {
				e = (dot0 - hw);
				if (e > 0) {
					if (e > rad) {
						return (collisionCount);
					}
					len = (len + (e * e));
					px = hw;
				} else {
					px = dot0;
				}
			}
			e = (dot1 + hh);
			if (e < 0) {
				if (e < -(rad)) {
					return (collisionCount);
				}
				len = (len + (e * e));
				py = -(hh);
			} else {
				e = (dot1 - hh);
				if (e > 0) {
					if (e > rad) {
						return (collisionCount);
					}
					len = (len + (e * e));
					py = hh;
				} else {
					py = dot1;
				}
			}
			e = (dot2 + hd);
			if (e < 0) {
				if (e < -(rad)) {
					return (collisionCount);
				}
				len = (len + (e * e));
				pz = -(hd);
			} else {
				e = (dot2 - hd);
				if (e > 0) {
					if (e > rad) {
						return (collisionCount);
					}
					len = (len + (e * e));
					pz = hd;
				} else {
					pz = dot2;
				}
			}
			if ((((len > 0)) && ((len < (rad * rad))))) {
				if (!(collisions[collisionCount])) {
					collisions[collisionCount] = new Contact();
				}
				c = collisions[collisionCount++];
				c.posX = ((((px * x1x) + (py * y1x)) + (pz * z1x)) + b.position.x);
				c.posY = ((((px * x1y) + (py * y1y)) + (pz * z1y)) + b.position.y);
				c.posZ = ((((px * x1z) + (py * y1z)) + (pz * z1z)) + b.position.z);
				nx = (s.position.x - c.posX);
				ny = (s.position.y - c.posY);
				nz = (s.position.z - c.posZ);
				len = Math.sqrt((((nx * nx) + (ny * ny)) + (nz * nz)));
				invLen = (1 / len);
				nx = (nx * invLen);
				ny = (ny * invLen);
				nz = (nz * invLen);
				c.normalX = nx;
				c.normalY = ny;
				c.normalZ = nz;
				c.overlap = (rad - len);
				c.collider0 = collider0;
				c.collider1 = collider1;
				c.tri = null;
				c.edge = null;
			}
			return (collisionCount);
		}
	
	}
}

