package zen.effects
{
    import zen.shaders.ShaderFilter;
    import flash.utils.ByteArray;
    import zen.materials.*;
    import zen.display.*;
    import zen.shaders.*;
    import flash.display.*;
    import flash.utils.*;

    public class PlanarMapFilter extends ShaderFilter 
    {

        public static const PROJECTED:String = "projected";
        public static const SPHERICAL:String = "spherical";

		[Embed(source = "../utils/assets/effects/PlanarMapFilter.data", mimeType = "application/octet-stream")]
        private static var compiledShader:Class;
		
        private static var data:ByteArray;

        public function PlanarMapFilter(texture:Texture3D=null, blendMode:String="multiply", techniqueName:String="projected")
        {
			if (data == null) {
				data = new compiledShader();
			}
			
            super(data, blendMode, techniqueName);
            params.texture.value = texture;
        }

    }
}

