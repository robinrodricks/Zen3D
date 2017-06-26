package zen.effects
{
    import zen.shaders.ShaderFilter;
    import flash.utils.ByteArray;
    import zen.shaders.*;
    import flash.display.*;
    import flash.utils.*;
    

    public class FogFilter extends ShaderFilter 
    {

		[Embed(source = "../utils/assets/effects/FogFilter.data", mimeType = "application/octet-stream")]
        private static var compiledShader:Class;
        private static var data:ByteArray;

        public function FogFilter(near:Number=0, far:Number=1000, blendMode:String="multiply")
        {
			if (data == null) {
				data = new compiledShader();
			}
			
            super(data, blendMode);
            params.nearFar.value = Vector.<Number>([near, far]);
        }

    }
}

