package zen.shaders.core {
	import zen.shaders.*;
	import zen.enums.*;
	import flash.geom.Matrix3D;
	
	/** ShaderMatrix defines a Matrix3D object to be used as a parameter */
	public class ShaderMatrix extends ShaderBase {
		
		public var value:Matrix3D;
		
		public function ShaderMatrix(value:Matrix3D = null) {
			this.varType = ZSLFlags.MATRIX;
			this.value = value;
		}
		
		public function clone():ShaderMatrix {
			var m:ShaderMatrix = new ShaderMatrix(this.value);
			m.name = name;
			m.varType = varType;
			m.semantic = semantic;
			return (m);
		}
	
	}
}

