package zen.display
{
	import zen.display.*;
	import zen.materials.*;
    import zen.shaders.textures.*;
    import zen.shaders.*;
    import zen.utils.*;
	import zen.geom.*;
    import flash.display3D.*;
    import flash.events.*;
    import flash.geom.*;
    import flash.utils.*;
	
	import zen.enums.*;
    

    public class ZenFace extends EventDispatcher 
    {


        public var bounds:Cube3D;
        public var vertexBuffer:VertexBuffer3D;
        public var vertexBytes:ByteArray;
        public var indexBuffer:IndexBuffer3D;
        public var indexBytes:ByteArray;
        public var numTriangles:int = -1;
        public var firstIndex:int = 0;
        public var sizePerVertex:int = 0;
        public var offset:Vector.<int>;
        public var sources:Vector.<ZenFace>;
        public var format:Vector.<String>;
        public var name:String;
        public var scene:Zen3D;
        private var _material:ShaderMaterialBase;
        private var _indexVector:Vector.<uint>;
        private var _vertexVector:Vector.<Number>;
        private var _instanceOf:ZenFace;
        private var _polys:Vector.<Poly3D>;
        public var visible:Boolean = true;
		
        public var edgeVector:Vector.<uint>;
		
		

        public function ZenFace(name:String=null)
        {
            this.offset = new Vector.<int>(16, true);
            this.sources = new Vector.<ZenFace>(16, true);
            this.format = new Vector.<String>();
            super();
            this.name = name;
            var i:int;
            while (i < this.offset.length) {
                this.offset[i] = -1;
                this.format[i] = null;
                i++;
            }
        }

        public function addVertexData(dataIndex:uint, size:int=-1, vector:Vector.<Number>=null):int
        {
            var count:int;
            var i:int;
            var e:int;
            var step:int;
            var length:int;
            var newVec:Vector.<Number>;
            if (this._instanceOf){
                return (this._instanceOf.addVertexData(dataIndex, size, vector));
            }
            if (size == -1){
                switch (dataIndex){
                    case VertexType.POSITION:
                    case VertexType.NORMAL:
                    case VertexType.COLOR0:
                    case VertexType.COLOR1:
                    case VertexType.COLOR2:
                    case VertexType.BITANGENT:
                    case VertexType.TANGENT:
                        size = 3;
                        break;
                    case VertexType.UV0:
                    case VertexType.UV1:
                    case VertexType.UV2:
                    case VertexType.UV3:
                        size = 2;
                        break;
                    case VertexType.PARTICLE:
                        size = 4;
                        break;
                    case VertexType.SKIN_INDICES:
                    case VertexType.SKIN_WEIGHTS:
                        size = ZenUtils.maxBonesPerVertex;
                        break;
                }
            }
            this.format[dataIndex] = ("float" + size);
            if (this.offset[dataIndex] != -1){
                this.sizePerVertex = Math.max(this.sizePerVertex, (this.offset[dataIndex] + size));
                return (this.offset[dataIndex]);
            }
            this.offset[dataIndex] = this.sizePerVertex;
            if (vector){
                step = (this.sizePerVertex + size);
                length = (this.vertexVector.length / this.sizePerVertex);
                newVec = new Vector.<Number>((length * step));
                if (length == 0){
                    this.vertexVector = vector.concat();
                } else {
                    i = 0;
                    while (i < length) {
                        e = 0;
                        while (e < this.sizePerVertex) {
                            newVec[((i * step) + e)] = this.vertexVector[((i * this.sizePerVertex) + e)];
                            e++;
                        }
                        e = this.sizePerVertex;
                        while (e < step) {
                            newVec[((i * step) + e)] = vector[count++];
                            e++;
                        }
                        i++;
                    }
                    this.vertexVector = newVec;
                }
            }
            this.sizePerVertex = (this.sizePerVertex + size);
            this.download();
            return (this.offset[dataIndex]);
        }

        public function removeVertexData(data:int):Boolean
        {
            var c:int;
            this.sources[data] = null;
            if (!(this.hasVertexData(data))){
                return (false);
            }
            if (this._instanceOf){
                return (this._instanceOf.removeVertexData(data));
            }
            var size:int = int(this.format[data].substr(-1));
            var offset:int = this.offset[data];
            var length:int = (this.vertexVector.length / this.sizePerVertex);
            var newVec:Vector.<Number> = new Vector.<Number>((length * (this.sizePerVertex - size)));
            var startAt:int = offset;
            var endAt:int = (offset + size);
            var count:int;
            var i:int;
            while (i < length) {
                c = 0;
                while (c < this.sizePerVertex) {
                    if ((((c < startAt)) || ((c >= endAt)))){
                        var _local11 = count++;
                        newVec[_local11] = this._vertexVector[((i * this.sizePerVertex) + c)];
                    }
                    c++;
                }
                i++;
            }
            this.sizePerVertex = (this.sizePerVertex - size);
            i = (data + 1);
            while (i < 16) {
                if (this.offset[i] >= 0){
                    this.offset[i] = (this.offset[i] - size);
                }
                i++;
            }
            this.offset[data] = -1;
            this.format[data] = null;
            this.vertexVector = newVec;
            this.download();
            return (true);
        }

        public function hasVertexData(data:int):Boolean
        {
            if (this._instanceOf){
                return (this._instanceOf.hasVertexData(data));
            }
            return ((((((this.offset[data] >= 0)) || (this.sources[data]))) ? true : false));
        }

        public function dispose():void
        {
            var i:int;
            while (i < this.sources.length) {
                if (this.sources[i]){
                    this.sources[i].dispose();
                }
                i++;
            }
            this.download();
            this.scene = null;
            this.indexBytes = null;
            this.vertexBytes = null;
            this.bounds = null;
            this.offset = null;
            this.format = null;
            this._vertexVector = null;
            this._indexVector = null;
            if (this._material){
                this._material.removeEventListener(Event.CHANGE, this.changedMaterialEvent);
                this._material = null;
            }
        }

        public function upload(scene:Zen3D):void
        {
            if (this.instanceOf){
                this.instanceOf.upload(scene);
                this.scene = scene;
                return;
            }
            if (this.scene){
                return;
            }
            this.scene = scene;
            if (this.scene.surfaces.indexOf(this) == -1){
                this.scene.surfaces.push(this);
            }
            if (this.scene.context){
                this.contextEvent();
            }
            this.scene.addEventListener(Event.CONTEXT3D_CREATE, this.contextEvent);
            if (this._material){
                this._material.upload(scene);
            }
        }

        public function download():void
        {
            if (this.instanceOf){
                this.instanceOf.download();
                return;
            }
            if (this.indexBuffer){
                this.indexBuffer.dispose();
            }
            if (this.vertexBuffer){
                this.vertexBuffer.dispose();
            }
            if (this.scene){
                this.scene.removeEventListener(Event.CONTEXT3D_CREATE, this.contextEvent);
                this.scene.surfaces.splice(this.scene.surfaces.indexOf(this), 1);
                this.scene = null;
            }
            this.indexBuffer = null;
            this.vertexBuffer = null;
            dispatchEvent(new Event("download"));
        }

        public function updateVertexBuffer(startVertex:int=0, numVertices:int=-1):void
        {
            if (((!(this.scene)) || (!(this.scene.context)))){
                return;
            }
            if (((this._vertexVector) && ((this._vertexVector.length > 0)))){
                if (numVertices == -1){
                    numVertices = (this._vertexVector.length / this.sizePerVertex);
                }
                if (!(this.vertexBuffer)){
                    this.vertexBuffer = this.scene.context.createVertexBuffer(numVertices, this.sizePerVertex);
                }
                this.vertexBuffer.uploadFromVector(this._vertexVector, startVertex, numVertices);
            } else {
                if (((this.vertexBytes) && ((this.vertexBytes.length > 0)))){
                    if (numVertices == -1){
                        numVertices = ((this.vertexBytes.length / 4) / this.sizePerVertex);
                    }
                    if (!(this.vertexBuffer)){
                        this.vertexBuffer = this.scene.context.createVertexBuffer(numVertices, this.sizePerVertex);
                    }
                    this.vertexBuffer.uploadFromByteArray(this.vertexBytes, 0, startVertex, numVertices);
                } else {
					
                    throw new Error((("Surface '" + this.name) + "' does not have vertex data."));
					
					return;
                }
            }
        }

        public function updateIndexBuffer(startIndex:int=0, numIndices:int=-1):void
        {
            var len:int;
            var i:int;
            if (((!(this.scene)) || (!(this.scene.context)))){
                return;
            }
            if (((this._indexVector) && ((this._indexVector.length > 0)))){
                if (this.numTriangles == -1){
                    this.numTriangles = (this._indexVector.length / 3);
                }
                if (numIndices == -1){
                    numIndices = this._indexVector.length;
                }
                if (!(this.indexBuffer)){
                    this.indexBuffer = this.scene.context.createIndexBuffer(numIndices);
                }
                this.indexBuffer.uploadFromVector(this._indexVector, startIndex, numIndices);
            } else {
                if (((this.indexBytes) && ((this.indexBytes.length > 0)))){
                    if (this.numTriangles == -1){
                        this.numTriangles = ((this.indexBytes.length / 2) / 3);
                    }
                    if (numIndices == -1){
                        numIndices = (this.indexBytes.length / 2);
                    }
                    if (!(this.indexBuffer)){
                        this.indexBuffer = this.scene.context.createIndexBuffer(numIndices);
                    }
                    this.indexBuffer.uploadFromByteArray(this.indexBytes, 0, startIndex, numIndices);
                } else {
                    len = ((this._vertexVector) ? (this._vertexVector.length / this.sizePerVertex) : ((this.vertexBytes.length / 4) / this.sizePerVertex));
                    this._indexVector = new Vector.<uint>(len);
                    i = 0;
                    while (i < len) {
                        this._indexVector[i] = i;
                        i++;
                    }
                    this.indexBuffer = this.scene.context.createIndexBuffer(this._indexVector.length);
                    this.indexBuffer.uploadFromVector(this._indexVector, 0, this._indexVector.length);
                    this.numTriangles = (len / 3);
                }
            }
        }

        private function contextEvent(e:Event=null):void
        {
            if (this.instanceOf){
                return;
            }
            if (this.vertexBuffer){
                this.vertexBuffer.dispose();
            }
            if (this.indexBuffer){
                this.indexBuffer.dispose();
            }
            this.vertexBuffer = null;
            this.indexBuffer = null;
            this.updateVertexBuffer();
            this.updateIndexBuffer();
            dispatchEvent(new Event("upload"));
        }

		
        override public function toString():String
        {
            return ((((("[object ZenFace name:" + this.name) + " triangles:") + this.numTriangles) + "]"));
        }
		

        public function clone():ZenFace
        {
            var g:ZenFace = new ZenFace(this.name);
            g.instanceOf = ((this.instanceOf) || (this));
            g.numTriangles = this.numTriangles;
            g.firstIndex = this.firstIndex;
            g.material = this.material;
            return (g);
        }

        public function updateBoundings():Cube3D
        {
            var dx:Number;
            var dy:Number;
            var dz:Number;
            var temp:Number;
            var x:Number;
            var y:Number;
            var z:Number;
            if (this._instanceOf){
                this.bounds = this._instanceOf.updateBoundings();
                return (this.bounds);
            }
            this.bounds = new Cube3D();
            this.bounds.min.setTo(10000000, 10000000, 10000000);
            this.bounds.max.setTo(-10000000, -10000000, -10000000);
            var v:Vector.<Number> = this.vertexVector;
            var l:int = v.length;
            var i:int = this.offset[VertexType.POSITION];
            while (i < l) {
                x = v[i];
                y = v[(i + 1)];
                z = v[(i + 2)];
                if (x < this.bounds.min.x){
                    this.bounds.min.x = x;
                }
                if (y < this.bounds.min.y){
                    this.bounds.min.y = y;
                }
                if (z < this.bounds.min.z){
                    this.bounds.min.z = z;
                }
                if (x > this.bounds.max.x){
                    this.bounds.max.x = x;
                }
                if (y > this.bounds.max.y){
                    this.bounds.max.y = y;
                }
                if (z > this.bounds.max.z){
                    this.bounds.max.z = z;
                }
                i = (i + this.sizePerVertex);
            }
            this.bounds.length.x = (this.bounds.max.x - this.bounds.min.x);
            this.bounds.length.y = (this.bounds.max.y - this.bounds.min.y);
            this.bounds.length.z = (this.bounds.max.z - this.bounds.min.z);
            this.bounds.center.x = ((this.bounds.length.x * 0.5) + this.bounds.min.x);
            this.bounds.center.y = ((this.bounds.length.y * 0.5) + this.bounds.min.y);
            this.bounds.center.z = ((this.bounds.length.z * 0.5) + this.bounds.min.z);
            i = 0;
            while (i < l) {
                x = v[i];
                y = v[(i + 1)];
                z = v[(i + 2)];
                dx = (this.bounds.center.x - x);
                dy = (this.bounds.center.y - y);
                dz = (this.bounds.center.z - z);
                temp = (((dx * dx) + (dy * dy)) + (dz * dz));
                if (temp > this.bounds.radius){
                    this.bounds.radius = temp;
                }
                i = (i + this.sizePerVertex);
            }
            this.bounds.radius = Math.sqrt(this.bounds.radius);
            dispatchEvent(new Event(Event.CHANGE));
            return (this.bounds);
        }

        public function get material():ShaderMaterialBase
        {
            return (this._material);
        }

        public function set material(value:ShaderMaterialBase):void
        {
            if (this._material){
                this._material.removeEventListener(Event.CHANGE, this.changedMaterialEvent);
            }
            if (((value) && (value.validate(this)))){
                this._material = value;
                this._material.validate(this);
                this._material.addEventListener(Event.CHANGE, this.changedMaterialEvent, false, 0, true);
            }
        }

        private function changedMaterialEvent(e:Event):void
        {
            this._material.validate(this);
        }

        public function get vertexVector():Vector.<Number>
        {
            var i:uint;
            if (this._instanceOf){
                return (this._instanceOf.vertexVector);
            }
            if (!(this._vertexVector)){
                this._vertexVector = new Vector.<Number>();
                if (this.vertexBytes){
                    this.vertexBytes.position = 0;
                    i = 0;
                    while (this.vertexBytes.bytesAvailable) {
                        var _local2 = i++;
                        this._vertexVector[_local2] = this.vertexBytes.readFloat();
                    }
                }
            }
            return (this._vertexVector);
        }

        public function set vertexVector(value:Vector.<Number>):void
        {
            if (this._instanceOf){
                this._instanceOf._vertexVector = value;
            } else {
                this._vertexVector = value;
            }
        }

        public function get indexVector():Vector.<uint>
        {
            if (this._instanceOf){
                return (this._instanceOf.indexVector);
            }
            if (!(this._indexVector)){
                this._indexVector = new Vector.<uint>();
                if (this.indexBytes){
                    this.indexBytes.position = 0;
                    while (this.indexBytes.bytesAvailable) {
                        this._indexVector.push(this.indexBytes.readUnsignedShort(), this.indexBytes.readUnsignedShort(), this.indexBytes.readUnsignedShort());
                    }
                }
            }
            return (this._indexVector);
        }

        public function set indexVector(value:Vector.<uint>):void
        {
            if (this._instanceOf){
                this._instanceOf.indexVector = value;
            } else {
                this._indexVector = value;
            }
        }

        public function get instanceOf():ZenFace
        {
            return (this._instanceOf);
        }

        public function set instanceOf(value:ZenFace):void
        {
            this._instanceOf = value;
            if (value){
                this._instanceOf.addEventListener("download", this.instanceStateEvent, false, 0, true);
                this._instanceOf.addEventListener("upload", this.instanceStateEvent, false, 0, true);
                this._instanceOf.addEventListener("dispose", this.instanceStateEvent, false, 0, true);
                this.vertexBuffer = this._instanceOf.vertexBuffer;
                this.vertexBytes = this._instanceOf.vertexBytes;
                this.indexBuffer = this._instanceOf.indexBuffer;
                this.indexBytes = this._instanceOf.indexBytes;
                this.sizePerVertex = this._instanceOf.sizePerVertex;
                this.offset = this._instanceOf.offset;
                this.sources = this._instanceOf.sources;
                this.format = this._instanceOf.format;
                this.bounds = this._instanceOf.bounds;
            }
        }

        public function get polys():Vector.<Poly3D>
        {
            if (this._instanceOf){
                return (this._instanceOf.polys);
            }
            return (this._polys);
        }

        public function set polys(value:Vector.<Poly3D>):void
        {
            if (this._instanceOf){
                this._instanceOf.polys = value;
            } else {
                this._polys = value;
            }
        }

        private function instanceStateEvent(e:Event):void
        {
            this.instanceOf = this._instanceOf;
        }


		public function getVertex(v:int, out:Vector3D = null):Vector3D {
			if (!out) {
				out = new Vector3D();
			}
			var vector:Vector.<Number> = _instanceOf ? _instanceOf.vertexVector : _vertexVector;
			var i:int = v * sizePerVertex;
			out.x = vector[i];
			out.y = vector[i + 1];
			out.z = vector[i + 2];
			return out;
		}
		public function getNormal(v:int, out:Vector3D = null):Vector3D {
			if (!out) {
				out = new Vector3D();
			}
			var vector:Vector.<Number> = _instanceOf ? _instanceOf.vertexVector : _vertexVector;
			var i:int = v * sizePerVertex;
			out.x = vector[i + 3];
			out.y = vector[i + 4];
			out.z = vector[i + 5];
			return out;
		}
		
		
		
        public function buildPolys(force:Boolean=false):Vector.<Poly3D>
        {
            var v0:Vector3D;
            var v1:Vector3D;
            var v2:Vector3D;
            var c:uint;
            var b:uint;
            var a:uint;
            var p:Poly3D;
            if (((this.polys) && ((force == false)))){
                return (this.polys);
            }
            this.polys = new Vector.<Poly3D>();
            if (this.numTriangles == -1){
                this.numTriangles = (this.indexVector.length / 3);
            }
            var index:Vector.<uint> = this.indexVector;
            var vertex:Vector.<Number> = this.vertexVector;
            var start:int;
            var end:int = this.indexVector.length;
            var position:int = this.offset[VertexType.POSITION];
            var uv:int = ((!((this.offset[VertexType.UV0] == -1))) ? this.offset[VertexType.UV0] : this.offset[VertexType.UV1]);
            var i:int;
            if (uv == -1){
                uv = 0;
            }
            while (i < end) {
                c = (index[i++] * this.sizePerVertex);
                b = (index[i++] * this.sizePerVertex);
                a = (index[i++] * this.sizePerVertex);
                v0 = new Vector3D(vertex[(a + position)], vertex[((a + 1) + position)], vertex[((a + 2) + position)]);
                v1 = new Vector3D(vertex[(b + position)], vertex[((b + 1) + position)], vertex[((b + 2) + position)]);
                v2 = new Vector3D(vertex[(c + position)], vertex[((c + 1) + position)], vertex[((c + 2) + position)]);
                p = new Poly3D(v0, v1, v2);
                if (uv != -1){
                    p.uv0 = new Point(vertex[(a + uv)], vertex[((a + 1) + uv)]);
                    p.uv1 = new Point(vertex[(b + uv)], vertex[((b + 1) + uv)]);
                    p.uv2 = new Point(vertex[(c + uv)], vertex[((c + 1) + uv)]);
                }
                this.polys.push(p);
            }
            this.updateBoundings();
            return (this.polys);
        }

        public function flipNormals():void
        {
            var index:int;
            var offset:int = this.offset[VertexType.NORMAL];
            if (offset == -1){
                return;
            }
            var used:Array = [];
            var start:int = this.firstIndex;
            var end:int = (((this.numTriangles < 0)) ? this.indexVector.length : (start + (this.numTriangles * 3)));
            var i:int = start;
            while (i < end) {
                index = this.indexVector[i];
                if (!(used[index])){
                    used[index] = true;
                    index = ((index * this.sizePerVertex) + offset);
                    this.vertexVector[index] = -(this.vertexVector[index++]);
                    this.vertexVector[index] = -(this.vertexVector[index++]);
                    this.vertexVector[index] = -(this.vertexVector[index]);
                }
                i++;
            }
        }

        public function transformBy(matrix:Matrix3D, firstIndex:int=-1, numTriangles:int=-1):void
        {
            var index:int;
            var x:Number;
            var y:Number;
            var z:Number;
            var position:int = this.offset[VertexType.POSITION];
            var normals:int = this.offset[VertexType.NORMAL];
            var used:Array = [];
            var start:int = (((firstIndex == -1)) ? this.firstIndex : firstIndex);
            var end:int = (((this.numTriangles < 0)) ? this.indexVector.length : (start + (this.numTriangles * 3)));
            if (numTriangles != -1){
                end = (start + (numTriangles * 3));
            }
            var right:Vector3D = new Vector3D();
            matrix.copyRowTo(0, right);
            var up:Vector3D = new Vector3D();
            matrix.copyRowTo(1, up);
            var dir:Vector3D = new Vector3D();
            matrix.copyRowTo(2, dir);
            var pos:Vector3D = new Vector3D();
            matrix.copyColumnTo(3, pos);
            var normal:Vector3D = new Vector3D();
            var indices:Vector.<uint> = this.indexVector;
            var vertex:Vector.<Number> = this.vertexVector;
            var sizePerVertex:int = this.sizePerVertex;
            var i:int = start;
            while (i < end) {
                index = indices[i];
                if (used[index] == undefined){
                    used[index] = true;
                    index = ((index * sizePerVertex) + position);
                    x = vertex[index];
                    y = vertex[(index + 1)];
                    z = vertex[(index + 2)];
                    var _local23 = index++;
                    vertex[_local23] = (((pos.x + (x * right.x)) + (y * right.y)) + (z * right.z));
                    var _local24 = index++;
                    vertex[_local24] = (((pos.y + (x * up.x)) + (y * up.y)) + (z * up.z));
                    vertex[index] = (((pos.z + (x * dir.x)) + (y * dir.y)) + (z * dir.z));
                    if (normals >= 0){
                        index = ((indices[i] * sizePerVertex) + normals);
                        normal.x = vertex[index];
                        normal.y = vertex[(index + 1)];
                        normal.z = vertex[(index + 2)];
                        normal.normalize();
                        var _local25 = index++;
                        vertex[_local25] = (((normal.x * right.x) + (normal.y * right.y)) + (normal.z * right.z));
                        var _local26 = index++;
                        vertex[_local26] = (((normal.x * up.x) + (normal.y * up.y)) + (normal.z * up.z));
                        vertex[index] = (((normal.x * dir.x) + (normal.y * dir.y)) + (normal.z * dir.z));
                    }
                }
                i++;
            }
            if (this.vertexBuffer){
                this.vertexBuffer.uploadFromVector(this.vertexVector, 0, (this.vertexVector.length / this.sizePerVertex));
            }
        }

        public function concat(dest:ZenFace):void
        {
            var index:int;
            var srcOffset:int;
            var dstOffset:int;
            var e:int;
            var offset:int = (dest.vertexVector.length / dest.sizePerVertex);
            var size:int = dest.sizePerVertex;
            var start:int = this.firstIndex;
            var end:int = (((this.numTriangles < 0)) ? this.indexVector.length : (start + (this.numTriangles * 3)));
            var srcIndex:Vector.<uint> = this.indexVector;
            var dstIndex:Vector.<uint> = dest.indexVector;
            var srcVertex:Vector.<Number> = this.vertexVector;
            var dstVertex:Vector.<Number> = dest.vertexVector;
            var i:int = start;
            while (i < end) {
                index = srcIndex[i];
                dstIndex.push((index + offset));
                srcOffset = (index * size);
                dstOffset = ((offset * size) + srcOffset);
                if (dstVertex.length < dstOffset){
                    dstVertex.length = dstOffset;
                }
                e = 0;
                while (e < size) {
                    dstVertex[(dstOffset + e)] = srcVertex[(srcOffset + e)];
                    e++;
                }
                i++;
            }
            dest.firstIndex = 0;
            dest.numTriangles = (dest.indexVector.length / 3);
            dest.polys = null;
            dest.bounds = null;
        }

        public function buildTangentsAndBitangents():void
        {
            var i0:int;
            var i1:int;
            var i2:int;
            var p0index:int;
            var p1index:int;
            var p2index:int;
            var u0Index:int;
            var u1Index:int;
            var u2Index:int;
            var x1:Number;
            var x2:Number;
            var y1:Number;
            var y2:Number;
            var z1:Number;
            var z2:Number;
            var s1:Number;
            var s2:Number;
            var t1:Number;
            var t2:Number;
            var aux:Number;
            var iS:int;
            var i6:int;
            var offset:Vector.<int> = this.offset;
            var vertexVector:Vector.<Number> = this.vertexVector;
            var indexVector:Vector.<uint> = this.indexVector;
            var sizePerVertex:int = this.sizePerVertex;
            if (this.hasVertexData(VertexType.TANGENT)){
                return;
            }
            if (this.hasVertexData(VertexType.BITANGENT)){
                return;
            }
            if (!(this.hasVertexData(VertexType.NORMAL))) {
				
                throw ((("Surface " + this.name) + " does not have normals needed to generate tangent vectors."));
				
				return;
            }
            if (!(this.hasVertexData(VertexType.UV0))) {
				
                throw ((("Surface " + this.name) + " does not have Uv's channel needed to generate tangeent vectors."));
				
				return;
            }
            var tangentVector:Vector.<Number> = new Vector.<Number>(((vertexVector.length / sizePerVertex) * 3));
            var bitangentVector:Vector.<Number> = new Vector.<Number>(((vertexVector.length / sizePerVertex) * 3));
            var p0:Vector3D = new Vector3D();
            var p1:Vector3D = new Vector3D();
            var p2:Vector3D = new Vector3D();
            var tanDir:Vector3D = new Vector3D();
            var bitanDir:Vector3D = new Vector3D();
            var u0:Point = new Point();
            var u1:Point = new Point();
            var u2:Point = new Point();
            var p:int = offset[VertexType.POSITION];
            var u:int = offset[VertexType.UV0];
            var n:int = offset[VertexType.NORMAL];
            if (u == -1){
                trace((("Warning!, Surface " + this.name) + " does not have Uv's channel needed to generate tangeent vectors."));
                u = 0;
            }
            if (n == -1){
                trace((("Warning!, Surface " + this.name) + " does not have normals needed to generate tangent vectors."));
                n = 0;
            }
            var iLength:int = indexVector.length;
            var i:int;
            while (i < iLength) {
                i0 = indexVector[i];
                i1 = indexVector[(i + 1)];
                i2 = indexVector[(i + 2)];
                p0index = ((i0 * sizePerVertex) + p);
                p1index = ((i1 * sizePerVertex) + p);
                p2index = ((i2 * sizePerVertex) + p);
                u0Index = ((i0 * sizePerVertex) + u);
                u1Index = ((i1 * sizePerVertex) + u);
                u2Index = ((i2 * sizePerVertex) + u);
                p0.setTo(vertexVector[p0index], vertexVector[(p0index + 1)], vertexVector[(p0index + 2)]);
                p1.setTo(vertexVector[p1index], vertexVector[(p1index + 1)], vertexVector[(p1index + 2)]);
                p2.setTo(vertexVector[p2index], vertexVector[(p2index + 1)], vertexVector[(p2index + 2)]);
                x1 = (p1.x - p0.x);
                x2 = (p2.x - p0.x);
                y1 = (p1.y - p0.y);
                y2 = (p2.y - p0.y);
                z1 = (p1.z - p0.z);
                z2 = (p2.z - p0.z);
                u0.setTo(vertexVector[u0Index], -(vertexVector[(u0Index + 1)]));
                u1.setTo(vertexVector[u1Index], -(vertexVector[(u1Index + 1)]));
                u2.setTo(vertexVector[u2Index], -(vertexVector[(u2Index + 1)]));
                s1 = (u1.x - u0.x);
                s2 = (u2.x - u0.x);
                t1 = (u1.y - u0.y);
                t2 = (u2.y - u0.y);
                aux = (1 / ((s1 * t2) - (s2 * t1)));
                tanDir.setTo((((t2 * x1) - (t1 * x2)) * aux), (((t2 * y1) - (t1 * y2)) * aux), (((t2 * z1) - (t1 * z2)) * aux));
                bitanDir.setTo((((s1 * x2) - (s2 * x1)) * aux), (((s1 * y2) - (s2 * y1)) * aux), (((s1 * z2) - (s2 * z1)) * aux));
                tangentVector[(i0 * 3)] = (tangentVector[(i0 * 3)] + tanDir.x);
                tangentVector[((i0 * 3) + 1)] = (tangentVector[((i0 * 3) + 1)] + tanDir.y);
                tangentVector[((i0 * 3) + 2)] = (tangentVector[((i0 * 3) + 2)] + tanDir.z);
                tangentVector[(i1 * 3)] = (tangentVector[(i1 * 3)] + tanDir.x);
                tangentVector[((i1 * 3) + 1)] = (tangentVector[((i1 * 3) + 1)] + tanDir.y);
                tangentVector[((i1 * 3) + 2)] = (tangentVector[((i1 * 3) + 2)] + tanDir.z);
                tangentVector[(i2 * 3)] = (tangentVector[(i2 * 3)] + tanDir.x);
                tangentVector[((i2 * 3) + 1)] = (tangentVector[((i2 * 3) + 1)] + tanDir.y);
                tangentVector[((i2 * 3) + 2)] = (tangentVector[((i2 * 3) + 2)] + tanDir.z);
                bitangentVector[(i0 * 3)] = (bitangentVector[(i0 * 3)] + bitanDir.x);
                bitangentVector[((i0 * 3) + 1)] = (bitangentVector[((i0 * 3) + 1)] + bitanDir.y);
                bitangentVector[((i0 * 3) + 2)] = (bitangentVector[((i0 * 3) + 2)] + bitanDir.z);
                bitangentVector[(i1 * 3)] = (bitangentVector[(i1 * 3)] + bitanDir.x);
                bitangentVector[((i1 * 3) + 1)] = (bitangentVector[((i1 * 3) + 1)] + bitanDir.y);
                bitangentVector[((i1 * 3) + 2)] = (bitangentVector[((i1 * 3) + 2)] + bitanDir.z);
                bitangentVector[(i2 * 3)] = (bitangentVector[(i2 * 3)] + bitanDir.x);
                bitangentVector[((i2 * 3) + 1)] = (bitangentVector[((i2 * 3) + 1)] + bitanDir.y);
                bitangentVector[((i2 * 3) + 2)] = (bitangentVector[((i2 * 3) + 2)] + bitanDir.z);
                i = (i + 3);
            }
            var buffers:ZenFace = new ZenFace(("tangents/bitangents : " + this.name));
            buffers.addVertexData(VertexType.TANGENT, 3, tangentVector);
            buffers.addVertexData(VertexType.BITANGENT, 3, bitangentVector);
            var buffersVector:Vector.<Number> = buffers.vertexVector;
            vertexVector = this.vertexVector;
            sizePerVertex = this.sizePerVertex;
            var t:int;
            var b:int = 3;
            var normal:Vector3D = new Vector3D();
            var tangent:Vector3D = new Vector3D();
            var bitangent:Vector3D = new Vector3D();
            var auxv:Vector3D = new Vector3D();
            var start:int;
            var end:int = (vertexVector.length / sizePerVertex);
            i = start;
            while (i < end) {
                iS = (i * sizePerVertex);
                i6 = (i * 6);
                normal.setTo(vertexVector[(iS + n)], vertexVector[((iS + n) + 1)], vertexVector[((iS + n) + 2)]);
                tangent.setTo(buffersVector[(i6 + t)], buffersVector[((i6 + t) + 1)], buffersVector[((i6 + t) + 2)]);
                bitangent.setTo(buffersVector[(i6 + b)], buffersVector[((i6 + b) + 1)], buffersVector[((i6 + b) + 2)]);
                auxv.copyFrom(normal);
                auxv.scaleBy(normal.dotProduct(tangent));
                tangent = tangent.subtract(auxv);
                tangent.normalize();
                auxv.copyFrom(normal);
                auxv.scaleBy(normal.dotProduct(bitangent));
                bitangent = bitangent.subtract(auxv);
                bitangent.normalize();
                buffersVector[((i * 6) + t)] = tangent.x;
                buffersVector[(((i * 6) + t) + 1)] = tangent.y;
                buffersVector[(((i * 6) + t) + 2)] = tangent.z;
                buffersVector[((i * 6) + b)] = bitangent.x;
                buffersVector[(((i * 6) + b) + 1)] = bitangent.y;
                buffersVector[(((i * 6) + b) + 2)] = bitangent.z;
                i++;
            }
            this.sources[VertexType.TANGENT] = buffers;
            this.sources[VertexType.BITANGENT] = buffers;
        }

        public function compress(surf:ZenFace, vertex:Vector.<Number>=null, indices:Vector.<uint>=null):void
        {
            var hash:int;
            var arr:Array;
            var v:int;
            var pass:Boolean;
            var v0:uint;
            var v1:uint;
            var b:int;
            var l:int;
            var vertexVector:Vector.<Number> = surf.vertexVector;
            var indexVector:Vector.<uint> = surf.indexVector;
            var sizePerVertex:int = surf.sizePerVertex;
            var table:Array = [];
            var length:int = vertexVector.length;
            var index:uint;
            var n:int;
            n = 0;
            while (n < length) {
                hash = (vertexVector[n] * 100000);
                if (!(table[hash])){
                    table[hash] = [index];
                } else {
                    (table[hash] as Array).push(index);
                }
                index++;
                n = (n + sizePerVertex);
            }
            var iVector:Vector.<uint> = new Vector.<uint>(indexVector.length);
            var vVector:Vector.<Number> = new Vector.<Number>();
            var pack:Array = new Array();
            var packIndex:int;
            length = indexVector.length;
            n = 0;
            while (n < length) {
                index = indexVector[n];
                hash = (vertexVector[(index * sizePerVertex)] * 100000);
                arr = (table[hash] as Array);
                for each (v in arr) {
                    pass = true;
                    v0 = (v * sizePerVertex);
                    v1 = (index * sizePerVertex);
                    b = 0;
                    while (b < sizePerVertex) {
                        if (vertexVector[(v0 + b)] != vertexVector[(v1 + b)]){
                            pass = false;
                            break;
                        }
                        b++;
                    }
                    if (!!(pass)){
                        if (pack[v] == undefined){
                            v1 = (v0 + sizePerVertex);
                            l = vVector.length;
                            while (v0 < v1) {
                                var _local25 = l++;
                                vVector[_local25] = vertexVector[v0++];
                            }
                            pack[v] = packIndex++;
                        }
                        iVector[n] = (pack[v] as uint);
                        break;
                    }
                }
                n++;
            }
            surf.vertexBytes = null;
            surf.indexBytes = null;
            surf.vertexVector = ((vertex) || (vVector));
            surf.indexVector = ((indices) || (iVector));
            surf.download();
        }

		
    }
}

