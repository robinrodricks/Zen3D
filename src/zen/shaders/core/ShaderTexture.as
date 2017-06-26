package zen.shaders.core
{
	import zen.shaders.*;
	import zen.enums.*;
    import zen.materials.*;

	/** ShaderTexture defines a sampler object to be used as a texture. */
    public class ShaderTexture extends ShaderBase 
    {


        public var type:int = 0;
        public var format:int = 0;
        public var mip:int = 2;
        public var filter:int = 1;
        public var wrap:int = 1;
        public var bias:int = 0;
        public var options:int;
        public var optimizeForRenderToTexture:Boolean = false;
        public var request:String;
        public var width:int = 0;
        public var height:int = 0;
        public var value:Texture3D;
        public var order:int = 0;
        public var ui:String;

        public function ShaderTexture(value:Texture3D=null, type:int=0)
        {
            this.varType = (((type == TextureType.FLAT)) ? ZSLFlags.SAMPLER2D : ZSLFlags.SAMPLERCUBE);
            this.type = type;
            this.value = value;
        }

        public function clone():ShaderTexture
        {
            var s:ShaderTexture = new ShaderTexture(this.value, this.type);
            s.mip = this.mip;
            s.filter = this.filter;
            s.wrap = this.wrap;
            s.bias = this.bias;
            s.options = this.options;
            s.optimizeForRenderToTexture = this.optimizeForRenderToTexture;
            s.request = this.request;
            s.width = this.width;
            s.height = this.height;
            s.name = name;
            s.varType = varType;
            s.semantic = semantic;
            s.order = this.order;
            s.ui = this.ui;
            return (s);
        }


    }
}

