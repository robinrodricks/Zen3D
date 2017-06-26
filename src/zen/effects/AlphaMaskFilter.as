package zen.effects
{
    import zen.shaders.ShaderFilter;
    import flash.utils.ByteArray;
    import zen.display.*;
    import zen.shaders.*;
    import flash.display.*;
    import flash.events.*;
    import flash.utils.*;
    

    public class AlphaMaskFilter extends ShaderFilter 
    {

		[Embed(source = "../utils/assets/effects/AlphaMaskFilter.data", mimeType = "application/octet-stream")]
        private static var compiledShader:Class;
		
        private static var data:ByteArray;

        public function AlphaMaskFilter(threshold:Number=0.5)
        {
			if (data == null) {
				data = new compiledShader();
			}
			
            super(data, null);
            super.techniqueName = "alphaMask";
            params.threshold.value = Vector.<Number>([threshold]);
        }

        override public function get techniqueName():String
        {
            return (super.techniqueName);
        }

        override public function set techniqueName(value:String):void
        {
        }

        override public function get blendMode():String
        {
            return (super.blendMode);
        }

        override public function set blendMode(value:String):void
        {
        }

        public function get threshold():Number
        {
            return (params.threshold.value[0]);
        }

        public function set threshold(value:Number):void
        {
            params.threshold.value[0] = value;
        }


    }
}

