package zen.physics
{
    
    import zen.physics.ICollision;
    import zen.physics.colliders.Collider;
    import zen.physics.ZenPhysics;
    import zen.physics.Contact;
    import zen.physics.*;
    import zen.physics.colliders.*;
    

    public class SweepAndPrune implements IBroadPhase 
    {

        private var _collisions:Vector.<ICollision>;
        private var _colliders:Vector.<Collider>;
        private var _axisVector:Vector.<Vector.<Collider>>;
        private var _sortAxis:int;
        private var _count:int;
        private var _axis:int = 0;

        public function SweepAndPrune(collisions:Vector.<ICollision>)
        {
            this._collisions = collisions;
            this._colliders = new Vector.<Collider>();
            this._axisVector = new Vector.<Vector.<Collider>>(3, true);
            this._axisVector[0] = new Vector.<Collider>(ZenPhysics.MAX_COLLIDERS, true);
            this._axisVector[1] = new Vector.<Collider>(ZenPhysics.MAX_COLLIDERS, true);
            this._axisVector[2] = new Vector.<Collider>(ZenPhysics.MAX_COLLIDERS, true);
        }

        public function addCollider(collider:Collider):Boolean
        {
            this._axisVector[0][this._count] = collider;
            this._axisVector[1][this._count] = collider;
            this._axisVector[2][this._count] = collider;
            this._colliders[this._count] = collider;
            this._count++;
            return (true);
        }

        public function removeCollider(collider:Collider):Boolean
        {
            this.removeFromAxis(collider, this._axisVector[0]);
            this.removeFromAxis(collider, this._axisVector[1]);
            this.removeFromAxis(collider, this._axisVector[2]);
            var index:int = this._colliders.indexOf(collider);
            if (index != -1){
                this._count--;
                this._colliders.splice(index, 1);
                return (true);
            }
            return (false);
        }

        private function removeFromAxis(collider:Collider, colliders:Vector.<Collider>):void
        {
            var idx:int = -1;
            var i:int;
            while (i < this._count) {
                if (colliders[i] == collider){
                    idx = i;
                    break;
                }
                i++;
            }
            if (idx == -1){
                return;
            }
            var j:int = idx;
            while (j < (this._count - 1)) {
                colliders[j] = colliders[(j + 1)];
                j++;
            }
            colliders[this._count] = null;
        }

        public function test(contacts:Vector.<Contact>):int
        {
            if (this._axis != -1){
                this._sortAxis = this._axis;
            }
            switch (this._sortAxis){
                case 0:
                    this.insertX(this._axisVector[0]);
                    return (this.sweepX(this._axisVector[0], contacts));
                case 1:
                    this.insertY(this._axisVector[1]);
                    return (this.sweepY(this._axisVector[1], contacts));
                case 2:
                    this.insertZ(this._axisVector[2]);
                    return (this.sweepZ(this._axisVector[2], contacts));
                default:
					
                    throw ((("Invalid axis (" + this._sortAxis) + ")"));
					
					return 0;
            }
        }

        private function sweepX(colliders:Vector.<Collider>, contacts:Vector.<Contact>):int
        {
            var c:Number;
            var s0:Collider;
            var j:int;
            var s1:Collider;
            var mx:Number = 0;
            var my:Number = 0;
            var mz:Number = 0;
            var mx2:Number = 0;
            var my2:Number = 0;
            var mz2:Number = 0;
            var numContacts:int;
            var i:int;
            while (i < this._count) {
                s0 = colliders[i];
                if (!!(s0.enabled)){
                    c = (s0.minX + s0.maxX);
                    mx = (mx + c);
                    mx2 = (mx2 + (c * c));
                    c = (s0.minY + s0.maxY);
                    my = (my + c);
                    my2 = (my2 + (c * c));
                    c = (s0.minZ + s0.maxZ);
                    mz = (mz + c);
                    mz2 = (mz2 + (c * c));
                    j = i;
                    while (++j < this._count) {
                        s1 = colliders[j];
                        if (s0.maxX < s1.minX){
                            break;
                        }
                        if (((s0.isStatic) && (s1.isStatic))){
                        } else {
                            if (((s0.sleeping) && (s1.sleeping))){
                            } else {
                                if (((((s0.parent) && (s1.parent))) && ((s0.parent == s1.parent)))){
                                } else {
                                    if ((s0.groups & s1.groups) == 0){
                                    } else {
                                        if ((((((((s0.maxY < s1.minY)) || ((s0.minY > s1.maxY)))) || ((s0.maxZ < s1.minZ)))) || ((s0.minZ > s1.maxZ)))){
                                        } else {
                                            if (s0.shape <= s1.shape){
                                                numContacts = this._collisions[(s0.shape | s1.shape)].test(s0, s1, contacts, numContacts);
                                            } else {
                                                numContacts = this._collisions[(s0.shape | s1.shape)].test(s1, s0, contacts, numContacts);
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
            var invNum:Number = (1 / this._count);
            mx = (mx2 - ((mx * mx) * invNum));
            my = (my2 - ((my * my) * invNum));
            mz = (mz2 - ((mz * mz) * invNum));
            if ((((mx > my)) && ((mx > mz)))){
                this._sortAxis = 0;
            } else {
                if ((((my > mx)) && ((my > mz)))){
                    this._sortAxis = 1;
                } else {
                    if ((((mz > mx)) && ((mz > my)))){
                        this._sortAxis = 2;
                    }
                }
            }
            return (numContacts);
        }

        private function sweepY(colliders:Vector.<Collider>, contacts:Vector.<Contact>):int
        {
            var c:Number;
            var s0:Collider;
            var j:int;
            var s1:Collider;
            var mx:Number = 0;
            var my:Number = 0;
            var mz:Number = 0;
            var mx2:Number = 0;
            var my2:Number = 0;
            var mz2:Number = 0;
            var numContacts:int;
            var i:int;
            while (i < this._count) {
                s0 = colliders[i];
                if (!!(s0.enabled)){
                    c = (s0.minX + s0.maxX);
                    mx = (mx + c);
                    mx2 = (mx2 + (c * c));
                    c = (s0.minY + s0.maxY);
                    my = (my + c);
                    my2 = (my2 + (c * c));
                    c = (s0.minZ + s0.maxZ);
                    mz = (mz + c);
                    mz2 = (mz2 + (c * c));
                    j = i;
                    while (++j < this._count) {
                        s1 = colliders[j];
                        if (s0.maxY < s1.minY){
                            break;
                        }
                        if (((s0.isStatic) && (s1.isStatic))){
                        } else {
                            if (((s0.sleeping) && (s1.sleeping))){
                            } else {
                                if (((((s0.parent) && (s1.parent))) && ((s0.parent == s1.parent)))){
                                } else {
                                    if ((s0.groups & s1.groups) == 0){
                                    } else {
                                        if ((((((((s0.maxX < s1.minX)) || ((s0.minX > s1.maxX)))) || ((s0.maxZ < s1.minZ)))) || ((s0.minZ > s1.maxZ)))){
                                        } else {
                                            if (s0.shape <= s1.shape){
                                                numContacts = this._collisions[(s0.shape | s1.shape)].test(s0, s1, contacts, numContacts);
                                            } else {
                                                numContacts = this._collisions[(s0.shape | s1.shape)].test(s1, s0, contacts, numContacts);
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
            var invNum:Number = (1 / this._count);
            mx = (mx2 - ((mx * mx) * invNum));
            my = (my2 - ((my * my) * invNum));
            mz = (mz2 - ((mz * mz) * invNum));
            if ((((mx > my)) && ((mx > mz)))){
                this._sortAxis = 0;
            } else {
                if ((((my > mx)) && ((my > mz)))){
                    this._sortAxis = 1;
                } else {
                    if ((((mz > mx)) && ((mz > my)))){
                        this._sortAxis = 2;
                    }
                }
            }
            return (numContacts);
        }

        private function sweepZ(colliders:Vector.<Collider>, contacts:Vector.<Contact>):int
        {
            var c:Number;
            var s0:Collider;
            var j:int;
            var s1:Collider;
            var mx:Number = 0;
            var my:Number = 0;
            var mz:Number = 0;
            var mx2:Number = 0;
            var my2:Number = 0;
            var mz2:Number = 0;
            var numContacts:int;
            var i:int;
            while (i < this._count) {
                s0 = colliders[i];
                if (!!(s0.enabled)){
                    c = (s0.minX + s0.maxX);
                    mx = (mx + c);
                    mx2 = (mx2 + (c * c));
                    c = (s0.minY + s0.maxY);
                    my = (my + c);
                    my2 = (my2 + (c * c));
                    c = (s0.minZ + s0.maxZ);
                    mz = (mz + c);
                    mz2 = (mz2 + (c * c));
                    j = i;
                    while (++j < this._count) {
                        s1 = colliders[j];
                        if (s0.maxZ < s1.minZ){
                            break;
                        }
                        if (((s0.isStatic) && (s1.isStatic))){
                        } else {
                            if (((s0.sleeping) && (s1.sleeping))){
                            } else {
                                if (((((s0.parent) && (s1.parent))) && ((s0.parent == s1.parent)))){
                                } else {
                                    if ((s0.groups & s1.groups) == 0){
                                    } else {
                                        if ((((((((s0.maxY < s1.minY)) || ((s0.minY > s1.maxY)))) || ((s0.maxX < s1.minX)))) || ((s0.minX > s1.maxX)))){
                                        } else {
                                            if (s0.shape <= s1.shape){
                                                numContacts = this._collisions[(s0.shape | s1.shape)].test(s0, s1, contacts, numContacts);
                                            } else {
                                                numContacts = this._collisions[(s0.shape | s1.shape)].test(s1, s0, contacts, numContacts);
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
            var invNum:Number = (1 / this._count);
            mx = (mx2 - ((mx * mx) * invNum));
            my = (my2 - ((my * my) * invNum));
            mz = (mz2 - ((mz * mz) * invNum));
            if ((((mx > my)) && ((mx > mz)))){
                this._sortAxis = 0;
            } else {
                if ((((my > mx)) && ((my > mz)))){
                    this._sortAxis = 1;
                } else {
                    if ((((mz > mx)) && ((mz > my)))){
                        this._sortAxis = 2;
                    }
                }
            }
            return (numContacts);
        }

        private function insertX(colliders:Vector.<Collider>):void
        {
            var i:int;
            var j:int;
            var e:int;
            var min:Number;
            var collider:Collider;
            i = 1;
            while (i < this._count) {
                collider = colliders[i];
                j = (i - 1);
                e = i;
                min = collider.minX;
                while ((((j >= 0)) && ((colliders[j].minX > min)))) {
                    var _local7 = e--;
                    colliders[_local7] = colliders[j--];
                }
                colliders[e] = collider;
                i++;
            }
        }

        private function insertY(colliders:Vector.<Collider>):void
        {
            var i:int;
            var j:int;
            var e:int;
            var min:Number;
            var collider:Collider;
            i = 1;
            while (i < this._count) {
                collider = colliders[i];
                j = (i - 1);
                e = i;
                min = collider.minY;
                while ((((j >= 0)) && ((colliders[j].minY > min)))) {
                    var _local7 = e--;
                    colliders[_local7] = colliders[j--];
                }
                colliders[e] = collider;
                i++;
            }
        }

        private function insertZ(colliders:Vector.<Collider>):void
        {
            var i:int;
            var j:int;
            var e:int;
            var min:Number;
            var collider:Collider;
            i = 1;
            while (i < this._count) {
                collider = colliders[i];
                j = (i - 1);
                e = i;
                min = collider.minZ;
                while ((((j >= 0)) && ((colliders[j].minZ > min)))) {
                    var _local7 = e--;
                    colliders[_local7] = colliders[j--];
                }
                colliders[e] = collider;
                i++;
            }
        }

        public function get axis():int
        {
            return (this._axis);
        }

        public function set axis(value:int):void
        {
            this._axis = value;
        }


    }
}

