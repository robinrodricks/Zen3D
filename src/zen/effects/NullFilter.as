package zen.effects
{
    import zen.shaders.ShaderFilter;
    import flash.utils.ByteArray;
    import zen.shaders.*;
    import flash.display.*;
    import flash.utils.*;
    

    public class NullFilter extends ShaderFilter 
    {

		[Embed(source = "../utils/assets/effects/NullFilter.data", mimeType = "application/octet-stream")]
        private static var compiledShader:Class;
        private static var data:ByteArray;

        public function NullFilter(color:int=0xFFFFFF, size:Number=10, blendMode:String="multiply")
        {
			if (data == null) {
				data = new compiledShader();
			}
			
            super(data, blendMode);
            params.color.value = new Vector.<Number>(4, true);
            params.size.value = Vector.<Number>([size, 0, 0, 0]);
            this.color = color;
        }

        public function set r(value:Number):void
        {
            params.color.value[0] = value;
        }

        public function set g(value:Number):void
        {
            params.color.value[1] = value;
        }

        public function set b(value:Number):void
        {
            params.color.value[2] = value;
        }

        public function set a(value:Number):void
        {
            params.color.value[3] = value;
        }

        public function get r():Number
        {
            return (params.color.value[0]);
        }

        public function get g():Number
        {
            return (params.color.value[1]);
        }

        public function get b():Number
        {
            return (params.color.value[2]);
        }

        public function get a():Number
        {
            return (params.color.value[3]);
        }

        public function set color(value:uint):void
        {
            var a:Number = ((uint((value >> 24)) & 0xFF) / 0xFF);
            var r:Number = ((uint((value >> 16)) & 0xFF) / 0xFF);
            var g:Number = ((uint((value >> 8)) & 0xFF) / 0xFF);
            var b:Number = ((uint((value >> 0)) & 0xFF) / 0xFF);
            params.color.value[0] = r;
            params.color.value[1] = g;
            params.color.value[2] = b;
            params.color.value[3] = a;
        }

        public function get color():uint
        {
            return ((((((params.color.value[3] * 0xFF) << 24) ^ ((params.color.value[0] * 0xFF) << 16)) ^ ((params.color.value[1] * 0xFF) << 8)) ^ (params.color.value[2] * 0xFF)));
        }


    }
}

