package zen.animation
{
	import zen.materials.*;
	import zen.enums.*;
	import zen.display.*;
    import flash.events.Event;
    import flash.geom.Matrix3D;
    
    import flash.events.EventDispatcher;
    import flash.utils.Dictionary;
    import flash.geom.Vector3D;
    import zen.display.*;


    import zen.Label3D;
    import zen.shaders.textures.ShaderMaterialBase;
    import flash.events.*;
    import zen.display.*;
    import flash.utils.*;
    
    import zen.shaders.textures.*;
    import zen.utils.*;
    import zen.geom.*;
    import flash.display3D.*;
    import flash.geom.*;

    [Event(name="cange", type="flash.events.Event")]
    public class ZenSkinModifier extends Modifier implements IEventDispatcher 
    {
		// to keep IEventDispatcher functions
		

        private static var _changeEvent:Event = new Event(Event.CHANGE);

        public var mesh:ZenMesh;
        public var bindTransform:Matrix3D;
        public var bones:Vector.<ZenObject>;
        public var skinData:Vector.<Vector.<int>>;
        public var invBoneMatrix:Vector.<Matrix3D>;
        public var root:ZenObject;
        private var _totalFrames:int;
        private var _transformList:Vector.<ZenObject>;
        private var _events:EventDispatcher;
        private var _blending:Dictionary;

        public function ZenSkinModifier()
        {
            this.bindTransform = new Matrix3D();
            this.invBoneMatrix = new Vector.<Matrix3D>();
            this.root = new ZenObject("Root");
            this._blending = new Dictionary(true);
            super();
            this._events = new EventDispatcher(this);
        }

        public static function split(skin:ZenSkinModifier, surfaces:Vector.<ZenFace>):void
        {
            var surf:ZenFace;
            var data:ZenFace;
            var bonesPerVertex:int;
            var addeddBones:Dictionary;
            var sortedBones:Array;
            var last:int;
            var idx:int;
            var length:int;
            var offsetS:int;
            var offsetL:int;
            var temp:Vector.<Number>;
            var a:uint;
            var b:uint;
            var c:uint;
            var bone:int;
            var x:int;
            var y:int;
            var z:int;
            var newSurf:ZenFace;
            skin.skinData = new Vector.<Vector.<int>>();
            var maxBones:int = ZenUtils.maxBonesPerSurface;
            var newSurfaces:Vector.<ZenFace> = new Vector.<ZenFace>();
            var surfIndex:int;
            while (surfIndex < surfaces.length) {
                surf = surfaces[surfIndex];
                data = ((surf.sources[VertexType.SKIN_INDICES]) || (surf));
                bonesPerVertex = int(data.format[VertexType.SKIN_INDICES].substr(-1));
                addeddBones = new Dictionary();
                sortedBones = [];
                if (surf.numTriangles == -1){
                    surf.numTriangles = (surf.indexVector.length / 3);
                }
                last = 0;
                idx = surf.firstIndex;
                length = (idx + (surf.numTriangles * 3));
                offsetS = data.offset[VertexType.SKIN_INDICES];
                offsetL = (offsetS + bonesPerVertex);
                temp = data.vertexVector.concat();
                while (idx < length) {
                    a = surf.indexVector[idx++];
                    b = surf.indexVector[idx++];
                    c = surf.indexVector[idx++];
                    bone = offsetS;
                    while (bone < offsetL) {
                        x = temp[((a * data.sizePerVertex) + bone)];
                        y = temp[((b * data.sizePerVertex) + bone)];
                        z = temp[((c * data.sizePerVertex) + bone)];
                        if (addeddBones[x] == undefined){
                            addeddBones[x] = sortedBones.length;
                            sortedBones.push((x / 3));
                        }
                        if (addeddBones[y] == undefined){
                            addeddBones[y] = sortedBones.length;
                            sortedBones.push((y / 3));
                        }
                        if (addeddBones[z] == undefined){
                            addeddBones[z] = sortedBones.length;
                            sortedBones.push((z / 3));
                        }
                        data.vertexVector[((a * data.sizePerVertex) + bone)] = (addeddBones[x] * 3);
                        data.vertexVector[((b * data.sizePerVertex) + bone)] = (addeddBones[y] * 3);
                        data.vertexVector[((c * data.sizePerVertex) + bone)] = (addeddBones[z] * 3);
                        bone++;
                    }
                    if ((((sortedBones.length > maxBones)) || ((idx == length)))){
                        if (sortedBones.length > maxBones){
                            idx = (idx - 3);
                            sortedBones.length = maxBones;
                        }
                        if (sortedBones.length > 0){
                            newSurf = surf.clone();
                            newSurf.name = ("instanceOf " + surf.name);
                            newSurf.firstIndex = last;
                            newSurf.numTriangles = ((idx - last) / 3);
                            newSurfaces.push(newSurf);
                            skin.skinData.push(Vector.<int>(sortedBones));
                        }
                        addeddBones = new Dictionary();
                        sortedBones = [];
                        last = idx;
                    }
                }
                surfIndex++;
            }
            surfaces.length = 0;
            for each (surf in newSurfaces) {
                surfaces.push(surf);
            }
        }

        public static function updatePolys(skin:ZenSkinModifier, mesh:ZenMesh):void
        {
            var i:int;
            var bonePivot:ZenObject;
            var index:int;
            var s:ZenFace;
            var data:Vector.<int>;
            var boneCount:int;
            var transforms:Vector.<Matrix3D>;
            var b:int;
            var pIndex:int;
            var src:ZenFace;
            var indices:int;
            var weights:int;
            var bonesPerVertex:int;
            var size:int;
            var end:int;
            var vertex:Vector.<Number>;
            var srcVector:Vector.<Number>;
            var srcSize:int;
            var siv:Vector.<uint>;
            var bone:int;
            var i0:int;
            var i1:int;
            var i2:int;
            var boneIndex:int;
            var boneWeight:Number;
            var p:Poly3D;
            var length:int = skin._transformList.length;
            var frame:int = (mesh.currentFrame % skin.totalFrames);
            i = 0;
            while (i < length) {
                bonePivot = skin._transformList[i];
                if (bonePivot.frames){
                    bonePivot.transform.copyFrom(bonePivot.frames[frame]);
                }
                bonePivot.dirty = true;
                i++;
            }
            var bounds:Cube3D = new Cube3D();
            bounds.min.setTo(10000000, 10000000, 10000000);
            bounds.max.setTo(-10000000, -10000000, -10000000);
            var v0:Vector3D = new Vector3D();
            var v1:Vector3D = new Vector3D();
            var v2:Vector3D = new Vector3D();
            var t:Vector3D = new Vector3D();
            for each (s in mesh.surfaces) {
                if (!(s.polys)){
                    s.buildPolys();
                }
                data = skin.skinData[index++];
                boneCount = data.length;
                transforms = new Vector.<Matrix3D>();
                b = 0;
                while (b < boneCount) {
                    bone = data[b];
                    ZenUtils.temporal0.copyFrom(skin.invBoneMatrix[bone]);
                    ZenUtils.temporal0.append(skin.bones[bone].world);
                    transforms[b] = ZenUtils.temporal0.clone();
                    b++;
                }
                pIndex = (s.firstIndex / 3);
                src = ((s.sources[VertexType.SKIN_INDICES]) || (s));
                indices = src.offset[VertexType.SKIN_INDICES];
                weights = src.offset[VertexType.SKIN_WEIGHTS];
                bonesPerVertex = int(src.format[VertexType.SKIN_INDICES].substr(-1));
                size = s.sizePerVertex;
                end = (s.firstIndex + (s.numTriangles * 3));
                vertex = s.vertexVector;
                srcVector = src.vertexVector;
                srcSize = src.sizePerVertex;
                siv = s.indexVector;
                i = s.firstIndex;
                while (i < end) {
                    i0 = siv[(i + 2)];
                    i1 = siv[(i + 1)];
                    i2 = siv[i];
                    v0.setTo(0, 0, 0);
                    v1.setTo(0, 0, 0);
                    v2.setTo(0, 0, 0);
                    bone = 0;
                    while (bone < bonesPerVertex) {
                        boneIndex = (srcVector[(((i0 * srcSize) + indices) + bone)] / 3);
                        boneWeight = srcVector[(((i0 * srcSize) + weights) + bone)];
                        t.x = vertex[(i0 * size)];
                        t.y = vertex[((i0 * size) + 1)];
                        t.z = vertex[((i0 * size) + 2)];
                        M3D.transformVector(transforms[boneIndex], t, t);
                        t.scaleBy(boneWeight);
                        v0.incrementBy(t);
                        boneIndex = (srcVector[(((i1 * srcSize) + indices) + bone)] / 3);
                        boneWeight = srcVector[(((i1 * srcSize) + weights) + bone)];
                        t.x = vertex[(i1 * size)];
                        t.y = vertex[((i1 * size) + 1)];
                        t.z = vertex[((i1 * size) + 2)];
                        M3D.transformVector(transforms[boneIndex], t, t);
                        t.scaleBy(boneWeight);
                        v1.incrementBy(t);
                        boneIndex = (srcVector[(((i2 * srcSize) + indices) + bone)] / 3);
                        boneWeight = srcVector[(((i2 * srcSize) + weights) + bone)];
                        t.x = vertex[(i2 * size)];
                        t.y = vertex[((i2 * size) + 1)];
                        t.z = vertex[((i2 * size) + 2)];
                        M3D.transformVector(transforms[boneIndex], t, t);
                        t.scaleBy(boneWeight);
                        v2.incrementBy(t);
                        bone++;
                    }
                    V3D.min(bounds.min, v0, bounds.min);
                    V3D.min(bounds.min, v1, bounds.min);
                    V3D.min(bounds.min, v2, bounds.min);
                    V3D.max(bounds.max, v0, bounds.max);
                    V3D.max(bounds.max, v1, bounds.max);
                    V3D.max(bounds.max, v2, bounds.max);
                    if (s.polys){
                        p = s.polys[pIndex++];
                        p.v0.x = v0.x;
                        p.v0.y = v0.y;
                        p.v0.z = v0.z;
                        p.v1.x = v1.x;
                        p.v1.y = v1.y;
                        p.v1.z = v1.z;
                        p.v2.x = v2.x;
                        p.v2.y = v2.y;
                        p.v2.z = v2.z;
                        p.update();
                    }
                    i = (i + 3);
                }
            }
            bounds.length.x = (bounds.max.x - bounds.min.x);
            bounds.length.y = (bounds.max.y - bounds.min.y);
            bounds.length.z = (bounds.max.z - bounds.min.z);
            bounds.center.x = (bounds.min.x + (bounds.length.x * 0.5));
            bounds.center.y = (bounds.min.y + (bounds.length.y * 0.5));
            bounds.center.z = (bounds.min.z + (bounds.length.z * 0.5));
            bounds.radius = Vector3D.distance(bounds.center, bounds.max);
            mesh.bounds = bounds;
        }


        override public function clone():Modifier
        {
            return (this);
        }

        public function addBone(pivot:ZenObject):int
        {
            if (!(this.bones)){
                this.bones = new Vector.<ZenObject>();
            }
            if (((pivot.frames) && ((pivot.frames.length > this._totalFrames)))){
                this._totalFrames = pivot.frames.length;
            }
            return ((this.bones.push(pivot) - 1));
        }

        public function update():void
        {
            var p:ZenObject;
            if (!(this._transformList)){
                this._totalFrames = 0;
                this._transformList = new Vector.<ZenObject>();
                this.root.lock = true;
                for each (p in this.root.children) {
                    this.addBoneToList(p);
                }
                for each (p in this._transformList) {
                    while (((p.frames) && ((p.frames.length < this._totalFrames)))) {
                        p.frames.push(p.frames[(p.frames.length - 1)]);
                    }
                }
            }
        }

        public function setBlendingState(mesh:ZenMesh):void
        {
            var p:ZenObject;
            var m:Matrix3D;
            this.setFrame(mesh);
            var length:int = this._transformList.length;
            var blend:Dictionary = ((this._blending[mesh]) || (new Dictionary(true)));
            this._blending[mesh] = blend;
            var i:int;
            while (i < length) {
                p = this._transformList[i];
                m = ((blend[p]) || (new Matrix3D()));
                m.copyFrom(p.transform);
                blend[p] = m;
                i++;
            }
        }

        private function setFrame(mesh:ZenMesh):void
        {
            var i:int;
            var p:ZenObject;
            var label:Label3D;
            var from:int;
            var to:int;
            var labelLength:int;
            var toFrame:int;
            var percent:Number;
            var length:int = this._transformList.length;
            var currFrame:int = mesh.currentFrame;
            var smooth:int = mesh.animationSmoothMode;
            if ((((((mesh.frameSpeed >= 1)) && ((currFrame == mesh.currentFrame)))) || ((smooth == AnimationType.SMOOTH_NONE)))){
                i = 0;
                while (i < length) {
                    p = this._transformList[i];
                    if (p.frames){
                        p.transform.copyFrom(p.frames[currFrame]);
                    }
                    p.dirty = true;
                    i++;
                }
            } else {
                label = mesh.currentLabel;
                if (!(label)){
                    from = 0;
                    to = this._totalFrames;
                } else {
                    from = label.from;
                    to = label.to;
                }
                labelLength = (to - from);
                toFrame = ((currFrame + 1) - from);
                percent = (mesh.currentFrame - currFrame);
                if (mesh.animationMode == AnimationType.LOOP_MODE){
                    toFrame = (toFrame % labelLength);
                } else {
                    if (mesh.animationMode == AnimationType.STOP_MODE){
                        if (toFrame > labelLength){
                            toFrame = labelLength;
                        }
                    }
                }
                i = 0;
                while (i < length) {
                    p = this._transformList[i];
                    if (p.frames){
                        p.transform.copyFrom(p.frames[currFrame]);
                        if (smooth == AnimationType.SMOOTH_NORMAL){
                            p.transform.interpolateTo(p.frames[(toFrame + from)], percent);
                        } else {
                            M3D.interpolateTo(p.transform, p.frames[(toFrame + from)], percent);
                        }
                    }
                    p.dirty = true;
                    i++;
                }
            }
        }

        override public function draw(mesh:ZenMesh, material:ShaderMaterialBase=null):void
        {
            var i:int;
            var p:ZenObject;
            var index:int;
            var surf:ZenFace;
            var blend:Dictionary;
            var data:Vector.<int>;
            var boneCount:int;
            var b:int;
            var bone:int;
            var length:int = this._transformList.length;
            var currFrame:int = mesh.currentFrame;
            var transform:Boolean = true;
            var smooth:int = mesh.animationSmoothMode;
            this.setFrame(mesh);
            if (mesh.blendValue != 1){
                blend = this._blending[mesh];
                i = 0;
                while (i < length) {
                    p = this._transformList[i];
                    if (p.frames){
                        if (smooth == AnimationType.SMOOTH_NORMAL){
                            p.transform.interpolateTo(Matrix3D(blend[p]), (1 - mesh.blendValue));
                        } else {
                            M3D.interpolateTo(p.transform, Matrix3D(blend[p]), (1 - mesh.blendValue));
                        }
                    }
                    p.dirty = true;
                    i++;
                }
            }
            if (this._events.hasEventListener(Event.CHANGE)){
                this.dispatchEvent(_changeEvent);
            }
            ZenUtils.global.copyFrom(mesh.world);
            ZenUtils.worldViewProj.copyFrom(ZenUtils.global);
            ZenUtils.worldViewProj.append(ZenUtils.viewProj);
            ZenUtils.objectsDrawn++;
            for each (surf in mesh.surfaces) {
                data = this.skinData[index++];
                if (!(surf.visible)){
                } else {
                    boneCount = data.length;
                    b = 0;
                    while (b < boneCount) {
                        bone = data[b];
                        ZenUtils.temporal0.copyFrom(this.invBoneMatrix[bone]);
                        ZenUtils.temporal0.append(this.bones[bone].world);
                        ZenUtils.temporal0.copyRawDataTo(ZenUtils.bones, (b * 12), true);
                        b++;
                    }
                    ShaderMaterialBase(((material) || (surf.material))).draw(mesh, surf, surf.firstIndex, surf.numTriangles);
                }
            }
        }

        private function addBoneToList(pivot:ZenObject):void
        {
            var p:ZenObject;
            pivot.lock = true;
            for each (p in pivot.children) {
                this.addBoneToList(p);
            }
            if (((pivot.frames) && ((pivot.frames.length > this._totalFrames)))){
                this._totalFrames = pivot.frames.length;
            }
            this._transformList.push(pivot);
        }

        public function get totalFrames():int
        {
            return (this._totalFrames);
        }

        public function set totalFrames(value:int):void
        {
            this._totalFrames = value;
        }

        public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void
        {
            this._events.addEventListener(type, listener, useCapture, priority, useWeakReference);
        }

        public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
        {
            this._events.removeEventListener(type, listener, useCapture);
        }

        public function dispatchEvent(event:Event):Boolean
        {
            return (this._events.dispatchEvent(event));
        }

        public function hasEventListener(type:String):Boolean
        {
            return (this._events.hasEventListener(type));
        }

        public function willTrigger(type:String):Boolean
        {
            return (this._events.willTrigger(type));
        }


    }
}

