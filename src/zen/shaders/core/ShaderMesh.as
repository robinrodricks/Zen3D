package zen.shaders.core {
	import zen.shaders.*;
	import zen.enums.*;
	import zen.display.*;
	
	/** ShaderMesh defines a ZenFace object to be used as a target surface for an specific pass. */
	public class ShaderMesh extends ShaderBase {
		
		public var value:ZenFace;
		
		public function ShaderMesh(value:ZenFace = null) {
			this.varType = ZSLFlags.SURFACE;
			this.value = value;
		}
	
	}
}

