package zen.shaders.core
{
    
	import zen.shaders.*;
	import zen.enums.*;
    import flash.utils.ByteArray;
    import flash.utils.Dictionary;
    import flash.utils.Endian;
    import flash.geom.*;
    import flash.utils.*;
    
	/** ShaderContext defines an scope of compiled ZSL code such as a namespace, function, technique or pass. */
    public class ShaderContext extends ShaderBase 
    {

        public static var resultOps:Vector.<uint>;
        private static var root:ShaderContext;

        public var parent:ShaderContext;
        public var paramCount:int;
        public var value:uint;
        public var code:ByteArray;
        public var globals:Vector.<ShaderBase>;
        public var sources:Vector.<uint>;
        public var names:Vector.<String>;
        public var locals:Vector.<uint>;
        public var safeZone:int;
        public var params:Dictionary;

        public function ShaderContext(name:String=null)
        {
            this.globals = new Vector.<ShaderBase>();
            this.sources = new Vector.<uint>();
            this.names = new Vector.<String>();
            this.locals = new Vector.<uint>();
            super();
            this.name = name;
            this.code = new ByteArray();
            this.code.endian = "littleEndian";
            this.varType = ZSLFlags.NAMESPACE;
        }


        public function bind(byteCode:ByteArray):void
        {
            var type:String;
            var key:String;
            var value:String;
            var length:int;
            byteCode.position = 0;
            byteCode.endian = "littleEndian";
            byteCode.position = 0;
            if ((((byteCode.length < 5)) || (!((byteCode.readMultiByte(4, "") == "ShaderBase"))))) {
				
                throw new Error("Invalid ShaderBase file.");
				
				return;
            }
            var version:int = byteCode.readUnsignedByte();
            root = this;
            root.params = null;
            while (byteCode.bytesAvailable) {
                type = byteCode.readUTF();
                length = (byteCode.readUnsignedInt() + byteCode.position);
                if (type == "def"){
                    while (byteCode.position < length) {
                        key = byteCode.readUTF();
                        value = byteCode.readUTF();
                        ShaderCompiler.defines[key] = value;
                    }
                } else {
                    if (type == "smtc"){
                        while (byteCode.position < length) {
                            key = byteCode.readUTF();
                            value = byteCode.readUTF();
                            ShaderCompiler.semantics[key] = value;
                        }
                    } else {
                        if (type == "code"){
                            this.varType = byteCode.readUnsignedByte();
                            this.name = "topLevel";
                            byteCode.readUTF();
                            this.paramCount = byteCode.readUnsignedByte();
                            this.read(byteCode);
                        }
                    }
                }
            }
            root = null;
        }

        private function read(bytes:ByteArray):void
        {
            var name:String;
            var semantic:String;
            var type:int;
            var size:int;
            var length:int;
            var f:ShaderBase;
            var _local11:ShaderContext;
            var codeLength:int = bytes.readUnsignedInt();
            if (codeLength > 0){
                bytes.readBytes(this.code, 0, codeLength);
            }
            var passes:int;
            var index:int;
            if (this.varType == ZSLFlags.FUNCTION){
                type = bytes.readUnsignedByte();
                name = bytes.readUTF();
                size = bytes.readUnsignedByte();
                length = bytes.readUnsignedByte();
                semantic = bytes.readUTF();
                this.value = (((type << 16) | ((size - 1) << 22)) | (length << 24));
            }
            while (true) {
                type = bytes.readUnsignedByte();
                switch (type){
                    case 0xFF:
                        this.safeZone = (this.locals.length = this.sources.length);
                        return;
                    case 254:
                        index = (index + bytes.readUnsignedByte());
                        if (this.sources.length < index){
                            this.names.length = index;
                            this.globals.length = index;
                            this.sources.length = index;
                        }
                        break;
                    case ZSLFlags.FUNCTION:
                    case ZSLFlags.NAMESPACE:
                    case ZSLFlags.TECHNIQUE:
                    case ZSLFlags.PASS:
                        name = bytes.readUTF();
                        _local11 = null;
                        if (index < this.globals.length){
                            _local11 = (this.globals[index] as ShaderContext);
                        }
                        if (!(_local11)){
                            _local11 = new ShaderContext(name);
                        }
                        _local11.parent = this;
                        _local11.varType = type;
                        _local11.paramCount = bytes.readUnsignedByte();
                        _local11.read(bytes);
                        this.sources[index] = (index | (type << 16));
                        this.names[index] = _local11.name;
                        this.globals[index] = _local11;
                        index++;
                        if (_local11.varType == ZSLFlags.PASS){
                            passes++;
                        }
                        break;
                    default:
                        name = bytes.readUTF();
                        size = bytes.readUnsignedByte();
                        length = bytes.readUnsignedByte();
                        semantic = bytes.readUTF();
                        f = null;
                        if (index >= this.paramCount){
                            switch (type){
                                case ZSLFlags.PARAM:
                                    f = new ShaderVar();
                                    break;
                                case ZSLFlags.MATRIX:
                                    f = new ShaderMatrix();
                                    break;
                                case ZSLFlags.SAMPLER2D:
                                    f = new ShaderTexture(null, TextureType.FLAT);
                                    break;
                                case ZSLFlags.SAMPLERCUBE:
                                    f = new ShaderTexture(null, TextureType.CUBE);
                                    break;
                                case ZSLFlags.INPUT:
                                    f = new ShaderInput();
                                    break;
                            }
                            if (f){
                                f.varType = type;
                                f.name = name;
                                f.semantic = semantic;
                                if (semantic.length == 0){
                                    if (!(this.params)){
                                        this.params = new Dictionary(true);
                                    }
                                    this.params[name] = f;
                                    if (!(root.params)){
                                        root.params = new Dictionary(true);
                                    }
                                    if (((!(root.params[name])) || ((this == root)))){
                                        root.params[name] = f;
                                    }
                                }
                            }
                        }
                        this.names[index] = name;
                        this.sources[index] = (((index | (type << 16)) | ((size - 1) << 22)) | (length << 24));
                        this.globals[index] = f;
                        index++;
                }
            }
        }

        private function getFirstTechnique(scope:ShaderContext):ShaderContext
        {
            var s:ShaderContext;
            var i:int;
            while (i < scope.globals.length) {
                s = (scope.globals[i] as ShaderContext);
                if (!!(s)){
                    if (s.varType == ZSLFlags.TECHNIQUE){
                        return (s);
                    }
                    s = this.getFirstTechnique(s);
                    if (s){
                        return (s);
                    }
                }
                i++;
            }
            return (null);
        }

        public function call(ns:String="", params:Array=null):uint
        {
            var result:uint;
            var arr:Array;
            var fName:String;
            var func:ShaderContext;
            var n:int;
            if (ns == null){
                func = this.getFirstTechnique(this);
                if (func){
                    return (this.call(func.name, params));
                }
				
                throw (("Can not find any technique in " + this.name));
				
				return 0;
            }
            if (ns != ""){
                arr = ns.split(".");
                fName = arr.shift();
                func = (this.getGlobal(fName) as ShaderContext);
                if (!(func)) {
					
                    throw ((((("Function '" + ns) + "' not found on ") + this) + "."));
					
					return 0;
                }
                return (func.call(arr.join("."), params));
            }
            var passCount:int;
            if (!(resultOps)){
                resultOps = new Vector.<uint>();
            }
            if (varType == ZSLFlags.TECHNIQUE){
                n = 0;
                while (n < this.sources.length) {
                    if (((this.sources[n] >> 16) & 63) == ZSLFlags.PASS){
                        if (ShaderCompiler.currentPass == passCount){
                            result = ShaderCompiler.call((this.globals[n] as ShaderContext), resultOps);
                        }
                        passCount++;
                    }
                    n++;
                }
            }
            if (((!((varType == ZSLFlags.TECHNIQUE))) || ((((passCount == 0)) && ((ShaderCompiler.currentPass == 0)))))){
                result = ShaderCompiler.call(this, resultOps, params);
            }
            return (result);
        }

        public function getLocal(i:int):uint
        {
            var r:uint = this.locals[i];
            if (!(r)) {
				
                throw (((("Can not found a reference (" + i) + ") in ") + this.name));
				
				return 0;
            }
            return (r);
        }

        public function getIndex(name:String):int
        {
            var len:int = this.names.length;
            var i:int;
            while (i < len) {
                if (this.names[i] == name){
                    return (i);
                }
                i++;
            }
            return (-1);
        }

        private function getGlobal(name:String):ShaderBase
        {
            var len:int = this.globals.length;
            var i:int;
            while (i < len) {
                if (((this.globals[i]) && ((this.globals[i].name == name)))){
                    return (this.globals[i]);
                }
                i++;
            }
            return (null);
        }

        public function getScope(ns:String):ShaderContext
        {
            if (ns == null){
                return (this.getFirstTechnique(this));
            }
            var arr:Array = ns.split(".");
            var fName:String = arr.shift();
            var func:ShaderContext = (this.getGlobal(fName) as ShaderContext);
            if (arr.length == 0){
                return (func);
            }
            if (func){
                return (func.getScope(arr.join(".")));
            }
            return (null);
        }

        public function getPasses(ns:String):int
        {
            var s:ShaderContext;
            if (!(ns)){
                s = this.getFirstTechnique(this);
            } else {
                s = this.getScope(ns);
            }
            if (!(s)){
                return (0);
            }
            var count:int;
            var n:int;
            while (n < s.sources.length) {
                if (((s.sources[n] >> 16) & 63) == ZSLFlags.PASS){
                    count++;
                }
                n++;
            }
            if (count == 0){
                count = 1;
            }
            return (count);
        }

        public function createRegisterFromParam(param:ShaderVar):uint
        {
            var source:uint = (((0 | (ZSLFlags.PARAM << 16)) | (3 << 22)) | (param.length << 24));
            return (ShaderCompiler.alloc(((param.name) || ("temp")), source, param));
        }

        public function getRegister(register:uint, mask:String="xyzw", offset:int=0):uint
        {
            return (ShaderCompiler.getNewRegisterOffset(ShaderCompiler.getNewRegisterFromMask(register, ShaderCompiler.strToMask(mask), mask.length), offset));
        }

        public function getRegisterByName(name:String, mask:String="xyzw", offset:int=0):uint
        {
            var reg:uint;
            var arr:Array = name.split(".");
            var fName:String = arr.shift();
            var func:ShaderContext = (this.getGlobal(fName) as ShaderContext);
            if (arr.length == 0){
                reg = this.locals[this.getIndex(fName)];
                if (reg == 0){
                    reg = this.locals[this.getIndex(fName)];
					
                    throw ((name + " is not initialized!."));
					
					return 0;
                }
                return (this.getRegister(reg, mask, offset));
            }
            return (func.getRegisterByName(arr.join("."), mask, offset));
        }

        public function print(level:int=0, index:int=0, out:String=""):String
        {
            var end:String = "\n";
            var space:String = "";
            var i:int;
            while (i < level) {
                space = (space + "    ");
                i++;
            }
            out = ((((((((space + index) + " (") + ShaderCompiler.typeToStr(varType)) + ") ") + this.name) + " - ") + this.code.length) + " bytes\n");
            var e:int;
            while (e < this.sources.length) {
                if ((this.globals[e] is ShaderContext)){
                    out = (out + (ShaderContext(this.globals[e]).print((level + 1), e, out) + end));
                } else {
                    if (this.globals[e]){
                        out = (out + (((((space + "    ") + e) + " ") + this.globals[e]) + end));
                    } else {
                        if (((!((varType == ZSLFlags.FUNCTION))) && (this.sources[e]))){
                            out = (out + (((((((space + "    ") + e) + " (") + ShaderCompiler.typeToStr(((this.sources[e] >> 16) & 63))) + ") ") + this.names[e]) + end));
                        }
                    }
                }
                e++;
            }
            return (out.substr(0, -1));
        }

		
        override public function toString():String
        {
            var n:String = name;
            var p:ShaderContext = this.parent;
            while (p) {
                n = ((p.name + ".") + n);
                p = p.parent;
            }
            return (((("(" + ShaderCompiler.typeToStr(varType)) + ") ") + n));
        }
		

        public function getTechniqueNames():Array
        {
            var scope:ShaderContext;
            var out:Array = [];
            var i:int;
            while (i < this.globals.length) {
                if (this.globals[i]){
                    if (this.globals[i].varType == ZSLFlags.TECHNIQUE){
                        out.push(this.globals[i].name);
                    }
                    scope = (this.globals[i] as ShaderContext);
                    if (scope){
                        out = out.concat(scope.getTechniqueNames());
                    }
                }
                i++;
            }
            return (out);
        }


    }
}

