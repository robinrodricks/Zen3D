package zen.display
{
    
    import zen.materials.*;
    import zen.shaders.*;
	import zen.display.*;
    import zen.shaders.textures.*;
    import zen.utils.*;
    import flash.display.*;
    import flash.geom.*;
    

    public class ZenBatchRenderer extends ZenObject implements IDrawable 
    {

        private static const raw:Vector.<Number> = new Vector.<Number>(16, true);
        private static const vec:Vector3D = new Vector3D();

		[Embed(source = "../utils/assets/display/ZenBatchRenderer_BatchFilter.data", mimeType = "application/octet-stream")]
        private static var BatchFilter:Class;

        public var positions:Vector.<Vector3D>;
        public var orientations:Vector.<Vector3D>;
        public var maxInstances:int = -1;
        public var enableCameraCulling:Boolean = true;
        private var _mesh:ZenMesh;
        private var _sources:Vector.<ZenFace>;
        private var _material:ZenMaterial;
        private var _count:Vector.<int>;
        private var _tris:Vector.<int>;
        private var _maxCount:int = 100;
        private var _enableRotation:Boolean;
        private var _posParam:Vector.<Number>;
        private var _quatParam:Vector.<Number>;
        private var _transform:ShaderFilter;
        public var surfaces:Vector.<ZenFace>;

        public function ZenBatchRenderer(mesh:ZenMesh, enableRotation:Boolean=true, material:ZenMaterial=null)
        {
            var src:ZenFace;
            var surf:ZenFace;
            var numVertex:uint;
            var numIndices:uint;
            var countVertex:uint;
            var countIndices:uint;
            var count:uint;
            var positionVector:Vector.<Number>;
            var vertexVector:Vector.<Number>;
            var indexVector:Vector.<uint>;
            var srcIndexVector:Vector.<uint>;
            var srcVertexVector:Vector.<Number>;
            var srcVertexLength:uint;
            var tp:uint;
            var tv:uint;
            var ti:uint;
            var sourceIndices:ZenFace;
            var vtx:uint;
            var idx:uint;
            var pos:uint;
            this.positions = new Vector.<Vector3D>();
            this.orientations = new Vector.<Vector3D>();
            this._sources = new Vector.<ZenFace>();
            this.surfaces = new Vector.<ZenFace>();
            super();
            var maxIndices:int = 524287;
            var maxVertex:int = 65536;
            this._mesh = mesh;
            this._enableRotation = enableRotation;
            this._sources = new Vector.<ZenFace>(mesh.surfaces.length, true);
            this._count = new Vector.<int>(mesh.surfaces.length, true);
            this._tris = new Vector.<int>(mesh.surfaces.length, true);
            if (enableRotation){
                this._maxCount = 50;
            }
            this._transform = new ShaderFilter(new BatchFilter(), BlendMode.NORMAL, ("main" + this._maxCount));
            if (!(material)){
                material = (mesh.surfaces[0].material as ZenMaterial);
            }
            if (!(material)){
                material = new ZenMaterial("meshBatch", null, true, this._transform);
            }
            material = material.duplicate();
            material.transform = this._transform;
            if (this._maxCount == 100){
                this._posParam = (this._transform.params.pos100.value = new Vector.<Number>((this._maxCount * 4)));
            } else {
                this._posParam = (this._transform.params.pos50.value = new Vector.<Number>((this._maxCount * 4)));
            }
            this._quatParam = (this._transform.params.quat50.value = new Vector.<Number>((this._maxCount * 4)));
            this._material = material;
            var i:int;
            while (i < mesh.surfaces.length) {
                src = mesh.surfaces[i];
                surf = new ZenFace(("batch_" + src.name));
                if ((((src.numTriangles == -1)) || ((src.numTriangles == (src.indexVector.length / 3))))){
                    numVertex = (src.vertexVector.length / src.sizePerVertex);
                    numIndices = src.indexVector.length;
                    countVertex = 0;
                    countIndices = 0;
                    count = 0;
                    positionVector = new Vector.<Number>();
                    vertexVector = new Vector.<Number>();
                    indexVector = new Vector.<uint>();
                    srcIndexVector = src.indexVector;
                    srcVertexVector = src.vertexVector;
                    srcVertexLength = src.vertexVector.length;
                    tp = 0;
                    tv = 0;
                    ti = 0;
                    while ((((((count < this._maxCount)) && (((countVertex + numVertex) < maxVertex)))) && (((countIndices + numIndices) < maxIndices)))) {
                        vtx = 0;
                        while (vtx < srcVertexLength) {
                            var _local27 = tv++;
                            vertexVector[_local27] = srcVertexVector[vtx];
                            vtx++;
                        }
                        idx = 0;
                        while (idx < numIndices) {
                            _local27 = ti++;
                            indexVector[_local27] = (srcIndexVector[idx] + countVertex);
                            idx++;
                        }
                        pos = 0;
                        while (pos < numVertex) {
                            _local27 = tp++;
                            positionVector[_local27] = count;
                            pos++;
                        }
                        countVertex = (countVertex + numVertex);
                        countIndices = (countIndices + numIndices);
                        count++;
                    }
                    this._count[i] = count;
                    this._tris[i] = (numIndices / 3);
                    surf.vertexVector = vertexVector;
                    surf.indexVector = indexVector;
                    surf.offset = src.offset;
                    surf.format = src.format;
                    surf.sizePerVertex = src.sizePerVertex;
                    sourceIndices = new ZenFace();
                    sourceIndices.addVertexData(8, 1, positionVector);
                    surf.sources[8] = sourceIndices;
                    surf.material = this._material;
                }
                this.surfaces.push(surf);
                i++;
            }
        }

        public function addInstance(position:Vector3D, orientation:Vector3D=null):void
        {
            this.positions.push(position);
            if (this._enableRotation) {
				
                if (!(orientation)){
					
                    throw new Error("Orientation vector can not be null when enableRotation is set to true.");
					
					return;
                }
				
                this.orientations.push(orientation);
            }
        }

        override public function get inView():Boolean
        {
            return (true);
        }

        public function get material():ZenMaterial
        {
            return (this._material);
        }

        public function get transformFilter():ShaderFilter
        {
            return (this._transform);
        }

        override public function draw(includeChildren:Boolean=true, material:ShaderMaterialBase=null):void
        {
            var surf:ZenFace;
            var total:int;
            var count:int;
            var paramIndex:int;
            var objRenderCount:int;
            var objIndex:int;
            var pos:Vector3D;
            var x:Number;
            var y:Number;
            var z:Number;
            var w:Number;
            var rot:Vector3D;
            if (!(scene)){
                upload(ZenUtils.scene);
            }
            ZenUtils.global.copyFrom(world);
            ZenUtils.worldViewProj.copyFrom(ZenUtils.global);
            ZenUtils.worldViewProj.append(ZenUtils.viewProj);
            ZenUtils.objectsDrawn++;
            material = ((material) || (this._material));
            var cam:ZenCamera = ZenUtils.camera;
            var radius:Number = this._mesh.bounds.radius;
            cam.view.copyRawDataTo(raw);
            var i:int;
            while (i < this.surfaces.length) {
                surf = this.surfaces[i];
                total = this.positions.length;
                count = this._count[i];
                paramIndex = 0;
                objRenderCount = 0;
                objIndex = 0;
                if (this.maxInstances >= 0){
                    total = this.maxInstances;
                }
                while (total > 0) {
                    pos = this.positions[objIndex];
                    x = pos.x;
                    y = pos.y;
                    z = pos.z;
                    w = pos.w;
                    if (this.enableCameraCulling){
                        vec.x = ((((x * raw[0]) + (y * raw[4])) + (z * raw[8])) + raw[12]);
                        vec.y = ((((x * raw[1]) + (y * raw[5])) + (z * raw[9])) + raw[13]);
                        vec.z = ((((x * raw[2]) + (y * raw[6])) + (z * raw[10])) + raw[14]);
                    }
                    if (((!(this.enableCameraCulling)) || (cam.isSphereInView(vec, (radius * w))))){
                        if (this._enableRotation){
                            rot = this.orientations[objIndex];
                            this._quatParam[paramIndex] = rot.x;
                            var _local18 = paramIndex++;
                            this._posParam[_local18] = x;
                            this._quatParam[paramIndex] = rot.y;
                            var _local19 = paramIndex++;
                            this._posParam[_local19] = y;
                            this._quatParam[paramIndex] = rot.z;
                            var _local20 = paramIndex++;
                            this._posParam[_local20] = z;
                            this._quatParam[paramIndex] = rot.w;
                            var _local21 = paramIndex++;
                            this._posParam[_local21] = w;
                        } else {
                            _local18 = paramIndex++;
                            this._posParam[_local18] = x;
                            _local19 = paramIndex++;
                            this._posParam[_local19] = y;
                            _local20 = paramIndex++;
                            this._posParam[_local20] = z;
                            _local21 = paramIndex++;
                            this._posParam[_local21] = w;
                        }
                        objRenderCount++;
                    }
                    objIndex++;
                    total--;
                    if ((((total == 0)) || ((objRenderCount >= count)))){
                        this._material.draw(this, surf, 0, (this._tris[i] * objRenderCount));
                        objRenderCount = 0;
                        paramIndex = 0;
                    }
                }
                i++;
            }
        }


    }
}

