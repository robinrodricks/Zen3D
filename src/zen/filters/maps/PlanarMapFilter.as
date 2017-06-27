package zen.filters.maps {
	import zen.shaders.ShaderFilter;
	import flash.utils.ByteArray;
	import zen.materials.*;
	import zen.display.*;
	import zen.shaders.*;
	import flash.display.*;
	import flash.utils.*;
	
	/** A material filter that uses a bitmap to specify a planar map */
	public class PlanarMapFilter extends ShaderFilter {
		
		public static const PROJECTED:String = "projected";
		public static const SPHERICAL:String = "spherical";
		
		[Embed(source = "../../utils/assets/effects/PlanarMapFilter.data", mimeType = "application/octet-stream")]
		private static var compiledShader:Class;
		
		private static var data:ByteArray;
		
		public function PlanarMapFilter(texture:ZenTexture = null, blendMode:String = "multiply", techniqueName:String = "projected") {
			if (data == null) {
				data = new compiledShader();
			}
			
			super(data, blendMode, techniqueName);
			params.texture.value = texture;
		}
	
	}
}

