package zen.effects
{
    import zen.shaders.ShaderFilter;
    import flash.utils.ByteArray;
    import zen.materials.*;
    import zen.display.*;
    import zen.shaders.*;
    import flash.display.*;
    import flash.events.*;
    import flash.utils.*;
    

    public class TextureMaskFilter extends ShaderFilter 
    {

        public static const ALPHA:String = "alpha";
        public static const RED:String = "red";
        public static const GREEN:String = "green";
        public static const BLUE:String = "blue";

		[Embed(source = "../utils/assets/effects/TextureMaskFilter.data", mimeType = "application/octet-stream")]
        private static var compiledShader:Class;
		
        private static var data:ByteArray;

        public function TextureMaskFilter(texture:Texture3D=null, channel:int=0, threshold:Number=0.5, technique:String="alpha")
        {
			if (data == null) {
				data = new compiledShader();
			}
			
            super(data, "");
            params.threshold.value = Vector.<Number>([threshold]);
            params.channel.value = Vector.<Number>([channel]);
            params.texture.value = texture;
        }

    }
}

