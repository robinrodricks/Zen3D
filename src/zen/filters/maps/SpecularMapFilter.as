package zen.filters.maps {
	import zen.shaders.ShaderFilter;
	import flash.utils.ByteArray;
	import zen.materials.*;
	import zen.display.*;
	import zen.shaders.*;
	import zen.shaders.core.*;
	import flash.utils.*;
	
	/** A material filter that uses a bitmap to specify a specular map */
	public class SpecularMapFilter extends ShaderFilter {
		
		[Embed(source = "../../utils/assets/effects/SpecularMapFilter.data", mimeType = "application/octet-stream")]
		private static var compiledShader:Class;
		private static var data:ByteArray;
		
		public function SpecularMapFilter(texture:ZenTexture = null, power:Number = 50, level:Number = 1, channel:int = 0) {
			if (data == null) {
				data = new compiledShader();
			}
			
			super(data, null);
			params.texture.value = texture;
			params.channel.value = Vector.<Number>([channel]);
			params.powerLevel.value = Vector.<Number>([power, level, 0, 0]);
		}
		
		private function setParamValue(param:ShaderVar, index:int, value:Number, def:Array):void {
			if (!(param.value)) {
				param.value = Vector.<Number>(def);
			}
			param.value[index] = value;
		}
		
		public function get offsetX():Number {
			return (params.offset.value[0]);
		}
		
		public function set offsetX(value:Number):void {
			this.setParamValue(params.offset, 0, value, [0, 0, 0, 0]);
		}
		
		public function get offsetY():Number {
			return (params.offset.value[1]);
		}
		
		public function set offsetY(value:Number):void {
			this.setParamValue(params.offset, 1, value, [0, 0, 0, 0]);
		}
		
		public function get repeatX():Number {
			return (params.repeat.value[0]);
		}
		
		public function set repeatX(value:Number):void {
			this.setParamValue(params.repeat, 0, value, [1, 1, 1, 1]);
		}
		
		public function get repeatY():Number {
			return (params.repeat.value[1]);
		}
		
		public function set repeatY(value:Number):void {
			this.setParamValue(params.repeat, 1, value, [1, 1, 1, 1]);
		}
		
		public function get texture():ZenTexture {
			return (params.texture.value);
		}
		
		public function set texture(value:ZenTexture):void {
			params.texture.value = value;
		}
		
		public function get channel():int {
			return (params.channel.value[0]);
		}
		
		public function set channel(value:int):void {
			this.setParamValue(params.channel, 0, value, [0, 0, 0, 0]);
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

