import zen.display.*;
package zen.physics.colliders
{
    
	import zen.enums.*;
    import flash.geom.Vector3D;
    import zen.ZenObject;
    import flash.geom.Matrix3D;
    import zen.display.*;
    import zen.physics.ContactData;
    import zen.physics.ZenPhysics;
    import zen.physics.test.AxisInfo;
    import zen.physics.*;
    import zen.display.*;
    import zen.physics.test.*;
    import zen.utils.*;
    import flash.geom.*;
    import flash.utils.*;
    

    public class Collider implements IShape 
    {

        private static const raw:Vector.<Number> = new Vector.<Number>(16, true);
        private static const zero:Vector.<Number> = new Vector.<Number>(16, true);
        private static const scale:Vector3D = new Vector3D();

        public var shape:int;
        public var minX:Number = 0;
        public var minY:Number = 0;
        public var minZ:Number = 0;
        public var maxX:Number = 0;
        public var maxY:Number = 0;
        public var maxZ:Number = 0;
        public var pivot:ZenObject;
        public var isTrigger:Boolean = false;
        public var isStatic:Boolean = false;
        public var isRigidBody:Boolean = false;
        public var mass:Number = 1;
        public var invMass:Number = 1;
        public var groups:uint = 1;
        public var parent:Collider;
        public var transform:Matrix3D;
        public var invTransform:Matrix3D;
        public var invInertia:Matrix3D;
        public var invLocalInertia:Matrix3D;
        public var position:Vector3D;
        public var orientation:Vector3D;
        public var linearVelocity:Vector3D;
        public var angularVelocity:Vector3D;
        public var displacement:Vector3D;
        public var numContacts:int;
        public var collectContacts:Boolean = false;
        public var contactData:Vector.<ContactData>;
        public var contactGroups:uint;
        public var gravity:Vector3D;
        public var friction:Number = 1;
        public var restitution:Number = 0;
        public var sleeping:Boolean = false;
        public var neverSleep:Boolean = false;
        public var sleepingFactor:Number = 0.9;
        public var enabled:Boolean = true;
        public var scaledPivot:Boolean = true;
        private var sleepingMotion:Number = 200;
        private var prevPosition:Vector3D;

        public function Collider()
        {
            this.shape = ColliderShape.NULL;
            super();
            this.shape = ColliderShape.NULL;
            this.transform = new Matrix3D();
            this.invTransform = new Matrix3D();
            this.invInertia = new Matrix3D();
            this.invLocalInertia = new Matrix3D();
            this.position = new Vector3D(0, 0, 0, 1);
            this.orientation = new Vector3D(0, 0, 0, 1);
            this.linearVelocity = new Vector3D();
            this.angularVelocity = new Vector3D();
            this.displacement = new Vector3D();
            this.setMass(this.mass);
        }

        private static function matrixToQuat(m:Matrix3D, quat:Vector3D):void
        {
            m.copyRawDataTo(raw);
            quat.w = (Math.sqrt(Math.max(0, (((1 + raw[0]) + raw[5]) + raw[10]))) * 0.5);
            quat.x = (Math.sqrt(Math.max(0, (((1 + raw[0]) - raw[5]) - raw[10]))) * 0.5);
            quat.y = (Math.sqrt(Math.max(0, (((1 - raw[0]) + raw[5]) - raw[10]))) * 0.5);
            quat.z = (Math.sqrt(Math.max(0, (((1 - raw[0]) - raw[5]) + raw[10]))) * 0.5);
            quat.x = ((((raw[6] - raw[9]) < 0)) ? (((quat.x < 0)) ? quat.x : -(quat.x)) : (((quat.x < 0)) ? -(quat.x) : quat.x));
            quat.y = ((((raw[8] - raw[2]) < 0)) ? (((quat.y < 0)) ? quat.y : -(quat.y)) : (((quat.y < 0)) ? -(quat.y) : quat.y));
            quat.z = ((((raw[1] - raw[4]) < 0)) ? (((quat.z < 0)) ? quat.z : -(quat.z)) : (((quat.z < 0)) ? -(quat.z) : quat.z));
        }


        public function setMass(mass:Number):void
        {
            this.mass = mass;
            if (mass > 0){
                this.invMass = (1 / mass);
            } else {
                this.invMass = 0;
            }
        }

        public function constrainLocalRotation(x:Number=1, y:Number=1, z:Number=1):void
        {
            this.setMass(this.mass);
            this.invLocalInertia.copyRawDataTo(raw);
            if (x == 0){
                raw[0] = 0;
            } else {
                raw[0] = (raw[0] / x);
            }
            if (y == 0){
                raw[5] = 0;
            } else {
                raw[5] = (raw[5] / y);
            }
            if (z == 0){
                raw[10] = 0;
            } else {
                raw[10] = (raw[10] / z);
            }
            this.invLocalInertia.copyRawDataFrom(raw);
        }

        public function updateInertia():void
        {
            var c:Collider;
            var xy:Number;
            var yz:Number;
            var zx:Number;
            var e01:uint;
            var e10:uint;
            var e02:uint;
            var e20:uint;
            var e12:uint;
            var e21:uint;
            var i:int;
            var relPos:Vector3D;
            var children:Vector.<Collider> = this.collect(this.pivot);
            var mass:Number = 0;
            var inv:Matrix3D = this.pivot.invWorld;
            var rawData:Vector.<Number> = new Vector.<Number>(16, true);
            for each (c in children) {
                mass = (mass + c.mass);
                c.invLocalInertia.copyRawDataTo(raw);
                i = 0;
                while (i < 16) {
                    rawData[i] = (rawData[i] + raw[i]);
                    i++;
                }
            }
            xy = 0;
            yz = 0;
            zx = 0;
            for each (c in children) {
                relPos = c.pivot.getPosition();
                rawData[0] = (rawData[0] + (c.mass * ((relPos.y * relPos.y) + (relPos.z * relPos.z))));
                rawData[5] = (rawData[5] + (c.mass * ((relPos.x * relPos.x) + (relPos.z * relPos.z))));
                rawData[10] = (rawData[10] + (c.mass * ((relPos.x * relPos.x) + (relPos.y * relPos.y))));
                xy = (xy - ((c.mass * relPos.x) * relPos.y));
                yz = (yz - ((c.mass * relPos.y) * relPos.z));
                zx = (zx - ((c.mass * relPos.z) * relPos.x));
            }
            e01 = 1;
            e10 = 4;
            e02 = 2;
            e20 = 8;
            e12 = 6;
            e21 = 9;
            rawData[e01] = xy;
            rawData[e10] = xy;
            rawData[e02] = zx;
            rawData[e20] = zx;
            rawData[e12] = yz;
            rawData[e21] = yz;
            this.mass = mass;
            this.invMass = (1 / mass);
            this.invLocalInertia.copyRawDataFrom(rawData);
            this.invLocalInertia.invert();
        }

        private function collect(p:ZenObject, children:Vector.<Collider>=null):Vector.<Collider>
        {
            var c:ZenObject;
            children = ((children) || (new Vector.<Collider>()));
            if (p.collider){
                children.push(p.collider);
            }
            for each (c in p.children) {
                this.collect(c, children);
            }
            return (children);
        }

        public function dispose():void
        {
        }

        public function update(timeStep:Number):void
        {
            var sx:Number;
            var sy:Number;
            var sz:Number;
            var d:Number;
            var p:Number;
            var dx:Number;
            var dy:Number;
            var dz:Number;
            var f:Number;
            var vx:Number;
            var vy:Number;
            var vz:Number;
            var os:Number;
            var ox:Number;
            var oy:Number;
            var oz:Number;
            var s:Number;
            var x:Number;
            var y:Number;
            var z:Number;
            if (this.isTrigger){
                this.isStatic = true;
            }
            if (this.isStatic){
                this.isRigidBody = false;
            }
            if (this.pivot){
                this.transform.copyFrom(this.pivot.world);
                if (this.scaledPivot){
                    this.pivot.getScale(false, scale);
                    sx = scale.x;
                    sy = scale.y;
                    sz = scale.z;
                    d = ((sx * sy) * sz);
                    if ((((d > 0.999)) && ((d < 1.001)))){
                        this.scaledPivot = false;
                    }
                    this.transform.copyRawDataTo(raw);
                    sx = (1 / Math.sqrt((((raw[0] * raw[0]) + (raw[1] * raw[1])) + (raw[2] * raw[2]))));
                    sy = (1 / Math.sqrt((((raw[4] * raw[4]) + (raw[5] * raw[5])) + (raw[6] * raw[6]))));
                    sz = (1 / Math.sqrt((((raw[8] * raw[8]) + (raw[9] * raw[9])) + (raw[10] * raw[10]))));
                    raw[0] = (raw[0] * sx);
                    raw[1] = (raw[1] * sx);
                    raw[2] = (raw[2] * sx);
                    raw[4] = (raw[4] * sy);
                    raw[5] = (raw[5] * sy);
                    raw[6] = (raw[6] * sy);
                    raw[8] = (raw[8] * sz);
                    raw[9] = (raw[9] * sz);
                    raw[10] = (raw[10] * sz);
                    this.transform.copyRawDataFrom(raw);
                }
                this.transform.copyColumnTo(3, this.position);
                matrixToQuat(this.transform, this.orientation);
            }
            if (!(this.enabled)){
                return;
            }
            this.invTransform.copyFrom(this.transform);
            this.invTransform.invert();
            if ((((timeStep == 0)) || (this.parent))){
                return;
            }
            if (!(this.prevPosition)){
                this.prevPosition = this.position.clone();
            }
            if (this.isStatic){
                this.invMass = 0;
                this.mass = 0;
                this.invInertia.copyRawDataFrom(zero);
                this.invLocalInertia.copyRawDataFrom(zero);
                this.sleeping = true;
            } else {
                if (this.neverSleep){
                    this.sleeping = false;
                } else {
                    p = ZenPhysics.sleepingOverlap;
                    dx = (this.prevPosition.x - this.position.x);
                    dy = (this.prevPosition.y - this.position.y);
                    dz = (this.prevPosition.z - this.position.z);
                    f = (((dx * dx) + (dy * dy)) + (dz * dz));
                    if (f > p){
                        this.sleepingMotion = 200;
                    }
                    this.sleepingMotion = (this.sleepingMotion * this.sleepingFactor);
                    if (this.sleepingMotion > 1){
                        if (this.sleeping){
                            this.linearVelocity.scaleBy(0);
                            this.angularVelocity.scaleBy(0);
                        }
                        this.sleeping = false;
                    } else {
                        this.sleeping = true;
                    }
                }
            }
            this.prevPosition.x = this.position.x;
            this.prevPosition.y = this.position.y;
            this.prevPosition.z = this.position.z;
            if (((((((!(this.parent)) && (!(this.sleeping)))) && (this.isRigidBody))) && ((timeStep > 0)))){
                this.linearVelocity.x = (this.linearVelocity.x + this.gravity.x);
                this.linearVelocity.y = (this.linearVelocity.y + this.gravity.y);
                this.linearVelocity.z = (this.linearVelocity.z + this.gravity.z);
                this.invInertia.copyFrom(this.invTransform);
                this.invInertia.append(this.invLocalInertia);
                this.invInertia.append(this.transform);
                vx = (this.linearVelocity.x * timeStep);
                vy = (this.linearVelocity.y * timeStep);
                vz = (this.linearVelocity.z * timeStep);
                this.position.x = (this.position.x + vx);
                this.position.y = (this.position.y + vy);
                this.position.z = (this.position.z + vz);
                vx = this.angularVelocity.x;
                vy = this.angularVelocity.y;
                vz = this.angularVelocity.z;
                os = this.orientation.w;
                ox = this.orientation.x;
                oy = this.orientation.y;
                oz = this.orientation.z;
                timeStep = (timeStep * 0.5);
                s = ((((-(vx) * ox) - (vy * oy)) - (vz * oz)) * timeStep);
                x = ((((vx * os) + (vy * oz)) - (vz * oy)) * timeStep);
                y = ((((-(vx) * oz) + (vy * os)) + (vz * ox)) * timeStep);
                z = ((((vx * oy) - (vy * ox)) + (vz * os)) * timeStep);
                os = (os + s);
                ox = (ox + x);
                oy = (oy + y);
                oz = (oz + z);
                s = (1 / Math.sqrt(((((os * os) + (ox * ox)) + (oy * oy)) + (oz * oz))));
                this.orientation.x = (ox * s);
                this.orientation.y = (oy * s);
                this.orientation.z = (oz * s);
                this.orientation.w = (os * s);
            }
            this.minX = this.position.x;
            this.minY = this.position.y;
            this.minZ = this.position.z;
            this.maxX = this.position.x;
            this.maxY = this.position.y;
            this.maxZ = this.position.z;
        }

        public function project(axis:Vector3D, info:AxisInfo):void
        {
            info.max = 0;
            info.min = 0;
        }

        public function getSupportPoints(axis:Vector3D, out:Vector.<Vector3D>):int
        {
            return (0);
        }

        public function awake():void
        {
            this.sleeping = false;
            this.sleepingMotion = 200;
        }

        public function sleep():void
        {
            this.sleeping = true;
            this.sleepingMotion = 0;
        }

        public function resetVelocities():void
        {
            this.linearVelocity.scaleBy(0);
            this.angularVelocity.scaleBy(0);
        }

        public function applyTorque(x:Number, y:Number, z:Number):void
        {
            this.invInertia.copyRawDataTo(raw);
            var rx:Number = (((x * raw[0]) + (y * raw[4])) + (z * raw[8]));
            var ry:Number = (((x * raw[1]) + (y * raw[5])) + (z * raw[9]));
            var rz:Number = (((x * raw[2]) + (y * raw[6])) + (z * raw[10]));
            this.angularVelocity.x = (this.angularVelocity.x + rx);
            this.angularVelocity.y = (this.angularVelocity.y + ry);
            this.angularVelocity.z = (this.angularVelocity.z + rz);
        }

        public function applyLocalTorque(x:Number, y:Number, z:Number):void
        {
            var tx:Number;
            var ty:Number;
            var tz:Number;
            this.transform.copyRawDataTo(raw);
            tx = (((x * raw[0]) + (y * raw[4])) + (z * raw[8]));
            ty = (((x * raw[1]) + (y * raw[5])) + (z * raw[9]));
            tz = (((x * raw[2]) + (y * raw[6])) + (z * raw[10]));
            this.invInertia.copyRawDataTo(raw);
            var rx:Number = (((tx * raw[0]) + (ty * raw[4])) + (tz * raw[8]));
            var ry:Number = (((tx * raw[1]) + (ty * raw[5])) + (tz * raw[9]));
            var rz:Number = (((tx * raw[2]) + (ty * raw[6])) + (tz * raw[10]));
            this.angularVelocity.x = (this.angularVelocity.x + rx);
            this.angularVelocity.y = (this.angularVelocity.y + ry);
            this.angularVelocity.z = (this.angularVelocity.z + rz);
        }

        public function applyImpulse(x:Number, y:Number, z:Number, position:Vector3D=null):void
        {
            var cx:Number;
            var cy:Number;
            var cz:Number;
            var rx:Number;
            var ry:Number;
            var rz:Number;
            this.linearVelocity.x = (this.linearVelocity.x + (x * this.invMass));
            this.linearVelocity.y = (this.linearVelocity.y + (y * this.invMass));
            this.linearVelocity.z = (this.linearVelocity.z + (z * this.invMass));
            if (position){
                this.invInertia.copyRawDataTo(raw);
                cx = ((position.y * z) - (position.z * y));
                cy = ((position.z * x) - (position.x * z));
                cz = ((position.x * y) - (position.y * x));
                rx = (((cx * raw[0]) + (cy * raw[4])) + (cz * raw[8]));
                ry = (((cx * raw[1]) + (cy * raw[5])) + (cz * raw[9]));
                rz = (((cx * raw[2]) + (cy * raw[6])) + (cz * raw[10]));
                this.angularVelocity.x = (this.angularVelocity.x + rx);
                this.angularVelocity.y = (this.angularVelocity.y + ry);
                this.angularVelocity.z = (this.angularVelocity.z + rz);
            }
        }

        public function applyLocalImpulse(x:Number, y:Number, z:Number, position:Vector3D=null):void
        {
            var px:Number;
            var py:Number;
            var pz:Number;
            var cx:Number;
            var cy:Number;
            var cz:Number;
            var rx:Number;
            var ry:Number;
            var rz:Number;
            this.transform.copyRawDataTo(raw);
            var fx:Number = (((x * raw[0]) + (y * raw[4])) + (z * raw[8]));
            var fy:Number = (((x * raw[1]) + (y * raw[5])) + (z * raw[9]));
            var fz:Number = (((x * raw[2]) + (y * raw[6])) + (z * raw[10]));
            this.linearVelocity.x = (this.linearVelocity.x + (fx * this.invMass));
            this.linearVelocity.y = (this.linearVelocity.y + (fy * this.invMass));
            this.linearVelocity.z = (this.linearVelocity.z + (fz * this.invMass));
            if (position){
                px = (((position.x * raw[0]) + (position.y * raw[4])) + (position.z * raw[8]));
                py = (((position.x * raw[1]) + (position.y * raw[5])) + (position.z * raw[9]));
                pz = (((position.x * raw[2]) + (position.y * raw[6])) + (position.z * raw[10]));
                this.invInertia.copyRawDataTo(raw);
                cx = ((py * z) - (pz * y));
                cy = ((pz * x) - (px * z));
                cz = ((px * y) - (py * x));
                rx = (((cx * raw[0]) + (cy * raw[4])) + (cz * raw[8]));
                ry = (((cx * raw[1]) + (cy * raw[5])) + (cz * raw[9]));
                rz = (((cx * raw[2]) + (cy * raw[6])) + (cz * raw[10]));
                this.angularVelocity.x = (this.angularVelocity.x + rx);
                this.angularVelocity.y = (this.angularVelocity.y + ry);
                this.angularVelocity.z = (this.angularVelocity.z + rz);
            }
        }

        public function clone():Collider
        {
            var collider:Collider = new Collider();
            collider.isStatic = this.isStatic;
            collider.isRigidBody = this.isRigidBody;
            collider.isTrigger = this.isTrigger;
            collider.setMass(this.mass);
            collider.enabled = this.enabled;
            collider.groups = this.groups;
            collider.collectContacts = this.collectContacts;
            collider.gravity = this.gravity;
            collider.neverSleep = this.neverSleep;
            collider.sleepingFactor = this.sleepingFactor;
            if (this.sleeping){
                collider.sleep();
            }
            return (collider);
        }


    }
}

