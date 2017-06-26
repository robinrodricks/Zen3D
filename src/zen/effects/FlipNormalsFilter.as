package zen.effects
{
    import zen.shaders.ShaderFilter;
    import flash.utils.ByteArray;

    public class FlipNormalsFilter extends ShaderFilter 
    {

		[Embed(source = "../utils/assets/effects/FlipNormalsFilter.data", mimeType = "application/octet-stream")]
        private static var compiledShader:Class;
        private static var data:ByteArray;

        public function FlipNormalsFilter()
        {
			if (data == null) {
				data = new compiledShader();
			}
			
            super(data, "");
        }

    }
}

