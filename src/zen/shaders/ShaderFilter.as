package zen.shaders
{
	import zen.shaders.core.*;
	import zen.enums.*;
    import flash.utils.ByteArray;
    import flash.events.EventDispatcher;
    import flash.utils.getQualifiedClassName;
    import flash.events.Event;
    import zen.shaders.textures.ShaderMaterialBase;
    import flash.events.*;
    import flash.utils.*;
    import zen.shaders.textures.*;
    import flash.display.*;

	/** Filters are small pieces of pre compiled ZSL shaders to be used in Shader3D materials */
    public class ShaderFilter extends ShaderContext implements IEventDispatcher 
    {
		// to keep IEventDispatcher functions
		

        private var _byteCode:ByteArray;
        private var _blendMode:String;
        private var _techniqueName:String;
        private var _events:EventDispatcher;
        private var _passes:int;
        public var url:String;
        public var enabled:Boolean = true;

        public function ShaderFilter(byteCode:ByteArray=null, blendMode:String="multiply", techniqueName:String=null)
        {
            super("topLevel");
            this._events = new EventDispatcher(this);
            this._byteCode = byteCode;
            this.blendMode = blendMode;
            if (this._byteCode){
                bind(this._byteCode);
            }
            this.name = getQualifiedClassName(this);
            this.name = (name.substr((name.indexOf("::") + 2)) + ":topLevel");
            this.techniqueName = techniqueName;
        }

        public function clone():ShaderFilter
        {
            var p:*;
            var f:ShaderFilter = new ((Object(this).constructor as Class))();
            if (Object(this).constructor == ShaderFilter){
                f.byteCode = this.byteCode;
                f.techniqueName = this.techniqueName;
            }
            for (p in params) {
                if ((((params[p] is ShaderTexture)) || ((params[p] is ShaderMatrix)))){
                    f.params[p].value = params[p].value;
                } else {
                    if (params[p].value){
                        f.params[p].value = params[p].value.concat();
                    }
                }
            }
            f.blendMode = this._blendMode;
            f.techniqueName = this._techniqueName;
            f.enabled = this.enabled;
            return (f);
        }

        public function process(scope:ShaderContext2):void
        {
            var p:Array;
            var i:int;
            var ns:ShaderContext = getScope(this._techniqueName);
            if (!(ns)){
                return;
            }
            if (this.blendMode == null){
                if (ns.varType == ZSLFlags.TECHNIQUE){
                    scope.call(this._techniqueName);
                } else {
                    if (scope.outputFragment){
                        p = [];
                        i = 0;
                        while (i < ns.paramCount) {
                            p.push(scope.outputFragment);
                            i++;
                        }
                        scope.outputFragment = ns.call("", p);
                    }
                }
            } else {
                scope.call(this._techniqueName);
            }
        }

        public function get blendMode():String
        {
            return (this._blendMode);
        }

        public function set blendMode(value:String):void
        {
            if ((((value == "")) || ((value == "null")))){
                value = null;
            }
            this._blendMode = value;
        }

        public function get techniqueName():String
        {
            return (this._techniqueName);
        }

        public function set techniqueName(value:String):void
        {
            this._passes = getPasses(value);
            if (value != this._techniqueName){
                this._techniqueName = value;
                this.build();
            }
        }

        public function build():void
        {
            this.dispatchEvent(new Event("build"));
        }

        public function get hash():String
        {
            return (getQualifiedClassName(this));
        }

        public function get byteCode():ByteArray
        {
            return (this._byteCode);
        }

        public function set byteCode(value:ByteArray):void
        {
            if (value != this._byteCode){
                this._byteCode = value;
                this._techniqueName = null;
                bind(this._byteCode);
            }
        }

        public function init(material:ShaderMaterialBase, index:int, pass:int):void
        {
        }

        public function get passes():int
        {
            return (this._passes);
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

