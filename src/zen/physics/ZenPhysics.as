package zen.physics
{
	import zen.enums.ColliderShape;
	import zen.enums.*;
    import zen.physics.colliders.RayCollider;
    
    import flash.geom.Vector3D;
    import zen.physics.colliders.Collider;
    import zen.physics.test.NullCollision;
    import zen.physics.test.RaySphere;
    import zen.physics.test.RayBox;
    import zen.physics.test.RayMesh;
    import zen.physics.test.SphereSphere;
    import zen.physics.test.SphereBox;
    import zen.physics.test.SphereMesh;
    import zen.physics.test.BoxBox;
    import zen.physics.test.BoxMesh;
    import zen.physics.colliders.*;
    import zen.physics.test.*;
    import zen.display.*;
    import zen.shaders.textures.*;
    import zen.effects.*;
    import flash.geom.*;
    

    public class ZenPhysics 
    {

        private static const ray:RayCollider = new RayCollider();
        private static const raw:Vector.<Number> = new Vector.<Number>(16, true);
        private static const s:Vector3D = new Vector3D();
        public static const MAX_COLLIDERS:uint = 65536;
        public static const MAX_CONTACTS:uint = 65536;

        public static var allowOverlaping:Number = 0.2;
        public static var sleepingOverlap:Number = 0.02;

        public var gravity:Vector3D;
        public var colliders:Vector.<Collider>;
        private var _broad:IBroadPhase;
        private var _collisions:Vector.<ICollision>;
        private var _contacs:Vector.<Contact>;
        private var _contactData:Vector.<ContactData>;
        private var _numContacts:int;
        private var _dataIndex:int;

        public function ZenPhysics()
        {
            this.gravity = new Vector3D(0, -0.98, 0);
            super();
            this.colliders = new Vector.<Collider>();
            this._collisions = new Vector.<ICollision>(((ColliderShape.BOX + ColliderShape.MESH) + 1), true);
            this._collisions[(ColliderShape.NULL | ColliderShape.NULL)] = new NullCollision();
            this._collisions[(ColliderShape.NULL | ColliderShape.RAY)] = new NullCollision();
            this._collisions[(ColliderShape.NULL | ColliderShape.SPHERE)] = new NullCollision();
            this._collisions[(ColliderShape.NULL | ColliderShape.BOX)] = new NullCollision();
            this._collisions[(ColliderShape.NULL | ColliderShape.MESH)] = new NullCollision();
            this._collisions[(ColliderShape.RAY | ColliderShape.RAY)] = new NullCollision();
            this._collisions[(ColliderShape.RAY | ColliderShape.SPHERE)] = new RaySphere();
            this._collisions[(ColliderShape.RAY | ColliderShape.BOX)] = new RayBox();
            this._collisions[(ColliderShape.RAY | ColliderShape.MESH)] = new RayMesh();
            this._collisions[(ColliderShape.SPHERE | ColliderShape.SPHERE)] = new SphereSphere();
            this._collisions[(ColliderShape.SPHERE | ColliderShape.BOX)] = new SphereBox();
            this._collisions[(ColliderShape.SPHERE | ColliderShape.MESH)] = new SphereMesh();
            this._collisions[(ColliderShape.BOX | ColliderShape.BOX)] = new BoxBox();
            this._collisions[(ColliderShape.BOX | ColliderShape.MESH)] = new BoxMesh();
            this._collisions[(ColliderShape.MESH | ColliderShape.MESH)] = new NullCollision();
            this._broad = new SweepAndPrune(this._collisions);
            this._contacs = new Vector.<Contact>(MAX_CONTACTS, true);
            this._contactData = new Vector.<ContactData>(MAX_CONTACTS, true);
        }

        public function step(iterations:int=3, timeStep:Number=0.0555555555555556):void
        {
            this.updateColliders(timeStep);
            this.detectCollisions();
            if (iterations > 0){
                this.solveCollisions(iterations);
                this.solveColliders();
            }
        }

        private function updateColliders(timeStep:Number):void
        {
            var c:Collider;
            var collidersCount:int = this.colliders.length;
            var i:int;
            while (i < collidersCount) {
                c = this.colliders[i];
                c.numContacts = 0;
                c.contactGroups = 0;
                c.update(timeStep);
                i++;
            }
        }

        private function detectCollisions():void
        {
            this._numContacts = this._broad.test(this._contacs);
        }

        private function solveCollisions(precision:int):void
        {
            var i:int;
            var e:int;
            var c:Contact;
            var s0:Collider;
            var s1:Collider;
            this._dataIndex = 0;
            i = 0;
            while (i < this._numContacts) {
                c = this._contacs[i];
                c.preSolve();
                s0 = c.parent0;
                s1 = c.parent1;
                if (s0 != s1){
                    if (s0.collectContacts){
                        if (!(s0.contactData)){
                            s0.contactData = new Vector.<ContactData>();
                        }
                        s0.contactData[s0.numContacts] = this.addData(c, s1);
                    }
                    if (s1.collectContacts){
                        if (!(s1.contactData)){
                            s1.contactData = new Vector.<ContactData>();
                        }
                        s1.contactData[s1.numContacts] = this.addData(c, s0);
                    }
                    s0.contactGroups = (s0.contactGroups | s1.groups);
                    s1.contactGroups = (s1.contactGroups | s0.groups);
                    s0.numContacts++;
                    s1.numContacts++;
                }
                i++;
            }
            e = 0;
            while (e < precision) {
                i = 0;
                while (i < this._numContacts) {
                    this._contacs[i].solve();
                    i++;
                }
                e++;
            }
        }

        private function solveColliders():void
        {
            var c:Collider;
            var position:Vector3D;
            var orientation:Vector3D;
            var displacement:Vector3D;
            var disp:Number;
            var x:Number;
            var y:Number;
            var z:Number;
            var w:Number;
            var fTx:Number;
            var fTy:Number;
            var fTz:Number;
            var fTwx:Number;
            var fTwy:Number;
            var fTwz:Number;
            var fTxx:Number;
            var fTxy:Number;
            var fTxz:Number;
            var fTyy:Number;
            var fTyz:Number;
            var fTzz:Number;
            var numColliders:int = this.colliders.length;
            var i:int;
            while (i < numColliders) {
                c = this.colliders[i];
                if (((c.parent) || (c.isStatic))){
                } else {
                    position = c.position;
                    orientation = c.orientation;
                    displacement = c.displacement;
                    position.x = (position.x + displacement.x);
                    position.y = (position.y + displacement.y);
                    position.z = (position.z + displacement.z);
                    disp = displacement.lengthSquared;
                    displacement.x = 0;
                    displacement.y = 0;
                    displacement.z = 0;
                    if (((((c.sleeping) && ((disp < allowOverlaping)))) || (!(c.enabled)))){
                    } else {
                        x = orientation.x;
                        y = orientation.y;
                        z = orientation.z;
                        w = -(orientation.w);
                        fTx = (2 * x);
                        fTy = (2 * y);
                        fTz = (2 * z);
                        fTwx = (fTx * w);
                        fTwy = (fTy * w);
                        fTwz = (fTz * w);
                        fTxx = (fTx * x);
                        fTxy = (fTy * x);
                        fTxz = (fTz * x);
                        fTyy = (fTy * y);
                        fTyz = (fTz * y);
                        fTzz = (fTz * z);
                        raw[0] = (1 - (fTyy + fTzz));
                        raw[1] = (fTxy - fTwz);
                        raw[2] = (fTxz + fTwy);
                        raw[4] = (fTxy + fTwz);
                        raw[5] = (1 - (fTxx + fTzz));
                        raw[6] = (fTyz - fTwx);
                        raw[8] = (fTxz - fTwy);
                        raw[9] = (fTyz + fTwx);
                        raw[10] = (1 - (fTxx + fTyy));
                        raw[12] = position.x;
                        raw[13] = position.y;
                        raw[14] = position.z;
                        raw[15] = 1;
                        c.transform.copyRawDataFrom(raw);
                        if (c.pivot){
                            if (c.scaledPivot){
                                c.pivot.getScale(false, s);
                                c.pivot.world = c.transform;
                                c.pivot.transform.prependScale(s.x, s.y, s.z);
                            } else {
                                c.pivot.world = c.transform;
                            }
                        }
                    }
                }
                i++;
            }
        }

        public function rayCast(pos:Vector3D, dir:Vector3D, target:Collider, maxDistance:Number=1000):Contact
        {
            ray.position.copyFrom(pos);
            ray.dir.copyFrom(dir);
            ray.distance = maxDistance;
            var count:int = this.test(ray, target);
            if (count){
                return (this.contacts[0]);
            }
            return (null);
        }

        public function test(c0:Collider, c1:Collider, contactCount:int=0):int
        {
            c0.update(0);
            c1.update(0);
            if ((((((((((((c0.maxX < c1.minX)) || ((c0.minX > c1.maxX)))) || ((c0.maxY < c1.minY)))) || ((c0.minY > c1.maxY)))) || ((c0.maxZ < c1.minZ)))) || ((c0.minZ > c1.maxZ)))){
                return (contactCount);
            }
            if (c0.shape <= c1.shape){
                contactCount = this._collisions[(c0.shape | c1.shape)].test(c0, c1, this._contacs, contactCount);
            } else {
                contactCount = this._collisions[(c1.shape | c0.shape)].test(c1, c0, this._contacs, contactCount);
            }
            return (contactCount);
        }

        public function addCollider(collider:Collider):Collider
        {
            if (this.colliders.indexOf(collider) != -1){
                return (null);
            }
            if (this._broad.addCollider(collider)){
                this.colliders.push(collider);
            }
            collider.gravity = this.gravity;
            return (collider);
        }

        public function removeCollider(collider:Collider):void
        {
            var index:int = this.colliders.indexOf(collider);
            if (index != -1){
                this.colliders.splice(index, 1);
            }
            this._broad.removeCollider(collider);
        }

        public function get numContacts():int
        {
            return (this._numContacts);
        }

        public function get contacts():Vector.<Contact>
        {
            return (this._contacs);
        }

        public function debug(contacts:Boolean=true, aabb:Boolean=true, count:int=-1):void
        {
        }

        private function addData(info:Contact, collider:Collider):ContactData
        {
            if (!(this._contactData[this._dataIndex])){
                this._contactData[this._dataIndex] = new ContactData();
            }
            this._contactData[this._dataIndex].collider = collider;
            this._contactData[this._dataIndex].pivot = collider.pivot;
            this._contactData[this._dataIndex].info = info;
            return (this._contactData[this._dataIndex++]);
        }

        public function get axis():int
        {
            return (this._broad.axis);
        }

        public function set axis(value:int):void
        {
            this._broad.axis = value;
        }


    }
}

