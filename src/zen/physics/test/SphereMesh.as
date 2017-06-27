package zen.physics.test {
	import zen.geom.physics.*;
	import zen.physics.core.*;
	import flash.geom.*;
	import zen.physics.*;
	import zen.physics.colliders.*;
	import zen.physics.geom.*;
	import zen.utils.*;
	import zen.geom.physics.*;
	import zen.geom.*;
	
	public class SphereMesh implements ICollision {
		
		private static const pIPoint:Vector3D = new Vector3D();
		private static const sIPoint:Vector3D = new Vector3D();
		private static const list:Vector.<Vector.<Tri3D>> = new Vector.<Vector.<Tri3D>>();
		private static const bvhList:Vector.<PhysicsNode3D> = new Vector.<PhysicsNode3D>(0x0400, true);
		private static const out:Vector3D = new Vector3D();
		private static const normal:Vector3D = new Vector3D();
		private static const pos:Vector3D = new Vector3D();
		
		private static var refIndex:uint = 0;
		
		public function test(collider0:Collider, collider1:Collider, collisions:Vector.<Contact>, collisionCount:int):int {
			var overlap:Number;
			var tris:Vector.<Tri3D>;
			var count:int;
			var i:int;
			var tri:Tri3D;
			var nrm:Vector3D;
			var dist:Number;
			var edge:TriEdge3D;
			var c:Contact;
			var dx:Number;
			var dy:Number;
			var dz:Number;
			var front:Boolean;
			refIndex++;
			refIndex = (refIndex & 0xFFFFFF);
			var b0:SphereCollider = (collider0 as SphereCollider);
			var b1:MeshCollider = (collider1 as MeshCollider);
			M3D.transformVector(b1.invTransform, b0.position, out);
			var listCount:int = b1.bvh.intersectSphere(out, b0.radius, bvhList);
			var l:int;
			while (l < listCount) {
				list[l] = bvhList[l].tris;
				l++;
			}
			var px:Number = out.x;
			var py:Number = out.y;
			var pz:Number = out.z;
			var rad:Number = b0.radius;
			var twoSided:Number = -(rad);
			var s:int;
			while (s < listCount) {
				tris = list[s];
				count = tris.length;
				i = 0;
				for (; i < count; i++) {
					tri = tris[i];
					if (tri.ref != refIndex) {
						tri.ref = refIndex;
						nrm = tri.n;
						dist = ((((nrm.x * px) + (nrm.y * py)) + (nrm.z * pz)) + nrm.w);
						edge = null;
						if ((((dist < rad)) && ((dist > twoSided)))) {
							pIPoint.x = (px - (nrm.x * dist));
							pIPoint.y = (py - (nrm.y * dist));
							pIPoint.z = (pz - (nrm.z * dist));
							if (tri.isPoint(pIPoint.x, pIPoint.y, pIPoint.z)) {
								if (dist > 0) {
									normal.x = nrm.x;
									normal.y = nrm.y;
									normal.z = nrm.z;
									overlap = (rad - dist);
								} else {
									normal.x = -(nrm.x);
									normal.y = -(nrm.y);
									normal.z = -(nrm.z);
									overlap = (rad + dist);
								}
							} else {
								edge = tri.closetPoint(pIPoint, pIPoint);
								dx = (px - pIPoint.x);
								dy = (py - pIPoint.y);
								dz = (pz - pIPoint.z);
								front = (((dist > 0)) ? true : false);
								dist = (((dx * dx) + (dy * dy)) + (dz * dz));
								if (dist > (rad * rad)) continue;
								if (((!(edge)) || (edge.valid))) {
									normal.x = (px - pIPoint.x);
									normal.y = (py - pIPoint.y);
									normal.z = (pz - pIPoint.z);
									normal.normalize();
								} else {
									if (front) {
										normal.x = nrm.x;
										normal.y = nrm.y;
										normal.z = nrm.z;
									} else {
										normal.x = -(nrm.x);
										normal.y = -(nrm.y);
										normal.z = -(nrm.z);
									}
								}
								overlap = (rad - Math.sqrt(dist));
							}
							if (!(collisions[collisionCount])) {
								collisions[collisionCount] = new Contact();
							}
							c = collisions[collisionCount++];
							pos.x = (px - (normal.x * (rad - overlap)));
							pos.y = (py - (normal.y * (rad - overlap)));
							pos.z = (pz - (normal.z * (rad - overlap)));
							M3D.transformVector(b1.transform, pos, pos);
							c.posX = pos.x;
							c.posY = pos.y;
							c.posZ = pos.z;
							M3D.deltaTransformVector(b1.transform, normal, normal);
							c.normalX = normal.x;
							c.normalY = normal.y;
							c.normalZ = normal.z;
							c.overlap = overlap;
							c.depth = overlap;
							c.collider0 = collider0;
							c.collider1 = collider1;
							c.tri = tri;
							c.edge = edge;
						}
					}
				}
				s++;
			}
			return (collisionCount);
		}
	
	}
}

