package zen.physics.test
{
    import flash.geom.Vector3D;
    import zen.physics.Contact;
    import zen.physics.colliders.RayCollider;
    import zen.physics.colliders.SphereCollider;
    import zen.physics.colliders.Collider;
    
    import flash.geom.*;
    import zen.physics.*;
    import zen.physics.colliders.*;

    public class RaySphere implements ICollision 
    {

        private static var _q:Vector3D = new Vector3D();


        public function test(collider0:Collider, collider1:Collider, collisions:Vector.<Contact>, collisionCount:int):int
        {
            var dist:Number;
            var c:Contact;
            var b0:RayCollider = (collider0 as RayCollider);
            var b1:SphereCollider = (collider1 as SphereCollider);
            var p0:Vector3D = collider0.position;
            var p1:Vector3D = collider1.position;
            var dx:Number = (p0.x - p1.x);
            var dy:Number = (p0.y - p1.y);
            var dz:Number = (p0.z - p1.z);
            var rV:Vector3D = b0.dir;
            var sR:Number = b1.radius;
            var b:Number = (((dx * rV.x) + (dy * rV.y)) + (dz * rV.z));
            var n:Number = ((((dx * dx) + (dy * dy)) + (dz * dz)) - (sR * sR));
            var d:Number = ((b * b) - n);
            if (d > 0){
                dist = (-(b) - Math.sqrt(d));
                if (dist > b0.distance){
                    return (collisionCount);
                }
                collisions[collisionCount] = ((collisions[collisionCount]) || (new Contact()));
                c = collisions[collisionCount++];
                _q.x = (p0.x + (b0.dir.x * dist));
                _q.y = (p0.y + (b0.dir.y * dist));
                _q.z = (p0.z + (b0.dir.z * dist));
                c.posX = _q.x;
                c.posY = _q.y;
                c.posZ = _q.z;
                _q.x = (_q.x - p1.x);
                _q.y = (_q.y - p1.y);
                _q.z = (_q.z - p1.z);
                _q.normalize();
                c.normalX = _q.x;
                c.normalY = _q.y;
                c.normalZ = _q.z;
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

