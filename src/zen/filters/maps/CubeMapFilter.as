package zen.filters.maps {
	import zen.shaders.ShaderFilter;
	import flash.utils.ByteArray;
	import zen.materials.*;
	import zen.display.*;
	import zen.shaders.*;
	import flash.display.*;
	import flash.events.*;
	import flash.utils.*;
	
	/** A material filter that uses a bitmap as a cube map */
	public class CubeMapFilter extends ShaderFilter {
		
		[Embed(source = "../../utils/assets/effects/CubeMapFilter.data", mimeType = "application/octet-stream")]
		private static var compiledShader:Class;
		private static var data:ByteArray;
		
		public function CubeMapFilter(texture:ZenTexture = null, level:Number = 1, blendMode:String = "multiply") {
			if (data == null) {
				data = new compiledShader();
			}
			
			super(data, blendMode);
			this.texture = texture;
			params.level.value = Vector.<Number>([level]);
		}
		
		public function get level():Number {
			return (params.level.value[0]);
		}
		
		public function set level(value:Number):void {
			params.level.value[0] = value;
		}
		
		public function get texture():ZenTexture {
			return (params.texture.value);
		}
		
		public function set texture(value:ZenTexture):void {
			params.texture.value = value;
		}
	
	}
}

