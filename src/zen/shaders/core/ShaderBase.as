package zen.shaders.core {
	import zen.enums.*;
	import flash.utils.Dictionary;
	import flash.utils.*;
	import zen.shaders.*;
	
	/** The base ZSL object. */
	public class ShaderBase {
		
		public var state:int = 0;
		public var varType:int = 0;
		public var name:String;
		public var semantic:String;
		
		public function toString():String {
			var mask:String = "xyzw";
			if ((((((this.varType >= ZSLFlags.TEMPORAL)) && ((this.varType <= ZSLFlags.MATRIX)))) || ((((this.varType >= ZSLFlags.INPUT)) && ((this.varType <= ZSLFlags.OUTPUT)))))) {
				return (((("(" + ShaderCompiler.typeToStr(this.varType)) + ") ") + this.name));
			}
			return (((("(" + ShaderCompiler.typeToStr(this.varType)) + ") ") + this.name));
		}
	
	}
}

