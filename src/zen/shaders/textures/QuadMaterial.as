package zen.shaders.textures {
	import zen.shaders.textures.ShaderMaterial;
	import flash.utils.ByteArray;
	import zen.materials.*;
	import zen.display.*;
	import zen.shaders.*;
	import flash.utils.*;
	
	public class QuadMaterial extends ShaderMaterial {
		
		[Embed(source = "../../utils/assets/textures/QuadMaterial.data", mimeType = "application/octet-stream")]
		private static var compiledShader:Class;
		
		private static var data:ByteArray;
		
		private var _texture:ZenTexture;
		
		public function QuadMaterial(texture:ZenTexture = null) {
			if (data == null) {
				data = new compiledShader();
			}
			
			super("quad");
			this.byteCode = data;
			this.texture = texture;
			this.rebuild();
		}
		
		public function get texture():ZenTexture {
			return (this._texture);
		}
		
		public function set texture(value:ZenTexture):void {
			this._texture = value;
			this.params.texture.value = this._texture;
		}
	
	}
}

