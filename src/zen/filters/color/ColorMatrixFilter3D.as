package zen.filters.color {
	import zen.shaders.ShaderFilter;
	
	import flash.utils.ByteArray;
	import zen.shaders.*;
	import flash.utils.*;
	
	/** A material filter that modifies the face by the given color matrix */
	public class ColorMatrixFilter3D extends ShaderFilter {
		
		public static var GRAY:Vector.<Number> = Vector.<Number>([0.212671, 0.71516, 0.072169, 0, 0.212671, 0.71516, 0.072169, 0, 0.212671, 0.71516, 0.072169, 0, 0, 0, 0, 1]);
		
		[Embed(source = "../../utils/assets/effects/ColorMatrixFilter.data", mimeType = "application/octet-stream")]
		private static var compiledShader:Class;
		private static var data:ByteArray;
		
		private var _values:Vector.<Number>;
		
		public function ColorMatrixFilter3D(values:Vector.<Number> = null) {
			if (data == null) {
				data = new compiledShader();
			}
			
			super(data, null);
			techniqueName = "colorMatrix";
			if (!(values)) {
				values = Vector.<Number>([1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1]);
			}
			params.matrix.value = values;
		}
		
		public function get values():Vector.<Number> {
			return (params.matrix.value);
		}
		
		public function set values(value:Vector.<Number>):void {
			params.matrix.value = value;
		}
	
	}
}

