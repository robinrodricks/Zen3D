package zen.display
{
	import zen.display.*;
	import zen.display.*;
	import zen.materials.*;
	import zen.enums.*;
    import flash.geom.*;
	import flash.utils.Dictionary;
    import zen.shaders.*;
    import zen.shaders.textures.*;
    import zen.effects.*;
    import zen.animation.*;
    import zen.utils.*;
    import zen.geom.*;
    import flash.display3D.*;
    

    public class ZenShadowLight extends ZenLight 
    {


		[Embed(source = "../utils/assets/display/ZenShadowLight_DepthPass.data", mimeType = "application/octet-stream")]
        private static var DepthPass:Class;
		
		[Embed(source = "../utils/assets/display/ZenShadowLight_ShadowPass.data", mimeType = "application/octet-stream")]
        private static var ShadowPass:Class;

        private var _camera:ZenCamera;
        private var _debug:Boolean = false;
        private var _depthTexture:Texture3D;
        private var _cascades:int;
        private var _quality:int;
        private var _autoFade:Boolean = false;
        private var _mapSize:int;
        private var _bias:Number = 0.0002;
        private var _scissorRec:Rectangle;
        private var _build:Boolean = false;
        private var _depth:ShaderMaterial;
        private var _depthSkin:ShaderMaterial;
        private var _depthKill:ShaderMaterial;
        private var _shadow:ShaderMaterial;
        private var _shadowSkin:ShaderMaterial;
        private var _shadowKill:ShaderMaterial;
        private var _corners:Vector.<Vector3D>;
        private var _wCorners:Vector.<Vector3D>;
        private var _projection:Vector.<Matrix3D>;
        private var _lightViewProjection:Vector.<Matrix3D>;
        private var _min:Vector3D;
        private var _max:Vector3D;
        private var _size:Vector3D;
        private var _splits:Vector.<Number>;
        public var casters:Vector.<ZenObject>;
        public var receivers:Vector.<ZenObject>;
        public var depth:Number = 5000;
        public var filter:Number = 500;
        public var autoFadeStrength:Number = 1;
        private var _near:Number = 0.1;
        private var _far:Number = 300;
        private var _splitStrength:Number = 0.5;
        private var _fov:Number;
        private var _dir:Vector3D;

        public function ZenShadowLight(name:String="Shadow Projector", quality:int=0x0800, cascades:int=1)
        {
            this._min = new Vector3D();
            this._max = new Vector3D();
            this._size = new Vector3D();
            this._dir = new Vector3D();
            super(name, LightType.DIRECTIONAL);
            this._cascades = cascades;
            this._quality = quality;
            layer = -1000;
        }

        override public function upload(scene:Zen3D, includeChildren:Boolean=true):void
        {
            super.upload(scene, includeChildren);
            if (!(this._build)){
                this.build();
            }
        }

        override protected function addedToScene(scene:Zen3D):void
        {
            if (!(scene.lights.projectors)){
                scene.lights.projectors = new Vector.<ZenShadowLight>();
            }
            scene.lights.projectors.push(this);
            super.addedToScene(scene);
            if (!(this._build)){
                this.build();
            }
        }

        override protected function removedFromScene():void
        {
            this._build = false;
            scene.lights.projectors.splice(scene.lights.projectors.indexOf(this), 1);
            if (scene.lights.projectors.length == 0){
                scene.lights.projectors = null;
            }
            super.removedFromScene();
        }

        override public function clone():ZenObject
        {
            var c:ZenObject;
            var n:ZenShadowLight = new ZenShadowLight(name, this.quality, this.cascades);
            n.copyFrom(this);
            n.debug = this.debug;
            n.near = this.near;
            n.far = this.far;
            n.splitStrength = this.splitStrength;
            n.autoFade = this.autoFade;
            n.autoFadeStrength = this.autoFadeStrength;
            n.filter = this.filter;
            n.depth = this.depth;
            n.setParams(((((color.x * 0xFF) << 16) ^ ((color.y * 0xFF) << 8)) ^ (color.z * 0xFF)), radius, attenuation, multiplier, infinite);
            for each (c in children) {
                if (!(c.lock)){
                    n.addChild(c.clone());
                }
            }
            return (n);
        }

        override public function dispose():void
        {
            super.dispose();
            this._camera = null;
            this._depthTexture.dispose();
            this._depthTexture = null;
            this._scissorRec = null;
            this._depth.dispose();
            this._depth = null;
            this._depthSkin.dispose();
            this._depthSkin = null;
            this._depthKill.dispose();
            this._depthKill = null;
            this._shadow.dispose();
            this._shadow = null;
            this._shadowSkin.dispose();
            this._shadowSkin = null;
            this._shadowKill.dispose();
            this._shadowKill = null;
            this._corners = null;
            this._wCorners = null;
            this._projection = null;
            this._lightViewProjection = null;
            this._min = null;
            this._max = null;
            this._size = null;
            this._splits = null;
            this._dir = null;
            this.casters = null;
            this.receivers = null;
        }

        public function get depthTexture():Texture3D
        {
            return (this._depthTexture);
        }

        public function get debug():Boolean
        {
            return (this._debug);
        }

        public function set debug(value:Boolean):void
        {
            this._debug = value;
            this._build = false;
        }

        public function get autoFade():Boolean
        {
            return (this._autoFade);
        }

        public function set autoFade(value:Boolean):void
        {
            this._autoFade = value;
            this._build = false;
        }

        public function get far():Number
        {
            return (this._far);
        }

        public function set far(value:Number):void
        {
            this._far = value;
            this.computeSplites();
        }

        public function get near():Number
        {
            return (this._near);
        }

        public function set near(value:Number):void
        {
            this._near = value;
            this.computeSplites();
        }

        public function get splitStrength():Number
        {
            return (this._splitStrength);
        }

        public function set splitStrength(value:Number):void
        {
            this._splitStrength = value;
            this.computeSplites();
        }

        public function get quality():int
        {
            return (this._quality);
        }

        public function set quality(value:int):void
        {
            this._quality = value;
            this._build = false;
        }

        public function get cascades():int
        {
            return (this._cascades);
        }

        public function set cascades(value:int):void
        {
            this._cascades = value;
            this._build = false;
        }

        public function get bias():Number
        {
            return ((this._bias * 10000));
        }

        public function set bias(value:Number):void
        {
            this._bias = (value / 10000);
        }

        private function build():void
        {
            if (!(scene)) {
				
                throw new Error("The projector must be uploaded to the scene first.");
				
				return;
            }
            this._build = true;
            this._mapSize = (((this.cascades > 1)) ? (this.quality * 0.5) : this.quality);
            this._scissorRec = new Rectangle(1, 1, (this._mapSize - 2), (this._mapSize - 2));
            if (this._depthTexture){
                this._depthTexture.dispose();
            }
            if (this.cascades == 1){
                this._depthTexture = new Texture3D(new Rectangle(0, 0, this.quality, this.quality), true);
            } else {
                if (this.cascades <= 2){
                    this._depthTexture = new Texture3D(new Rectangle(0, 0, this.quality, (this.quality * 0.5)), true);
                } else {
                    this._depthTexture = new Texture3D(new Rectangle(0, 0, this.quality, this.quality), true);
                }
            }
            this._depthTexture.wrapMode = TextureWrap.CLAMP;
            this._depthTexture.mipMode = TextureMipMapping.NONE;
            this._depthTexture.upload(scene);
            this._depth = new ShaderMaterial("depth", new DepthPass(), "shadowDepth_normal");
            this._depthSkin = new ShaderMaterial("depthSkin", null, "shadowDepth_skin");
            this._depthSkin.byteCode = new DepthPass();
            this._depthSkin.params.bones = Vector.<Number>([ZenUtils.maxBonesPerVertex]);
            this._depthSkin.build();
            this._depthKill = new ShaderMaterial("depthKill", new DepthPass(), "shadowDepth_kill");
            this._shadow = new ShaderMaterial("shadow", null, "shadowMap_normal");
            this._shadow.byteCode = new ShadowPass();
            this._shadow.params.depthMap.value = this._depthTexture;
            this._shadow.params.splits.value = Vector.<Number>([this._cascades]);
            this._shadow.params.autoFade.value = Vector.<Number>([((this._autoFade) ? 1 : 0)]);
            this._shadow.params.debug.value = Vector.<Number>([((this._debug) ? 1 : 0)]);
            this._shadow.params.autoFadeAtten.value = new Vector.<Number>();
            this._shadow.build();
            this._shadowSkin = new ShaderMaterial("shadowSkin", null, "shadowMap_skin");
            this._shadowSkin.byteCode = new ShadowPass();
            this._shadowSkin.params.depthMap.value = this._depthTexture;
            this._shadowSkin.params.splits.value = Vector.<Number>([this._cascades]);
            this._shadowSkin.params.autoFade.value = Vector.<Number>([((this._autoFade) ? 1 : 0)]);
            this._shadowSkin.params.debug.value = Vector.<Number>([((this._debug) ? 1 : 0)]);
            this._shadowSkin.params.autoFadeAtten.value = new Vector.<Number>();
            this._shadowSkin.params.bones = Vector.<Number>([ZenUtils.maxBonesPerVertex]);
            this._shadowSkin.build();
            this._shadowKill = new ShaderMaterial("shadowSkin", null, "shadowMap_kill");
            this._shadowKill.byteCode = new ShadowPass();
            this._shadowKill.params.depthMap.value = this._depthTexture;
            this._shadowKill.params.splits.value = Vector.<Number>([this._cascades]);
            this._shadowKill.params.autoFade.value = Vector.<Number>([((this._autoFade) ? 1 : 0)]);
            this._shadowKill.params.debug.value = Vector.<Number>([((this._debug) ? 1 : 0)]);
            this._shadowKill.params.autoFadeAtten.value = new Vector.<Number>();
            this._shadowKill.build();
            this.computeSplites();
        }

        private function computeSplites():void
        {
            var partisionFactor:Number;
            var lerpValue1:Number;
            var lerpValue2:Number;
            if (!(this._build)){
                return;
            }
            var distance_scale:Number = (this._far / this._near);
            this._splits = new Vector.<Number>((this._cascades + 1), true);
            var i:int;
            while (i < this._cascades) {
                partisionFactor = (((0.5 * i) / this._cascades) * 2);
                lerpValue1 = (this.near + (partisionFactor * (this._far - this._near)));
                lerpValue2 = (this.near * Math.pow(distance_scale, partisionFactor));
                this._splits[i] = ((((1 - this._splitStrength) * lerpValue1) + (this._splitStrength * lerpValue2)) + this._near);
                i++;
            }
            this._splits[i] = this._far;
            var splitNear:Vector.<Number> = new Vector.<Number>(4);
            var splitFar:Vector.<Number> = new Vector.<Number>(4);
            i = 0;
            while (i < this._cascades) {
                splitNear[i] = this._splits[i];
                splitFar[i] = this._splits[(i + 1)];
                i++;
            }
            while (i < 4) {
                splitNear[i] = this._far;
                splitFar[i] = this._far;
                i++;
            }
            this._shadow.params.lightSplitsNear.value = splitNear;
            this._shadow.params.lightSplitsFar.value = splitFar;
            this._shadowSkin.params.lightSplitsNear.value = splitNear;
            this._shadowSkin.params.lightSplitsFar.value = splitFar;
            this._shadowKill.params.lightSplitsNear.value = splitNear;
            this._shadowKill.params.lightSplitsFar.value = splitFar;
            this.computeCorners();
        }

        private function computeCorners():void
        {
            var split:Number;
            var sx:Number;
            var sy:Number;
            if (!(this._build)){
                return;
            }
            var cam:ZenCamera = ((this._camera) || (ZenUtils.camera));
            var aspectRatio:Number = ((cam.aspectRatio) || (1));
            var count:int;
            this._fov = cam.fieldOfView;
            this._projection = new Vector.<Matrix3D>();
            this._lightViewProjection = new Vector.<Matrix3D>();
            this._corners = new Vector.<Vector3D>();
            this._wCorners = new Vector.<Vector3D>();
            var i:int;
            while (i <= this._cascades) {
                split = this._splits[i];
                sx = (cam.zoom * split);
                sy = ((cam.zoom * split) / aspectRatio);
                var _local8 = count++;
                this._corners[_local8] = new Vector3D(-(sx), sy, split);
                var _local9 = count++;
                this._corners[_local9] = new Vector3D(sx, sy, split);
                var _local10 = count++;
                this._corners[_local10] = new Vector3D(-(sx), -(sy), split);
                var _local11 = count++;
                this._corners[_local11] = new Vector3D(sx, -(sy), split);
                i++;
            }
            i = 0;
            while (i < this._corners.length) {
                this._wCorners[i] = new Vector3D();
                i++;
            }
            i = 0;
            while (i < this._cascades) {
                this._projection[i] = new Matrix3D();
                this._lightViewProjection[i] = new Matrix3D();
                i++;
            }
        }

        private function updateAllCorners():void
        {
            var cam:ZenCamera = ((this._camera) || (ZenUtils.camera));
            ZenUtils.temporal0.copyFrom(cam.world);
            ZenUtils.temporal0.append(invWorld);
            var len:int = this._corners.length;
            var i:int;
            while (i < len) {
                M3D.transformVector(ZenUtils.temporal0, this._corners[i], this._wCorners[i]);
                i++;
            }
        }

        private function updateCascade(index:int=0):void
        {
            var from:int = (index * 4);
            var len:int = (from + 8);
            this._min.copyFrom(this._wCorners[from]);
            this._max.copyFrom(this._wCorners[from]);
            var i:int = from;
            while (i < len) {
				var corner:Vector3D = this._wCorners[i];
                if (corner.x < this._min.x){
                    this._min.x = corner.x;
                }
                if (corner.y < this._min.y){
                    this._min.y = corner.y;
                }
                if (corner.z < this._min.z){
                    this._min.z = corner.z;
                }
                if (corner.x > this._max.x){
                    this._max.x = corner.x;
                }
                if (corner.y > this._max.y){
                    this._max.y = corner.y;
                }
                if (corner.z > this._max.z){
                    this._max.z = corner.z;
                }
                i++;
            }
            this._size.copyFrom(this._wCorners[(from + 2)]);
            this._size.decrementBy(this._wCorners[(from + 5)]);
            var diagonalLength:Number = (this._size.length + 2);
            var worldsUnitsPerTexel:Number = ((diagonalLength / this._mapSize) * 2);
            var vBorderOffset:Vector3D = new Vector3D(diagonalLength, diagonalLength, diagonalLength);
            this._size.copyFrom(this._max);
            this._size.decrementBy(this._min);
            vBorderOffset.decrementBy(this._size);
            vBorderOffset.scaleBy(0.5);
            this._max.incrementBy(vBorderOffset);
            this._min.decrementBy(vBorderOffset);
            this._min.scaleBy((1 / worldsUnitsPerTexel));
            this._max.scaleBy((1 / worldsUnitsPerTexel));
            this._min.x = (int(this._min.x) * worldsUnitsPerTexel);
            this._min.y = (int(this._min.y) * worldsUnitsPerTexel);
            this._min.z = (int(this._min.z) * worldsUnitsPerTexel);
            this._max.x = (int(this._max.x) * worldsUnitsPerTexel);
            this._max.y = (int(this._max.y) * worldsUnitsPerTexel);
            this._max.z = (int(this._max.z) * worldsUnitsPerTexel);
            this._min.z = 0;
            this._max.z = this.depth;
            M3D.buildOrthoProjection(this._min.x, this._max.x, this._min.y, this._max.y, this._min.z, this._max.z, this._projection[index]);
        }

        private function drawDepth(index:int, x:Number, y:Number):void
        {
            var m:ZenMesh;
            var surfaces:int;
            var s:int;
            var surf:ZenFace;
            var shader:ZenMaterial;
            this.updateCascade(index);
            this._scissorRec.x = (x + 1);
            this._scissorRec.y = (y + 1);
            this._scissorRec.width = (this._mapSize - 2);
            this._scissorRec.height = (this._mapSize - 2);
            scene.context.setScissorRectangle(this._scissorRec);
            this._lightViewProjection[index].copyFrom(invWorld);
            this._lightViewProjection[index].append(this._projection[index]);
            ZenUtils.viewProj.copyFrom(this._projection[index]);
            if (this._cascades > 1){
                ZenUtils.viewProj.appendScale(0.5, 0.5, 1);
                ZenUtils.viewProj.appendTranslation((-0.5 + (x / this._mapSize)), (0.5 - (y / this._mapSize)), 0);
            }
            ZenUtils.viewProj.prepend(invWorld);
            var vec:Vector.<ZenObject> = ((this.casters) || (scene.renderList));
            var len:int = vec.length;
            var i:int;
            while (i < len) {
                m = (vec[i] as ZenMesh);
                if (((((!(m)) || ((m.visible == false)))) || (!(m.castShadows)))){
                } else {
                    if (Object(m.modifier).constructor == Modifier){
                        ZenUtils.global.copyFrom(m.world);
                        ZenUtils.worldViewProj.copyFrom(ZenUtils.global);
                        ZenUtils.worldViewProj.append(ZenUtils.viewProj);
                        ZenUtils.objectsDrawn++;
                        surfaces = m.surfaces.length;
                        s = 0;
                        while (s < surfaces) {
                            surf = m.surfaces[s];
                            if (!!(surf.material)){
                                if ((surf.material.flags & MaterialFlags.MASK)){
                                    shader = (surf.material as ZenMaterial);
									var params0:Dictionary = (shader.filters[0] as ShaderFilter).params;
                                    if ((((shader.filters[0] is TextureMapFilter)) && ((params0.mask.value[0] > 0)))) {
										var dkparams:Dictionary = this._depthKill.params;
                                        dkparams.texture.value = params0.texture.value;
                                        dkparams.mask.value[0] = params0.mask.value[0];
                                        dkparams.ro.value[0] = params0.repeat.value[0];
                                        dkparams.ro.value[1] = params0.repeat.value[1];
                                        dkparams.ro.value[2] = params0.offset.value[0];
                                        dkparams.ro.value[3] = params0.offset.value[1];
                                        this._depthKill.programs[0].cullFace = surf.material.cullFace;
                                        this._depthKill.draw(m, surf, surf.firstIndex, surf.numTriangles);
                                    } else {
                                        this._depth.programs[0].cullFace = surf.material.cullFace;
                                        this._depth.draw(m, surf, surf.firstIndex, surf.numTriangles);
                                    }
                                } else {
                                    this._depth.programs[0].cullFace = surf.material.cullFace;
                                    this._depth.draw(m, surf, surf.firstIndex, surf.numTriangles);
                                }
                            }
                            s++;
                        }
                    } else {
                        m.modifier.draw(m, this._depthSkin);
                    }
                }
                i++;
            }
        }

        public function renderShadowMap(srcFactor:String="one", destFactor:String="zero", shadowTexture:Texture3D=null):void
        {
            var m:ZenMesh;
            var surfaces:int;
            var s:int;
            var surf:ZenFace;
            var shader:ZenMaterial;
            if (((((!(visible)) || (!(scene)))) || (!(scene.context)))){
                return;
            }
            if (!(this._build)){
                this.build();
            }
            if (shadowTexture){
                scene.context.setRenderToTexture(shadowTexture.texture, true);
                scene.context.clear();
            }
            var cam:ZenCamera = ((this._camera) || (ZenUtils.camera));
            this._shadow.params.lightViewProj0.value = this._lightViewProjection[0];
            if (this._cascades > 1){
                this._shadow.params.lightViewProj1.value = this._lightViewProjection[1];
            }
            if (this._cascades > 2){
                this._shadow.params.lightViewProj2.value = this._lightViewProjection[2];
            }
            if (this._cascades > 3){
                this._shadow.params.lightViewProj3.value = this._lightViewProjection[3];
            }
            this._shadowSkin.params.lightViewProj0.value = this._lightViewProjection[0];
            if (this._cascades > 1){
                this._shadowSkin.params.lightViewProj1.value = this._lightViewProjection[1];
            }
            if (this._cascades > 2){
                this._shadowSkin.params.lightViewProj2.value = this._lightViewProjection[2];
            }
            if (this._cascades > 3){
                this._shadowSkin.params.lightViewProj2.value = this._lightViewProjection[3];
            }
            this._shadowKill.params.lightViewProj0.value = this._lightViewProjection[0];
            if (this._cascades > 1){
                this._shadowKill.params.lightViewProj1.value = this._lightViewProjection[1];
            }
            if (this._cascades > 2){
                this._shadowKill.params.lightViewProj2.value = this._lightViewProjection[2];
            }
            if (this._cascades > 3){
                this._shadowKill.params.lightViewProj2.value = this._lightViewProjection[3];
            }
            this._dir = getDir(false, this._dir);
            this._dir.negate();
			var shparams:Dictionary = this._shadow.params;
            shparams.lightDir.value[0] = this._dir.x;
            shparams.lightDir.value[1] = this._dir.y;
            shparams.lightDir.value[2] = this._dir.z;
            shparams.bias.value[0] = this._bias;
            shparams.shadowFiltering.value[0] = this.filter;
            shparams.autoFadeAtten.value[0] = this.autoFadeStrength;
			var skparams:Dictionary = this._shadowSkin.params;
            skparams.lightDir.value[0] = this._dir.x;
            skparams.lightDir.value[1] = this._dir.y;
            skparams.lightDir.value[2] = this._dir.z;
            skparams.bias.value[0] = this._bias;
            skparams.shadowFiltering.value[0] = this.filter;
            skparams.autoFadeAtten.value[0] = this.autoFadeStrength;
			var shkparams:Dictionary = this._shadowKill.params;
            shkparams.lightDir.value[0] = this._dir.x;
            shkparams.lightDir.value[1] = this._dir.y;
            shkparams.lightDir.value[2] = this._dir.z;
            shkparams.bias.value[0] = this._bias;
            shkparams.shadowFiltering.value[0] = this.filter;
            shkparams.autoFadeAtten.value[0] = this.autoFadeStrength;
            this._shadow.programs[0].sourceFactor = srcFactor;
            this._shadow.programs[0].destFactor = destFactor;
            this._shadowSkin.programs[0].sourceFactor = srcFactor;
            this._shadowSkin.programs[0].destFactor = destFactor;
            this._shadowKill.programs[0].sourceFactor = srcFactor;
            this._shadowKill.programs[0].destFactor = destFactor;
            scene.context.setScissorRectangle(cam.viewPort);
            ZenUtils.viewProj.copyFrom(cam.viewProjection);
            var vec:Vector.<ZenObject> = ((this.receivers) || (scene.renderList));
            var len:int = vec.length;
            var offset:Number = 0;
            var i:int;
            while (i < len) {
                m = (vec[i] as ZenMesh);
                if (((((!(m)) || ((m.visible == false)))) || (!(m.inView)))){
                } else {
                    offset = ((m.receiveShadows) ? 0 : 1);
                    this._shadow.params.offset.value[0] = offset;
                    this._shadowSkin.params.offset.value[0] = offset;
                    this._shadowKill.params.offset.value[0] = offset;
                    if (Object(m.modifier).constructor == Modifier){
                        ZenUtils.global.copyFrom(m.world);
                        ZenUtils.worldViewProj.copyFrom(ZenUtils.global);
                        ZenUtils.worldViewProj.append(ZenUtils.viewProj);
                        ZenUtils.objectsDrawn++;
                        surfaces = m.surfaces.length;
                        s = 0;
                        while (s < surfaces) {
                            surf = m.surfaces[s];
                            shader = (surf.material as ZenMaterial);
                            if (!!(shader)){
                                if ((surf.material.flags & MaterialFlags.MASK)){
									var params0:Dictionary = (shader.filters[0] as ShaderFilter).params;
                                    if ((((shader.filters[0] is TextureMapFilter)) && ((params0.mask.value[0] > 0)))) {
										var skparams:Dictionary = this._shadowKill.params;
                                        skparams.texture.value = params0.texture.value;
                                        skparams.mask.value[0] = params0.mask.value[0];
                                        skparams.ro.value[0] = params0.repeat.value[0];
                                        skparams.ro.value[1] = params0.repeat.value[1];
                                        skparams.ro.value[2] = params0.offset.value[0];
                                        skparams.ro.value[3] = params0.offset.value[1];
                                        this._shadowKill.programs[0].cullFace = surf.material.cullFace;
                                        this._shadowKill.draw(m, surf, surf.firstIndex, surf.numTriangles);
                                    } else {
                                        this._shadow.programs[0].cullFace = surf.material.cullFace;
                                        this._shadow.draw(m, surf, surf.firstIndex, surf.numTriangles);
                                    }
                                } else {
                                    this._shadow.programs[0].cullFace = surf.material.cullFace;
                                    this._shadow.draw(m, surf, surf.firstIndex, surf.numTriangles);
                                }
                            }
                            s++;
                        }
                    } else {
                        m.draw(false, this._shadowSkin);
                    }
                }
                i++;
            }
        }

        public function renderDepthMap(depthTexture:Texture3D=null):void
        {
            if (((!(scene)) || (!(scene.context)))){
                return;
            }
            if (!(this._build)){
                this.build();
            }
            var cam:ZenCamera = ((this._camera) || (ZenUtils.camera));
            if (this._fov != cam.fieldOfView){
                this.computeCorners();
            }
            depthTexture = ((depthTexture) || (this._depthTexture));
            if (!(depthTexture.scene)){
                depthTexture.upload(scene);
            }
            scene.context.setRenderToTexture(depthTexture.texture, true);
            scene.context.clear(1, 1, 1, 1);
            this.updateAllCorners();
            this.drawDepth(0, 0, 0);
            if (this._cascades > 1){
                this.drawDepth(1, this._mapSize, 0);
            }
            if (this._cascades > 2){
                this.drawDepth(2, 0, this._mapSize);
            }
            if (this._cascades > 3){
                this.drawDepth(3, this._mapSize, this._mapSize);
            }
        }


    }
}

