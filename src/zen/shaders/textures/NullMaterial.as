package zen.shaders.textures {
	import zen.shaders.textures.ShaderMaterial;
	import flash.utils.ByteArray;
	
	import zen.shaders.ShaderProgram;
	
	public class NullMaterial extends ShaderMaterial {
		
		[Embed(source = "../../utils/assets/textures/NullMaterial.data", mimeType = "application/octet-stream")]
		private static var compiledShader:Class;
		
		private static var data:ByteArray;
		private static var _programs:Vector.<ShaderProgram>;
		
		public function NullMaterial(name:String = "nullMaterial") {
			if (data == null) {
				data = new compiledShader();
			}
			
			super(name, data, "main");
		}
		
		public static function get programs2():Vector.<ShaderProgram> {
			if (!(_programs)) {
				var mat:NullMaterial = new NullMaterial();
				_programs = mat.programs;
			}
			return (_programs);
		}
	
	}
}

