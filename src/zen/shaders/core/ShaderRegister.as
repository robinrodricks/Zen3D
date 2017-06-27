package zen.shaders.core {
	import zen.shaders.*;
	import zen.enums.*;
	import zen.shaders.ShaderBase;
	
	import flash.utils.Dictionary;
	import zen.shaders.*;
	import flash.utils.*;
	
	public class ShaderRegister extends ShaderBase {
		
		private static const _sizes:Array = [0, 1, 3, 7, 15];
		
		private var maxRegisters:int;
		public var memory:Vector.<int>;
		public var addr:Dictionary;
		
		private static function fill(v:int):String {
			var value:String = v.toString(2);
			while (value.length < 4) {
				value = ("0" + value);
			}
			return (value);
		}
		
		public function reset(name:String, maxRegisters:int = 0):void {
			this.name = name;
			this.maxRegisters = maxRegisters;
			this.memory = new Vector.<int>(maxRegisters);
			this.addr = new Dictionary(true);
		}
		
		public function dispose():void {
			this.memory = null;
			this.addr = null;
		}
		
		public function alloc(v:uint):int {
			var start:int;
			var count:int;
			var offset:int;
			var semantic:String;
			var mem:int;
			var reg:int;
			var source:int = ShaderCompiler.getSourceAddress((v & 0xFFFF));
			if (ShaderCompiler.globals[source]) {
				semantic = ShaderCompiler.globals[source].semantic;
			}
			if (((((semantic) && (!((semantic == ""))))) && (!((this.addr[semantic] == undefined))))) {
				this.addr[source] = this.addr[semantic];
				return (-1);
			}
			if (this.addr[source] != undefined) {
				return (-1);
			}
			var fill:Boolean;
			var size:int = ShaderCompiler.getSourceSize(source);
			var length:int = ShaderCompiler.getSourceLength(source);
			var type:int = ShaderCompiler.getRegisterType(v);
			if ((((((((type == ZSLFlags.INPUT)) || ((type == ZSLFlags.PARAM)))) || ((type == ZSLFlags.SAMPLER2D)))) || ((type == ZSLFlags.SAMPLERCUBE)))) {
				fill = true;
			}
			var address:int;
			var a:int;
			while ((((a < (this.memory.length * 4))) && (!((count == (size * length)))))) {
				start = (address / 4);
				offset = (address % 4);
				while (this.memory.length <= start) {
					this.memory.length++;
				}
				mem = this.memory[start];
				reg = (_sizes[size] << offset);
				if ((((size <= (4 - offset))) && (((mem ^ (reg & mem)) == mem)))) {
					count = (count + size);
					if ((((size >= 3)) || (fill))) {
						address = (address + 4);
					} else {
						address = (address + size);
					}
				} else {
					if ((((size >= 3)) || (fill))) {
						address = (address + 4);
					} else {
						address++;
					}
					a = address;
					count = 0;
				}
			}
			if ((a / 4) >= this.maxRegisters) {
				this.memory.length++;
			}
			this.addr[source] = a;
			if (semantic) {
				this.addr[semantic] = a;
			}
			count = 0;
			while (count != (size * length)) {
				start = (a / 4);
				offset = (a % 4);
				if (fill) {
					this.memory[start] = 15;
				} else {
					this.memory[start] = (this.memory[start] | (_sizes[size] << offset));
				}
				if (size >= 3) {
					a = (a + 4);
				} else {
					a = (a + size);
				}
				count = (count + size);
			}
			return (this.addr[source]);
		}
		
		public function free(v:uint):void {
			var start:int;
			var offset:int;
			var count:int;
			var source:int = ShaderCompiler.getSourceAddress((v & 0xFFFF));
			if (this.addr[source] == undefined) {
				return;
			}
			var size:int = ShaderCompiler.getSourceSize((v & 0xFFFF));
			var length:int = ShaderCompiler.getSourceLength((v & 0xFFFF));
			var address:int = this.addr[source];
			while (count != (size * length)) {
				start = (address / 4);
				offset = (address % 4);
				this.memory[start] = (this.memory[start] | (_sizes[size] << offset));
				this.memory[start] = (this.memory[start] - (_sizes[size] << offset));
				if (size >= 3) {
					address = (address + 4);
				} else {
					address = (address + size);
				}
				count = (count + size);
			}
			this.addr[source] = undefined;
		}
	
	}
}

