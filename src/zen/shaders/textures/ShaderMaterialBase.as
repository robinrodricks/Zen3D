package zen.shaders.textures
{
    import flash.events.EventDispatcher;
    import flash.events.Event;
    import flash.display3D.Context3DBlendFactor;
    import flash.display3D.Context3DTriangleFace;
	
	import zen.enums.*;
    import zen.display.*;
    import zen.display.*;
    import zen.utils.*;

    public class ShaderMaterialBase extends EventDispatcher 
    {
		


        public var name:String;
        public var depthWrite:Boolean = true;
        public var depthCompare:String = "lessEqual";
        public var cullFace:String;
        public var sourceFactor:String;
        public var destFactor:String;
        public var flags:uint;
        private var _blendMode:int = 0;
        protected var _scene:Zen3D;
		
		public var info:Object; /// for loaded material info

        public function ShaderMaterialBase(name:String="")
        {
            this.cullFace = ZenUtils.defaultCullFace;
            this.sourceFactor = ZenUtils.defaultSourceFactor;
            this.destFactor = ZenUtils.defaultDestFactor;
            super();
            this.name = name;
        }

        public function dispose():void
        {
            this.download();
        }

        public function download():void
        {
            if (this._scene){
                this._scene.removeEventListener(Event.CONTEXT3D_CREATE, this.context3DEvent);
                this._scene.materials.splice(this._scene.materials.indexOf(this), 1);
                this._scene = null;
            }
        }

        public function upload(scene:Zen3D):void
        {
            if (!(scene)) {
				
                throw new Error("Parameter scene can not be null.");
				
				return;
            }
            if (this._scene){
                return;
            }
            this._scene = scene;
            if (this._scene.materials.indexOf(this) == -1){
                this._scene.materials.push(this);
            }
            if (scene.context){
                this.context3DEvent();
            }
            scene.addEventListener(Event.CONTEXT3D_CREATE, this.context3DEvent, false, 0, true);
        }

        protected function context3DEvent(e:Event=null):void
        {
        }

        public function get scene():Zen3D
        {
            return (this._scene);
        }

        public function validate(surf:ZenFace):Boolean
        {
            return (true);
        }

        public function clone():ShaderMaterialBase
        {
            var m:ShaderMaterialBase = new ShaderMaterialBase(this.name);
            m.name = this.name;
            m.transparent = this.transparent;
            m.twoSided = this.twoSided;
            m.depthWrite = this.depthWrite;
            m.cullFace = this.cullFace;
            m.sourceFactor = this.sourceFactor;
            m.destFactor = this.destFactor;
            return (m);
        }

        public function draw(pivot:ZenObject, surf:ZenFace, firstIndex:int=0, count:int=-1):void
        {
            if (!(this._scene)){
                this.upload(pivot.scene);
            }
            if (!(surf.scene)){
                surf.upload(this._scene);
            }
            ZenUtils.drawCalls++;
            ZenUtils.trianglesDrawn = (ZenUtils.trianglesDrawn + count);
        }

        public function get transparent():Boolean
        {
            return ((((this.sourceFactor == Context3DBlendFactor.SOURCE_ALPHA)) && ((this.destFactor == Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA))));
        }

        public function set transparent(value:Boolean):void
        {
            if (value){
                this.sourceFactor = Context3DBlendFactor.SOURCE_ALPHA;
                this.destFactor = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
            } else {
                this.sourceFactor = Context3DBlendFactor.ONE;
                this.destFactor = Context3DBlendFactor.ZERO;
            }
        }

        public function get twoSided():Boolean
        {
            return ((this.cullFace == Context3DTriangleFace.NONE));
        }

        public function set twoSided(value:Boolean):void
        {
            if (value){
                this.cullFace = Context3DTriangleFace.NONE;
            } else {
                this.cullFace = Context3DTriangleFace.BACK;
            }
        }

        public function get blendMode():int
        {
            return (this._blendMode);
        }

        public function set blendMode(value:int):void
        {
            this._blendMode = value;
            switch (this._blendMode){
                case MaterialBlendMode.NONE:
                    this.sourceFactor = Context3DBlendFactor.ONE;
                    this.destFactor = Context3DBlendFactor.ZERO;
                    break;
                case MaterialBlendMode.ADDITIVE:
                    this.sourceFactor = Context3DBlendFactor.ONE;
                    this.destFactor = Context3DBlendFactor.ONE;
                    break;
                case MaterialBlendMode.ALPHA_BLENDED:
                    this.sourceFactor = Context3DBlendFactor.ONE;
                    this.destFactor = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
                    break;
                case MaterialBlendMode.MULTIPLY:
                    this.sourceFactor = Context3DBlendFactor.DESTINATION_COLOR;
                    this.destFactor = Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA;
                    break;
                case MaterialBlendMode.SCREEN:
                    this.sourceFactor = Context3DBlendFactor.ONE;
                    this.destFactor = Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR;
                    break;
            }
        }

		
        override public function toString():String
        {
            return ((("[object ShaderMaterialBase name:" + this.name) + "]"));
        }
		


    }
}

