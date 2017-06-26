package zen.display
{
	import zen.animation.*;
	import zen.enums.*;
	import zen.input.*;
	import zen.display.*;
    import flash.geom.*;
    import zen.materials.*;
    import zen.utils.*;
    import zen.shaders.*;
    import zen.shaders.textures.*;
	import zen.shaders.core.*;
    import zen.utils.*;
    import zen.geom.*;
    import flash.display.*;
    import flash.display3D.*;
    import flash.events.*;
    import flash.utils.*;
    

    [Event(name="click", type="zen.input.MouseEvent3D")]
    [Event(name="mouseDown", type="zen.input.MouseEvent3D")]
    [Event(name="mouseMove", type="zen.input.MouseEvent3D")]
    [Event(name="mouseOut", type="zen.input.MouseEvent3D")]
    [Event(name="mouseOver", type="zen.input.MouseEvent3D")]
    [Event(name="mouseUp", type="zen.input.MouseEvent3D")]
    [Event(name="mouseWheel", type="zen.input.MouseEvent3D")]
    public class ZenMesh extends ZenObject implements IDrawable 
    {
		

        private static const CLICK:int = (1 << 6);
        private static const MOUSE_DOWN:int = (1 << 7);
        private static const MOUSE_MOVE:int = (1 << 8);
        private static const MOUSE_OUT:int = (1 << 9);
        private static const MOUSE_OVER:int = (1 << 10);
        private static const MOUSE_UP:int = (1 << 11);
        private static const MOUSE_WHELL:int = (1 << 12);

        private static var _modifier:Modifier;
        private static var _bScale:Vector3D = new Vector3D();
        private static var _bCenter:Vector3D = new Vector3D();
        private static var _bRaw:Vector.<Number> = new Vector.<Number>(16, true);

        public var surfaces:Vector.<ZenFace>;
        public var modifier:Modifier;
        private var _bounds:Cube3D;
        private var _inView:Boolean = false;
        private var _boundsCenter:Vector3D;
        private var _boundsRadius:Number = 1;
        private var _updateBoundsScale:Boolean = true;
        public var mouseEnabled:Boolean = true;
        public var useHandCursor:Boolean = false;

        public function ZenMesh(name:String="")
        {
            this.surfaces = new Vector.<ZenFace>();
            this.modifier = _modifier;
            this._boundsCenter = new Vector3D();
            super(name);
            if (!(_modifier)){
                _modifier = new Modifier();
            }
            this.modifier = _modifier;
        }

        override public function dispose():void
        {
			
			// if already disposed
			if (surfaces == null){
				return;
			}
			
            this._bounds = null;
            this.modifier = null;
            var i:int;
            while (i < this.surfaces.length) {
                if (this.surfaces[i]){
                    if (this.surfaces[i].material){
                        this.surfaces[i].material.dispose();
                    }
                    this.surfaces[i].dispose();
                }
                i++;
            }
            this.surfaces = null;
            super.dispose();
        }

        override public function upload(scene:Zen3D, includeChildren:Boolean=true):void
        {
            var s:ZenFace;
            super.upload(scene, includeChildren);
            for each (s in this.surfaces) {
                s.upload(scene);
            }
        }

        override public function download(includeChildren:Boolean=true):void
        {
            var s:ZenFace;
            super.download();
            for each (s in this.surfaces) {
                s.download();
            }
        }

        override public function clone():ZenObject
        {
            var surf:ZenFace;
            var c:ZenObject;
            var n:ZenMesh = new ZenMesh(name);
            n.copyFrom(this);
            n.useHandCursor = this.useHandCursor;
            n.bounds = this._bounds;
            for each (surf in this.surfaces) {
                n.surfaces.push(surf.clone());
            }
            if (this.modifier){
                n.modifier = this.modifier.clone();
            }
            for each (c in children) {
                if (!(c.lock)){
                    n.addChild(c.clone());
                }
            }
            return (n);
        }
		
        override public function getChildByName(name:String, startIndex:int=0, includeChildren:Boolean=true):ZenObject
        {
            var child:ZenObject = super.getChildByName(name, startIndex, includeChildren);
            if (((((!(child)) && (includeChildren))) && ((this.modifier is ZenSkinModifier)))){
                child = ZenSkinModifier(this.modifier).root.getChildByName(name, startIndex, includeChildren);
            }
            return (child);
        }

        override public function setMaterial(material:ShaderMaterialBase, includeChildren:Boolean=true):void
        {
            var surf:ZenFace;
            super.setMaterial(material, includeChildren);
            for each (surf in this.surfaces) {
                surf.material = material;
            }
        }

        public function updateBoundings():void
        {
            this._bounds = null;
            this._bounds = this.bounds;
        }

        public function get bounds():Cube3D
        {
            var s:ZenFace;
            if (this._bounds){
                return (this._bounds);
            }
            this._bounds = new Cube3D();
            this._bounds.min.setTo(10000000, 10000000, 10000000);
            this._bounds.max.setTo(-10000000, -10000000, -10000000);
            for each (s in this.surfaces) {
                if (!(s.bounds)){
                    s.updateBoundings();
                }
                V3D.min(s.bounds.min, this._bounds.min, this._bounds.min);
                V3D.max(s.bounds.max, this._bounds.max, this._bounds.max);
            }
            this._bounds.length.x = (this._bounds.max.x - this._bounds.min.x);
            this._bounds.length.y = (this._bounds.max.y - this._bounds.min.y);
            this._bounds.length.z = (this._bounds.max.z - this._bounds.min.z);
            this._bounds.center.x = ((this._bounds.length.x * 0.5) + this._bounds.min.x);
            this._bounds.center.y = ((this._bounds.length.y * 0.5) + this._bounds.min.y);
            this._bounds.center.z = ((this._bounds.length.z * 0.5) + this._bounds.min.z);
            this._bounds.radius = Vector3D.distance(this._bounds.center, this._bounds.max);
            return (this._bounds);
        }

        public function set bounds(value:Cube3D):void
        {
            this._bounds = value;
        }

        override public function getTextures(includeChildren:Boolean=true, out:Vector.<Texture3D>=null):Vector.<Texture3D>
        {
            var m:ShaderMaterial;
            var p:ShaderProgram;
            var s:ShaderTexture;
            out = super.getTextures(includeChildren, out);
            var length:int = this.surfaces.length;
            var i:int;
            while (i < length) {
                if ((this.surfaces[i].material is ShaderMaterial)){
                    m = (this.surfaces[i].material as ShaderMaterial);
                    if (((((m) && (!(m.programs)))) && (scene))){
                        m.upload(scene);
                    }
                    for each (p in m.programs) {
                        for each (s in p.samplers) {
                            if (((s.value) && ((out.indexOf(s.value) == -1)))){
                                out.push(s.value);
                            }
                        }
                    }
                }
                i++;
            }
            return (out);
        }

        override public function getMaterials(includeChildren:Boolean=true, out:Vector.<ShaderMaterialBase>=null):Vector.<ShaderMaterialBase>
        {
            out = super.getMaterials(includeChildren, out);
            var length:int = this.surfaces.length;
            var i:int;
            while (i < length) {
                if (out.indexOf(this.surfaces[i].material) == -1){
                    out.push(this.surfaces[i].material);
                }
                i++;
            }
            return (out);
        }

        override public function getMaterialByName(name:String, includeChildren:Boolean=true):ShaderMaterialBase
        {
            var surf:ZenFace;
            var c:ZenObject;
            var material:ShaderMaterialBase;
            for each (surf in this.surfaces) {
                if (surf.material.name == name){
                    return (surf.material);
                }
            }
            if (includeChildren){
                for each (c in children) {
                    material = c.getMaterialByName(name);
                    if (material){
                        return (material);
                    }
                }
            }
            return (null);
        }

        override public function replaceMaterial(source:ShaderMaterialBase, replaceFor:ShaderMaterialBase, includeChildren:Boolean=true):void
        {
            var surf:ZenFace;
            super.replaceMaterial(source, replaceFor, includeChildren);
            for each (surf in this.surfaces) {
                if (surf.material == source){
                    surf.material = replaceFor;
                }
            }
        }

        override public function updateTransforms(includeChildren:Boolean=false):void
        {
            super.updateTransforms(includeChildren);
            this._updateBoundsScale = true;
        }

        override public function get inView():Boolean
        {
            this._inView = false;
            if (!(visible)){
                return (false);
            }
            if (this._bounds){
                if (this._updateBoundsScale){
                    M3D.transformVector(world, this._bounds.center, this._boundsCenter);
                    M3D.getScale(world, _bScale);
                    this._boundsRadius = (this._bounds.radius * Math.max(_bScale.x, _bScale.y, _bScale.z));
                    this._updateBoundsScale = false;
                }
                ZenUtils.view.copyRawDataTo(_bRaw);
                _bCenter.x = ((((this._boundsCenter.x * _bRaw[0]) + (this._boundsCenter.y * _bRaw[4])) + (this._boundsCenter.z * _bRaw[8])) + _bRaw[12]);
                _bCenter.y = ((((this._boundsCenter.x * _bRaw[1]) + (this._boundsCenter.y * _bRaw[5])) + (this._boundsCenter.z * _bRaw[9])) + _bRaw[13]);
                _bCenter.z = ((((this._boundsCenter.x * _bRaw[2]) + (this._boundsCenter.y * _bRaw[6])) + (this._boundsCenter.z * _bRaw[10])) + _bRaw[14]);
                if ((_sortMode & SortMode.CENTER)){
                    priority = ((_bCenter.z / ZenUtils.camera.far) * 100000);
                } else {
                    if ((_sortMode & SortMode.NEAR)){
                        priority = (((_bCenter.z - this._boundsRadius) / ZenUtils.camera.far) * 100000);
                    } else {
                        if ((_sortMode & SortMode.FAR)){
                            priority = (((_bCenter.z + this._boundsRadius) / ZenUtils.camera.far) * 100000);
                        }
                    }
                }
                if ((((_bCenter.x * _bCenter.x) + (_bCenter.y * _bCenter.y)) + (_bCenter.z * _bCenter.z)) <= (this._boundsRadius * this._boundsRadius)){
                    return (true);
                }
                if (!(ZenUtils.camera.isSphereInView(_bCenter, this._boundsRadius))){
                    return (false);
                }
            } else {
                getPosition(false, this._boundsCenter);
                M3D.transformVector(ZenUtils.view, this._boundsCenter, _bCenter);
                priority = ((_bCenter.z / ZenUtils.camera.far) * 100000);
            }
            return (true);
        }

        public function getScreenRect(out:Rectangle=null, camera:ZenCamera=null, viewPort:Rectangle=null):Rectangle
        {
            if (!(this._bounds)){
                return (null);
            }
            if (!(out)){
                out = new Rectangle();
            }
            if (!(viewPort)){
                viewPort = ZenUtils.scene.viewPort;
            }
            if (!(camera)){
                camera = ZenUtils.camera;
            }
            ZenUtils.temporal0.copyFrom(world);
            ZenUtils.temporal0.append(camera.viewProjection);
            var inFront:Boolean;
            var t:Vector3D = this.projectCorner(0, ZenUtils.temporal0);
            if (t.w > 0){
                inFront = true;
            }
            out.setTo(t.x, t.y, t.x, t.y);
            var i:int = 1;
            while (i < 8) {
                t = this.projectCorner(i, ZenUtils.temporal0);
                if (t.w > 0){
                    inFront = true;
                }
                if (t.x < out.x){
                    out.x = t.x;
                }
                if (t.y > out.y){
                    out.y = t.y;
                }
                if (t.x > out.width){
                    out.width = t.x;
                }
                if (t.y < out.height){
                    out.height = t.y;
                }
                i++;
            }
            if (!(inFront)){
                return (null);
            }
            out.y = -(out.y);
            out.width = (out.width - out.x);
            out.height = (-(out.height) - out.y);
            var w2:Number = (viewPort.width * 0.5);
            var h2:Number = (viewPort.height * 0.5);
            out.x = (((out.x * w2) + w2) + viewPort.x);
            out.y = (((out.y * h2) + h2) + viewPort.y);
            out.width = (out.width * w2);
            out.height = (out.height * h2);
            if (out.x < 0){
                out.width = (out.width + out.x);
                out.x = 0;
            }
            if (out.y < 0){
                out.height = (out.height + out.y);
                out.y = 0;
            }
            if (out.right > viewPort.width){
                out.right = viewPort.width;
            }
            if (out.bottom > viewPort.height){
                out.bottom = viewPort.height;
            }
            return (out);
        }

        private function projectCorner(i:int, m:Matrix3D):Vector3D
        {
            switch (i){
                case 0:
                    _bCenter.setTo(this._bounds.min.x, this._bounds.min.y, this._bounds.min.z);
                    break;
                case 1:
                    _bCenter.setTo(this._bounds.max.x, this._bounds.min.y, this._bounds.min.z);
                    break;
                case 2:
                    _bCenter.setTo(this._bounds.min.x, this._bounds.max.y, this._bounds.min.z);
                    break;
                case 3:
                    _bCenter.setTo(this._bounds.max.x, this._bounds.max.y, this._bounds.min.z);
                    break;
                case 4:
                    _bCenter.setTo(this._bounds.min.x, this._bounds.min.y, this._bounds.max.z);
                    break;
                case 5:
                    _bCenter.setTo(this._bounds.max.x, this._bounds.min.y, this._bounds.max.z);
                    break;
                case 6:
                    _bCenter.setTo(this._bounds.min.x, this._bounds.max.y, this._bounds.max.z);
                    break;
                case 7:
                    _bCenter.setTo(this._bounds.max.x, this._bounds.max.y, this._bounds.max.z);
                    break;
            }
            return (Utils3D.projectVector(m, _bCenter));
        }

        override public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void
        {
            var mouseEvents:Boolean = (((_eventFlags >= CLICK)) ? true : false);
            switch (type){
                case MouseEvent3D.CLICK:
                    _eventFlags = (_eventFlags | CLICK);
                    break;
                case MouseEvent3D.MOUSE_DOWN:
                    _eventFlags = (_eventFlags | MOUSE_DOWN);
                    break;
                case MouseEvent3D.MOUSE_MOVE:
                    _eventFlags = (_eventFlags | MOUSE_MOVE);
                    break;
                case MouseEvent3D.MOUSE_OUT:
                    _eventFlags = (_eventFlags | MOUSE_OUT);
                    break;
                case MouseEvent3D.MOUSE_OVER:
                    _eventFlags = (_eventFlags | MOUSE_OVER);
                    break;
                case MouseEvent3D.MOUSE_UP:
                    _eventFlags = (_eventFlags | MOUSE_UP);
                    break;
                case MouseEvent3D.MOUSE_WHEEL:
                    _eventFlags = (_eventFlags | MOUSE_WHELL);
                    break;
            }
            if (((((scene) && (!(mouseEvents)))) && ((_eventFlags >= CLICK)))){
                scene.insertIntoScene(this, false, false, true);
            }
            super.addEventListener(type, listener, useCapture, priority, useWeakReference);
        }

        override public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
        {
            super.removeEventListener(type, listener, useCapture);
            switch (type){
                case MouseEvent3D.CLICK:
                    if (!(hasEventListener(type))){
                        _eventFlags = (_eventFlags | CLICK);
                        _eventFlags = (_eventFlags - CLICK);
                    }
                    break;
                case MouseEvent3D.MOUSE_DOWN:
                    if (!(hasEventListener(type))){
                        _eventFlags = (_eventFlags | MOUSE_DOWN);
                        _eventFlags = (_eventFlags - MOUSE_DOWN);
                    }
                    break;
                case MouseEvent3D.MOUSE_MOVE:
                    if (!(hasEventListener(type))){
                        _eventFlags = (_eventFlags | MOUSE_MOVE);
                        _eventFlags = (_eventFlags - MOUSE_MOVE);
                    }
                    break;
                case MouseEvent3D.MOUSE_OUT:
                    if (!(hasEventListener(type))){
                        _eventFlags = (_eventFlags | MOUSE_OUT);
                        _eventFlags = (_eventFlags - MOUSE_OUT);
                    }
                    break;
                case MouseEvent3D.MOUSE_OVER:
                    if (!(hasEventListener(type))){
                        _eventFlags = (_eventFlags | MOUSE_OVER);
                        _eventFlags = (_eventFlags - MOUSE_OVER);
                    }
                    break;
                case MouseEvent3D.MOUSE_UP:
                    if (!(hasEventListener(type))){
                        _eventFlags = (_eventFlags | MOUSE_UP);
                        _eventFlags = (_eventFlags - MOUSE_UP);
                    }
                    break;
                case MouseEvent3D.MOUSE_WHEEL:
                    if (!(hasEventListener(type))){
                        _eventFlags = (_eventFlags | MOUSE_WHELL);
                        _eventFlags = (_eventFlags - MOUSE_WHELL);
                    }
                    break;
            }
            if (((scene) && ((_eventFlags < CLICK)))){
                scene.removeFromScene(this, false, false, true);
            }
        }

        override public function draw(includeChildren:Boolean=true, material:ShaderMaterialBase=null):void
        {
            var length:int;
            var i:int;
            if (!(_scene)){
                this.upload(ZenUtils.scene);
            }
            if ((_eventFlags & ObjectFlags.ENTER_DRAW_FLAG)){
                dispatchEvent(_enterDrawEvent);
            }
            if (this.inView){
                this.modifier.draw(this, material);
            }
            if (includeChildren){
                length = children.length;
                i = 0;
                while (i < length) {
                    children[i].draw(includeChildren, material);
                    i++;
                }
            }
            if ((_eventFlags & ObjectFlags.EXIT_DRAW_FLAG)){
                dispatchEvent(_exitDrawEvent);
            }
        }

        public function transformBy(matrix:Matrix3D):void
        {
            var s:ZenFace;
            for each (s in this.surfaces) {
                s.transformBy(matrix, s.firstIndex, s.numTriangles);
            }
        }

    }
}

