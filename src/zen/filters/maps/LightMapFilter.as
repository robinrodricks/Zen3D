package zen.filters.maps {
	import zen.enums.*;
	import zen.display.*;
	import zen.materials.*;
	import zen.shaders.*;
	import flash.events.*;
	import flash.utils.*;
	
	/** A material filter that uses a bitmap to respond to scene lighting */
	public class LightMapFilter extends ShaderFilter {
		
		[Embed(source = "../../utils/assets/effects/LightMapFilter.data", mimeType = "application/octet-stream")]
		private static var compiledShader:Class;
		private static var data:ByteArray;
		
		public function LightMapFilter(texture:ZenTexture = null) {
			if (data == null) {
				data = new compiledShader();
			}
			
			super(null, "");
			if (texture) {
				texture.wrapMode = TextureWrap.CLAMP;
				texture.mipMode = TextureMipMapping.NONE;
			}
			this.byteCode = data;
			this.params.texture.value = texture;
		}
	
	}
}

