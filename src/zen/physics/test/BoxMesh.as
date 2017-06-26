package zen.physics.test
{
    
    import flash.geom.Vector3D;
    import zen.physics.geom.PhysicsNode3D;
	import zen.geom.*;
    import zen.physics.Contact;
    import zen.physics.*;
    import zen.physics.colliders.*;
    import zen.physics.geom.*;
    import zen.utils.*;
    import flash.geom.*;
    

    public class BoxMesh implements ICollision 
    {

        private static const EPSILON:Number = 0.0001;
        private static const raw:Vector.<Number> = new Vector.<Number>(16, true);
        private static const crossAxis:Vector3D = new Vector3D();
        private static const bvhList:Vector.<PhysicsNode3D> = new Vector.<PhysicsNode3D>(0x0400, true);
        private static const ax:Vector3D = new Vector3D();
        private static const ay:Vector3D = new Vector3D();
        private static const az:Vector3D = new Vector3D();
        private static const pos:Vector3D = new Vector3D();
        private static const axis:Vector3D = new Vector3D();
        private static const t:Vector3D = new Vector3D();

        private static var box:BoxCollider;
        private static var tri:Tri3D;
        private static var depth:Number;
        private static var flags:uint;
        private static var refIndex:uint;
        private static var aX0x:Number;
        private static var aX0y:Number;
        private static var aX0z:Number;
        private static var aY0x:Number;
        private static var aY0y:Number;
        private static var aY0z:Number;
        private static var aZ0x:Number;
        private static var aZ0y:Number;
        private static var aZ0z:Number;
        private static var p0x:Number;
        private static var p0y:Number;
        private static var p0z:Number;
        private static var w0:Number;
        private static var h0:Number;
        private static var d0:Number;


        private static function removeDuplicatedContacts(from:int, contacts:Vector.<Contact>, numContacts:int):int
        {
            var c0:Contact;
            var px:Number;
            var py:Number;
            var pz:Number;
            var e:int;
            var c1:Contact;
            var dx:Number;
            var dy:Number;
            var dz:Number;
            var d:Number;
            var j:int;
            var tmp:Contact;
            var i:int = from;
            while (i < numContacts) {
                c0 = contacts[i];
                px = c0.posX;
                py = c0.posY;
                pz = c0.posZ;
                e = (i + 1);
                while (e < numContacts) {
                    c1 = contacts[e];
                    if (c0.normalX == c1.normalX){
                        if (c0.normalY == c1.normalY){
                            if (c0.normalZ == c1.normalZ){
                                dx = Math.abs((px - c1.posX));
                                dy = Math.abs((py - c1.posY));
                                dz = Math.abs((pz - c1.posZ));
                                d = ((dx + dy) + dz);
                                if (d < EPSILON){
                                    numContacts--;
                                    j = e;
                                    while (j < numContacts) {
                                        tmp = contacts[j];
                                        contacts[j] = contacts[(j + 1)];
                                        contacts[(j + 1)] = tmp;
                                        j++;
                                    }
                                    e--;
                                }
                            }
                        }
                    }
                    e++;
                }
                i++;
            }
            return (numContacts);
        }

        private static function testAx(testAxis:Vector3D, flag:uint):Boolean
        {
            var v0:LinkedVector3D;
            var v1:LinkedVector3D;
            var v2:LinkedVector3D;
            var tx:Number = testAxis.x;
            var ty:Number = testAxis.y;
            var tz:Number = testAxis.z;
            var len:Number = (((tx * tx) + (ty * ty)) + (tz * tz));
            if (len < EPSILON){
                return (false);
            }
            if ((((len < 0.99)) || ((len > 1.01)))){
                len = (1 / Math.sqrt(len));
                tx = (tx * len);
                ty = (ty * len);
                tz = (tz * len);
            }
            var lx:Number = (((aX0x * tx) + (aX0y * ty)) + (aX0z * tz));
            if (lx < 0){
                lx = -(lx);
            }
            var ly:Number = (((aY0x * tx) + (aY0y * ty)) + (aY0z * tz));
            if (ly < 0){
                ly = -(ly);
            }
            var lz:Number = (((aZ0x * tx) + (aZ0y * ty)) + (aZ0z * tz));
            if (lz < 0){
                lz = -(lz);
            }
            len = (((lx * w0) + (ly * h0)) + (lz * d0));
            var pos:Number = (((p0x * tx) + (p0y * ty)) + (p0z * tz));
            var minA:Number = (pos - len);
            var maxA:Number = (pos + len);
            v0 = tri.v0;
            v1 = tri.v1;
            v2 = tri.v2;
            var dot0:Number = (((v0.x * tx) + (v0.y * ty)) + (v0.z * tz));
            var dot1:Number = (((v1.x * tx) + (v1.y * ty)) + (v1.z * tz));
            var dot2:Number = (((v2.x * tx) + (v2.y * ty)) + (v2.z * tz));
            var minB:Number = (((((dot0 < dot1)) && ((dot0 < dot2)))) ? dot0 : (((dot1 < dot2)) ? dot1 : dot2));
            var maxB:Number = (((((dot0 > dot1)) && ((dot0 > dot2)))) ? dot0 : (((dot1 > dot2)) ? dot1 : dot2));
            var m:Number = ((maxA - minA) * 0.5);
            var s:Number = ((minA + maxA) * 0.5);
            minB = (minB - m);
            maxB = (maxB + m);
            var dmin:Number = (minB - s);
            var dmax:Number = (maxB - s);
            if ((((dmin > 0)) || ((dmax < 0)))){
                return (true);
            }
            if (dmin < 0){
                dmin = -(dmin);
            }
            if (dmax < dmin){
                if (dmax < (depth - EPSILON)){
                    depth = dmax;
                    axis.x = tx;
                    axis.y = ty;
                    axis.z = tz;
                    flags = flag;
                }
            } else {
                if (dmin < (depth - EPSILON)){
                    depth = dmin;
                    axis.x = -(tx);
                    axis.y = -(ty);
                    axis.z = -(tz);
                    flags = flag;
                }
            }
            return (false);
        }

        private static function cross(a:Vector3D, b:Vector3D):Vector3D
        {
            crossAxis.x = ((a.y * b.z) - (a.z * b.y));
            crossAxis.y = ((a.z * b.x) - (a.x * b.z));
            crossAxis.z = ((a.x * b.y) - (a.y * b.x));
            return (crossAxis);
        }

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


        final public function test(collider0:Collider, collider1:Collider, contacts:Vector.<Contact>, numContacts:int):int
        {
            var tris:Vector.<Tri3D>;
            var count:int;
            var i:int;
            var n:Vector3D;
            var backface:Number;
            var e0:TriEdge3D;
            var e1:TriEdge3D;
            var e2:TriEdge3D;
            var prev:int;
            refIndex++;
            box = (collider0 as BoxCollider);
            var num:int = numContacts;
            var mesh:MeshCollider = (collider1 as MeshCollider);
            mesh.invTransform.copyRawDataTo(raw);
            deltaTransformVector(raw, box.axisX, ax);
            deltaTransformVector(raw, box.axisY, ay);
            deltaTransformVector(raw, box.axisZ, az);
            transformVector(raw, box.position, pos);
            aX0x = ax.x;
            aX0y = ax.y;
            aX0z = ax.z;
            aY0x = ay.x;
            aY0y = ay.y;
            aY0z = ay.z;
            aZ0x = az.x;
            aZ0y = az.y;
            aZ0z = az.z;
            p0x = pos.x;
            p0y = pos.y;
            p0z = pos.z;
            w0 = box.halfWidth;
            h0 = box.halfHeight;
            d0 = box.halfDepth;
            var listCount:int = mesh.bvh.intersectSphere(pos, box.radius, bvhList);
            var s:int;
            while (s < listCount) {
                tris = bvhList[s].tris;
                count = tris.length;
                i = 0;
                while (i < count) {
                    tri = tris[i];
                    if (tri.ref != refIndex){
                        tri.ref = refIndex;
                        n = tri.n;
                        backface = ((((n.x * p0x) + (n.y * p0y)) + (n.z * p0z)) + n.w);
                        if (backface >= 0){
                            e0 = tri.e0;
                            e1 = tri.e1;
                            e2 = tri.e2;
                            depth = 1000000;
                            axis.x = 0;
                            axis.y = 0;
                            axis.z = 0;
                            flags = 0;
                            if (!testAx(tri.n, 1)){
                                if (!testAx(ax, 2)){
                                    if (!testAx(ay, 3)){
                                        if (!testAx(az, 4)){
                                            if (!testAx(cross(az, e0), 5)){
                                                if (!testAx(cross(ay, e0), 6)){
                                                    if (!testAx(cross(az, e0), 7)){
                                                        if (!testAx(cross(az, e1), 8)){
                                                            if (!testAx(cross(ay, e1), 9)){
                                                                if (!testAx(cross(az, e1), 10)){
                                                                    if (!testAx(cross(az, e2), 11)){
                                                                        if (!testAx(cross(ay, e2), 12)){
                                                                            if (!testAx(cross(az, e2), 13)){
                                                                                SAT3D.axis.copyFrom(axis);
                                                                                SAT3D.depth = depth;
                                                                                SAT3D.collider0 = box;
                                                                                SAT3D.collider1 = tri;
                                                                                prev = numContacts;
                                                                                numContacts = SAT3D.generateContacts(contacts, numContacts, box, mesh, mesh.transform);
                                                                            }
                                                                        }
                                                                    }
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    i++;
                }
                s++;
            }
            numContacts = removeDuplicatedContacts(num, contacts, numContacts);
            return (numContacts);
        }


    }
}

