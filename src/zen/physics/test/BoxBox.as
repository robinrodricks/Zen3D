package zen.physics.test
{
    import flash.geom.Vector3D;
    import zen.physics.colliders.BoxCollider;
    import zen.physics.colliders.Collider;
    
    import zen.physics.Contact;
    import zen.physics.*;

    public class BoxBox implements ICollision 
    {

        private static const EPSILON:Number = 0.0001;
        private static const axis:Vector3D = new Vector3D();
        private static const crossAxis:Vector3D = new Vector3D();

        private static var box0:BoxCollider;
        private static var box1:BoxCollider;
        private static var depth:Number;
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
        private static var aX1x:Number;
        private static var aX1y:Number;
        private static var aX1z:Number;
        private static var aY1x:Number;
        private static var aY1y:Number;
        private static var aY1z:Number;
        private static var aZ1x:Number;
        private static var aZ1y:Number;
        private static var aZ1z:Number;
        private static var p1x:Number;
        private static var p1y:Number;
        private static var p1z:Number;
        private static var w1:Number;
        private static var h1:Number;
        private static var d1:Number;


        final public function test(collider0:Collider, collider1:Collider, contacs:Vector.<Contact>, numContacts:int):int
        {
            if (!(this.collide(collider0, collider1))){
                return (numContacts);
            }
            SAT3D.axis.copyFrom(axis);
            SAT3D.collider0 = collider0;
            SAT3D.collider1 = collider1;
            SAT3D.depth = depth;
            return (SAT3D.generateContacts(contacs, numContacts));
        }

        final private function collide(b0:Collider, b1:Collider):Boolean
        {
            box0 = (b0 as BoxCollider);
            box1 = (b1 as BoxCollider);
            depth = 1000000;
            axis.x = 0;
            axis.y = 0;
            axis.z = 0;
            aX0x = box0.axisX.x;
            aX0y = box0.axisX.y;
            aX0z = box0.axisX.z;
            aY0x = box0.axisY.x;
            aY0y = box0.axisY.y;
            aY0z = box0.axisY.z;
            aZ0x = box0.axisZ.x;
            aZ0y = box0.axisZ.y;
            aZ0z = box0.axisZ.z;
            p0x = box0.position.x;
            p0y = box0.position.y;
            p0z = box0.position.z;
            w0 = box0.halfWidth;
            h0 = box0.halfHeight;
            d0 = box0.halfDepth;
            aX1x = box1.axisX.x;
            aX1y = box1.axisX.y;
            aX1z = box1.axisX.z;
            aY1x = box1.axisY.x;
            aY1y = box1.axisY.y;
            aY1z = box1.axisY.z;
            aZ1x = box1.axisZ.x;
            aZ1y = box1.axisZ.y;
            aZ1z = box1.axisZ.z;
            p1x = box1.position.x;
            p1y = box1.position.y;
            p1z = box1.position.z;
            w1 = box1.halfWidth;
            h1 = box1.halfHeight;
            d1 = box1.halfDepth;
            if (this.testAx(box0.axisX)){
                return (false);
            }
            if (this.testAx(box0.axisY)){
                return (false);
            }
            if (this.testAx(box0.axisZ)){
                return (false);
            }
            if (this.testAx(box1.axisX)){
                return (false);
            }
            if (this.testAx(box1.axisY)){
                return (false);
            }
            if (this.testAx(box1.axisZ)){
                return (false);
            }
            if (this.testAx(this.cross(box0.axisX, box1.axisX))){
                return (false);
            }
            if (this.testAx(this.cross(box0.axisX, box1.axisY))){
                return (false);
            }
            if (this.testAx(this.cross(box0.axisX, box1.axisZ))){
                return (false);
            }
            if (this.testAx(this.cross(box0.axisY, box1.axisX))){
                return (false);
            }
            if (this.testAx(this.cross(box0.axisY, box1.axisY))){
                return (false);
            }
            if (this.testAx(this.cross(box0.axisY, box1.axisZ))){
                return (false);
            }
            if (this.testAx(this.cross(box0.axisZ, box1.axisX))){
                return (false);
            }
            if (this.testAx(this.cross(box0.axisZ, box1.axisY))){
                return (false);
            }
            if (this.testAx(this.cross(box0.axisZ, box1.axisZ))){
                return (false);
            }
            return (true);
        }

        [Inline]
        final private function testAx(testAxis:Vector3D):Boolean
        {
            var pos:Number;
            var lx:Number;
            var ly:Number;
            var lz:Number;
            var tx:Number = testAxis.x;
            var ty:Number = testAxis.y;
            var tz:Number = testAxis.z;
            var len:Number = (((tx * tx) + (ty * ty)) + (tz * tz));
            if (len < EPSILON){
                tx = 0;
                ty = 1;
                tz = 0;
            } else {
                if ((((len < 0.99)) || ((len > 1.01)))){
                    len = (1 / Math.sqrt(len));
                    tx = (tx * len);
                    ty = (ty * len);
                    tz = (tz * len);
                }
            }
            lx = (((aX0x * tx) + (aX0y * ty)) + (aX0z * tz));
            if (lx < 0){
                lx = -(lx);
            }
            ly = (((aY0x * tx) + (aY0y * ty)) + (aY0z * tz));
            if (ly < 0){
                ly = -(ly);
            }
            lz = (((aZ0x * tx) + (aZ0y * ty)) + (aZ0z * tz));
            if (lz < 0){
                lz = -(lz);
            }
            len = (((lx * w0) + (ly * h0)) + (lz * d0));
            pos = (((p0x * tx) + (p0y * ty)) + (p0z * tz));
            var minA:Number = (pos - len);
            var maxA:Number = (pos + len);
            lx = (((aX1x * tx) + (aX1y * ty)) + (aX1z * tz));
            if (lx < 0){
                lx = -(lx);
            }
            ly = (((aY1x * tx) + (aY1y * ty)) + (aY1z * tz));
            if (ly < 0){
                ly = -(ly);
            }
            lz = (((aZ1x * tx) + (aZ1y * ty)) + (aZ1z * tz));
            if (lz < 0){
                lz = -(lz);
            }
            len = (((lx * w1) + (ly * h1)) + (lz * d1));
            pos = (((p1x * tx) + (p1y * ty)) + (p1z * tz));
            var minB:Number = (pos - len);
            var maxB:Number = (pos + len);
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
                }
            } else {
                if (dmin < (depth - EPSILON)){
                    depth = dmin;
                    axis.x = -(tx);
                    axis.y = -(ty);
                    axis.z = -(tz);
                }
            }
            return (false);
        }

        [Inline]
        final private function cross(a:Vector3D, b:Vector3D):Vector3D
        {
            crossAxis.x = ((a.y * b.z) - (a.z * b.y));
            crossAxis.y = ((a.z * b.x) - (a.x * b.z));
            crossAxis.z = ((a.x * b.y) - (a.y * b.x));
            return (crossAxis);
        }


    }
}

