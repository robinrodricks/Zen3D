package zen.shaders.objects {
	
	import zen.shaders.*;
	
	public class ShaderError extends Error {
		
		public var line:int;
		public var pos:int;
		
		public function ShaderError(message:String = "", line:int = -1, pos:int = -1) {
			super(message, 0);
			this.pos = pos;
			this.line = line;
		}
		
		public function toString():String {
			if (((!((this.line == -1))) && (!((this.pos == -1))))) {
				return (((((("Line: " + this.line) + " col: ") + this.pos) + " - ") + message));
			}
			return (message);
		}
	
	}
}

