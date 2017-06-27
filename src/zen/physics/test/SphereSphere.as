package zen.physics.test {
	import zen.geom.physics.*;
	import zen.physics.core.*;
	import zen.physics.*;
	import zen.physics.colliders.*;
	import flash.geom.*;
	
	public class SphereSphere implements ICollision {
		
		public function test(collider0:Collider, collider1:Collider, collisions:Vector.<Contact>, collisionCount:int):int {
			var c:Contact;
			var invLen:Number;
			var s0:SphereCollider = (collider0 as SphereCollider);
			var s1:SphereCollider = (collider1 as SphereCollider);
			var p0:Vector3D = collider0.position;
			var p1:Vector3D = collider1.position;
			var dx:Number = (p0.x - p1.x);
			var dy:Number = (p0.y - p1.y);
			var dz:Number = (p0.z - p1.z);
			var len:Number = (((dx * dx) + (dy * dy)) + (dz * dz));
			var r0:Number = s0.radius;
			var r1:Number = s1.radius;
			var rad:Number = (r0 + r1);
			if ((((len > 0)) && ((len < (rad * rad))))) {
				if (!(collisions[collisionCount])) {
					collisions[collisionCount] = new Contact();
				}
				c = collisions[collisionCount++];
				len = Math.sqrt(len);
				invLen = (1 / len);
				dx = (dx * invLen);
				dy = (dy * invLen);
				dz = (dz * invLen);
				c.normalX = dx;
				c.normalY = dy;
				c.normalZ = dz;
				c.posX = (p0.x - (dx * r0));
				c.posY = (p0.y - (dy * r0));
				c.posZ = (p0.z - (dz * r0));
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

