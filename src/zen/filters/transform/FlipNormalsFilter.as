package zen.filters.transform {
	import zen.shaders.ShaderFilter;
	import flash.utils.ByteArray;
	
	/** A material filter that flips all vertex/face normals */
	public class FlipNormalsFilter extends ShaderFilter {
		
		[Embed(source = "../../utils/assets/effects/FlipNormalsFilter.data", mimeType = "application/octet-stream")]
		private static var compiledShader:Class;
		private static var data:ByteArray;
		
		public function FlipNormalsFilter() {
			if (data == null) {
				data = new compiledShader();
			}
			
			super(data, "");
		}
	
	}
}

