package zen.effects
{
    import zen.shaders.ShaderFilter;
    import flash.utils.ByteArray;
    import zen.materials.*;
    import zen.display.*;
    import zen.shaders.textures.*;
    import zen.shaders.*;
    import zen.utils.*;
    import flash.display.*;
    import flash.utils.*;
    

    public class EnvironmentMapFilter extends ShaderFilter 
    {

        public static const PER_VERTEX:String = "perVertex";
        public static const PER_PIXEL:String = "perPixel";

		[Embed(source = "../utils/assets/effects/EnvironmentMapFilter.data", mimeType = "application/octet-stream")]
        private static var compiledShader:Class;
        private static var data:ByteArray;

        public function EnvironmentMapFilter(texture:Texture3D=null, blendMode:String="multiply", alpha:Number=1, techniqueName:String="perPixel")
        {
			if (data == null) {
				data = new compiledShader();
			}
			
            super(data, blendMode, techniqueName);
            params.alpha.value = new Vector.<Number>(4);
            params.scale.value = Vector.<Number>([0.5, -0.5]);
            this.alpha = alpha;
            this.texture = texture;
        }

        public function get texture():Texture3D
        {
            return (params.texture.value);
        }

        public function set texture(value:Texture3D):void
        {
            params.texture.value = value;
        }

        public function get alpha():Number
        {
            return (params.alpha.value[0]);
        }

        public function set alpha(value:Number):void
        {
            params.alpha.value[0] = value;
        }

        public function get scaleX():Number
        {
            return (params.scale.value[0]);
        }

        public function set scaleX(value:Number):void
        {
            params.scale.value[0] = value;
        }

        public function get scaleY():Number
        {
            return (params.scale.value[1]);
        }

        public function set scaleY(value:Number):void
        {
            params.scale.value[1] = value;
        }


    }
}

