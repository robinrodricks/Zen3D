package zen.shaders {
	import zen.enums.*;
	import zen.shaders.ShaderBase;
	import zen.shaders.core.*;
	import zen.shaders.objects.*;
	
	import flash.utils.Dictionary;
	import zen.shaders.ShaderContext;
	import flash.utils.ByteArray;
	import zen.shaders.ShaderVar;
	import zen.shaders.ShaderTexture;
	import flash.display3D.Context3DProgramType;
	import zen.shaders.ShaderError;
	import zen.shaders.ShaderProgram;
	import flash.utils.getTimer;
	import flash.utils.Endian;
	import flash.geom.Rectangle;
	import zen.shaders.ShaderInput;
	import zen.shaders.ShaderMatrix;
	import flash.geom.Matrix3D;
	import flash.utils.*;
	import zen.shaders.*;
	import flash.display3D.*;
	import flash.geom.*;
	
	
	/** ZSL Engine is a JIT compiler for the high-level ZSL shaders into low-level AGAL shaders.
	 * 
	 * Merges all of the "Filters" per Material into an optimized AGAL program.
	 * 
	 * - It allow you to modify the appearance of each object / material / pixel on the screen.
	 * - You can not only make things look better, but also faster!
	 * - It gives to you full control, it puts all the render pipeline into your hands!! you will be able to twist the engine to its limits!
	 * - It’s a very simple and powerful language, you will not need to deal with AGAL/Assembler or low level code.
	 * - It produces optimized bytecode and deals with all the hard and boring stuff for you
	 * - It is the first shader language based on a dynamic virtual machine
	 * 
	 * */
	public class ShaderCompiler extends ShaderBase {
		
		
		private static const evalValues:Vector.<Number> = new Vector.<Number>(4, true);
		private static const UP:int = (((1 | (1 << 2)) | (1 << 4)) | (1 << 6));
		private static const FULL:int = (((0 | (1 << 2)) | (2 << 4)) | (3 << 6));
		private static const DIRECT:int = 0;
		private static const INDIRECT:int = (1 << 7);
		private static const F_MASK1:uint = 1;
		private static const F_MASK3:uint = 2;
		private static const F_MASK4:uint = 4;
		private static const M_XYZW:int = FULL;
		private static const M_XYZ:int = ((0 | (1 << 2)) | (2 << 4));
		private static const M_XY:int = (0 | (1 << 2));
		private static const M_X:int = 0;
		private static const MASK_XYZ:int = ((3 | (3 << 2)) | (3 << 4));
		private static const MASK_XY:int = (3 | (3 << 2));
		private static const MASK_X:int = 3;
		private static const SAMPLER_FORMAT_SHIFT:uint = 8;
		private static const SAMPLER_TYPE_SHIFT:uint = 12;
		private static const SAMPLER_SPECIAL_SHIFT:uint = 16;
		private static const SAMPLER_WRAP_SHIFT:uint = 20;
		private static const SAMPLER_MIPMAP_SHIFT:uint = 24;
		private static const SAMPLER_FILTER_SHIFT:uint = 28;
		
		public static var semantics:Dictionary = new Dictionary();
		public static var defines:Dictionary = new Dictionary();
		public static var globals:Vector.<ShaderBase> = new Vector.<ShaderBase>(1);
		public static var sources:Vector.<uint> = new Vector.<uint>(1);
		public static var names:Vector.<String> = new Vector.<String>(1);
		public static var states:Vector.<int> = new Vector.<int>(1);
		public static var indirect:Vector.<uint> = new Vector.<uint>(1);
		public static var float:Vector.<Number> = new Vector.<Number>(1);
		private static var srcCount:int = 1;
		private static var floatCount:int = 1;
		private static var indirectCount:int = 1;
		private static var lastLine:int = -1;
		private static var lastPos:int = -1;
		private static var stackCalls:Vector.<ShaderContext>;
		private static var stack:Vector.<uint>;
		private static var calls:Dictionary;
		public static var outputVertex:uint;
		public static var outputFragment:uint;
		public static var currentPass:int;
		private static var _state:String;
		private static var _registers:Vector.<ShaderRegister> = new Vector.<ShaderRegister>(7, true);
		private static var _firstRead:Array;
		private static var _currBytes:ByteArray;
		private static var _write:Dictionary;
		
		public static var OPS:Array = [];
		public static var agalVersion:int = 1;
		
		
		
		
		// STATIC INIT
		
		public static function init():void {
			
			_registers[ZSLFlags.R_INPUT] = new ShaderRegister();
			_registers[ZSLFlags.R_CONSTANT] = new ShaderRegister();
			_registers[ZSLFlags.R_TEMPORAL] = new ShaderRegister();
			_registers[ZSLFlags.R_OUTPUT] = new ShaderRegister();
			_registers[ZSLFlags.R_INTERPOLATED] = new ShaderRegister();
			_registers[ZSLFlags.R_SAMPLER] = new ShaderRegister();
			_registers[ZSLFlags.R_DEPTH] = new ShaderRegister();
			
            OPS = ["mov", "add", "sub", "mul", "div", "rcp", "min", "max", "frc", "sqr", "rsq", "pow", "log", "exp", "nrm", "sin", "cos", "crs", "dp3", "dp4", "abs", "neg", "sat", "m33", "m44", "m34", "ddx", "ddy", "ife", "ine", "ifg", "ilt", "els", "eif", null, null, null, null, "ted", "kill", "tex", "sge", "slt", null, "seq", "sne"];
			OPS[160] = "#get";
            OPS[161] = "#get_ns";
            OPS[162] = "#parent";
            OPS[163] = "#parent_n";
            OPS[164] = "#call";
            OPS[165] = "#agal";
            OPS[166] = "#null";
            OPS[167] = "#ret";
            OPS[176] = "#prop";
            OPS[177] = "#index";
            OPS[178] = "#meta";
            OPS[192] = "#dup";
            OPS[193] = "#swap";
            OPS[208] = "#or";
            OPS[209] = "#and";
            OPS[210] = "#not";
            OPS[224] = "#if";
            OPS[225] = "#jump";
            OPS[226] = "#sge";
            OPS[227] = "#slt";
            OPS[228] = "#seq";
            OPS[229] = "#sne";
            OPS[240] = "#debug_d";
            OPS[241] = "#debug";
		}
		
		
		
		// COMPILE SHADER CODE TO BYTES
		
        public static var libs:Vector.<ByteArray> = new Vector.<ByteArray>();
		
        public static function compileShader(source:String):ByteArray
        {
            var l:ByteArray;
			
			// parse source code
            var tokens:Vector.<ShaderToken> = ShaderTokenizer.parse(source);
			
			// reset engine state
            ShaderCompiler.gc();
            ShaderParser.reset();
			
			// ???
            if (libs){
                for each (l in libs) {
                    ShaderParser.bind(l);
                }
            }
			
			// ???
            var bytes:ByteArray = ShaderParser.parse(tokens);
            return (bytes);
        }

		
		
		
		// DECOMPILE SHADER BYTES TO CODE
		
        private static var _disState:int;
        private static var _disVertexCount:int;
        private static var _disFragmentCount:int;
        private static var _disResult:String;

		/** Helper to trace binary AGAL code as strings. */
        public static function decompile(vtx:ByteArray, frg:ByteArray):String
        {
            _disVertexCount = 0;
            _disFragmentCount = 0;
            _disResult = "";
            _disState = 0;
            vtx.position = 7;
            while (vtx.bytesAvailable > 0) {
                getOpCode(++_disVertexCount, vtx.readUnsignedInt(), vtx);
            }
            _disResult = (_disResult + "-----------\n");
            _disState = 1;
            frg.position = 7;
            while (frg.bytesAvailable > 0) {
                getOpCode(++_disFragmentCount, frg.readUnsignedInt(), frg);
            }
            _disResult = (_disResult + "-----------\n");
            _disResult = (_disResult + ((("vertex: " + _disVertexCount) + " / fragment: ") + _disFragmentCount));
            return (_disResult);
        }

        public static function printVertex(bytes:ByteArray):String
        {
            _disState = 0;
            _disResult = "";
            _disVertexCount = 0;
            bytes.position = 7;
            while (bytes.bytesAvailable > 0) {
                getOpCode(++_disVertexCount, bytes.readUnsignedInt(), bytes);
            }
            return (_disResult);
        }

        public static function printFragment(bytes:ByteArray):String
        {
            _disState = 1;
            _disResult = "";
            _disFragmentCount = 0;
            bytes.position = 7;
            while (bytes.bytesAvailable > 0) {
                getOpCode(++_disFragmentCount, bytes.readUnsignedInt(), bytes);
            }
            return (_disResult);
        }

        private static function getOpCode(count:int, id:int, bytes:ByteArray):void
        {
            switch (id){
                case ZSLOpcode.MOV:
                case ZSLOpcode.SAT:
                case ZSLOpcode.FRC:
                case ZSLOpcode.RCP:
                case ZSLOpcode.SQRT:
                case ZSLOpcode.RSQ:
                case ZSLOpcode.LOG:
                case ZSLOpcode.EXP:
                case ZSLOpcode.NRM:
                case ZSLOpcode.SIN:
                case ZSLOpcode.COS:
                case ZSLOpcode.ABS:
                case ZSLOpcode.NEG:
                    _disResult = (_disResult + (((((((((count + " ") + ShaderCompiler.OPS[id]) + " ") + getDest(bytes)) + " ") + getSource(bytes)) + " ") + getNull(bytes)) + "\n"));
                    break;
                case ZSLOpcode.KILL:
                    bytes.readUnsignedShort();
                    bytes.readUnsignedByte();
                    bytes.readUnsignedByte();
                    _disResult = (_disResult + (((((((count + " ") + ShaderCompiler.OPS[id]) + " ") + getSource(bytes)) + " ") + getNull(bytes)) + "\n"));
                    break;
                case ZSLOpcode.TEX:
                case ZSLOpcode.TED:
                    _disResult = (_disResult + (((((((((count + " ") + ShaderCompiler.OPS[id]) + " ") + getDest(bytes)) + " ") + getSource(bytes)) + " ") + getSampler(bytes)) + "\n"));
                    break;
                default:
                    _disResult = (_disResult + (((((((((count + " ") + ShaderCompiler.OPS[id]) + " ") + getDest(bytes)) + " ") + getSource(bytes)) + " ") + getSource(bytes)) + "\n"));
            }
        }

        private static function getNull(bytes:ByteArray):String
        {
            bytes.readUnsignedInt();
            bytes.readUnsignedInt();
            return ("");
        }

        private static function getDest(bytes:ByteArray):String
        {
            var index:int = bytes.readUnsignedShort();
            var dmask:int = bytes.readUnsignedByte();
            var data:int = bytes.readUnsignedByte();
            var dsmask:String = "";
            if ((dmask & 1)){
                dsmask = (dsmask + "x");
            }
            if ((dmask & 2)){
                dsmask = (dsmask + "y");
            }
            if ((dmask & 4)){
                dsmask = (dsmask + "z");
            }
            if ((dmask & 8)){
                dsmask = (dsmask + "w");
            }
            return ((((getData(data) + index) + ".") + dsmask));
        }

        private static function getSource(bytes:ByteArray):String
        {
            var index:int = bytes.readUnsignedShort();
            var indirect:int = bytes.readUnsignedByte();
            var mask:int = bytes.readUnsignedByte();
            var data:int = bytes.readUnsignedByte();
            var rType:int = bytes.readUnsignedByte();
            var rSelect:int = bytes.readUnsignedByte();
            var rMode:int = bytes.readUnsignedByte();
            if (rMode > 0){
                return (((((((((((getData(data) + "[") + getData(rType)) + index) + ".") + "xyzw".charAt(rSelect)) + "+") + indirect) + "]") + ".") + maskToString(mask)));
            }
            return ((((getData(data) + index) + ".") + maskToString(mask)));
        }

        private static function getSampler(bytes:ByteArray):String
        {
            var index:int = bytes.readUnsignedShort();
            var bias:int = bytes.readByte();
            bytes.readByte();
            var flags:uint = bytes.readUnsignedInt();
            var filter:uint = (flags >> 28);
            var mip:uint = ((flags >> 24) & 15);
            var wrap:uint = ((flags >> 20) & 15);
            var special:uint = ((flags >> 16) & 15);
            var type:uint = ((flags >> 12) & 15);
            var format:uint = ((flags >> 8) & 15);
            var fs:String = (("fs" + index) + " <");
            fs = (fs + ["fNearest", "fLinear"][filter]);
            fs = (fs + ("," + ["mNone", "mNearest", "mLinear"][mip]));
            fs = (fs + ("," + ["wClamp", "wRepeat"][wrap]));
            fs = (fs + ("," + ["2d", "cube"][type]));
            fs = (fs + ("," + ["rgba", "compressed", "compressedAlpha"][format]));
            fs = (fs + (",b:" + bias));
            return ((fs + ">"));
        }

        private static function getData(value:int):String
        {
            switch (value){
                case 0:
                    return ("va");
                case 1:
                    return ((((_disState == 0)) ? "vc" : "fc"));
                case 2:
                    return ((((_disState == 0)) ? "vt" : "ft"));
                case 3:
                    return ((((_disState == 0)) ? "vo" : "fo"));
                case 4:
                    return ("vi");
                case 5:
                    return ("fs");
                case 6:
                    return ("fd");
            }
            return ("?");
        }

        private static function maskToString(mask:int):String
        {
            var m:String;
            var b:String = "xyzw";
            m = b.charAt((mask & 3));
            m = (m + b.charAt(((mask >> 2) & 3)));
            m = (m + b.charAt(((mask >> 4) & 3)));
            m = (m + b.charAt(((mask >> 6) & 3)));
            return (m);
        }

		
		
		
		
		// PRE ENTRY POINTS
		
		// externally called to build the `ShaderContext.resultOps` data
		
		public static function call(scope:ShaderContext, out:Vector.<uint>, params:Array = null):uint {
			var r:int;
			if (params) {
				r = 0;
				while (r < scope.paramCount) {
					scope.locals[r] = params[r];
					r++;
				}
			}
			if (!(stack)) {
				stack = new Vector.<uint>();
			}
			if (!(calls)) {
				calls = new Dictionary();
			}
			lastLine = -1;
			lastPos = -1;
			stackCalls = new Vector.<ShaderContext>();
			outputVertex = 0;
			outputFragment = 0;
			if (scope.parent) {
				callFW(scope.parent, out);
			}
			execute(scope, out);
			return (((stack.length) ? stack[(stack.length - 1)] : 0));
		}
		
		private static function callFW(scope:ShaderContext, out:Vector.<uint>):void {
			if (scope.parent) {
				callFW(scope.parent, out);
			}
			if (!(calls[scope.code])) {
				execute(scope, out);
			}
		}
		
		public static function alloc(name:String, source:uint, global:ShaderBase = null):uint {
			var dataIndex:int;
			var param:ShaderVar;
			var type:int = ((source >> 16) & 63);
			var size:int = ((source >> 22) & 3);
			var len:int = ((source >> 24) & 0xFF);
			if (len == 0) {
				len = 1;
			}
			switch (type) {
				case ZSLFlags.OUTPUT: 
				case ZSLFlags.MATRIX: 
				case ZSLFlags.PARAM: 
				case ZSLFlags.CONST: 
				case ZSLFlags.INPUT: 
				case ZSLFlags.INTERPOLATED: 
				case ZSLFlags.TEMPORAL: 
				case ZSLFlags.OUTPUT: 
					dataIndex = floatCount;
					floatCount = (floatCount + ((size + 1) * len));
					if (float.length < floatCount) {
						float.length = floatCount;
					}
					break;
				case ZSLFlags.SAMPLER2D: 
				case ZSLFlags.SAMPLERCUBE: 
					dataIndex = srcCount;
					break;
			}
			var start:int = srcCount;
			var i:int;
			while (i < len) {
				globals[srcCount] = global;
				sources[srcCount] = (((dataIndex | (type << 16)) | (size << 22)) | (i << 24));
				names[srcCount] = name;
				states[srcCount] = ZSLFlags.STATE_UNDEFINED;
				srcCount++;
				i++;
			}
			if ((((type == ZSLFlags.CONST)) && (!(isNaN(Number(name)))))) {
				float[dataIndex] = Number(name);
				states[start] = ZSLFlags.STATE_INIT;
			} else {
				if (type == ZSLFlags.INPUT) {
					states[start] = ZSLFlags.STATE_INIT;
				} else {
					if ((global is ShaderVar)) {
						param = (global as ShaderVar);
						param.format = ("float" + (size + 1));
						param.length = len;
						if (param.value) {
							i = 0;
							while (i < param.value.length) {
								float[(dataIndex + i)] = param.value[i];
								i++;
							}
							states[start] = ZSLFlags.STATE_USER_DEFINED;
						}
					} else {
						if ((((type == ZSLFlags.SAMPLER2D)) && (ShaderTexture(global).value))) {
							states[start] = ZSLFlags.STATE_USER_DEFINED;
						} else {
							if ((((type == ZSLFlags.SAMPLERCUBE)) && (ShaderTexture(global).value))) {
								states[start] = ZSLFlags.STATE_USER_DEFINED;
							}
						}
					}
				}
			}
			if (srcCount >= 0xFFFF) {
				error(null, "Out of memory.");
			}
			var mask:int = FULL;
			if (size == 1) {
				mask = M_XY;
			}
			if (size == 2) {
				mask = M_XYZ;
			}
			if ((((size == 3)) || ((type == ZSLFlags.INPUT)))) {
				mask = FULL;
			}
			return (((start | (mask << 16)) | (size << 24)));
		}
		
		private static function execute(scope:ShaderContext, out:Vector.<uint>):uint {
			var i:int;
			var e:int;
			var curr:ShaderContext;
			var func:ShaderContext;
			var param:ShaderVar;
			var dest:uint;
			var src0:uint;
			var src1:uint;
			var temp:uint;
			var code:ByteArray;
			var id:int;
			var _local15:int;
			var _local16:String;
			var _local17:String;
			var _local18:String;
			var _local19:ShaderBase;
			var _local20:int;
			var _local21:int;
			var _local22:String;
			var _local23:int;
			var _local24:int;
			var val:int;
			var addr:uint;
			var reg:uint;
			var res:String;
			var regSize:int;
			var regType:int;
			var regValues:Array;
			var s:int;
			i = scope.paramCount;
			while (i < scope.sources.length) {
				if (scope.sources[i]) {
					scope.locals[i] = alloc(scope.names[i], scope.sources[i], scope.globals[i]);
				}
				i++;
			}
			if (((!((scope.varType == ZSLFlags.FUNCTION))) && (calls[scope.code]))) {
				error(scope, "Namespaces can not be executed multiple times.");
			}
			calls[scope.code] = true;
			stackCalls.push(scope);
			var verbose:Boolean;
			code = scope.code;
			code.position = 0;
			while (code.bytesAvailable > 0) {
				if (!(curr)) {
					curr = scope;
				}
				id = code.readUnsignedByte();
				switch (id) {
					case ZSLFlags.NULL: 
						stack.push(0);
						break;
					case ZSLFlags.GET: 
						e = code.readUnsignedByte();
						if (verbose) {
							trace("\tget", e, ShaderCompiler.registerToStr(curr.getLocal(e)));
						}
						if (!(curr.locals[e])) {
							error(curr, (("Can not find reference to " + e) + "."));
						}
						stack.push(curr.getLocal(e));
						curr = scope;
						break;
					case ZSLFlags.GET_NS: 
						curr = (curr.globals[code.readUnsignedByte()] as ShaderContext);
						if (!(calls[curr.code])) {
							execute(curr, out);
						}
						break;
					case ZSLFlags.PARENT: 
						curr = curr.parent;
						if (verbose) {
							trace("\tparent", curr);
						}
						break;
					case ZSLFlags.PARENT_N: 
						_local15 = code.readUnsignedByte();
						while (_local15--) {
							curr = curr.parent;
						}
						if (verbose) {
							trace("\tparent_n", curr);
						}
						break;
					case ZSLFlags.CALL: 
						e = code.readUnsignedByte();
						if (verbose) {
							trace("\tcall", e, curr.globals[e]);
						}
						func = (curr.globals[e] as ShaderContext);
						if (!(func)) {
							error(curr, (("Can not find reference to reference " + e) + "."));
						}
						i = (func.paramCount - 1);
						while (i >= 0) {
							func.locals[i] = stack.pop();
							i--;
						}
						execute(func, out);
						curr = scope;
						break;
					case ZSLFlags.PROP: 
						_local16 = code.readUTF();
						if (verbose) {
							trace("\tprop", _local16);
						}
						if (!(isNaN(Number(_local16)))) {
							stack.push(getNewRegisterOffset(stack.pop(), int(_local16)));
						} else {
							stack.push(getNewRegisterFromMask(stack.pop(), ShaderCompiler.strToMask(_local16), _local16.length));
						}
						break;
					case ZSLFlags.INDEX: 
						src1 = stack.pop();
						src0 = stack.pop();
						if (((isConstant(src0)) && (isConstant(src1)))) {
							val = getRegisterValue(src1, 0);
							addr = (getSourceAddress((src0 & 0xFFFF)) + val);
							reg = ((src0 & 0xFFFF0000) | addr);
							stack.push(reg);
						} else {
							stack.push(setRegisterIndirectValue(src0, src1));
						}
						break;
					case ZSLFlags.META: 
						dest = stack.pop();
						_local17 = code.readUTF();
						_local18 = code.readUTF();
						_local19 = globals[(dest & 0xFFFF)];
						_local19[_local17] = _local18;
						break;
					case ZSLFlags.IF: 
						_local20 = code.readShort();
						dest = stack.pop();
						if (verbose) {
							trace("if", ShaderCompiler.registerToStr(dest), toBoolean(dest));
						}
						param = (globals[(dest & 0xFFFF)] as ShaderVar);
						if (((param) && (!(param.value)))) {
							param.value = getSourceValues((dest & 0xFFFF));
						}
						if (!(toBoolean(dest))) {
							code.position = _local20;
						}
						break;
					case ZSLFlags.JUMP: 
						code.position = code.readShort();
						break;
					case ZSLFlags.NOT: 
						src0 = stack.pop();
						dest = alloc(("not:" + names[(src0 & 0xFFFF)]), (ZSLFlags.CONST << 16));
						out.push(id, dest, src0, 0);
						eval(id, dest, src0, src1);
						stack.push(dest);
						break;
					case ZSLFlags.OR: 
						src1 = stack.pop();
						src0 = stack.pop();
						if (toBoolean(src0)) {
							stack.push(src0);
						} else {
							if (toBoolean(src1)) {
								stack.push(src1);
							} else {
								stack.push(alloc("null", (ZSLFlags.CONST << 16)));
							}
						}
						break;
					case ZSLFlags.AND: 
					case ZSLFlags.SEQ: 
					case ZSLFlags.SNE: 
					case ZSLFlags.SGE: 
					case ZSLFlags.SLT: 
						src1 = stack.pop();
						src0 = stack.pop();
						dest = alloc((((("[" + names[(src0 & 0xFFFF)]) + ":") + names[(src1 & 0xFFFF)]) + "]"), (ZSLFlags.CONST << 16));
						out.push(id, dest, src0, src1);
						param = (globals[(src0 & 0xFFFF)] as ShaderVar);
						if (((param) && (!(param.value)))) {
							param.value = getSourceValues((src0 & 0xFFFF));
						}
						param = (globals[(src1 & 0xFFFF)] as ShaderVar);
						if (((param) && (!(param.value)))) {
							param.value = getSourceValues((src1 & 0xFFFF));
						}
						eval(id, dest, src0, src1);
						stack.push(dest);
						break;
					case ZSLFlags.DEBUG: 
						_local21 = code.readUnsignedByte();
						_local22 = "";
						while (_local21-- > 0) {
							src0 = stack.pop();
							regSize = getRegisterSize(src0);
							regType = getRegisterType(src0);
							if (regType == ZSLFlags.STRING) {
								res = names[(src0 & 0xFFFF)];
							} else {
								regValues = [];
								s = 0;
								while (s < regSize) {
									regValues[s] = getRegisterValue(src0, s);
									s++;
								}
								res = regValues.toString();
							}
							_local22 = ((res + " ") + _local22);
						}
						trace(_local22);
						break;
					case ZSLFlags.DEBUG_D: 
						lastLine = code.readUnsignedShort();
						lastPos = code.readUnsignedShort();
						break;
					case ZSLFlags.DUP: 
						stack.push(stack[(stack.length - 1)]);
						break;
					case ZSLFlags.SWAP: 
						src0 = stack.pop();
						src1 = stack.pop();
						stack.push(src0, src1);
						break;
					case ZSLFlags.AGAL: 
						_local23 = code.readUnsignedByte();
						_local24 = code.readUnsignedByte();
						if (verbose) {
							trace("\tagal", ("0x" + _local23.toString(16)), _local24);
						}
						if ((_local24 > 2)) {
							src1 = stack.pop();
						} else {
							src1 = 0;
						}
						if ((_local24 > 1)) {
							src0 = stack.pop();
						} else {
							src0 = 0;
						}
						if ((_local24 > 0)) {
							dest = stack.pop();
						} else {
							dest = 0;
						}
						if (((isConstant(src0)) && (isConstant(src1)))) {
							temp = src0;
							src0 = createFrom(src0, src1);
							out.push(ZSLOpcode.MOV, src0, temp, 0);
							eval(ZSLOpcode.MOV, src0, temp, 0);
						}
						out.push(_local23, dest, src0, src1);
						eval(_local23, dest, src0, src1);
						break;
					case ZSLOpcode.MOV: 
						if (verbose) {
							trace("\tmov");
						}
						src0 = stack.pop();
						dest = stack.pop();
						if (src0) {
							out.push(id, dest, src0, 0);
							eval(id, dest, src0, 0);
							if (getRegisterType(dest) == ZSLFlags.OUTPUT) {
								if (names[(dest & 0xFFFF)] == Context3DProgramType.VERTEX) {
									outputVertex = src0;
								}
								if (names[(dest & 0xFFFF)] == Context3DProgramType.FRAGMENT) {
									outputFragment = src0;
								}
							}
						} else {
							states[getSourceAddress((dest & 0xFFFF))] = ZSLFlags.STATE_UNDEFINED;
						}
						break;
					case ZSLOpcode.NEG: 
						src0 = stack.pop();
						if (isConstant(src0)) {
							temp = src0;
							src0 = createFrom(temp, temp);
							out.push(ZSLOpcode.MOV, src0, temp, 0);
							eval(ZSLOpcode.MOV, src0, temp, 0);
						}
						dest = alloc(("neg:" + names[(src0 & 0xFFFF)]), ((ZSLFlags.TEMPORAL << 16) | (((src0 >> 24) & 3) << 22)));
						out.push(id, dest, src0, 0);
						eval(id, dest, src0, 0);
						stack.push(dest);
						break;
					case ZSLFlags.RET: 
						return (((((stack.length) && (!((scope.varType == ZSLFlags.VOID))))) ? stack[(stack.length - 1)] : 0));
					default: 
						src1 = stack.pop();
						src0 = stack.pop();
						if (((isConstant(src0)) && (isConstant(src1)))) {
							temp = src0;
							src0 = createFrom(src0, src1);
							out.push(ZSLOpcode.MOV, src0, temp, 0);
							eval(ZSLOpcode.MOV, src0, temp, 0);
						}
						dest = createFrom(src0, src1);
						stack.push(dest);
						out.push(id, dest, src0, src1);
						eval(id, dest, src0, src1);
				}
			}
			return (((((stack.length) && (!((scope.varType == ZSLFlags.VOID))))) ? stack[(stack.length - 1)] : 0));
		}
		
		private static function error(ns:ShaderContext, msg:String):void {
			
			
			var s:ShaderContext;
			var n:String = ((ns) ? ns.name : "null");
			var m:String = "";
			for each (s in stackCalls) {
				m = ((("    " + s.toString()) + "\n") + m);
			}
			m = ((msg + "\n") + m);
			if (lastLine != -1) {
				throw(new ShaderError(((n + " - ") + m.substr(0, -1)), lastLine, lastPos));
				return;
			}
			throw(((n + " - ") + m.substr(0, -1)));
			
			
		}
		
		public static function createFrom(reg0:uint, reg1:uint, type:int = 1):uint {
			var name:String = "temp";
			var size0:int = ((reg0 >> 24) & 3);
			var size1:int = ((reg1 >> 24) & 3);
			var size:int = (((size0 > size1)) ? size0 : size1);
			return (alloc(name, ((type << 16) | (size << 22))));
		}
		
		
		
		
		// MAIN ENTRY POINTS
		
		/** Resets entire state
		 * ONLY called by `build()` and `ZSLCompiler` */
		public static function gc():void {
			sources.length = 1;
			globals.length = 1;
			names.length = 1;
			states.length = 1;
			float.length = 1;
			stackCalls = null;
			stack = null;
			calls = null;
			outputVertex = 0;
			outputFragment = 0;
			srcCount = 1;
			floatCount = 1;
			indirectCount = 1;
			ShaderContext.resultOps = null;
		}
		
		/** ??? */
		private static function eval(op:int, dest:uint, reg0:uint, reg1:uint):void {
			var i:int;
			var result:Boolean;
			var size0:int;
			var size1:int;
			var length:Number;
			var size:int = (((dest >> 24) & 3) + 1);
			states[getSourceAddress((dest & 0xFFFF))] = (states[getSourceAddress((dest & 0xFFFF))] | ZSLFlags.STATE_INIT);
			if (!(isFloat(dest))) {
				return;
			}
			if (!(isFloat(reg0))) {
				return;
			}
			if (op == ZSLOpcode.KILL) {
				return;
			}
			if ((((((((op == ZSLFlags.SEQ)) || ((op == ZSLFlags.SNE)))) || ((op == ZSLFlags.SGE)))) || ((op == ZSLFlags.SLT)))) {
				result = (((op == ZSLFlags.SNE)) ? false : true);
				size0 = ((reg0 >> 24) & 3);
				size1 = ((reg1 >> 24) & 3);
				size = ((((size0 > size1)) ? size0 : size1) + 1);
				i = 0;
				while (i < size) {
					switch (op) {
						case ZSLFlags.SEQ: 
							result = ((result) && ((getRegisterValue(reg0, i) == getRegisterValue(reg1, i))));
							break;
						case ZSLFlags.SNE: 
							result = ((result) || (!((getRegisterValue(reg0, i) == getRegisterValue(reg1, i)))));
							break;
						case ZSLFlags.SGE: 
							result = ((result) && ((getRegisterValue(reg0, i) >= getRegisterValue(reg1, i))));
							break;
						case ZSLFlags.SLT: 
							result = ((result) && ((getRegisterValue(reg0, i) < getRegisterValue(reg1, i))));
							break;
					}
					i++;
				}
				setRegisterValue(dest, 0, ((result) ? 1 : 0));
				return;
			}
			i = 0;
			while (i < size) {
				switch (op) {
					case ZSLOpcode.MOV: 
						evalValues[i] = getRegisterValue(reg0, i);
						break;
					case ZSLOpcode.ADD: 
						evalValues[i] = (getRegisterValue(reg0, i) + getRegisterValue(reg1, i));
						break;
					case ZSLOpcode.SUB: 
						evalValues[i] = (getRegisterValue(reg0, i) - getRegisterValue(reg1, i));
						break;
					case ZSLOpcode.MUL: 
						evalValues[i] = (getRegisterValue(reg0, i) * getRegisterValue(reg1, i));
						break;
					case ZSLOpcode.DIV: 
						evalValues[i] = (getRegisterValue(reg0, i) / getRegisterValue(reg1, i));
						break;
					case ZSLOpcode.NEG: 
						evalValues[i] = -(getRegisterValue(reg0, i));
						break;
					case ZSLOpcode.POW: 
						evalValues[i] = Math.pow(getRegisterValue(reg0, i), getRegisterValue(reg1, i));
						break;
					case ZSLOpcode.MAX: 
						evalValues[i] = Math.max(getRegisterValue(reg0, i), getRegisterValue(reg1, i));
						break;
					case ZSLOpcode.MIN: 
						evalValues[i] = Math.min(getRegisterValue(reg0, i), getRegisterValue(reg1, i));
						break;
					case ZSLOpcode.SEQ: 
						evalValues[i] = (((getRegisterValue(reg0, i) == getRegisterValue(reg1, i))) ? 1 : 0);
						break;
					case ZSLOpcode.SNE: 
						evalValues[i] = ((!((getRegisterValue(reg0, i) == getRegisterValue(reg1, i)))) ? 1 : 0);
						break;
					case ZSLOpcode.SGE: 
						evalValues[i] = (((getRegisterValue(reg0, i) >= getRegisterValue(reg1, i))) ? 1 : 0);
						break;
					case ZSLOpcode.SLT: 
						evalValues[i] = (((getRegisterValue(reg0, i) < getRegisterValue(reg1, i))) ? 1 : 0);
						break;
					case ZSLOpcode.NRM: 
						evalValues[i] = getRegisterValue(reg0, i);
						break;
					case ZSLFlags.NOT: 
						evalValues[i] = Number(!(toBoolean(reg0)));
						break;
					case ZSLFlags.AND: 
						evalValues[i] = Number(((toBoolean(reg0)) && (toBoolean(reg1))));
						break;
					case ZSLFlags.OR: 
						evalValues[i] = Number(((toBoolean(reg0)) || (toBoolean(reg1))));
					default: 
						return;
				}
				i++;
			}
			if (op == ZSLOpcode.NRM) {
				length = Math.sqrt((((evalValues[0] * evalValues[0]) + (evalValues[1] * evalValues[1])) + (evalValues[2] * evalValues[2])));
				evalValues[0] = (evalValues[0] / length);
				evalValues[1] = (evalValues[1] / length);
				evalValues[2] = (evalValues[2] / length);
			}
			i = 0;
			while (i < size) {
				setRegisterValue(dest, i, evalValues[i]);
				i++;
			}
		}
		
		/** Converts `ShaderContext.resultOps` into a ShaderProgram, (compiling it into AGAL?) */
		public static function build():ShaderProgram {
			
			// compiles `resultOps` into ShaderProgram
			var result:ShaderProgram = ShaderCompiler.compile(ShaderContext.resultOps);
			
			// clear `resultOps`
			ShaderContext.resultOps = null;
			
			// reset entire state
			ShaderCompiler.gc();
			
			// return new ShaderProgram
			return (result);
		}
		
		/** Compiles `ShaderContext.resultOps` into `ShaderProgram`
		 *
		 * ONLY called by `build()`
		 * INPUT : Vector<uint> .. raw ZSL ops
		 * OUTPUT : ShaderProgram .. contains the Stage3D class `Program3D`
		 * CALLS : `optimize()`, `filter()`
		 *
		 * */
		public static function compile(ops:Vector.<uint>):ShaderProgram {
			var id:int;
			var dest:int;
			var src0:int;
			var src1:int;
			var name:String;
			var time:int = getTimer();
			
			// SEPERATE OPS INTO FRAGMENT / VERTEX SHADER DATA
			filter(ops);
			var shared:Array = [];
			var fragment:Vector.<uint> = extractFragment(ops, shared);
			var vertex:Vector.<uint> = extractVertex(ops, shared);
			
			// OPTIMIZE OPS
			optimize(fragment);
			optimize(vertex);
			var debug:String = "";
			if (vertex.length == 0) {
				
				throw(new ShaderError("Shader must write output vertex to be used as a static material."));
				
				return null;
			}
			if (fragment.length == 0) {
				
				throw(new ShaderError("Shader must write output fragment to be used as a static material."));
				
				return null;
			}
			
			// CREATE PROGRAM
			var prg:ShaderProgram = new ShaderProgram();
			prg.debug = debug;
			
			// init vertex shader
			prg.vertexBytes = new ByteArray();
			prg.vertexBytes.endian = "littleEndian";
			prg.vertexBytes.writeByte(160);
			prg.vertexBytes.writeUnsignedInt(ShaderCompiler.agalVersion);
			prg.vertexBytes.writeByte(161);
			prg.vertexBytes.writeByte(0);
			
			// init fragment shader
			prg.fragmentBytes = new ByteArray();
			prg.fragmentBytes.endian = "littleEndian";
			prg.fragmentBytes.writeByte(160);
			prg.fragmentBytes.writeUnsignedInt(ShaderCompiler.agalVersion);
			prg.fragmentBytes.writeByte(161);
			prg.fragmentBytes.writeByte(1);
			
			// init registers
			(_registers[ZSLFlags.R_INPUT] as ShaderRegister).reset("inputs", 8);
			(_registers[ZSLFlags.R_CONSTANT] as ShaderRegister).reset("vertex constants", (((ShaderCompiler.agalVersion == 1)) ? 128 : 250));
			(_registers[ZSLFlags.R_TEMPORAL] as ShaderRegister).reset("vertex temporals", (((ShaderCompiler.agalVersion == 1)) ? 8 : 26));
			(_registers[ZSLFlags.R_OUTPUT] as ShaderRegister).reset("vertex outputs", 1);
			(_registers[ZSLFlags.R_INTERPOLATED] as ShaderRegister).reset("interpolated", (((ShaderCompiler.agalVersion == 1)) ? 8 : 10));
			_currBytes = prg.vertexBytes;
			_firstRead = [];
			_write = new Dictionary();
			_state = Context3DProgramType.VERTEX;
			allocRegisters(vertex, prg);
			if (vertex.length) {
				write(vertex, (vertex.length - 1), []);
			}
			(_registers[ZSLFlags.R_CONSTANT] as ShaderRegister).reset("fragment constants", (((ShaderCompiler.agalVersion == 1)) ? 28 : 64));
			(_registers[ZSLFlags.R_TEMPORAL] as ShaderRegister).reset("fragment temporals", (((ShaderCompiler.agalVersion == 1)) ? 8 : 26));
			(_registers[ZSLFlags.R_SAMPLER] as ShaderRegister).reset("samplers", (((ShaderCompiler.agalVersion == 1)) ? 8 : 16));
			(_registers[ZSLFlags.R_OUTPUT] as ShaderRegister).reset("fragment outputs", (((ShaderCompiler.agalVersion == 1)) ? 1 : 4));
			(_registers[ZSLFlags.R_DEPTH] as ShaderRegister).reset("depth", 1);
			_currBytes = prg.fragmentBytes;
			_firstRead = [];
			_write = new Dictionary();
			_state = Context3DProgramType.FRAGMENT;
			allocRegisters(fragment, prg);
			if (fragment.length) {
				write(fragment, (fragment.length - 1), []);
			}
			while ((prg.vertexConstants.length % 4)) {
				prg.vertexConstants.push(0);
			}
			while ((prg.fragmentConstants.length % 4)) {
				prg.fragmentConstants.push(0);
			}
			_currBytes = null;
			_firstRead = null;
			_write = null;
			(_registers[ZSLFlags.R_INPUT] as ShaderRegister).dispose();
			(_registers[ZSLFlags.R_CONSTANT] as ShaderRegister).dispose();
			(_registers[ZSLFlags.R_TEMPORAL] as ShaderRegister).dispose();
			(_registers[ZSLFlags.R_OUTPUT] as ShaderRegister).dispose();
			(_registers[ZSLFlags.R_INTERPOLATED] as ShaderRegister).dispose();
			(_registers[ZSLFlags.R_SAMPLER] as ShaderRegister).dispose();
			
			// BUILD PROGRAM BASED ON OPS
			var i:int;
			while (i < ops.length) {
				id = ops[i++];
				dest = ops[i++];
				src0 = ops[i++];
				src1 = ops[i++];
				name = names[(dest & 0xFFFF)];
				if (name != Context3DProgramType.VERTEX) {
					if (name != Context3DProgramType.FRAGMENT) {
						if (name != "depth") {
							if ((((id == ZSLOpcode.MOV)) && ((getRegisterKind(dest) == ZSLFlags.R_OUTPUT)))) {
								switch (typeof(prg[name])) {
									case "string": 
										prg[name] = names[(src0 & 0xFFFF)];
										break;
									case "number": 
										prg[name] = getRegisterValue(src0, 0);
										break;
									case "boolean": 
										prg[name] = getRegisterValue(src0, 0);
										break;
									case "object": 
										switch (name) {
										case "scissor": 
											prg.scissor = new Rectangle();
											prg.scissor.x = getRegisterValue(src0, 0);
											prg.scissor.y = getRegisterValue(src0, 1);
											prg.scissor.width = getRegisterValue(src0, 2);
											prg.scissor.height = getRegisterValue(src0, 3);
											break;
										case "colorMask": 
											prg.colorMask = Vector.<Boolean>(getSourceValues((src0 & 0xFFFF)));
											break;
										case "target": 
											prg.target = (globals[(src0 & 0xFFFF)] as ShaderTexture);
											break;
										default: 
											
											throw((("property '" + name) + "' is not a valid program output."));
											
											return null;
									}
										break;
								}
							}
						}
					}
				}
			}
			_currBytes = null;
			time = (getTimer() - time);
			
			// RETURN PROGRAM
			return (prg);
		}
		
		/** (Seperates ops into vertex/fragment shader ops?) */
		private static function filter(ops:Vector.<uint>):void {
			var vertex:Boolean;
			var i:int;
			var id:uint;
			var dest:uint;
			var src0:uint;
			var src1:uint;
			var frgIndex:int;
			var type:int;
			var read:Array;
			var pass:Boolean;
			var write:Array;
			var fragment:Array = [];
			i = (ops.length - 4);
			while (i >= 4) {
				dest = ops[(i + 1)];
				if (getRegisterType(dest) == ZSLFlags.OUTPUT) {
					if (names[(dest & 0xFFFF)] == "vertex") {
						if (!(vertex)) {
							vertex = true;
						} else {
							ops.splice(i, 4);
						}
					}
					if (names[(dest & 0xFFFF)] == "fragment") {
						frgIndex = ((dest & 0xFFFF) - getSourceAddress((dest & 0xFFFF)));
						if (!(fragment[frgIndex])) {
							fragment[frgIndex] = true;
						} else {
							ops.splice(i, 4);
						}
					}
				}
				i = (i - 4);
			}
			do {
				read = [];
				pass = true;
				i = 0;
				while (i < ops.length) {
					id = ops[i];
					src0 = ops[(i + 2)];
					src1 = ops[(i + 3)];
					if (src0) {
						read[getSourceAddress((src0 & 0xFFFF))] = true;
					}
					if (src1) {
						read[getSourceAddress((src1 & 0xFFFF))] = true;
					}
					if ((src0 >> 26)) {
						read[getSourceAddress((indirect[(src0 >> 26)] & 0xFFFF))] = true;
					}
					if ((src1 >> 26)) {
						read[getSourceAddress((indirect[(src1 >> 26)] & 0xFFFF))] = true;
					}
					i = (i + 4);
				}
				i = 0;
				while (i < ops.length) {
					dest = ops[(i + 1)];
					if (dest) {
						if (getRegisterType(dest) != ZSLFlags.OUTPUT) {
							if (read[getSourceAddress((dest & 0xFFFF))] != true) {
								ops.splice(i, 4);
								i = (i - 4);
								pass = false;
							}
						}
					}
					i = (i + 4);
				}
				write = [];
				i = 0;
				while (i < ops.length) {
					id = ops[i];
					dest = ops[(i + 1)];
					if (((write[(dest & 0xFFFF)]) && ((getRegisterSize(dest) == getSourceSize((dest & 0xFFFF)))))) {
						ops.splice(write[(dest & 0xFFFF)], 4);
						i = (i - 4);
						pass = false;
						break;
					}
					write[(dest & 0xFFFF)] = i;
					delete write[(ops[(i + 2)] & 0xFFFF)];
					delete write[(ops[(i + 3)] & 0xFFFF)];
					i = (i + 4);
				}
			} while (!(pass));
		}
		
		/** Get ops for vertex shader, from raw op data */
		private static function extractVertex(ops:Vector.<uint>, read:Array):Vector.<uint> {
			var output:Boolean;
			var src1:uint;
			var src0:uint;
			var dest:uint;
			var id:uint;
			var destType:int;
			var src0Type:int;
			var src1Type:int;
			var out:Vector.<uint> = new Vector.<uint>();
			var i:int = ops.length;
			for (; i > 0; ) {
				src1 = ops[--i];
				src0 = ops[--i];
				dest = ops[--i];
				id = ops[--i];
				destType = getSourceType((dest & 0xFFFF));
				src0Type = getSourceType((src0 & 0xFFFF));
				src1Type = getSourceType((src1 & 0xFFFF));
				if (destType == ZSLFlags.OUTPUT) {
					if (((!(output)) && ((names[(dest & 0xFFFF)] == Context3DProgramType.VERTEX)))) {
						read[getSourceAddress((dest & 0xFFFF))] = true;
						output = true;
					} else {
						continue;
					}
				}
				if (!isConstant(dest)) {
					if (id != ZSLOpcode.TEX) {
						if (id != ZSLOpcode.TED) {
							if (id != ZSLOpcode.KILL) {
								if (read[getSourceAddress((dest & 0xFFFF))]) {
									if (src0) {
										read[getSourceAddress((src0 & 0xFFFF))] = true;
									}
									if (src1) {
										read[getSourceAddress((src1 & 0xFFFF))] = true;
									}
									if ((src0 >> 26)) {
										read[getSourceAddress((indirect[(src0 >> 26)] & 0xFFFF))] = true;
									}
									if ((src1 >> 26)) {
										read[getSourceAddress((indirect[(src1 >> 26)] & 0xFFFF))] = true;
									}
									out.unshift(id, dest, src0, src1);
								}
							}
						}
					}
				}
			}
			if (!(output)) {
				out.length = 0;
			}
			return (out);
		}
		
		/** Get ops for fragment shader, from raw op data */
		private static function extractFragment(ops:Vector.<uint>, shared:Array):Vector.<uint> {
			var output:Boolean;
			var src1:uint;
			var src0:uint;
			var dest:uint;
			var id:uint;
			var destType:int;
			var src0Type:int;
			var src1Type:int;
			var read:Array = [];
			var out:Vector.<uint> = new Vector.<uint>();
			var i:int = ops.length;
			for (; i > 0; ) {
				src1 = ops[--i];
				src0 = ops[--i];
				dest = ops[--i];
				id = ops[--i];
				destType = getSourceType((dest & 0xFFFF));
				src0Type = getSourceType((src0 & 0xFFFF));
				src1Type = getSourceType((src1 & 0xFFFF));
				if (!isConstant(dest)) {
					if (destType != ZSLFlags.INTERPOLATED) {
						if (destType == ZSLFlags.OUTPUT) {
							if (names[(dest & 0xFFFF)] == "depth") {
								read[getSourceAddress((dest & 0xFFFF))] = true;
							} else {
								if (names[(dest & 0xFFFF)] == Context3DProgramType.FRAGMENT) {
									read[getSourceAddress((dest & 0xFFFF))] = true;
									output = true;
								} else {
									continue;
								}
							}
						}
						if (((((read[getSourceAddress((dest & 0xFFFF))]) || ((id == ZSLOpcode.KILL)))) || (isConditional(id)))) {
							if (src0Type == ZSLFlags.INPUT) {
								
								throw((("Input '" + ShaderCompiler.registerToStr(src0)) + "' can not be read in fragment programs."));
								
								return null;
							}
							if (src1Type == ZSLFlags.INPUT) {
								
								throw((("Input '" + ShaderCompiler.registerToStr(src1)) + "' can not be read in fragment programs."));
								
								return null;
							}
							if (src0) {
								read[getSourceAddress((src0 & 0xFFFF))] = true;
							}
							if (src1) {
								read[getSourceAddress((src1 & 0xFFFF))] = true;
							}
							if (getRegisterType(src0) == ZSLFlags.INTERPOLATED) {
								shared[getSourceAddress((src0 & 0xFFFF))] = true;
							}
							if (getRegisterType(src1) == ZSLFlags.INTERPOLATED) {
								shared[getSourceAddress((src1 & 0xFFFF))] = true;
							}
							if ((src0 >> 26)) {
								read[getSourceAddress((indirect[(src0 >> 26)] & 0xFFFF))] = true;
							}
							if ((src1 >> 26)) {
								read[getSourceAddress((indirect[(src1 >> 26)] & 0xFFFF))] = true;
							}
							out.unshift(id, dest, src0, src1);
						}
					}
				}
			}
			if (!(output)) {
				out.length = 0;
			}
			return (out);
		}
		
		
		
		
		// COMPILATION UTILS
		
		private static function pushRegister(reg:uint, type:int):uint {
			var source:uint = (((0 | (type << 16)) | (3 << 22)) | (1 << 24));
			return (ShaderCompiler.alloc(("new:" + names[(reg & 0xFFFF)]), source));
		}
		
		private static function canBeOptimized(register:uint):int {
			var type:int = getRegisterType(register);
			if (type == 0) {
				return (0);
			}
			if (((((!((type == ZSLFlags.INTERPOLATED))) && (!((type == ZSLFlags.SAMPLER2D))))) && (!((type == ZSLFlags.SAMPLERCUBE))))) {
				return (type);
			}
			return (0);
		}
		
		private static function compareMasks(r0:uint, r1:uint):Boolean {
			if (r0 == r1) {
				return (true);
			}
			return (false);
		}
		
		private static function bothAreConstants(r0:uint, r1:uint):Boolean {
			if ((((r0 == 0)) || ((r1 == 0)))) {
				return (true);
			}
			return (((!((isConstant(r0) == 0))) && (!((isConstant(r1) == 0)))));
		}
		
		private static function isConditional(id:uint):Boolean {
			if (id == ZSLOpcode.IFE) {
				return (true);
			}
			if (id == ZSLOpcode.INE) {
				return (true);
			}
			if (id == ZSLOpcode.IFG) {
				return (true);
			}
			if (id == ZSLOpcode.ILT) {
				return (true);
			}
			if (id == ZSLOpcode.ELS) {
				return (true);
			}
			if (id == ZSLOpcode.EIF) {
				return (true);
			}
			return (false);
		}
		
		/** Optimizes the raw ops data (what kind of optimizations?) */
		private static function optimize(ops:Vector.<uint>):void {
			var i:int;
			var e:int;
			var id:uint;
			var dest:uint;
			var src0:uint;
			var src1:uint;
			var pass:Boolean;
			var required:Boolean;
			var read:Array = [];
			i = (ops.length - 4);
			while (i >= 0) {
				id = ops[i];
				dest = ops[(i + 1)];
				src0 = ops[(i + 2)];
				src1 = ops[(i + 3)];
				pass = true;
				if ((((id == ZSLOpcode.MOV)) && (canBeOptimized(dest)))) {
					if (!(read[getSourceAddress((src0 & 0xFFFF))])) {
						e = (i - 4);
						while (e >= 0) {
							if (ops[e] == ZSLOpcode.KILL)
								break;
							if (isConditional(ops[e]))
								break;
							if ((src0 & 0xFFFF) == (ops[(e + 2)] & 0xFFFF))
								break;
							if ((src0 & 0xFFFF) == (ops[(e + 3)] & 0xFFFF))
								break;
							if (compareMasks(ops[(e + 1)], src0)) {
								ops[(e + 1)] = dest;
								ops.splice(i, 4);
								pass = false;
								break;
							}
							e = (e - 4);
						}
					}
					if (pass) {
						required = false;
						e = (i + 4);
						while (e < ops.length) {
							if ((dest & 0xFFFF) == (ops[(e + 1)] & 0xFFFF))
								break;
							if (compareMasks(dest, ops[(e + 2)])) {
								if (bothAreConstants(src0, ops[(e + 3)])) {
									required = true;
								} else {
									ops[(e + 2)] = src0;
									pass = false;
								}
							}
							if (compareMasks(dest, ops[(e + 3)])) {
								if (bothAreConstants(src0, ops[(e + 2)])) {
									required = true;
								} else {
									ops[(e + 3)] = src0;
									pass = false;
								}
							}
							if ((dest & 0xFFFF) == (ops[(e + 2)] & 0xFFFF)) {
								required = true;
							}
							if ((dest & 0xFFFF) == (ops[(e + 3)] & 0xFFFF)) {
								required = true;
							}
							e = (e + 4);
						}
						if (((!(pass)) && (!(required)))) {
							ops.splice(i, 4);
						}
					}
				}
				read[getSourceAddress((src0 & 0xFFFF))] = true;
				read[getSourceAddress((src1 & 0xFFFF))] = true;
				if ((src0 >> 26)) {
					read[getSourceAddress((indirect[(src0 >> 26)] & 0xFFFF))] = true;
				}
				if ((src1 >> 26)) {
					read[getSourceAddress((indirect[(src1 >> 26)] & 0xFFFF))] = true;
				}
				i = (i - 4);
			}
			i = 0;
			while (i < ops.length) {
				id = ops[i];
				dest = ops[(i + 1)];
				src0 = ops[(i + 2)];
				src1 = ops[(i + 3)];
				pass = true;
				if (((getRegisterIndirectValue(src0)) || (getRegisterIndirectValue(src1)))) {
				} else {
					if ((((((((((id == ZSLOpcode.MOV)) && (canBeOptimized(dest)))) && (isConstant(src0)))) && ((getRegisterMask(dest) == FULL)))) && ((getRegisterSize(dest) == 4)))) {
						e = (i + 4);
						while (e < ops.length) {
							if ((dest & 0xFFFF) == (ops[(e + 1)] & 0xFFFF)) {
								if (((!((ops[e] == ZSLOpcode.MOV))) || (!(((src0 & 0xFFFF) == (ops[(e + 2)] & 0xFFFF)))))) {
									pass = false;
								}
							}
							e = (e + 4);
						}
						if (pass) {
							e = (i + 4);
							while (e < ops.length) {
								if (((!(bothAreConstants(src0, ops[(e + 3)]))) && (((dest & 0xFFFF) == (ops[(e + 2)] & 0xFFFF))))) {
									ops[(e + 2)] = ((ops[(e + 2)] & 0xFFFF0000) + (src0 & 0xFFFF));
								} else {
									(pass == false);
								}
								if (((!(bothAreConstants(src0, ops[(e + 2)]))) && (((dest & 0xFFFF) == (ops[(e + 3)] & 0xFFFF))))) {
									ops[(e + 3)] = ((ops[(e + 3)] & 0xFFFF0000) + (src0 & 0xFFFF));
								} else {
									pass = false;
								}
								e = (e + 4);
							}
							if (((pass) && (!((getRegisterType(dest) == ZSLFlags.OUTPUT))))) {
								ops.splice(i, 4);
								i = (i - 4);
							}
						}
					}
				}
				i = (i + 4);
			}
		}
		
		private static function allocRegisters(ops:Vector.<uint>, prg:ShaderProgram):void {
			var i:int;
			var len:int = ops.length;
			i = 0;
			while (i < len) {
				if (getRegisterType(ops[(i + 2)]) == ZSLFlags.CONST) {
					allocProgramRegister(ops[(i + 2)], prg);
				}
				if (getRegisterType(ops[(i + 3)]) == ZSLFlags.CONST) {
					allocProgramRegister(ops[(i + 3)], prg);
				}
				i = (i + 4);
			}
			var constants:ShaderRegister = _registers[ZSLFlags.R_CONSTANT];
			i = 0;
			while (i < constants.memory.length) {
				if (constants.memory[i] != 0) {
					constants.memory[i] = 15;
				}
				i++;
			}
			i = 0;
			while (i < len) {
				if (getRegisterType(ops[(i + 1)]) != ZSLFlags.TEMPORAL) {
					allocProgramRegister(ops[(i + 1)], prg);
				}
				if (getRegisterType(ops[(i + 2)]) != ZSLFlags.TEMPORAL) {
					allocProgramRegister(ops[(i + 2)], prg);
				}
				if (getRegisterType(ops[(i + 3)]) != ZSLFlags.TEMPORAL) {
					allocProgramRegister(ops[(i + 3)], prg);
				}
				i = (i + 4);
			}
		}
		
		private static function allocProgramRegister(register:uint, prg:ShaderProgram):void {
			var i:int;
			var e:int;
			var index:int;
			var _local11:ShaderInput;
			var _local12:Vector.<Number>;
			var _local13:Vector.<Number>;
			var _local14:int;
			var _local15:ShaderVar;
			var _local16:ShaderMatrix;
			var _local17:ShaderTexture;
			index = (register & 0xFFFF);
			var kind:int = getRegisterKind(register);
			if (kind == -1) {
				return;
			}
			var type:int = getRegisterType(register);
			var reg:ShaderRegister = _registers[kind];
			var size:int = getSourceSize(index);
			var length:int = getSourceLength(index);
			if (reg.alloc(register) == -1) {
				return;
			}
			if ((register >> 26)) {
				allocProgramRegister(indirect[(register >> 26)], prg);
			}
			switch (type) {
				case ZSLFlags.TEMPORAL: 
				case ZSLFlags.OUTPUT: 
				case ZSLFlags.INTERPOLATED: 
					break;
				case ZSLFlags.INPUT: 
					_local11 = (globals[index] as ShaderInput);
					prg.inputs.push(_local11);
					break;
				case ZSLFlags.CONST: 
					_local12 = (((_state == Context3DProgramType.VERTEX)) ? prg.vertexConstants : prg.fragmentConstants);
					_local13 = getSourceValues(index);
					_local14 = (_registers[ZSLFlags.R_CONSTANT] as ShaderRegister).addr[getSourceAddress(index)];
					if (_local12.length < (_local14 + _local13.length)) {
						_local12.length = (_local14 + _local13.length);
					}
					i = 0;
					while (i < _local13.length) {
						_local12[(i + _local14)] = _local13[i];
						i++;
					}
					break;
				case ZSLFlags.PARAM: 
					_local15 = (globals[index] as ShaderVar);
					_local15.format = ("float" + size);
					_local15.length = length;
					if (_local15.semantic == "") {
						if (((!(_local15.value)) || (((states[(register & 0xFFFF)] & ZSLFlags.STATE_USER_DEFINED) == 0)))) {
							_local15.value = getSourceValues(index);
						}
						i = size;
						while (_local15.value.length < (4 * length)) {
							e = 0;
							while (e < (4 - size)) {
								_local15.value.splice((i + e), 0, 1);
								e++;
							}
							i = (i + 4);
						}
					}
					prg.params.push(_local15);
					prg.pTarget.push(_state);
					prg.pOffset.push(getAddress(register));
					break;
				case ZSLFlags.MATRIX: 
					_local16 = (globals[index] as ShaderMatrix);
					if (!(_local16.semantic)) {
						_local16.value = ((_local16.value) || (new Matrix3D(getSourceValues(index))));
					}
					prg.matrix.push(_local16);
					prg.mTarget.push(_state);
					prg.mOffset.push(getAddress(register));
					break;
				case ZSLFlags.SAMPLER2D: 
				case ZSLFlags.SAMPLERCUBE: 
					_local17 = (globals[index] as ShaderTexture);
					prg.samplers.push(_local17);
					break;
			}
		}
		
		private static function getAddress(register:uint):int {
			var type:int = getRegisterType(register);
			var reg:ShaderRegister = _registers[getRegisterKind(register)];
			return ((reg.addr[getSourceAddress((register & 0xFFFF))] / 4));
		}
		
		private static function getPointer(register:uint):int {
			var type:int = getRegisterType(register);
			var kind:int = getRegisterKind(register);
			if (kind == -1) {
				return (0);
			}
			var reg:ShaderRegister = _registers[kind];
			var index:int = (register & 0xFFFF);
			var size:int = getSourceSize(index);
			var offset:int = getSourceOffset(index);
			return ((reg.addr[getSourceAddress(index)] + (offset * (((size >= 3)) ? 4 : size))));
		}
		
		private static function getStringAddr(register:uint):uint {
			return ((getRegisterKind(register) + ((getPointer(register) / 4) << 16)));
		}
		
		private static function write(ops:Vector.<uint>, i:int, read:Array):void {
			var delDest:Boolean;
			var delSrc0:Boolean;
			var delSrc1:Boolean;
			var size:int;
			var mask:int;
			var src0Mask:int;
			var src1Mask:int;
			var src1:uint = ops[i--];
			var src0:uint = ops[i--];
			var dest:uint = ops[i--];
			var id:uint = ops[i--];
			if (((dest) && (!(read[getSourceAddress((dest & 0xFFFF))])))) {
				delDest = true;
				read[getSourceAddress((dest & 0xFFFF))] = true;
			}
			if (((src0) && (!(read[getSourceAddress((src0 & 0xFFFF))])))) {
				delSrc0 = true;
				read[getSourceAddress((src0 & 0xFFFF))] = true;
			}
			if (((src1) && (!(read[getSourceAddress((src1 & 0xFFFF))])))) {
				delSrc1 = true;
				read[getSourceAddress((src1 & 0xFFFF))] = true;
			}
			if (i > 0) {
				write(ops, i, read);
			}
			if (isTemporal(dest)) {
				allocProgramRegister(dest, null);
			}
			if (isTemporal(src0)) {
				allocProgramRegister(src0, null);
			}
			if (isTemporal(src1)) {
				allocProgramRegister(src1, null);
			}
			if (isFloat(dest)) {
				size = getRegisterSize(dest);
				mask = (getRegisterMask(dest) + ((getPointer(dest) % 4) * UP));
			}
			var flags:uint;
			switch (id) {
				case ZSLOpcode.M33: 
				case ZSLOpcode.M34: 
				case ZSLOpcode.NRM: 
				case ZSLOpcode.CROSS: 
					flags = (flags | F_MASK3);
					break;
				case ZSLOpcode.DP3: 
				case ZSLOpcode.DP4: 
				case ZSLOpcode.SGE: 
				case ZSLOpcode.SLT: 
				case ZSLOpcode.SEQ: 
				case ZSLOpcode.SNE: 
					flags = (flags | F_MASK1);
					break;
			}
			var addr:uint = getStringAddr(dest);
			if (((isFloat(dest)) && (!(_firstRead[addr])))) {
				if ((flags & F_MASK3)) {
					_currBytes.writeUnsignedInt(ZSLOpcode.MOV);
					writeDest(228, 4, dest);
					_currBytes.writeShort(0);
					_currBytes.writeByte(0);
					_currBytes.writeByte(228);
					_currBytes.writeUnsignedInt(1);
					_currBytes.writeUnsignedInt(0);
					_currBytes.writeUnsignedInt(0);
				} else {
					mask = FULL;
					size = 4;
				}
				_firstRead[addr] = true;
			}
			if (isFloat(src0)) {
				src0Mask = swizzle(mask, size, src0, flags);
			}
			if (isFloat(src1)) {
				src1Mask = swizzle(mask, size, src1, flags);
			}
			if ((flags & F_MASK3)) {
				mask = M_XYZ;
				size = 3;
			}
			if ((((((id == ZSLOpcode.M33)) || ((id == ZSLOpcode.M34)))) || ((id == ZSLOpcode.M44)))) {
				src1Mask = FULL;
			}
			_currBytes.writeUnsignedInt(id);
			writeDest(mask, size, dest);
			writeSource(src0, src0Mask);
			writeSource(src1, src1Mask);
			if (delDest) {
				(_registers[ZSLFlags.R_TEMPORAL] as ShaderRegister).free(dest);
			}
			if (delSrc0) {
				(_registers[ZSLFlags.R_TEMPORAL] as ShaderRegister).free(src0);
			}
			if (delSrc1) {
				(_registers[ZSLFlags.R_TEMPORAL] as ShaderRegister).free(src1);
			}
		}
		
		private static function swizzle(destMask:int, destSize:int, src:uint, flags:int):int {
			var srcMask:int;
			var i:int;
			var d:int;
			var s:int;
			var f:int;
			var result:int;
			var size:int = getRegisterSize(src);
			var mask:int = getRegisterMask(src);
			var type:int = getRegisterType(src);
			if (size > 1) {
				result = (mask & (0xFF >> (8 - (size * 2))));
			} else {
				result = ((mask & 3) * UP);
			}
			if ((flags & (F_MASK1 | F_MASK3)) == 0) {
				srcMask = result;
				result = 0;
				i = 0;
				while (i < destSize) {
					d = ((destMask >> (i << 1)) & 3);
					s = ((srcMask >> (i << 1)) & 3);
					f = (s << (d << 1));
					result = (result | f);
					i++;
				}
				while (i < 4) {
					result = (result | (f << (i * 2)));
					i++;
				}
			}
			result = (result + (((getPointer(src) % 4) * UP) & 0xFF));
			if (((!((type == ZSLFlags.TEMPORAL))) || ((_write[getStringAddr(src)] == 15)))) {
				if ((((((destMask & M_XYZ)) && ((size == 3)))) && (((result & MASK_XYZ) == M_XYZ)))) {
					result = FULL;
				} else {
					if ((((((destMask & M_XY)) && ((size == 2)))) && (((result & MASK_XY) == M_XY)))) {
						result = FULL;
					} else {
						if ((((((destMask & M_X)) && ((size == 1)))) && (((result & MASK_X) == M_X)))) {
							result = FULL;
						}
					}
				}
			}
			return (result);
		}
		
		private static function writeDest(mask:int, size:int, dest:uint):void {
			var w:int;
			var i:int;
			var x:int;
			if (dest) {
				if ((dest >> 26)) {
					
					throw((("Destination " + names[(dest & 0xFFFF)]) + " can not have indirect address."));
					
					return;
				}
				i = 0;
				while (i < size) {
					x = (1 << ((mask >> (i << 1)) & 3));
					if ((w & x)) {
						
						throw((("Invalid write mask '" + ShaderCompiler.maskToStr(getRegisterMask(dest), getRegisterSize(dest))) + "'. Components can not be repeteated."));
						
						return;
					}
					w = (w | x);
					i++;
				}
				if (getRegisterKind(dest) == ZSLFlags.R_DEPTH) {
					w = 1;
				}
				if (isTemporal(dest)) {
					_write[getSourceAddress((dest & 0xFFFF))] = (_write[getSourceAddress((dest & 0xFFFF))] | w);
				}
				_write[getStringAddr(dest)] = (_write[getStringAddr(dest)] | w);
				_currBytes.writeShort((getPointer(dest) / 4));
				_currBytes.writeByte(w);
				_currBytes.writeByte(getRegisterKind(dest));
			} else {
				_currBytes.writeShort(0);
				_currBytes.writeShort(0);
			}
		}
		
		private static function writeSource(src:uint, mask:int):void {
			var addr:int;
			var s:ShaderTexture;
			var flags:uint;
			var indirectReg:uint;
			if (getRegisterKind(src) == ZSLFlags.R_SAMPLER) {
				addr = getSourceAddress((src & 0xFFFF));
				s = (globals[addr] as ShaderTexture);
				if (s.value) {
					s.type = s.value.typeMode;
					s.wrap = s.value.wrapMode;
					s.mip = s.value.mipMode;
					s.filter = s.value.filterMode;
					s.bias = s.value.bias;
					s.format = s.value.format;
					s.options = s.value.options;
				}
				if (s.type != 0) {
					s.wrap = 0;
				}
				if (s.format == 3) {
					s.format = 0;
				}
				if (s.format == 4) {
					s.format = 0;
				}
				flags = 5;
				flags = (flags | (s.format << SAMPLER_FORMAT_SHIFT));
				flags = (flags | (s.type << SAMPLER_TYPE_SHIFT));
				flags = (flags | (s.options << SAMPLER_SPECIAL_SHIFT));
				flags = (flags | (s.wrap << SAMPLER_WRAP_SHIFT));
				flags = (flags | (s.mip << SAMPLER_MIPMAP_SHIFT));
				flags = (flags | (s.filter << SAMPLER_FILTER_SHIFT));
				_currBytes.writeShort(getAddress(src));
				_currBytes.writeByte(s.bias);
				_currBytes.writeByte(0);
				_currBytes.writeUnsignedInt(flags);
			} else {
				if (isFloat(src)) {
					if (isTemporal(src)) {
						if (!(_write[getSourceAddress((src & 0xFFFF))])) {
							
							throw(((names[(src & 0xFFFF)] + " is read but never written.") + ShaderCompiler.registerToStr(src)));
							
							return;
						}
					}
					indirectReg = indirect[(src >> 26)];
					_currBytes.writeShort(((indirectReg) ? getAddress(indirectReg) : (getPointer(src) / 4)));
					_currBytes.writeByte(((indirectReg) ? (getPointer(src) / 4) : 0));
					_currBytes.writeByte(mask);
					_currBytes.writeByte(getRegisterKind(src));
					_currBytes.writeByte(((indirectReg) ? getRegisterKind(indirectReg) : 0));
					_currBytes.writeByte(((indirectReg) ? (getRegisterMask(indirectReg) & 3) : 0));
					_currBytes.writeByte(((indirectReg) ? INDIRECT : DIRECT));
				} else {
					_currBytes.writeUnsignedInt(0);
					_currBytes.writeUnsignedInt(0);
				}
			}
		}
		
		
		
		
		// UTILS?
		
		public static function getNewRegisterOffset(register:uint, offset:int):uint {
			var index:int = ((register & 0xFFFF) + offset);
			var mask:int = getRegisterMask(register);
			var size:int = getRegisterSize(register);
			var indirect:int = getRegisterIndirectValue(register);
			return ((((index | (mask << 16)) | ((size - 1) << 24)) | (indirect << 26)));
		}
		
		public static function getNewRegisterFromMask(register:uint, mask:int, maskSize:int):uint {
			var component:int;
			var regMask:int = ((register >> 16) & 0xFF);
			var regSize:int = ((register >> 24) & 3);
			var regType:int = getRegisterType(register);
			if (regType == ZSLFlags.INPUT) {
				regSize = 3;
			}
			var resultMask:int;
			var i:int;
			while (i < maskSize) {
				component = ((mask >> (i << 1)) & 3);
				resultMask = (resultMask | (((regMask >> (component << 1)) & 3) << (i << 1)));
				if (component > regSize) {
					
					throw((("Mask is out of range in " + ShaderCompiler.registerToStr(register)) + "."));
					
					return 0;
				}
				i++;
			}
			while (i < 4) {
				resultMask = (resultMask | (((regMask >> (i << 1)) & 3) << (i << 1)));
				i++;
			}
			var srcIndex:int = (register & 0xFFFF);
			var indirect:int = ((register >> 26) & 63);
			return ((((srcIndex | (resultMask << 16)) | ((maskSize - 1) << 24)) | (indirect << 26)));
		}
		
		public static function toBoolean(register:uint):Boolean {
			var init:int = states[getSourceAddress((register & 0xFFFF))];
			if (init == ZSLFlags.STATE_UNDEFINED) {
				return (false);
			}
			if (isFloat(register)) {
				if (((sources[(register & 0xFFFF)] >> 22) & 3) == 0) {
					return (Boolean(getRegisterValue(register, 0)));
				}
			}
			return (true);
		}
		
		public static function isFloat(register:uint):int {
			if (register == 0) {
				return (0);
			}
			var type:int = ((sources[(register & 0xFFFF)] >> 16) & 63);
			return ((((((((type >= ZSLFlags.TEMPORAL)) && ((type <= ZSLFlags.MATRIX)))) || ((((type >= ZSLFlags.INPUT)) && ((type <= ZSLFlags.OUTPUT)))))) ? type : 0));
		}
		
		public static function isConstant(register:uint):int {
			if (register == 0) {
				return (0);
			}
			var type:int = ((sources[(register & 0xFFFF)] >> 16) & 63);
			return ((((((((type == ZSLFlags.PARAM)) || ((type == ZSLFlags.CONST)))) || ((type == ZSLFlags.MATRIX)))) ? type : 0));
		}
		
		public static function isTemporal(register:uint):int {
			if (register == 0) {
				return (0);
			}
			var type:int = ((sources[(register & 0xFFFF)] >> 16) & 63);
			return ((((type == ZSLFlags.TEMPORAL)) ? type : 0));
		}
		
		public static function getRegisterDataOffset(register:uint):int {
			var src:uint = sources[(register & 0xFFFF)];
			var index:int = (src & 0xFFFF);
			var size:int = (((src >> 22) & 3) + 1);
			var offset:int = ((src >> 24) & 0xFF);
			return ((index + (offset * size)));
		}
		
		public static function getRegisterValue(register:uint, i:int):Number {
			var src:uint = sources[(register & 0xFFFF)];
			var index:int = (src & 0xFFFF);
			var size:int = (((src >> 22) & 3) + 1);
			var offset:int = ((src >> 24) & 0xFF);
			var mask:int = ((register >> 16) & 0xFF);
			if (i >= size) {
				i = (size - 1);
			}
			var pos:int = ((offset * size) + ((mask >> (i << 1)) & 3));
			return (float[(index + pos)]);
		}
		
		public static function setRegisterValue(register:uint, i:int, value:Number):void {
			if ((states[(register & 0xFFFF)] & ZSLFlags.STATE_USER_DEFINED)) {
				return;
			}
			var src:uint = sources[(register & 0xFFFF)];
			var index:int = (src & 0xFFFF);
			var size:int = (((src >> 22) & 3) + 1);
			var offset:int = ((src >> 24) & 0xFF);
			var mask:int = ((register >> 16) & 0xFF);
			var pos:int = ((offset * size) + ((mask >> (i << 1)) & 3));
			float[(index + pos)] = value;
		}
		
		public static function getRegisterKind(register:uint):int {
			var type:int = getRegisterType(register);
			switch (type) {
				case ZSLFlags.TEMPORAL: 
					return (ZSLFlags.R_TEMPORAL);
				case ZSLFlags.INPUT: 
					return (ZSLFlags.R_INPUT);
				case ZSLFlags.INTERPOLATED: 
					return (ZSLFlags.R_INTERPOLATED);
				case ZSLFlags.PARAM: 
				case ZSLFlags.MATRIX: 
				case ZSLFlags.CONST: 
					return (ZSLFlags.R_CONSTANT);
				case ZSLFlags.SAMPLER2D: 
				case ZSLFlags.SAMPLERCUBE: 
					return (ZSLFlags.R_SAMPLER);
				case ZSLFlags.OUTPUT: 
					if (names[(register & 0xFFFF)] == "depth") {
						return (ZSLFlags.R_DEPTH);
					}
					return (ZSLFlags.R_OUTPUT);
			}
			return (-1);
		}
		
		public static function getRegisterType(register:uint):int {
			return (((sources[(register & 0xFFFF)] >> 16) & 63));
		}
		
		public static function getRegisterMask(register:uint):int {
			return (((register >> 16) & 0xFF));
		}
		
		public static function getRegisterSize(register:uint):int {
			return ((((register >> 24) & 3) + 1));
		}
		
		public static function getRegisterIndirectValue(register:uint):int {
			return (((register >> 26) & 63));
		}
		
		public static function setRegisterIndirectValue(register:uint, indirectReg:uint):uint {
			indirect[indirectCount] = indirectReg;
			register = (register & (0xFFFFFF | (3 << 24)));
			register = (register | (indirectCount << 26));
			indirectCount++;
			return (register);
		}
		
		public static function getSourceType(index:int):int {
			return (((sources[index] >> 16) & 63));
		}
		
		public static function getSourceOffset(index:int):int {
			return (((sources[index] >> 24) & 0xFF));
		}
		
		public static function getSourceAddress(index:int):int {
			var idx:int = (sources[index] & 0xFFFFFF);
			var lst:int = index;
			while (index > 0) {
				if ((sources[index] & 0xFFFFFF) != idx)
					break;
				lst = index;
				index--;
			}
			return (lst);
		}
		
		public static function getSourceSize(index:int):int {
			return ((((sources[index] >> 22) & 3) + 1));
		}
		
		public static function getSourceLength(i:int):int {
			var index:int = getSourceAddress(i);
			var count:int = 1;
			var idx:int = (sources[index] & 0xFFFFFF);
			index++;
			while (index < sources.length) {
				if ((sources[index++] & 0xFFFFFF) != idx)
					break;
				count++;
			}
			return (count);
		}
		
		public static function getSourceValues(index:int):Vector.<Number> {
			index = getSourceAddress(index);
			var size:int = getSourceSize(index);
			var len:int = getSourceLength(index);
			var start:int = (sources[index] & 0xFFFF);
			return (float.slice(start, (start + (size * len))));
		}
		
        public static function strToMask(str:String):int
        {
            var mask:int;
            var i:int;
            while (i < str.length) {
                switch (str.charAt(i)){
                    case "y":
                    case "r":
                        mask = (mask | (1 << (i << 1)));
                        break;
                    case "z":
                    case "g":
                        mask = (mask | (2 << (i << 1)));
                        break;
                    case "w":
                    case "b":
                        mask = (mask | (3 << (i << 1)));
                        break;
                }
                i++;
            }
            return (mask);
        }

        public static function typeToStr(t:int):String
        {
            switch (t){
                case ZSLFlags.VOID:
                    return ("void");
                case ZSLFlags.TEMPORAL:
                    return ("float");
                case ZSLFlags.PARAM:
                    return ("param");
                case ZSLFlags.CONST:
                    return ("const");
                case ZSLFlags.MATRIX:
                    return ("matrix");
                case ZSLFlags.SAMPLER2D:
                    return ("sampler2D");
                case ZSLFlags.SAMPLERCUBE:
                    return ("samplerCube");
                case ZSLFlags.INPUT:
                    return ("input");
                case ZSLFlags.INTERPOLATED:
                    return ("interpolated");
                case ZSLFlags.OUTPUT:
                    return ("output");
                case ZSLFlags.NAMESPACE:
                    return ("namespace");
                case ZSLFlags.FUNCTION:
                    return ("function");
                case ZSLFlags.TECHNIQUE:
                    return ("technique");
                case ZSLFlags.PASS:
                    return ("pass");
                case ZSLFlags.STRING:
                    return ("string");
                case ZSLFlags.SURFACE:
                    return ("surface");
            }
            return (null);
        }

        public static function registerToStr(register:uint, mask:int=-1, size:int=-1):String
        {
            if (register == 0){
                return ("");
            }
            if (mask == -1){
                mask = ((register >> 16) & 0xFF);
            }
            if (size == -1){
                size = (((register >> 24) & 3) + 1);
            }
            var index:int = (register & 0xFFFF);
            var indirectReg:uint = ShaderCompiler.indirect[(register >> 26)];
            var type:String = typeToStr(ShaderCompiler.getRegisterType(register));
            return ((ShaderCompiler.names[index] + (((ShaderCompiler.isFloat(register) > 0)) ? ("." + maskToStr(mask, size)) : "")));
        }

        public static function maskToStr(mask:int, size:int):String
        {
            var i:int;
            var idx:int;
            var r:String = "";
            while (i < size) {
                idx = ((mask >> (i * 2)) & 3);
                if (idx == 0){
                    r = (r + "x");
                } else {
                    if (idx == 1){
                        r = (r + "y");
                    } else {
                        if (idx == 2){
                            r = (r + "z");
                        } else {
                            if (idx == 3){
                                r = (r + "w");
                            }
                        }
                    }
                }
                i++;
            }
            return (r);
        }

        public static function isScope(type:int):int
        {
            if (type == ZSLFlags.NAMESPACE){
                return (type);
            }
            if (type == ZSLFlags.FUNCTION){
                return (type);
            }
            if (type == ZSLFlags.TECHNIQUE){
                return (type);
            }
            if (type == ZSLFlags.PASS){
                return (type);
            }
            return (0);
        }

		
		
	}
} 

