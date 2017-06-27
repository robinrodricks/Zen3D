package zen.filters.color {
	import zen.shaders.ShaderFilter;
	import flash.utils.ByteArray;
	import zen.shaders.*;
	import flash.utils.*;
	
	/** A material filter that modifies the specular values */
	public class SpecularFilter extends ShaderFilter {
		
		[Embed(source = "../../utils/assets/effects/SpecularFilter.data", mimeType = "application/octet-stream")]
		private static var compiledShader:Class;
		private static var data:ByteArray;
		
		public function SpecularFilter(power:Number = 50, level:Number = 1) {
			if (data == null) {
				data = new compiledShader();
			}
			
			super(data, null);
			params.powerLevel.value = Vector.<Number>([power, level, 0, 0]);
		}
		
		public function get power():Number {
			return (params.powerLevel.value[0]);
		}
		
		public function set power(value:Number):void {
			params.powerLevel.value[0] = value;
		}
		
		public function get level():Number {
			return (params.powerLevel.value[1]);
		}
		
		public function set level(value:Number):void {
			params.powerLevel.value[1] = value;
		}
	
	}
}

