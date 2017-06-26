package zen.physics.colliders
{
    
	import zen.enums.*;
    import zen.physics.geom.*;
	import zen.geom.*;
	import zen.display.*;
    import flash.geom.*;
    import zen.Cube3D;
    import zen.display.*;
    import zen.shaders.textures.*;
    import flash.utils.Dictionary;
    import zen.display.*;
    import zen.shaders.textures.*;
    import zen.physics.geom.*;
    import zen.utils.*;
    import flash.geom.*;
    import flash.utils.*;
    

    public class MeshCollider extends Collider 
    {

        private static const raw:Vector.<Number> = new Vector.<Number>(16, true);

        private var _tris:Vector.<Tri3D>;
        private var _vertices:Vector.<LinkedVector3D>;
        private var _edges:Vector.<TriEdge3D>;
        private var _bvh:PhysicsNode3D;
        private var _mesh:ZenMesh;
        private var _edgeThreshold:Number = 0.9;
        private var _max:Vector3D;
        private var _min:Vector3D;
        private var _length:Vector3D;
        private var _center:Vector3D;
        private var _bounds:Cube3D;
        private var _radius:Number;
        private var _tests:uint;

        public function MeshCollider(mesh:ZenMesh)
        {
            this._max = new Vector3D();
            this._min = new Vector3D();
            this._length = new Vector3D();
            this._center = new Vector3D();
            this._bounds = new Cube3D();
            super();
            this.shape = ColliderShape.MESH;
            this.setMesh(mesh);
            this.isStatic = true;
            this.setMass(1);
        }

        override public function update(timeStep:Number):void
        {
            if (isRigidBody){
                isStatic = true;
            }
            super.update(timeStep);
            this._mesh.getBounds(this._mesh.scene, false, this._bounds);
            minX = this._bounds.min.x;
            minY = this._bounds.min.y;
            minZ = this._bounds.min.z;
            maxX = this._bounds.max.x;
            maxY = this._bounds.max.y;
            maxZ = this._bounds.max.z;
        }

        private function setMesh(value:ZenMesh):void
        {
            var s:ZenFace;
            this._mesh = value;
            if (!(this._mesh)){
                return;
            }
            this.reset();
            var scale:Vector3D = this._mesh.getScale(false);
            var matrix:Matrix3D = new Matrix3D();
            matrix.appendScale(scale.x, scale.y, scale.z);
            for each (s in this._mesh.surfaces) {
                this.addSurface(s, matrix);
            }
            this.build();
            this.findEdges();
        }

        private function reset():void
        {
            this._vertices = new Vector.<LinkedVector3D>();
            this._edges = new Vector.<TriEdge3D>();
            this._tris = new Vector.<Tri3D>();
            this._bvh = new PhysicsNode3D();
            minX = (minY = (minZ = 1000000));
            maxX = (maxY = (maxZ = -1000000));
        }

        private function build():void
        {
            this._bvh.tris = this._tris;
            this._bvh.minX = minX;
            this._bvh.minY = minY;
            this._bvh.minZ = minZ;
            this._bvh.maxX = maxX;
            this._bvh.maxY = maxY;
            this._bvh.maxZ = maxZ;
            this._bvh.build();
            this._bvh.trim();
            this._mesh.world.copyColumnTo(3, position);
            var mx:Number = Math.max(Math.abs((maxX - position.x)), Math.abs((minX - position.x)));
            var my:Number = Math.max(Math.abs((maxY - position.y)), Math.abs((minY - position.y)));
            var mz:Number = Math.max(Math.abs((maxZ - position.z)), Math.abs((minZ - position.z)));
            this._radius = Math.sqrt((((mx * mx) + (my * my)) + (mz * mz)));
            this._max.x = (maxX - position.x);
            this._max.y = (maxY - position.y);
            this._max.z = (maxZ - position.z);
            this._min.x = (minX - position.x);
            this._min.y = (minY - position.y);
            this._min.z = (minZ - position.z);
        }

        private function addSurface(surface:ZenFace, transform:Matrix3D=null):void
        {
            var maxX:Number;
            var maxY:Number;
            var maxZ:Number;
            var minX:Number;
            var minY:Number;
            var minZ:Number;
            var x:Number;
            var y:Number;
            var z:Number;
            var v:LinkedVector3D;
            var v0:LinkedVector3D;
            var v1:LinkedVector3D;
            var v2:LinkedVector3D;
            var start:int;
            var end:int = surface.indexVector.length;
            var vertex:Vector.<Number> = surface.vertexVector;
            var indices:Vector.<uint> = surface.indexVector;
            var sizePerVertex:int = surface.sizePerVertex;
            var material:ShaderMaterialBase = surface.material;
            if (transform){
                transform.copyRawDataTo(raw);
            }
            var tri:int = this._tris.length;
            var vert:int = this._vertices.length;
            var fromVertex:int = this._vertices.length;
            var length:int = vertex.length;
            minZ = 10000000;
            minY = minZ;
            minX = minY;
            maxZ = -10000000;
            maxY = maxZ;
            maxX = maxY;
            this._vertices.length = (this._vertices.length + (length / sizePerVertex));
            this._tris.length = (this._tris.length + (indices.length / 3));
            var i:int;
            while (i < length) {
                x = vertex[i];
                y = vertex[(i + 1)];
                z = vertex[(i + 2)];
                v = new LinkedVector3D();
                if (transform){
                    v.x = ((((x * raw[0]) + (y * raw[4])) + (z * raw[8])) + raw[12]);
                    v.y = ((((x * raw[1]) + (y * raw[5])) + (z * raw[9])) + raw[13]);
                    v.z = ((((x * raw[2]) + (y * raw[6])) + (z * raw[10])) + raw[14]);
                } else {
                    v.x = x;
                    v.y = y;
                    v.z = z;
                }
                var _local27 = vert++;
                this._vertices[_local27] = v;
                if (v.x < minX){
                    minX = v.x;
                }
                if (v.y < minY){
                    minY = v.y;
                }
                if (v.z < minZ){
                    minZ = v.z;
                }
                if (v.x > maxX){
                    maxX = v.x;
                }
                if (v.y > maxY){
                    maxY = v.y;
                }
                if (v.z > maxZ){
                    maxZ = v.z;
                }
                i = (i + sizePerVertex);
            }
            while (start < end) {
                v0 = this._vertices[(fromVertex + indices[start++])];
                v1 = this._vertices[(fromVertex + indices[start++])];
                v2 = this._vertices[(fromVertex + indices[start++])];
                this._tris[tri] = new Tri3D(v0, v1, v2);
                this._tris[tri].material = material;
                tri++;
            }
            if (minX < this.minX){
                this.minX = minX;
            }
            if (minY < this.minY){
                this.minY = minY;
            }
            if (minZ < this.minZ){
                this.minZ = minZ;
            }
            if (maxX > this.maxX){
                this.maxX = maxX;
            }
            if (maxY > this.maxY){
                this.maxY = maxY;
            }
            if (maxZ > this.maxZ){
                this.maxZ = maxZ;
            }
        }

        final private function isSharedEdge(e:TriEdge3D, list:TriEdge3D=null):void
        {
            var rx:Number;
            var ry:Number;
            var rz:Number;
            var rw:Number;
            var n0:Vector3D;
            var n1:Vector3D;
            var dot:Number;
            if (!(e.valid)){
                return;
            }
            var EPSILON:Number = 0.001;
            var v:TriEdge3D = e.next;
            var r:Boolean = true;
            var ex:Number = (e.v0.x + e.v1.x);
            var ey:Number = (e.v0.y + e.v1.y);
            var ez:Number = (e.v0.z + e.v1.z);
            while (v) {
                rx = (ex - (v.v0.x + v.v1.x));
                ry = (ey - (v.v0.y + v.v1.y));
                rz = (ez - (v.v0.z + v.v1.z));
                rw = ((rx + ry) + rz);
                if (rw < 0){
                    rw = -(rw);
                }
                if (rw < EPSILON){
                    n0 = e.tri.n;
                    n1 = v.tri.n;
                    dot = (((n0.x * n1.x) + (n0.y * n1.y)) + (n0.z * n1.z));
                    if (dot < 0){
                        dot = -(dot);
                    }
                    if (dot > this._edgeThreshold){
                        e.valid = false;
                        v.valid = false;
                        r = false;
                    }
                }
                v = v.next;
                this._tests++;
            }
        }

        final private function findEdges():void
        {
            var hash:int;
            var h:TriEdge3D;
            var i:int;
            var t:Tri3D;
            var h0:int;
            var h1:int;
            var h2:int;
            var table:Dictionary = new Dictionary();
            var len:int = this._tris.length;
            var size:Number = 1;
            i = (len - 1);
            while (i >= 0) {
                t = this._tris[i];
                h0 = ((t.e0.v0.x + t.e0.v1.x) * size);
                h1 = ((t.e1.v0.x + t.e1.v1.x) * size);
                h2 = ((t.e2.v0.x + t.e2.v1.x) * size);
                h = table[h0];
                t.e0.next = h;
                table[h0] = t.e0;
                h = table[h1];
                t.e1.next = h;
                table[h1] = t.e1;
                h = table[h2];
                t.e2.next = h;
                table[h2] = t.e2;
                i--;
            }
            i = 0;
            while (i < len) {
                t = this._tris[i];
                this.isSharedEdge(t.e0);
                this.isSharedEdge(t.e1);
                this.isSharedEdge(t.e2);
                i++;
            }
        }

        public function get tris():Vector.<Tri3D>
        {
            return (this._tris);
        }

        public function get bvh():PhysicsNode3D
        {
            return (this._bvh);
        }

        public function get mesh():ZenMesh
        {
            return (this._mesh);
        }

        override public function clone():Collider
        {
            var collider:MeshCollider = new MeshCollider(this.mesh);
            collider.isStatic = isStatic;
            collider.isTrigger = isTrigger;
            collider.isRigidBody = isRigidBody;
            collider.setMass(mass);
            collider.enabled = enabled;
            collider.groups = groups;
            collider.collectContacts = collectContacts;
            collider.gravity = gravity;
            collider.neverSleep = neverSleep;
            collider.sleepingFactor = sleepingFactor;
            return (collider);
        }


    }
}

