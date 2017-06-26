package zen.effects
{
    import zen.shaders.ShaderFilter;
    import flash.utils.ByteArray;

    public class VertexColorFilter extends ShaderFilter 
    {

		[Embed(source = "../utils/assets/effects/VertexColorFilter.data", mimeType = "application/octet-stream")]
        private static var compiledShader:Class;
		
        private static var data:ByteArray;

        public function VertexColorFilter(channel:int=0, blendMode:String="multiply")
        {
			if (data == null) {
				data = new compiledShader();
			}
			
            super(data, blendMode);
        }

    }
}

