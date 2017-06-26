package zen.effects
{
    import zen.shaders.ShaderFilter;
    import flash.utils.ByteArray;
    import zen.shaders.*;
    import flash.utils.*;
    

    public class ColorTransformFilter extends ShaderFilter 
    {

		[Embed(source = "../utils/assets/effects/ColorTransformFilter.data", mimeType = "application/octet-stream")]
        private static var compiledShader:Class;
        private static var data:ByteArray;

        public function ColorTransformFilter(redMultiplier:Number=1, greenMultiplier:Number=1, blueMultiplier:Number=1, alphaMultiplier:Number=1, redOffset:Number=0, greenOffset:Number=0, blueOffset:Number=0, alphaOffset:Number=0)
        {
			if (data == null) {
				data = new compiledShader();
			}
			
            super(data, null, "colorTransform");
            params.multiplier.value = Vector.<Number>([redMultiplier, greenMultiplier, blueMultiplier, alphaMultiplier]);
            params.offset.value = Vector.<Number>([redOffset, greenOffset, blueOffset, alphaOffset]);
        }

    }
}

