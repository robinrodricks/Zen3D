package zen.shaders.core {
	import zen.shaders.*;
	import zen.shaders.core.*;
	
	/** The ShaderContext2 class is an utiliy helper used to proccess different ZSL filters that are in different scopes. */
	public class ShaderContext2 extends ShaderContext {
		
		public var outputVertex:uint;
		public var outputFragment:uint;
		
		public function ShaderContext2(name:String = null) {
			super(name);
		}
		
		private static function merge(srcScope:ShaderContext, destScope:ShaderContext):void {
			var dest:ShaderContext;
			var src:ShaderContext;
			var len:int = Math.max(destScope.safeZone, srcScope.sources.length);
			if (!(destScope.parent)) {
				destScope.name = srcScope.name;
				destScope.code = srcScope.code;
			}
			destScope.names.length = len;
			destScope.sources.length = len;
			destScope.globals.length = len;
			destScope.locals.length = len;
			var i:int;
			while (i < srcScope.sources.length) {
				dest = (destScope.globals[i] as ShaderContext);
				src = (srcScope.globals[i] as ShaderContext);
				if ((((((i < destScope.safeZone)) && (dest))) && (src))) {
					if (((!((dest.name == src.name))) || (!((dest.varType == src.varType))))) {
						
						throw("Scopes are not compatible and can not be merged.");
						
						return;
					}
				}
				if ((((((i < destScope.safeZone)) && (dest))) && (src))) {
					merge(src, dest);
				} else {
					if ((((i >= destScope.safeZone)) || (((!(dest)) && (src))))) {
						destScope.names[i] = srcScope.names[i];
						destScope.sources[i] = srcScope.sources[i];
						destScope.globals[i] = srcScope.globals[i];
						destScope.locals[i] = srcScope.locals[i];
						if (((src) && ((i >= destScope.safeZone)))) {
							src.parent = destScope;
						}
					}
				}
				i++;
			}
		}
		
		public function get currentPass():int {
			return (ShaderCompiler.currentPass);
		}
		
		public function getNumPasses(technique:String = null):int {
			return (getPasses(technique));
		}
		
		public function init(pass:int):void {
			this.outputVertex = 0;
			this.outputFragment = 0;
			ShaderCompiler.currentPass = pass;
		}
		
		public function process(filter:ShaderFilter):void {
			merge(filter, this);
			filter.process(this);
			this.outputVertex = ((ShaderCompiler.outputVertex) || (this.outputVertex));
			this.outputFragment = ((ShaderCompiler.outputFragment) || (this.outputFragment));
		}
		
		public function build():ShaderProgram {
			return (ShaderCompiler.build());
		}
	
	}
}

