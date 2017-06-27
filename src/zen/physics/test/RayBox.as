package zen.physics.test {
	
	import zen.geom.physics.*;
	import zen.physics.core.*;
	import zen.physics.*;
	import zen.physics.colliders.*;
	import flash.geom.*;
	
	public class RayBox implements ICollision {
		
		private static const RX:int = 0;
		private static const RY:int = 1;
		private static const RZ:int = 2;
		private static const UX:int = 4;
		private static const UY:int = 5;
		private static const UZ:int = 6;
		private static const DX:int = 8;
		private static const DY:int = 9;
		private static const DZ:int = 10;
		
		private static var r1:Vector.<Number> = new Vector.<Number>(16, true);
		
		public function test(collider0:Collider, collider1:Collider, collisions:Vector.<Contact>, collisionCount:int):int {
			var x1x:Number;
			var x1y:Number;
			var x1z:Number;
			var y1x:Number;
			var y1y:Number;
			var y1z:Number;
			var z1x:Number;
			var z1y:Number;
			var z1z:Number;
			var tmin:Number;
			var tmax:Number;
			var tymin:Number;
			var tymax:Number;
			var tzmin:Number;
			var tzmax:Number;
			var axis:int;
			var c:Contact;
			var n:Number;
			var ray:RayCollider = (collider0 as RayCollider);
			var box:BoxCollider = (collider1 as BoxCollider);
			var from:Vector3D = ray.position;
			var dir:Vector3D = ray.dir;
			box.transform.copyRawDataTo(r1);
			x1x = r1[RX];
			x1y = r1[RY];
			x1z = r1[RZ];
			y1x = r1[UX];
			y1y = r1[UY];
			y1z = r1[UZ];
			z1x = r1[DX];
			z1y = r1[DY];
			z1z = r1[DZ];
			var dx:Number = (ray.position.x - box.position.x);
			var dy:Number = (ray.position.y - box.position.y);
			var dz:Number = (ray.position.z - box.position.z);
			var dirx:Number = (((x1x * dir.x) + (x1y * dir.y)) + (x1z * dir.z));
			var diry:Number = (((y1x * dir.x) + (y1y * dir.y)) + (y1z * dir.z));
			var dirz:Number = (((z1x * dir.x) + (z1y * dir.y)) + (z1z * dir.z));
			var fromx:Number = (((x1x * dx) + (x1y * dy)) + (x1z * dz));
			var fromy:Number = (((y1x * dx) + (y1y * dy)) + (y1z * dz));
			var fromz:Number = (((z1x * dx) + (z1y * dy)) + (z1z * dz));
			var maxx:Number = box.halfWidth;
			var minx:Number = -(maxx);
			var maxy:Number = box.halfHeight;
			var miny:Number = -(maxy);
			var maxz:Number = box.halfDepth;
			var minz:Number = -(maxz);
			var t0:Number = 0;
			var t1:Number = 10000000;
			if (dirx >= 0) {
				tmin = ((minx - fromx) / dirx);
				tmax = ((maxx - fromx) / dirx);
			} else {
				tmin = ((maxx - fromx) / dirx);
				tmax = ((minx - fromx) / dirx);
			}
			if (diry >= 0) {
				tymin = ((miny - fromy) / diry);
				tymax = ((maxy - fromy) / diry);
			} else {
				tymin = ((maxy - fromy) / diry);
				tymax = ((miny - fromy) / diry);
			}
			if ((((tmin > tymax)) || ((tymin > tmax)))) {
				return (collisionCount);
			}
			if (tymin > tmin) {
				tmin = tymin;
				axis = 1;
			}
			if (tymax < tmax) {
				tmax = tymax;
			}
			if (dirz >= 0) {
				tzmin = ((minz - fromz) / dirz);
				tzmax = ((maxz - fromz) / dirz);
			} else {
				tzmin = ((maxz - fromz) / dirz);
				tzmax = ((minz - fromz) / dirz);
			}
			if ((((tmin > tzmax)) || ((tzmin > tmax)))) {
				return (collisionCount);
			}
			if (tzmin > tmin) {
				tmin = tzmin;
				axis = 2;
			}
			if (tzmax < tmax) {
				tmax = tzmax;
			}
			if ((((tmin < t1)) && ((tmax > t0)))) {
				if (tmin > ray.distance) {
					return (collisionCount);
				}
				collisions[collisionCount] = ((collisions[collisionCount]) || (new Contact()));
				c = collisions[collisionCount++];
				c.posX = (from.x + (dir.x * tmin));
				c.posY = (from.y + (dir.y * tmin));
				c.posZ = (from.z + (dir.z * tmin));
				if (axis == 0) {
					n = (((dirx >= 0)) ? -1 : 1);
					c.normalX = (x1x * n);
					c.normalY = (x1y * n);
					c.normalZ = (x1z * n);
				} else {
					if (axis == 1) {
						n = (((diry >= 0)) ? -1 : 1);
						c.normalX = (y1x * n);
						c.normalY = (y1y * n);
						c.normalZ = (y1z * n);
					} else {
						if (axis == 2) {
							n = (((dirz >= 0)) ? -1 : 1);
							c.normalX = (z1x * n);
							c.normalY = (z1y * n);
							c.normalZ = (z1z * n);
						}
					}
				}
				c.overlap = 0;
				c.depth = 0;
				c.collider0 = collider0;
				c.collider1 = collider1;
				c.tri = null;
				c.edge = null;
			}
			return (collisionCount);
		}
	
	}
}

