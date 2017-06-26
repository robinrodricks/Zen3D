package zen.physics.test
{
    
	import zen.geom.*;
    import zen.physics.*;
    import zen.physics.colliders.*;
    import zen.physics.geom.*;
    import flash.geom.*;
    

    public class RayMesh implements ICollision 
    {

        private static const EPSILON:Number = 0.0001;
        private static const raw:Vector.<Number> = new Vector.<Number>(16, true);
        private static const dir:Vector3D = new Vector3D();
        private static const pos:Vector3D = new Vector3D();

        private static var refIndex:uint;
        private static var pIPoint:Vector3D = new Vector3D();
        private static var list:Vector.<Vector.<Tri3D>> = new Vector.<Vector.<Tri3D>>();
        private static var bvhList:Vector.<PhysicsNode3D> = new Vector.<PhysicsNode3D>(100);


        private static function deltaTransformVector(raw:Vector.<Number>, vector:Vector3D, out:Vector3D):void
        {
            var x:Number = vector.x;
            var y:Number = vector.y;
            var z:Number = vector.z;
            out.x = (((x * raw[0]) + (y * raw[4])) + (z * raw[8]));
            out.y = (((x * raw[1]) + (y * raw[5])) + (z * raw[9]));
            out.z = (((x * raw[2]) + (y * raw[6])) + (z * raw[10]));
        }

        private static function transformVector(raw:Vector.<Number>, vector:Vector3D, out:Vector3D):void
        {
            var x:Number = vector.x;
            var y:Number = vector.y;
            var z:Number = vector.z;
            out.x = ((((x * raw[0]) + (y * raw[4])) + (z * raw[8])) + raw[12]);
            out.y = ((((x * raw[1]) + (y * raw[5])) + (z * raw[9])) + raw[13]);
            out.z = ((((x * raw[2]) + (y * raw[6])) + (z * raw[10])) + raw[14]);
        }


        public function test(collider0:Collider, collider1:Collider, collisions:Vector.<Contact>, collisionCount:int):int
        {
            var triangle:Tri3D;
            var tris:Vector.<Tri3D>;
            var count:int;
            var i:int;
            var tri:Tri3D;
            var nrm:Vector3D;
            var dist:Number;
            var c:Contact;
            refIndex++;
            refIndex = (refIndex & 0xFFFFFF);
            var ray:RayCollider = (collider0 as RayCollider);
            var mesh:MeshCollider = (collider1 as MeshCollider);
            mesh.invTransform.copyRawDataTo(raw);
            transformVector(raw, ray.position, pos);
            deltaTransformVector(raw, ray.dir, dir);
            var listCount:int = mesh.bvh.intersectRay(pos, dir, bvhList);
            if (list.length < listCount){
                list.length = listCount;
            }
            var l:int;
            while (l < listCount) {
                list[l] = bvhList[l].tris;
                l++;
            }
            var triangleDistance:Number = ray.distance;
            var s:int;
            while (s < listCount) {
                tris = list[s];
                count = tris.length;
                i = 0;
                while (i < count) {
                    tri = tris[i];
                    if (tri.ref != refIndex){
                        tri.ref = refIndex;
                        nrm = tri.n;
                        dist = (-(((((nrm.x * pos.x) + (nrm.y * pos.y)) + (nrm.z * pos.z)) + nrm.w)) / (((nrm.x * dir.x) + (nrm.y * dir.y)) + (nrm.z * dir.z)));
                        if ((((dist > 0)) && ((dist < triangleDistance)))){
                            pIPoint.x = (pos.x + (dir.x * dist));
                            pIPoint.y = (pos.y + (dir.y * dist));
                            pIPoint.z = (pos.z + (dir.z * dist));
                            if (tri.isPoint(pIPoint.x, pIPoint.y, pIPoint.z)){
                                triangleDistance = dist;
                                triangle = tri;
                            }
                        }
                    }
                    i++;
                }
                s++;
            }
            if (triangle){
                collisions[collisionCount] = ((collisions[collisionCount]) || (new Contact()));
                c = collisions[collisionCount++];
                c.posX = (ray.position.x + (ray.dir.x * triangleDistance));
                c.posY = (ray.position.y + (ray.dir.y * triangleDistance));
                c.posZ = (ray.position.z + (ray.dir.z * triangleDistance));
                c.normalX = triangle.n.x;
                c.normalY = triangle.n.y;
                c.normalZ = triangle.n.z;
                c.overlap = 0;
                c.depth = 0;
                c.collider0 = collider0;
                c.collider1 = collider1;
                c.tri = triangle;
                c.edge = null;
            }
            return (collisionCount);
        }


    }
}

