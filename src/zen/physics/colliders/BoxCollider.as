package zen.physics.colliders
{
    
	import zen.enums.*;
    import flash.geom.Vector3D;
    import zen.physics.test.AxisInfo;
    import zen.intersects.*;
    import zen.physics.*;
    import zen.physics.test.*;
    import flash.geom.*;
    

    public class BoxCollider extends Collider 
    {

        public var width:Number;
        public var height:Number;
        public var depth:Number;
        public var halfWidth:Number;
        public var halfHeight:Number;
        public var halfDepth:Number;
        public var vertex:Vector.<Vector3D>;
        public var axisX:Vector3D;
        public var axisY:Vector3D;
        public var axisZ:Vector3D;
        public var radius:Number;

        public function BoxCollider(width:Number, height:Number, depth:Number)
        {
            this.vertex = new Vector.<Vector3D>(8, true);
            super();
            this.shape = ColliderShape.BOX;
            this.width = width;
            this.height = height;
            this.depth = depth;
            this.halfWidth = (width * 0.5);
            this.halfHeight = (height * 0.5);
            this.halfDepth = (depth * 0.5);
            this.radius = Math.sqrt((((this.halfWidth * this.halfWidth) + (this.halfHeight * this.halfHeight)) + (this.halfDepth * this.halfDepth)));
            this.vertex[0] = new Vector3D();
            this.vertex[1] = new Vector3D();
            this.vertex[2] = new Vector3D();
            this.vertex[3] = new Vector3D();
            this.vertex[4] = new Vector3D();
            this.vertex[5] = new Vector3D();
            this.vertex[6] = new Vector3D();
            this.vertex[7] = new Vector3D();
            this.axisX = new Vector3D();
            this.axisY = new Vector3D();
            this.axisZ = new Vector3D();
            this.setMass(1);
        }

        final override public function setMass(mass:Number):void
        {
            var i:Number;
            var w:Number;
            var h:Number;
            var d:Number;
            super.setMass(mass);
            if (mass > 0){
                i = (mass / 12);
                w = this.width;
                h = this.height;
                d = this.depth;
                invLocalInertia.copyRawDataFrom(Vector.<Number>([(i * ((h * h) + (d * d))), 0, 0, 0, 0, (i * ((w * w) + (d * d))), 0, 0, 0, 0, (i * ((w * w) + (h * h))), 0, 1, 1, 1, 1]));
                invLocalInertia.invert();
            } else {
                invLocalInertia.rawData = new Vector.<Number>(16, true);
            }
        }

        final override public function update(timeStep:Number):void
        {
            super.update(timeStep);
            transform.copyColumnTo(0, this.axisX);
            transform.copyColumnTo(1, this.axisY);
            transform.copyColumnTo(2, this.axisZ);
            var x:Number = position.x;
            var y:Number = position.y;
            var z:Number = position.z;
            var wx:Number = (this.axisX.x * this.halfWidth);
            var wy:Number = (this.axisX.y * this.halfWidth);
            var wz:Number = (this.axisX.z * this.halfWidth);
            var hx:Number = (this.axisY.x * this.halfHeight);
            var hy:Number = (this.axisY.y * this.halfHeight);
            var hz:Number = (this.axisY.z * this.halfHeight);
            var dx:Number = (this.axisZ.x * this.halfDepth);
            var dy:Number = (this.axisZ.y * this.halfDepth);
            var dz:Number = (this.axisZ.z * this.halfDepth);
            this.vertex[0].x = (((x - wx) + hx) - dx);
            this.vertex[0].y = (((y - wy) + hy) - dy);
            this.vertex[0].z = (((z - wz) + hz) - dz);
            this.vertex[1].x = (((x - wx) - hx) - dx);
            this.vertex[1].y = (((y - wy) - hy) - dy);
            this.vertex[1].z = (((z - wz) - hz) - dz);
            this.vertex[2].x = (((x + wx) - hx) - dx);
            this.vertex[2].y = (((y + wy) - hy) - dy);
            this.vertex[2].z = (((z + wz) - hz) - dz);
            this.vertex[3].x = (((x + wx) + hx) - dx);
            this.vertex[3].y = (((y + wy) + hy) - dy);
            this.vertex[3].z = (((z + wz) + hz) - dz);
            this.vertex[4].x = (((x - wx) + hx) + dx);
            this.vertex[4].y = (((y - wy) + hy) + dy);
            this.vertex[4].z = (((z - wz) + hz) + dz);
            this.vertex[5].x = (((x - wx) - hx) + dx);
            this.vertex[5].y = (((y - wy) - hy) + dy);
            this.vertex[5].z = (((z - wz) - hz) + dz);
            this.vertex[6].x = (((x + wx) - hx) + dx);
            this.vertex[6].y = (((y + wy) - hy) + dy);
            this.vertex[6].z = (((z + wz) - hz) + dz);
            this.vertex[7].x = (((x + wx) + hx) + dx);
            this.vertex[7].y = (((y + wy) + hy) + dy);
            this.vertex[7].z = (((z + wz) + hz) + dz);
            if (wx < 0){
                wx = -(wx);
            }
            if (wy < 0){
                wy = -(wy);
            }
            if (wz < 0){
                wz = -(wz);
            }
            if (hx < 0){
                hx = -(hx);
            }
            if (hy < 0){
                hy = -(hy);
            }
            if (hz < 0){
                hz = -(hz);
            }
            if (dx < 0){
                dx = -(dx);
            }
            if (dy < 0){
                dy = -(dy);
            }
            if (dz < 0){
                dz = -(dz);
            }
            minX = (((position.x - wx) - hx) - dx);
            minY = (((position.y - wy) - hy) - dy);
            minZ = (((position.z - wz) - hz) - dz);
            maxX = (((position.x + wx) + hx) + dx);
            maxY = (((position.y + wy) + hy) + dy);
            maxZ = (((position.z + wz) + hz) + dz);
        }

        final override public function project(axis:Vector3D, info:AxisInfo):void
        {
            var x:Number = axis.x;
            var y:Number = axis.y;
            var z:Number = axis.z;
            var l0:Number = (((this.axisX.x * x) + (this.axisX.y * y)) + (this.axisX.z * z));
            var l1:Number = (((this.axisY.x * x) + (this.axisY.y * y)) + (this.axisY.z * z));
            var l2:Number = (((this.axisZ.x * x) + (this.axisZ.y * y)) + (this.axisZ.z * z));
            if (l0 < 0){
                l0 = -(l0);
            }
            if (l1 < 0){
                l1 = -(l1);
            }
            if (l2 < 0){
                l2 = -(l2);
            }
            var len:Number = (((l0 * this.halfWidth) + (l1 * this.halfHeight)) + (l2 * this.halfDepth));
            var pos:Number = (((position.x * x) + (position.y * y)) + (position.z * z));
            info.min = (pos - len);
            info.max = (pos + len);
        }

        final override public function getSupportPoints(axis:Vector3D, out:Vector.<Vector3D>):int
        {
            var fx:Number;
            fx = axis.dotProduct(this.axisX);
            var fy:Number = axis.dotProduct(this.axisY);
            var fz:Number = axis.dotProduct(this.axisZ);
            var afx:Number = (((fx < 0)) ? -(fx) : fx);
            var afy:Number = (((fy < 0)) ? -(fy) : fy);
            var afz:Number = (((fz < 0)) ? -(fz) : fz);
            if (afx > afy){
                if (afx > afz){
                    if (fx > 0){
                        out[0] = this.vertex[0];
                        out[1] = this.vertex[1];
                        out[2] = this.vertex[5];
                        out[3] = this.vertex[4];
                    } else {
                        out[0] = this.vertex[7];
                        out[1] = this.vertex[6];
                        out[2] = this.vertex[2];
                        out[3] = this.vertex[3];
                    }
                } else {
                    if (fz > 0){
                        out[0] = this.vertex[3];
                        out[1] = this.vertex[2];
                        out[2] = this.vertex[1];
                        out[3] = this.vertex[0];
                    } else {
                        out[0] = this.vertex[4];
                        out[1] = this.vertex[5];
                        out[2] = this.vertex[6];
                        out[3] = this.vertex[7];
                    }
                }
            } else {
                if (afy > afz){
                    if (fy > 0){
                        out[0] = this.vertex[6];
                        out[1] = this.vertex[5];
                        out[2] = this.vertex[1];
                        out[3] = this.vertex[2];
                    } else {
                        out[0] = this.vertex[4];
                        out[1] = this.vertex[7];
                        out[2] = this.vertex[3];
                        out[3] = this.vertex[0];
                    }
                } else {
                    if (fz > 0){
                        out[0] = this.vertex[3];
                        out[1] = this.vertex[2];
                        out[2] = this.vertex[1];
                        out[3] = this.vertex[0];
                    } else {
                        out[0] = this.vertex[4];
                        out[1] = this.vertex[5];
                        out[2] = this.vertex[6];
                        out[3] = this.vertex[7];
                    }
                }
            }
            return (4);
        }

        override public function clone():Collider
        {
            var collider:BoxCollider = new BoxCollider(this.width, this.height, this.depth);
            collider.isStatic = isStatic;
            collider.isRigidBody = isRigidBody;
            collider.isTrigger = isTrigger;
            collider.setMass(mass);
            collider.enabled = enabled;
            collider.groups = groups;
            collider.collectContacts = collectContacts;
            collider.gravity = gravity;
            collider.neverSleep = neverSleep;
            collider.sleepingFactor = sleepingFactor;
            if (sleeping){
                collider.sleep();
            }
            return (collider);
        }


    }
}

