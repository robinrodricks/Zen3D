package zen.shaders
{
    
	import zen.shaders.core.*;
	import zen.shaders.objects.*;
	import zen.enums.*;
    import flash.utils.*;
    import zen.shaders.*;
    import flash.display3D.*;
    

    public class ShaderParser extends ShaderCompiler 
    {

        private static const INCLUDE_NONE:int = 0;
        private static const INCLUDE_ALL:int = 1;
        private static const INCLUDE_TOPLEVEL:int = 2;

        private static var _position:int;
        private static var _tokens:Vector.<ShaderToken>;
        private static var _bytes:ByteArray;
        private static var _topLevel:ShaderContext;
        private static var _namespace:ShaderContext;
        private static var _data:Dictionary = new Dictionary();
        private static var _stack:Vector.<uint>;
        private static var _retValue:uint;
        private static var _usingNS:Vector.<ShaderContext>;
        private static var _dependences:Dictionary;
        private static var _includeScopes:Dictionary;
        private static var _localDefinitions:Dictionary;
        private static var _localSemantics:Dictionary;
        private static var _includeDebugReferences:Boolean = false;
        private static var _includeDependences:int = INCLUDE_ALL;//1
        private static var _referenceProgram:ShaderProgram = new ShaderProgram();
        private static var _conditionalState:Boolean = false;
        private static var _ifElseLevelState:int;
        private static var _singleRegister:Dictionary;
        private static var _padding:int = 200;
        private static var _debug:Boolean = false;

		public static function init():void {
			
            _data["void"] = [0, 0];
            _data["float"] = [1, 1];
            _data["float2"] = [2, 1];
            _data["float3"] = [3, 1];
            _data["float4"] = [4, 1];
            _data["float3x3"] = [3, 3];
            _data["float4x3"] = [4, 3];
            _data["float4x4"] = [4, 4];
            _data["output"] = [4, 1];
            _data["sampler2D"] = _data["void"];
            _data["samplerCube"] = _data["void"];
            _data["surface"] = _data["void"];
            _data["string"] = _data["void"];
            _data["namespace"] = _data["void"];
            _data["technique"] = _data["void"];
            _data["pass"] = _data["void"];
        }


        public static function reset():void
        {
            _topLevel = new ShaderContext("topLevel");
            _topLevel.varType = ZSLFlags.NAMESPACE;
            _usingNS = new Vector.<ShaderContext>();
            _stack = new Vector.<uint>();
            _singleRegister = new Dictionary();
            _includeScopes = new Dictionary();
            _dependences = new Dictionary();
            _dependences[_topLevel] = true;
            _includeDebugReferences = false;
            _includeDependences = INCLUDE_ALL;
            _ifElseLevelState = 0;
            _conditionalState = false;
        }

        public static function bind(bytes:ByteArray):void
        {
            _topLevel.bind(bytes);
        }

        public static function parse(tokens:Vector.<ShaderToken>):ByteArray
        {
            var i:*;
            _position = 0;
            _tokens = tokens;
            _namespace = _topLevel;
            _localDefinitions = null;
            _localSemantics = null;
            for (i in ShaderCompiler.defines) {
                define(i, ShaderCompiler.defines[i]);
            }
            if (_topLevel.sources.length < _padding){
                _topLevel.sources.length = _padding;
                _topLevel.globals.length = _padding;
                _topLevel.names.length = _padding;
                _topLevel.locals.length = _padding;
            }
            read();
            save();
            _topLevel = null;
            _usingNS = null;
            _stack = null;
            _singleRegister = null;
            _dependences = null;
            _includeScopes = null;
            return (_bytes);
        }

        private static function save():ByteArray
        {
            var pos:int;
            var d:*;
            var s:*;
            _bytes = new ByteArray();
            _bytes.endian = "littleEndian";
            _bytes.writeMultiByte("ShaderBase", "");
            _bytes.writeByte(1);
            if (_localDefinitions){
                _bytes.writeUTF("def");
                pos = _bytes.position;
                _bytes.writeUnsignedInt(0);
                for (d in _localDefinitions) {
                    _bytes.writeUTF(d);
                    _bytes.writeUTF(_localDefinitions[d]);
                }
                _bytes.position = pos;
                _bytes.writeUnsignedInt(((_bytes.length - pos) - 4));
                _bytes.position = _bytes.length;
            }
            if (_localSemantics){
                _bytes.writeUTF("smtc");
                pos = _bytes.position;
                _bytes.writeUnsignedInt(0);
                for (s in _localSemantics) {
                    _bytes.writeUTF(s);
                    _bytes.writeUTF(_localSemantics[s]);
                }
                _bytes.position = pos;
                _bytes.writeUnsignedInt(((_bytes.length - pos) - 4));
                _bytes.position = _bytes.length;
            }
            _bytes.writeUTF("code");
            pos = _bytes.position;
            _bytes.writeUnsignedInt(0);
            saveNS(_topLevel);
            _bytes.position = pos;
            _bytes.writeUnsignedInt(((_bytes.length - pos) - 4));
            _bytes.position = _bytes.length;
            return (_bytes);
        }

        private static function read(offset:int=0, isScope:Boolean=true):void
        {
            _position = (_position + offset);
            var t:ShaderToken = getToken();
            if (isScope){
                verbose(_namespace.code.position, _namespace.toString());
                _retValue = 0;
            }
            while (_position < _tokens.length) {
                switch (getToken().text){
                    case "}":
                        if (_namespace == _topLevel){
                            error(t, "Unexpected '}'.");
                        }
                        if (((((isScope) && (_namespace.value))) && (!(_retValue)))){
                            error(t, (((("Scope '" + _namespace.name) + "' should return a ") + sourceStrType(_namespace.value)) + " value."));
                        }
                        return;
                    case ";":
                    case "End of File":
                    case null:
                        _position++;
                        break;
                    default:
                        statement();
                }
            }
        }

        private static function statement(offset:int=0):void
        {
            var paramCount:int;
            var ns:ShaderContext;
            var _local5:int;
            var _local6:ShaderToken;
            var _local7:ShaderToken;
            var _local8:int;
            var src1:uint;
            var src0:uint;
            var dest:uint;
            if (_includeDebugReferences){
                write(ZSLFlags.DEBUG_D, getToken().line, getToken().pos);
            }
            var t:ShaderToken = getToken();
            _position = (_position + offset);
            switch (getToken().text){
                case "#topLevel":
                    if (_topLevel.sources.length > _padding){
                        error(t, "#topLevel must be used before any declaration.");
                    }
                    _local5 = (_topLevel.sources.length - 1);
                    while ((((_local5 > 0)) && ((_topLevel.sources[_local5] == 0)))) {
                        _local5--;
                    }
                    _local5++;
                    _topLevel.sources.length = _local5;
                    _topLevel.globals.length = _local5;
                    _topLevel.names.length = _local5;
                    _topLevel.locals.length = _local5;
                    _position++;
                    break;
                case "#dependences":
                    _position++;
                    trace("dependenteces", getToken().text);
                    if ((((getToken().text == "true")) || ((int(getToken().text) == 1)))){
                        _includeDependences = INCLUDE_ALL;
                    } else {
                        if ((((getToken().text == "false")) || ((int(getToken().text) == 0)))){
                            _includeDependences = INCLUDE_NONE;
                        } else {
                            _includeDependences = int(getToken().text);
                        }
                    }
                    _position++;
                    break;
                case "#debug":
                    _position++;
                    _includeDebugReferences = (((((getToken().text == "true")) || ((getToken().text == "1")))) ? true : false);
                    _position++;
                    break;
                case "#define":
                    if (getToken(2).type == TokenType.RESERVED){
                        error(getToken(2), "Definition can not be a reserved keyword.");
                    }
                    if (getToken(2).type == TokenType.OPERATOR){
                        error(getToken(2), "Definition can not be an operator.");
                    }
                    _position++;
                    if (!(_localDefinitions)){
                        _localDefinitions = new Dictionary();
                    }
                    _localDefinitions[getToken().text] = getToken(1).text;
                    define(getToken().text, getToken(1).text);
                    _position = (_position + 2);
                    break;
                case "#semantic":
                    _position++;
                    _local6 = getToken();
                    _position++;
                    _local7 = getToken();
                    _position++;
                    if (_data[_local7.text] == undefined){
                        error(getToken(), (("Expected data type but found '" + _local7.text) + "'."));
                    }
                    ShaderCompiler.semantics[_local6.text] = _local7.text;
                    if (!(_localSemantics)){
                        _localSemantics = new Dictionary();
                    }
                    _localSemantics[_local6.text] = _local7.text;
                    break;
                case "#if":
                    ifElseStatement();
                    break;
                case "#for":
                    forStatement();
                    break;
                case "trace":
                    t = getToken();
                    _position++;
                    if (getToken().text != "("){
                        expected("(");
                    }
                    _position++;
                    paramCount = 0;
                    while (getToken().text != ")") {
                        fullExpression();
                        paramCount++;
                        if (getToken().text == ","){
                            _position++;
                        } else {
                            if (getToken().text != ")"){
                                expected(",");
                            }
                        }
                    }
                    _position++;
                    write(ZSLFlags.DEBUG, paramCount);
                    break;
                case "use":
                    if (_namespace != _topLevel){
                        error(getToken(), "Namespaces can only be imported at top-level scope.");
                    }
                    _position++;
                    expected("namespace");
                    ns = _topLevel;
                    do  {
                        _position++;
                        ns = getScopeByName(ns, getToken().text);
                        if (((!(ns)) || (!((ns.varType == ZSLFlags.NAMESPACE))))){
                            error(getToken(), (("Expected namespace but found '" + getToken().text) + "'."));
                        }
                        _position++;
                    } while (getToken().text == ".");
                    _usingNS.push(ns);
                    break;
                case "agal":
                    t = getToken();
                    _position++;
                    if (getToken().text != "("){
                        expected("(");
                    }
                    _position++;
                    if (((!((getToken().type == TokenType.NUMBER))) || (!((Number(getToken().text) == int(getToken().text)))))){
                        error(getToken(), (("Expected constant agal operation value but found '" + getToken().text) + "'."));
                    }
                    _local8 = int(getToken().text);
                    _position++;
                    if (getToken().text == ","){
                        _position++;
                    }
                    paramCount = 0;
                    while (getToken().text != ")") {
                        fullExpression();
                        paramCount++;
                        if (getToken().text == ","){
                            _position++;
                        } else {
                            if (getToken().text != ")"){
                                expected(",");
                            }
                        }
                    }
                    _position++;
                    if (paramCount > 3){
                        error(t, "Incorrect number of arguments for function agal().");
                    }
                    if (paramCount > 2){
                        src1 = _stack.pop();
                    }
                    if (paramCount > 1){
                        src0 = _stack.pop();
                    }
                    if (paramCount > 0){
                        dest = _stack.pop();
                    }
                    write(ZSLFlags.AGAL, _local8, paramCount);
                    break;
                case "namespace":
                case "technique":
                case "pass":
                case "param":
                case "const":
                case "input":
                case "interpolated":
                case "output":
                case "void":
                case "float":
                case "float2":
                case "float3":
                case "float4":
                case "float4x4":
                case "float4x3":
                case "float3x3":
                case "sampler2D":
                case "samplerCube":
                case "string":
                case "surface":
                    if (getToken(1).text != "("){
                        declare();
                    } else {
                        atomicExpression();
                    }
                    break;
                case "return":
                    if (_namespace == _topLevel){
                        error(getToken(), "Invalid 'return' keyword on top level.");
                    }
                    t = getToken();
                    if (((!((getToken(1).text == "}"))) && (!((getToken(1).text == ";"))))){
                        fullExpression(1);
                        while (getToken().text == ";") {
                            _position++;
                        }
                        if ((((sourceStrType(_namespace.value) == "void")) || (!((sourceStrType(_namespace.value) == registerStrType(getLast())))))){
                            error(t, (((((((("Scope " + sourceStrType(_namespace.value)) + " ") + _namespace.name) + "(") + argsToStr(_namespace.locals, _namespace.paramCount)) + ") can not return a ") + registerStrType(getLast())) + " value."));
                        }
                        if (_ifElseLevelState == 0){
                            _retValue = _stack.pop();
                        } else {
                            _stack.pop();
                        }
                    } else {
                        if (_namespace.value){
                            error(getToken(), (((((("Scope " + sourceStrType(_namespace.value)) + " ") + _namespace.name) + " should return a ") + sourceStrType(_namespace.value)) + " value."));
                        }
                    }
                    write(ZSLFlags.RET);
                    break;
                case ";":
                case null:
                    _position++;
                    break;
                default:
                    fullExpression();
            }
            while ((((_position < _tokens.length)) && ((getToken().text == ";")))) {
                _position++;
            }
        }

        private static function fullExpression(offset:int=0):void
        {
            var t:ShaderToken = getToken();
            _position = (_position + offset);
            expression();
            while (true) {
                if (!(getToken())){
                    return;
                }
                switch (getToken().text){
                    case "=":
                        t = getToken();
                        fullExpression(1);
                        operation(t, ZSLOpcode.MOV);
                        break;
                    case "+=":
                        duplicate();
                        t = getToken();
                        fullExpression(1);
                        operation(t, ZSLOpcode.ADD);
                        operation(t, ZSLOpcode.MOV);
                        break;
                    case "-=":
                        duplicate();
                        t = getToken();
                        fullExpression(1);
                        operation(t, ZSLOpcode.SUB);
                        operation(t, ZSLOpcode.MOV);
                        break;
                    case "*=":
                        duplicate();
                        t = getToken();
                        fullExpression(1);
                        operation(t, ZSLOpcode.MUL);
                        operation(t, ZSLOpcode.MOV);
                        break;
                    case "/=":
                        duplicate();
                        t = getToken();
                        fullExpression(1);
                        operation(t, ZSLOpcode.DIV);
                        operation(t, ZSLOpcode.MOV);
                        break;
                    case "||":
                        t = getToken();
                        fullExpression(1);
                        operation(t, ZSLFlags.OR);
                        break;
                    case "&&":
                        t = getToken();
                        expression(1);
                        operation(t, ZSLFlags.AND);
                        break;
                    default:
                        return;
                }
            }
        }

        private static function expression(offset:int=0):void
        {
            _position = (_position + offset);
            _singleRegister = new Dictionary();
            atomicExpression();
            var t:ShaderToken = getToken();
            while (true) {
                if (!(getToken())){
                    return;
                }
                switch (getToken().text){
                    case "==":
                        t = getToken();
                        atomicExpression(1);
                        operation(t, ((_conditionalState) ? ZSLFlags.SEQ : ZSLOpcode.SEQ));
                        break;
                    case "!=":
                        t = getToken();
                        atomicExpression(1);
                        operation(t, ((_conditionalState) ? ZSLFlags.SNE : ZSLOpcode.SNE));
                        break;
                    case ">=":
                        t = getToken();
                        atomicExpression(1);
                        operation(t, ((_conditionalState) ? ZSLFlags.SGE : ZSLOpcode.SGE));
                        break;
                    case "<":
                        t = getToken();
                        atomicExpression(1);
                        operation(t, ((_conditionalState) ? ZSLFlags.SLT : ZSLOpcode.SLT));
                        break;
                    case ">":
                        t = getToken();
                        atomicExpression(1);
                        write(ZSLFlags.SWAP);
                        operation(t, ((_conditionalState) ? ZSLFlags.SLT : ZSLOpcode.SLT));
                        break;
                    case "<=":
                        t = getToken();
                        atomicExpression(1);
                        write(ZSLFlags.SWAP);
                        operation(t, ((_conditionalState) ? ZSLFlags.SGE : ZSLOpcode.SGE));
                        break;
                    default:
                        return;
                }
            }
        }

        private static function atomicExpression(offset:int=0):void
        {
            _position = (_position + offset);
            atomic();
            var t:ShaderToken = getToken();
            while (true) {
                if (!(getToken())){
                    return;
                }
                switch (getToken().text){
                    case "-":
                        t = getToken();
                        atomicExpression(1);
                        operation(t, ZSLOpcode.SUB);
                        break;
                    case "+":
                        t = getToken();
                        atomicExpression(1);
                        operation(t, ZSLOpcode.ADD);
                        break;
                    case "/":
                        t = getToken();
                        atomic(1);
                        operation(t, ZSLOpcode.DIV);
                        break;
                    case "*":
                        t = getToken();
                        atomic(1);
                        operation(t, ZSLOpcode.MUL);
                        break;
                    case "++":
                        duplicate();
                        t = getToken();
                        pushNumber("1");
                        _position++;
                        operation(t, ZSLOpcode.ADD);
                        operation(t, ZSLOpcode.MOV);
                        break;
                    case "--":
                        duplicate();
                        t = getToken();
                        pushNumber("1");
                        _position++;
                        operation(t, ZSLOpcode.SUB);
                        operation(t, ZSLOpcode.MOV);
                        break;
                    case ";":
                        _position++;
                        break;
                    default:
                        return;
                }
            }
        }

        private static function atomic(offset:int=0):void
        {
            _position = (_position + offset);
            var t:ShaderToken = getToken();
            if (getToken().text == "null"){
                _stack.push(0);
                _position++;
                write(ZSLFlags.NULL);
            } else {
                if (getToken().text == "++"){
                    atomicExpression(1);
                    duplicate();
                    pushNumber("1");
                    operation(t, ZSLOpcode.ADD);
                    operation(t, ZSLOpcode.MOV);
                } else {
                    if (getToken().text == "--"){
                        atomicExpression(1);
                        duplicate();
                        pushNumber("1");
                        operation(t, ZSLOpcode.SUB);
                        operation(t, ZSLOpcode.MOV);
                    } else {
                        if (getToken().type == TokenType.STRING){
                            pushString(getToken().text);
                            _position++;
                        } else {
                            if (getToken().type == TokenType.NUMBER){
                                pushNumber(getToken().text);
                                _position++;
                            } else {
                                if ((((getToken().type == TokenType.WORD)) || ((getToken().type == TokenType.KEYWORD)))){
                                    t = getToken();
                                    if (ShaderCompiler.semantics[t.text] != undefined){
                                        declare();
                                    } else {
                                        getReference();
                                    }
                                } else {
                                    if (getToken().text == "const"){
                                        t = getToken();
                                        if (ShaderCompiler.semantics[t.text] != undefined){
                                            declare();
                                        } else {
                                            getReference();
                                        }
                                    } else {
                                        if (getToken().text == "!"){
                                            fullExpression(1);
                                            write(ZSLFlags.NOT);
                                        } else {
                                            if (getToken().text == "+"){
                                                fullExpression(1);
                                            } else {
                                                if (getToken().text == "-"){
                                                    if (getToken(1).type == TokenType.NUMBER){
                                                        pushNumber(("-" + getToken(1).text));
                                                        _position = (_position + 2);
                                                    } else {
                                                        fullExpression(1);
                                                        operation(t, ZSLOpcode.NEG);
                                                    }
                                                } else {
                                                    if (getToken().text == "("){
                                                        t = getToken();
                                                        fullExpression(1);
                                                        expected(")");
                                                        _position++;
                                                    } else {
                                                        error(t, (("Unexpected token '" + ((getToken().text) ? getToken().text : "")) + "'."));
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            subAtomic();
        }

        private static function subAtomic():void
        {
            var t:ShaderToken;
            var dest:uint;
            var c:int;
            var len:int;
            var addr:int;
            var index:uint;
            var mask:String;
            t = getToken();
            if (getToken().text == "["){
                t = getToken();
                dest = _stack.pop();
                len = ShaderCompiler.getSourceLength((dest & 0xFFFF));
                addr = ShaderCompiler.getSourceAddress((dest & 0xFFFF));
                try {
                    if ((((isNaN(Number(getToken(1).text)) == false)) && ((getToken(2).text == "]")))){
                        dest = ShaderCompiler.getNewRegisterOffset(dest, int(getToken(1).text));
                        if ((dest & 0xFFFF) >= (addr + len)){
                            error(t, "Index is out of range.");
                        }
                        write(ZSLFlags.PROP, getToken(1).text);
                        _singleRegister[(dest & 0xFFFF)] = true;
                        _stack.push(dest);
                        _position = (_position + 2);
                    } else {
                        atomicExpression(1);
                        index = getLast();
                        if (!(index)) {
							
                            throw ((("Invalid index '" + registerToStr(getLast())) + "'."));
							
							return;
                        }
                        if (ShaderCompiler.getRegisterSize(index) > 1) {
							
                            throw ("Index should be a float1 value.");
							
							return;
                        }
                        dest = ShaderCompiler.setRegisterIndirectValue(dest, index);
                        _singleRegister[(dest & 0xFFFF)] = true;
                        _stack.pop();
                        _stack.push(dest);
                        write(ZSLFlags.INDEX);
                    }
                } catch(e) {
                    error(t, e);
                }
                expected("]");
                _position++;
                subAtomic();
            }
            if (getToken().text == "."){
                t = getToken();
                try {
                    dest = _stack.pop();
                    while (getToken().text == ".") {
                        if (!(ShaderCompiler.isFloat(dest))){
                            error(getToken(), "Can not access to a mask property for a non-float value.");
                        }
                        mask = getToken(1).text;
                        mask = mask.replace(new RegExp("r|s", "ig"), "x");
                        mask = mask.replace(new RegExp("g|t", "ig"), "y");
                        mask = mask.replace(new RegExp("b|p", "ig"), "z");
                        mask = mask.replace(new RegExp("a|q", "ig"), "w");
                        dest = ShaderCompiler.getNewRegisterFromMask(dest, ShaderCompiler.strToMask(mask), getToken(1).text.length);
                        write(ZSLFlags.PROP, mask);
                        _position = (_position + 2);
                    }
                } catch(e) {
                    error(t, e);
                }
                _stack.push(dest);
                subAtomic();
            }
        }

        private static function declare(isLocal:Boolean=false):void
        {
            var semantic:String;
            var source:uint;
            var t:ShaderToken;
            var name:String;
            var prev:ShaderContext;
            var i:int;
            var method:ShaderContext;
            var pass:Boolean;
            var e:int;
            var isLocal:Boolean = isLocal;
            var parent:ShaderContext = _namespace;
            var canBeLocal:Boolean = true;
            t = getToken();
            var type:String = getToken().text;
            if (ShaderCompiler.semantics[type] != undefined){
                semantic = type;
                type = ShaderCompiler.semantics[type];
            }
            switch (type){
                case "input":
                case "interpolated":
                case "const":
                case "param":
                    _position++;
                    if (getToken().text == "sampler2D"){
                        type = getToken().text;
                    } else {
                        if (getToken().text == "samplerCube"){
                            type = getToken().text;
                        } else {
                            canBeLocal = false;
                        }
                    }
                    break;
                case "string":
                case "sampler2D":
                case "samplerCube":
                    break;
                case "surface":
                case "output":
                case "void":
                    canBeLocal = false;
                    break;
                case "namespace":
                case "technique":
                case "pass":
                    canBeLocal = false;
                    break;
                default:
                    type = "float";
            }
            var data:String = getToken().text;
            if (ShaderCompiler.semantics[data] != undefined){
                semantic = data;
                data = ShaderCompiler.semantics[data];
            }
            if (!(_data[data])){
                error(getToken(), (("Expected data type but found '" + data) + "'."));
            }
            _position++;
            name = getToken().text;
            if (ShaderCompiler.semantics[name]){
                error(getToken(), (("Variable name '" + name) + "' can not be a semantic type."));
            }
            if (((((!((getToken().type == TokenType.WORD))) && (!((getToken().type == TokenType.KEYWORD))))) && (!((getToken().text == "const"))))){
                error(getToken(), (("Expected variable identifier but found '" + name) + (((getToken().type == TokenType.RESERVED)) ? "' reserved keyword." : "'.")));
            }
            if (((((((((((!((type == "input"))) && (!((type == "surface"))))) && (!((type == "sampler2D"))))) && (!((type == "samplerCube"))))) && (!((type == "param"))))) && (semantic))){
                error(t, (((("Variable '" + name) + "' can not be of semantic type '") + semantic) + "'. Semantic types can only be used with input, sampler, surfaces, or param values."));
            }
            var size:int = getSize(data);
            var length:int = getLength(data);
            var array:int = length;
            if (type == "namespace"){
                if (_namespace.getIndex(name) != -1){
                    _namespace = _namespace.getScope(name);
                } else {
                    _namespace = new ShaderContext(name);
                    _namespace.varType = getTypeId(type);
                    _namespace.parent = parent;
                    source = pushSource(parent, name, _namespace.varType, 0, 0, null, _namespace);
                }
                _position++;
                _dependences[_namespace] = true;
                while (getToken().text == ".") {
                    _position++;
                    name = getToken().text;
                    prev = _namespace;
                    if (_namespace.getIndex(name) != -1){
                        _namespace = _namespace.getScope(name);
                    } else {
                        _namespace = new ShaderContext(name);
                        _namespace.varType = getTypeId(type);
                        _namespace.parent = prev;
                        source = pushSource(prev, name, _namespace.varType, 0, 0, null, _namespace);
                    }
                    _dependences[_namespace] = true;
                    _position++;
                }
            } else {
                if ((((type == "technique")) || ((type == "pass")))){
                    _namespace = new ShaderContext(name);
                    _namespace.varType = getTypeId(type);
                    _namespace.parent = parent;
                    _dependences[_namespace] = true;
                    if (parent.getIndex(name) != -1){
                        error(t, (("Ducplicated scope declaration " + _namespace.name) + "."));
                    }
                    _position++;
                    source = pushSource(parent, name, _namespace.varType, 0, 0, null, _namespace);
                } else {
                    _position++;
                }
            }
            if ((((type == "namespace")) || ((type == "pass")))){
                expected("{");
            }
            if (getToken().text == "("){
                _position++;
                if (isLocal){
                    error(t, "Functions can not be defined as parameter values.");
                }
                if (array > 1){
                    error(t, "Return array values is not supported yet :(");
                }
                if (((((!((type == "float"))) && (!((type == "void"))))) && (!((type == "technique"))))){
                    error(getToken(), (((("Scope '" + name) + "' can not be of type '") + type) + "'."));
                }
                if (((((!((type == "technique"))) && (!((type == "namespace"))))) && (!((type == "pass"))))){
                    _namespace = new ShaderContext(name);
                    _namespace.varType = ZSLFlags.FUNCTION;
                    _namespace.parent = parent;
                    _namespace.value = (((getTypeId(type) << 16) | (Math.max(0, (size - 1)) << 22)) | (length << 24));
                    _dependences[_namespace] = true;
                    source = pushSource(parent, name, _namespace.varType, size, length, null, _namespace);
                }
                while (getToken().text != ")") {
                    _namespace.paramCount++;
                    declare(true);
                    if (getToken().text == ","){
                        _position++;
                    } else {
                        if (getToken().text != ")"){
                            error(getToken(), (("Expected ',' but found '" + getToken().text) + "'."));
                        }
                    }
                }
                _position++;
                expected("{");
                _position++;
                read();
                expected("}");
                _position++;
                i = 0;
                while (i < parent.globals.length) {
                    method = (parent.globals[i] as ShaderContext);
                    if (!(((method == null)) || ((method == _namespace)))){
                        if (!((!((method.name == _namespace.name))) || (!((method.paramCount == _namespace.paramCount))))){
                            pass = true;
                            e = 0;
                            while (e < _namespace.paramCount) {
                                if ((method.sources[e] & 0xFFFF0000) != (_namespace.sources[e] & 0xFFFF0000)){
                                    pass = false;
                                }
                                e = (e + 1);
                            }
                            if (pass){
                                error(t, (("Ducplicated scope declaration " + _namespace.name) + "."));
                            }
                        }
                    }
                    i = (i + 1);
                }
                _namespace = parent;
            } else {
                if (getToken().text == "{"){
                    if (array > 1){
                        error(t, "Scope can not be an array value.");
                    }
                    if (((((!((type == "namespace"))) && (!((type == "technique"))))) && (!((type == "pass"))))){
                        error(t, "Unexpected '{'.");
                    }
                    _position++;
                    read();
                    expected("}");
                    _position++;
                    _namespace = parent;
                } else {
                    if (_namespace.getIndex(name) != -1){
                        error(t, (("Duplicated variable definition '" + name) + "'."));
                    }
                    if (((isLocal) && ((canBeLocal == false)))){
                        error(t, (("Parameters can not be of type '" + type) + "'."));
                    }
                    if (type == "output"){
                        if (((((!((name == Context3DProgramType.VERTEX))) && (!((name == Context3DProgramType.FRAGMENT))))) && (!((name == "depth"))))){
                            try {
                                _referenceProgram[name];
                            } catch(e) {
                                error(t, (("Unknown output " + name) + "."));
                            }
                        }
                    }
                    if (getToken().text == "["){
                        if (((((((!((type == "float"))) && (!((type == "param"))))) && (!((type == "const"))))) && (!((((type == "output")) && ((name == "fragment"))))))){
                            error(t, (("Variable of type '" + type) + "' can not be an array."));
                        }
                        _position++;
                        if (getToken().type != TokenType.NUMBER){
                            error(t, (("Expected array index value but found '" + getToken().text) + "'."));
                        }
                        if (Number(getToken().text) != int(getToken().text)){
                            error(t, "Array index can not be a floating point value.");
                        }
                        array = int(getToken().text);
                        if (array == 0){
                            error(t, "Array length can not be 0.");
                        }
                        _position++;
                        expected("]");
                        _position++;
                        if (length > 1){
                            error(t, (("Variable of type " + data) + " can not be an array."));
                        }
                    }
                    if ((((((type == "const")) && ((array == 1)))) && (!((getToken().text == "="))))){
                        error(t, (("Constant variable '" + name) + "' should be assigned after declaration."));
                    }
                    if ((((type == "output")) && ((name == "depth")))){
                        size = 1;
                    }
                    source = pushSource(_namespace, name, getTypeId(type, data), size, array, semantic);
                    if (getToken().text == "<"){
                        if (isLocal){
                            error(getToken(), "Parameters can not have metadata.");
                        }
                        try {
                            readMeta(source);
                        } catch(e) {
                            error(_tokens[_position], e);
                        }
                    }
                    if (getToken().text == "="){
                        if (array > 1){
                            error(getToken(), "Can not assign values directly to an array of values after declaration.");
                        }
                        if (isLocal){
                            error(getToken(), (("Parameter '" + name) + "' can not be assigned after declaration."));
                        }
                        t = getToken();
                        write(ZSLFlags.GET, (source & 0xFFFF));
                        _stack.push(_namespace.locals[(source & 0xFFFF)]);
                        fullExpression(1);
                        operation(t, ZSLOpcode.MOV);
                    }
                }
            }
        }

        private static function define(source:String, value:String):void
        {
            var pos:int;
            if (source == value){
                return;
            }
            if (value != null){
                pos = _position;
                while (pos < _tokens.length) {
                    if (((!((_tokens[pos].type == TokenType.STRING))) && ((_tokens[pos].text == source)))){
                        _tokens[pos].text = value;
                        if (!(isNaN(Number(value)))){
                            _tokens[pos].type = TokenType.NUMBER;
                        }
                    }
                    pos++;
                }
                ShaderCompiler.defines[source] = value;
            }
        }

        private static function getReference(onlyScope:Boolean=false):void
        {
            var p:int = _position;
            var t:ShaderToken = getToken();
            var name:String = getToken().text;
            var ns:ShaderContext = getScopeOf(name, onlyScope);
            if (_includeDebugReferences){
                write(ZSLFlags.DEBUG_D, getToken().line, getToken().pos);
            }
            if (!(ns)){
                error(getToken(), (((("Undefined '" + getToken().text) + "' in '") + _namespace.name) + "'."));
            }
            var idx:int = ns.getIndex(name);
            var dest:uint = ns.locals[idx];
            var source:uint = ns.sources[idx];
            if (((source) && ((ShaderCompiler.isScope(((source >> 16) & 63)) == ZSLFlags.NAMESPACE)))){
                do  {
                    _position++;
                    expected(".", "Expected '.' after namespace.");
                    _position++;
                    ns = (ns.globals[idx] as ShaderContext);
                    if (ns){
                        idx = ns.getIndex(getToken().text);
                    } else {
                        idx = -1;
                    }
                    if (idx == -1){
                        error(getToken(), (((("Undefined '" + getToken().text) + "' in '") + ns.name) + "'."));
                    }
                    dest = ns.locals[idx];
                    source = ns.sources[idx];
                } while (((source) && ((ShaderCompiler.isScope(((source >> 16) & 63)) == ZSLFlags.NAMESPACE))));
            }
            if (ns){
                if (getToken(1).text != "("){
                    if (ShaderCompiler.isScope(((ns.sources[idx] >> 16) & 63))){
                        error(t, (("Expected () after '" + registerToStr(dest)) + "'."));
                    }
                    goToNamespace(ns, _namespace);
                    includeScope(ns);
                    _stack.push(ns.locals[idx]);
                    _position++;
                    write(ZSLFlags.GET, idx, ns);
                } else {
                    name = getToken().text;
                    _position++;
                    if (!(onlyScope)){
                        _position = p;
                        getReference(true);
                        return;
                    }
                    idx = call(ns, name);
                    goToNamespace(ns, _namespace);
                    includeScope((ns.globals[idx] as ShaderContext));
                    write(ZSLFlags.CALL, idx, ns.globals[idx]);
                }
            } else {
                error(t, (("Undefined variable or method '" + getToken().text) + "'."));
            }
        }

        private static function call(ns:ShaderContext, name:String):int
        {
            var p:Vector.<uint>;
            var i:int;
            var method:ShaderContext;
            var pass:Boolean;
            var e:int;
            var t:ShaderToken = getToken(-1);
            var paramCount:int = params();
            if (paramCount != -1){
                p = new Vector.<uint>();
                while (p.length < paramCount) {
                    p.unshift(_stack.pop());
                }
                i = 0;
                while (i < ns.globals.length) {
                    method = (ns.globals[i] as ShaderContext);
                    if (method != null){
                        if (!((!((method.name == name))) || (!((method.paramCount == paramCount))))){
                            pass = true;
                            e = 0;
                            while (e < paramCount) {
                                if (sourceStrType(method.sources[e]) != registerStrType(p[e])){
                                    pass = false;
                                }
                                e++;
                            }
                            if (pass){
                                ns = (ns.globals[i] as ShaderContext);
                                _stack.push(ShaderCompiler.alloc((("(" + ns.name) + ")"), ns.value));
                                return (i);
                            }
                        }
                    }
                    i++;
                }
                error(t, (((("No match for a call to function " + name) + "(") + argsToStr(p, p.length)) + ")."));
            }
            return (-1);
        }

        private static function params(offset:int=0):int
        {
            var count:int;
            _position = (_position + offset);
            if (getToken().text == "("){
                _position++;
                while (getToken().text != ")") {
                    fullExpression();
                    count++;
                    if (getToken().text == ","){
                        if (getToken(1).text == ")"){
                            error(getToken(), "Expected parameter but found ')'");
                        }
                        _position++;
                    } else {
                        if (getToken().text != ")"){
                            expected(",");
                        }
                    }
                }
                _position++;
                return (count);
            }
            return (-1);
        }

        private static function forStatement():void
        {
            _conditionalState = true;
            _position++;
            var t:ShaderToken = getToken(1);
            expected("(");
            _position++;
            statement();
            _conditionalState = true;
            var jumpPos:uint = _namespace.code.position;
            fullExpression();
            var exitPos:uint = _namespace.code.position;
            write(ZSLFlags.IF, 0);
            _conditionalState = false;
            var incrementPos:int = _position;
            while ((((_position < _tokens.length)) && (!((getToken().text == ")"))))) {
                _position++;
            }
            expected(")");
            _position++;
            if (getToken().text == "{"){
                read(1, false);
                expected("}");
                _position++;
            } else {
                statement();
            }
            var currPos:int = _position;
            _position = incrementPos;
            while (getToken().text != ")") {
                fullExpression();
            }
            _position = currPos;
            write(ZSLFlags.JUMP, jumpPos);
            currPos = _namespace.code.position;
            _namespace.code.position = (exitPos + 1);
            _namespace.code.writeShort(currPos);
            _namespace.code.position = currPos;
        }

        private static function ifElseStatement(level:int=0):void
        {
            var currPos:int;
            var elseSkip:int;
            _ifElseLevelState++;
            _position++;
            var t:ShaderToken = getToken(1);
            _conditionalState = true;
            expected("(");
            fullExpression(1);
            expected(")");
            _stack.pop();
            _conditionalState = false;
            var lastPos:int = _namespace.code.position;
            write(ZSLFlags.IF, 0);
            _position++;
            if (getToken().text == "{"){
                read(1, false);
                expected("}");
                _position++;
            } else {
                statement();
            }
            _ifElseLevelState--;
            _ifElseLevelState++;
            if ((((getToken().text == "#else")) || ((getToken().text == "#elseif")))){
                elseSkip = _namespace.code.position;
                write(ZSLFlags.JUMP, 0);
                currPos = _namespace.code.position;
                _namespace.code.position = (lastPos + 1);
                _namespace.code.writeShort(currPos);
                _namespace.code.position = currPos;
                if (getToken().text == "#elseif"){
                    ifElseStatement();
                } else {
                    _position++;
                    if (getToken().text == "if"){
                        ifElseStatement();
                    } else {
                        if (getToken().text == "{"){
                            read(1, false);
                            expected("}");
                            _position++;
                        } else {
                            statement();
                        }
                    }
                }
                currPos = _namespace.code.position;
                _namespace.code.position = (elseSkip + 1);
                _namespace.code.writeShort(currPos);
                _namespace.code.position = currPos;
            } else {
                currPos = _namespace.code.position;
                _namespace.code.position = (lastPos + 1);
                _namespace.code.writeShort(currPos);
                _namespace.code.position = currPos;
            }
            _ifElseLevelState--;
        }

        private static function readMeta(reg:uint):void
        {
            var f:ShaderBase;
            var meta:ShaderToken;
            var reg:uint = reg;
            var pushEqual:Boolean;
            f = _namespace.globals[(reg & 0xFFFF)];
            if (!(f)) {
				
                throw ("Pirvate declarations can not have <meta> values.");
				
				return;
            }
            if (getToken().text == "<"){
                _position++;
                if (getToken().text == ">="){
                    getToken().text = ">";
                    pushEqual = true;
                }
                while (getToken().text != ">") {
                    meta = getToken();
                    _position++;
                    expected("=");
                    _position++;
                    if (getToken().text == ">"){
                        error(getToken(), "Expected value but found '>'");
                    }
                    write(ZSLFlags.GET, (reg & 0xFFFF));
                    write(ZSLFlags.META, meta.text, getToken().text);
                    if ((((((((meta.text == "name")) || ((meta.text == "type")))) || ((meta.text == "state")))) || ((meta.text == "semantic")))) {
						
                        throw ((((("Property '" + meta.text) + "' of ") + f.name) + " can not be written."));
						
						return;
                    }
                    try {
                        f[meta.text] = getToken().text;
                    } catch (e) {
						
                        throw ((((((("Can not find property '" + meta.text) + "' in ") + ShaderCompiler.typeToStr(f.varType)) + " ") + f.name) + "."));
						
						return;
                    }
                    _position++;
                    if (getToken().text == ","){
                        _position++;
                    }
                    if (getToken().text == ">="){
                        getToken().text = ">";
                        pushEqual = true;
                    }
                }
                expected(">");
                _position++;
                if (pushEqual){
                    _tokens.splice(_position, 0, new ShaderToken("=", TokenType.OPERATOR, getToken().line, getToken().pos));
                }
            }
        }

        private static function operation(t:ShaderToken, id:int):void
        {
            var dest:uint;
            var src0:uint;
            var src1:uint;
            var name:String;
            var value:String;
            var f_size:int;
            var m_size:int;
            var f_length:int;
            var m_length:int;
            switch (id){
                case ZSLOpcode.MOV:
                    src0 = _stack.pop();
                    dest = _stack.pop();
                    if (src0 == dest){
                        error(t, "Source and destination varialbles are the same.");
                    }
                    if (((isFloat(getRegisterType(dest))) && (isFloat(getRegisterType(src0))))){
                        if (((!((registerStrType(dest) == registerStrType(src0)))) && ((getRegisterSize(src0) > 1)))){
                            error(t, (((((((("Can not convert " + registerToStr(src0)) + " ") + registerStrType(src0)) + " to a ") + registerToStr(dest)) + " ") + registerStrType(dest)) + " value."));
                        }
                        if (getRegisterType(dest) == ZSLFlags.OUTPUT){
                            if (((dest >> 16) & 0xFF) != 228){
                                error(t, "Output register can not be masked and should write all components.");
                            }
                        }
                        validateWriteMask(t, dest);
                    } else {
                        if (getRegisterType(dest) == ZSLFlags.OUTPUT){
                            name = names[(dest & 0xFFFF)];
                            value = names[(src0 & 0xFFFF)];
                            if ((((name == "sourceFactor")) || ((name == "destFactor")))){
                                switch (value){
                                    case Context3DBlendFactor.DESTINATION_ALPHA:
                                    case Context3DBlendFactor.DESTINATION_COLOR:
                                    case Context3DBlendFactor.ONE:
                                    case Context3DBlendFactor.ONE_MINUS_DESTINATION_ALPHA:
                                    case Context3DBlendFactor.ONE_MINUS_DESTINATION_COLOR:
                                    case Context3DBlendFactor.ONE_MINUS_SOURCE_ALPHA:
                                    case Context3DBlendFactor.ONE_MINUS_SOURCE_COLOR:
                                    case Context3DBlendFactor.SOURCE_ALPHA:
                                    case Context3DBlendFactor.SOURCE_COLOR:
                                    case Context3DBlendFactor.ZERO:
                                        break;
                                    default:
                                        error(t, (("Invalid " + name) + " value."));
                                }
                            }
                            if ((((name == "depthCompare")) || ((name == "stencilCompareMode")))){
                                switch (value){
                                    case Context3DCompareMode.ALWAYS:
                                    case Context3DCompareMode.EQUAL:
                                    case Context3DCompareMode.GREATER:
                                    case Context3DCompareMode.GREATER_EQUAL:
                                    case Context3DCompareMode.LESS:
                                    case Context3DCompareMode.LESS_EQUAL:
                                    case Context3DCompareMode.NEVER:
                                    case Context3DCompareMode.NOT_EQUAL:
                                        break;
                                    default:
                                        error(t, (("Invalid " + name) + " value."));
                                }
                            }
                            if ((((name == "cullFace")) || ((name == "stencilTriangleFace")))){
                                switch (value){
                                    case Context3DTriangleFace.BACK:
                                    case Context3DTriangleFace.FRONT:
                                    case Context3DTriangleFace.FRONT_AND_BACK:
                                    case Context3DTriangleFace.NONE:
                                        break;
                                    default:
                                        error(t, (("Invalid " + name) + " value."));
                                }
                            }
                            if ((((((name == "stencilOnPass")) || ((name == "stencilOnBothPass")))) || ((name == "stencilOnDepthFail")))){
                                switch (value){
                                    case Context3DStencilAction.DECREMENT_SATURATE:
                                    case Context3DStencilAction.DECREMENT_WRAP:
                                    case Context3DStencilAction.INCREMENT_SATURATE:
                                    case Context3DStencilAction.INCREMENT_WRAP:
                                    case Context3DStencilAction.INVERT:
                                    case Context3DStencilAction.KEEP:
                                    case Context3DStencilAction.SET:
                                    case Context3DStencilAction.ZERO:
                                        break;
                                    default:
                                        error(t, (("Invalid " + name) + " value."));
                                }
                            }
                        } else {
                            if (src0 != 0){
                                error(t, "Illegal operation.");
                            }
                        }
                    }
                    write(id);
                    break;
                case ZSLOpcode.NEG:
                    src0 = _stack.pop();
                    dest = ShaderCompiler.createFrom(src0, src0);
                    _stack.push(dest);
                    write(id);
                    break;
                case ZSLOpcode.ADD:
                case ZSLOpcode.SUB:
                case ZSLOpcode.MUL:
                case ZSLOpcode.DIV:
                case ZSLOpcode.SEQ:
                case ZSLFlags.SEQ:
                case ZSLOpcode.SNE:
                case ZSLFlags.SNE:
                case ZSLOpcode.SGE:
                case ZSLFlags.SGE:
                case ZSLOpcode.SLT:
                case ZSLFlags.SLT:
                case ZSLOpcode.M33:
                case ZSLOpcode.M34:
                case ZSLOpcode.M44:
                case ZSLFlags.AND:
                case ZSLFlags.OR:
                    src1 = _stack.pop();
                    src0 = _stack.pop();
                    if (((isFloat(getRegisterType(src0))) && (isFloat(getRegisterType(src1))))){
                        f_size = getRegisterSize(src0);
                        m_size = getRegisterSize(src1);
                        f_length = ((_singleRegister[(src0 & 0xFFFF)]) ? 1 : getSourceLength((src0 & 0xFFFF)));
                        m_length = ((_singleRegister[(src1 & 0xFFFF)]) ? 1 : getSourceLength((src1 & 0xFFFF)));
                        if ((((((id == ZSLOpcode.MUL)) && ((f_length == 1)))) && ((m_length >= 3)))){
                            if ((((((f_size == 3)) && ((m_size == 3)))) && ((m_length == 3)))){
                                id = ZSLOpcode.M33;
                            } else {
                                if ((((((f_size == 3)) && ((m_size == 3)))) && ((m_length == 4)))){
                                    id = ZSLOpcode.M33;
                                } else {
                                    if ((((((f_size == 3)) && ((m_size == 4)))) && ((m_length == 3)))){
                                        id = ZSLOpcode.M34;
                                    } else {
                                        if ((((((f_size == 3)) && ((m_size == 4)))) && ((m_length == 4)))){
                                            id = ZSLOpcode.M34;
                                        } else {
                                            if ((((((f_size == 4)) && ((m_size == 4)))) && ((m_length == 4)))){
                                                id = ZSLOpcode.M44;
                                            } else {
                                                if ((((((m_size == 3)) && ((f_size == 3)))) && ((f_length == 3)))){
                                                    error(t, "Vector can be multiplied by matrix, but matrix can not be multiplied by vector.");
                                                } else {
                                                    if ((((((m_size == 3)) && ((f_size == 4)))) && ((f_length == 3)))){
                                                        error(t, "Vector can be multiplied by matrix, but matrix can not be multiplied by vector.");
                                                    } else {
                                                        if ((((((m_size == 4)) && ((f_size == 4)))) && ((f_length == 3)))){
                                                            error(t, "Vector can be multiplied by matrix, but matrix can not be multiplied by vector.");
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        if ((((id == ZSLOpcode.M33)) || ((id == ZSLOpcode.M34)))){
                            dest = ShaderCompiler.createFrom(src0, src0);
                        } else {
                            dest = ShaderCompiler.createFrom(src0, src1);
                        }
                        if (id == ZSLOpcode.M33){
                            if ((getRegisterMask(src1) & 36) != 36){
                                error(t, (("Invalid mask '" + ShaderCompiler.maskToStr(getRegisterMask(src1), getRegisterSize(src1))) + "'. Components can not be swizzled for a matrix multiplication."));
                            }
                        } else {
                            if ((((id == ZSLOpcode.M34)) || ((id == ZSLOpcode.M44)))){
                                if (getRegisterMask(src1) != 228){
                                    error(t, (("Invalid mask '" + ShaderCompiler.maskToStr(getRegisterMask(src1), getRegisterSize(src1))) + "'. Components can not be swizzled for a matrix multiplication."));
                                }
                            } else {
                                if (!(((id == ZSLFlags.AND)) || ((id == ZSLFlags.OR)))){
                                    if (f_length != m_length){
                                        trace(f_length, m_length, f_size, m_size, _singleRegister[(src0 & 0xFFFF)], _singleRegister[(src1 & 0xFFFF)]);
                                        error(t, "Illegal operation.");
                                    }
                                    if (((((!((f_size == 1))) && (!((m_size == 1))))) && (!((f_size == m_size))))){
                                        error(t, (((("Can not convert " + registerStrType(src1)) + " to a ") + registerStrType(src0)) + " value."));
                                    }
                                }
                            }
                        }
                        write(id);
                        _stack.push(dest);
                    } else {
                        error(t, "Ilegal operation.");
                    }
                    break;
                default:
                    error(t, "Unknown token.");
            }
        }

        private static function write(... _args):void
        {
            var ns:ShaderContext = _namespace;
            var id:int = _args[0];
            if (!(_namespace.code)){
                _namespace.code = new ByteArray();
                _namespace.code.endian = "littleEndian";
            }
            _namespace.code.writeByte(id);
            switch (id){
                case ZSLFlags.GET:
                    if (_debug){
                        verbose(_namespace.code.position, ("getLocal " + _args[1]), (((("<" + ((_args[2]) || (_namespace)).name) + ":") + registerToStr(((_args[2]) || (_namespace)).locals[_args[1]])) + ">"));
                    }
                    _namespace.code.writeByte(_args[1]);
                    break;
                case ZSLFlags.NULL:
                    if (_debug){
                        verbose(_namespace.code.position, "null");
                    }
                    break;
                case ZSLFlags.PROP:
                    if (_debug){
                        verbose(_namespace.code.position, ("prop " + _args[1]));
                    }
                    _namespace.code.writeUTF(_args[1]);
                    break;
                case ZSLFlags.INDEX:
                    if (_debug){
                        verbose(_namespace.code.position, "index");
                    }
                    break;
                case ZSLFlags.META:
                    if (_debug){
                        verbose(_namespace.code.position, "meta", _args[1], _args[2]);
                    }
                    _namespace.code.writeUTF(_args[1]);
                    _namespace.code.writeUTF(_args[2]);
                    break;
                case ZSLFlags.PARENT:
                    if (_debug){
                        verbose(_namespace.code.position, "parent", (("<" + _args[1].name) + ">"));
                    }
                    break;
                case ZSLFlags.PARENT_N:
                    if (_debug){
                        verbose(_namespace.code.position, ("parent_n " + _args[1]), (("<" + _args[2].name) + ">"));
                    }
                    _namespace.code.writeByte(_args[1]);
                    break;
                case ZSLFlags.GET_NS:
                    if (_debug){
                        verbose(_namespace.code.position, ("ns " + _args[1]), (("<" + _args[2].name) + ">"));
                    }
                    _namespace.code.writeByte(_args[1]);
                    break;
                case ZSLFlags.CALL:
                    if (_debug){
                        verbose(_namespace.code.position, ("call " + _args[1]), (("<" + _args[2]) + ">"));
                    }
                    _namespace.code.writeByte(_args[1]);
                    break;
                case ZSLFlags.AGAL:
                    if (_debug){
                        verbose(_namespace.code.position, "agal", _args[1], _args[2]);
                    }
                    _namespace.code.writeByte(_args[1]);
                    _namespace.code.writeByte(_args[2]);
                    break;
                case ZSLFlags.IF:
                case ZSLFlags.JUMP:
                    if (_debug){
                        verbose(_namespace.code.position, ShaderCompiler.OPS[id], _args[1]);
                    }
                    _namespace.code.writeShort(_args[1]);
                    break;
                case ZSLFlags.DEBUG:
                    if (_debug){
                        verbose(_namespace.code.position, "debug", _args[1]);
                    }
                    _namespace.code.writeByte(_args[1]);
                    break;
                case ZSLFlags.DEBUG_D:
                    if (_debug){
                        verbose(_namespace.code.position, "debug_d", _args[1], _args[2]);
                    }
                    _namespace.code.writeShort(_args[1]);
                    _namespace.code.writeShort(_args[2]);
                    break;
                default:
                    if (_debug){
                        _args.shift();
                        verbose(_namespace.code.position, ShaderCompiler.OPS[id], _args);
                    }
            }
        }

        private static function saveNS(ns:ShaderContext):void
        {
            var src:uint;
            var i:int;
            var nullCount:int;
            var prev:int;
            var pos:int = _bytes.position;
            _bytes.writeByte(ns.varType);
            _bytes.writeUTF(ns.name);
            _bytes.writeByte(ns.paramCount);
            _bytes.writeUnsignedInt(ns.code.length);
            _bytes.writeBytes(ns.code, 0, ns.code.length);
            if (ns.varType == ZSLFlags.FUNCTION){
                writeValue(ns, "", ns.value, null);
            }
            pos = (_bytes.position - pos);
            var includeAll:Boolean;
            if (includeAll){
                i = 0;
                while (i < ns.sources.length) {
                    src = ns.sources[i];
                    if ((ns.globals[i] is ShaderContext)){
                        saveNS((ns.globals[i] as ShaderContext));
                    } else {
                        writeValue(ns, ns.names[i], src, ns.globals[i]);
                    }
                    i++;
                }
            } else {
                nullCount = 0;
                i = 0;
                while (i < ns.sources.length) {
                    src = ns.sources[i];
                    if ((ns.globals[i] is ShaderContext)){
                        if (_dependences[ns.globals[i]]){
                            if (nullCount > 0){
                                _bytes.writeByte(254);
                                _bytes.writeByte(nullCount);
                                nullCount = 0;
                            }
                            saveNS((ns.globals[i] as ShaderContext));
                        } else {
                            nullCount++;
                        }
                    } else {
                        prev = _bytes.position;
                        if (nullCount > 0){
                            _bytes.writeByte(254);
                            _bytes.writeByte(nullCount);
                            nullCount = 0;
                        }
                        if (src){
                            writeValue(ns, ns.names[i], src, ns.globals[i]);
                            pos = (pos + (_bytes.position - prev));
                        } else {
                            nullCount++;
                        }
                    }
                    i++;
                }
                if (nullCount > 0){
                    _bytes.writeByte(254);
                    _bytes.writeByte(nullCount);
                    nullCount = 0;
                }
            }
            _bytes.writeByte(0xFF);
        }

        private static function writeValue(ns:ShaderContext, name:String, src:uint, global:ShaderBase):void
        {
            var pos:int = _bytes.position;
            var type:int = ((src >> 16) & 63);
            var size:int = (((src >> 22) & 3) + 1);
            var length:int = ((src >> 24) & 0xFF);
            var semantic:String = ((global) ? global.semantic : "");
            _bytes.writeByte(type);
            _bytes.writeUTF(name);
            _bytes.writeByte(size);
            _bytes.writeByte(length);
            _bytes.writeUTF(((semantic) || ("")));
        }

        private static function getToken(offset:int=0):ShaderToken
        {
            if ((_position + offset) >= _tokens.length){
                return (null);
            }
            return (_tokens[(_position + offset)]);
        }

        private static function pushSource(ns:ShaderContext, name:String, type:int, size:int, length:int, semantic:String=null, global:ShaderBase=null):uint
        {
            var f:ShaderBase = global;
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
            }
            var index:int = ns.sources.length;
            var source:uint = (((index | (type << 16)) | (Math.max(0, (size - 1)) << 22)) | (Math.max(1, length) << 24));
            ns.names[index] = name;
            ns.sources[index] = source;
            ns.globals[index] = f;
            ns.locals[index] = ShaderCompiler.alloc(name, source, f);
            return (source);
        }

        private static function pushString(n:String):void
        {
            var source:uint;
            var index:int = _namespace.getIndex(n);
            if (index != -1){
                source = _namespace.sources[index];
            } else {
                source = pushSource(_namespace, n, ZSLFlags.STRING, 1, 1);
            }
            write(ZSLFlags.GET, (source & 0xFFFF));
            _stack.push(_namespace.locals[(source & 0xFFFF)]);
        }

        private static function pushNumber(n:String):void
        {
            var source:uint;
            var index:int = _namespace.getIndex(n);
            if (index != -1){
                source = _namespace.sources[index];
            } else {
                source = pushSource(_namespace, n, ZSLFlags.CONST, 1, 1);
            }
            write(ZSLFlags.GET, (source & 0xFFFF));
            _stack.push(_namespace.locals[(source & 0xFFFF)]);
        }

        private static function getScopeOf(name:String, onlyScope:Boolean=false):ShaderContext
        {
            var n:int;
            var ns:ShaderContext = _namespace;
            if (onlyScope == false){
                if (ns.getIndex(name) != -1){
                    return (ns);
                }
                n = 0;
                while (n < _usingNS.length) {
                    if (_usingNS[n].getIndex(name) != -1){
                        return (_usingNS[n]);
                    }
                    n++;
                }
                while (ns.parent) {
                    ns = ns.parent;
                    if (ns.getIndex(name) != -1){
                        return (ns);
                    }
                }
            } else {
                if (getScopeByName(ns, name)){
                    return (ns);
                }
                n = 0;
                while (n < _usingNS.length) {
                    if (getScopeByName(_usingNS[n], name)){
                        return (_usingNS[n]);
                    }
                    n++;
                }
                while (ns.parent) {
                    ns = ns.parent;
                    if (getScopeByName(ns, name)){
                        return (ns);
                    }
                }
            }
            return (null);
        }

        private static function getScopeByName(ns:ShaderContext, name:String):ShaderContext
        {
            var i:int;
            while (i < ns.globals.length) {
                if ((((ns.globals[i] is ShaderContext)) && ((ns.globals[i].name == name)))){
                    return ((ns.globals[i] as ShaderContext));
                }
                i++;
            }
            return (null);
        }

        private static function goToNamespace(ns:ShaderContext, curr:ShaderContext=null):void
        {
            if ((((ns == _namespace)) || ((ns == curr)))){
                return;
            }
            if (!(curr)){
                curr = _namespace;
            }
            var parentCount:int;
            while (((!((curr == _topLevel))) && (!((curr == ns))))) {
                curr = curr.parent;
                parentCount++;
            }
            if (parentCount == 1){
                write(ZSLFlags.PARENT, curr);
            } else {
                write(ZSLFlags.PARENT_N, parentCount, curr);
            }
            if (curr != ns){
                goToFwNamespace(ns);
            }
        }

        private static function goToFwNamespace(ns:ShaderContext):void
        {
            if (ns != _topLevel){
                goToFwNamespace(ns.parent);
                write(ZSLFlags.GET_NS, ns.parent.globals.indexOf(ns), ns);
            }
        }

        private static function getSize(data:String):int
        {
            if (_data[data]){
                return (_data[data][0]);
            }
            return (0);
        }

        private static function getLength(data:String):int
        {
            if (_data[data]){
                return (_data[data][1]);
            }
            return (0);
        }

        private static function getTypeId(type:String, data:String=null):int
        {
            switch (type){
                case "void":
                    return (ZSLFlags.VOID);
                case "float":
                    return (ZSLFlags.TEMPORAL);
                case "param":
                    switch (data){
                        case "float4x4":
                        case "float4x3":
                        case "float3x3":
                            return (ZSLFlags.MATRIX);
                        default:
                            return (ZSLFlags.PARAM);
                    }
                case "const":
                    return (ZSLFlags.CONST);
                case "sampler2D":
                    return (ZSLFlags.SAMPLER2D);
                case "samplerCube":
                    return (ZSLFlags.SAMPLERCUBE);
                case "string":
                    return (ZSLFlags.STRING);
                case "input":
                    return (ZSLFlags.INPUT);
                case "interpolated":
                    return (ZSLFlags.INTERPOLATED);
                case "output":
                    return (ZSLFlags.OUTPUT);
                case "namespace":
                    return (ZSLFlags.NAMESPACE);
                case "function":
                    return (ZSLFlags.FUNCTION);
                case "technique":
                    return (ZSLFlags.TECHNIQUE);
                case "pass":
                    return (ZSLFlags.PASS);
                case "surface":
                    return (ZSLFlags.SURFACE);
            }
            error(getToken(), (type + " - ERROR!"));
            return (0);
        }

        private static function getLast():uint
        {
            if (_stack.length == 0){
                error(getToken(), "Stack overflow.");
            }
            return (_stack[(_stack.length - 1)]);
        }

        private static function duplicate():void
        {
            write(ZSLFlags.DUP);
            _stack.push(getLast());
        }

        private static function includeScope(ns:ShaderContext):void
        {
            if (ns.parent){
                includeScope(ns.parent);
            }
            if (_includeScopes[ns]){
                return;
            }
            var i:int = ns.paramCount;
            while (i < ns.sources.length) {
                if (ns.sources[i]){
                    ns.locals[i] = alloc(ns.names[i], ns.sources[i], ns.globals[i]);
                }
                i++;
            }
            _includeScopes[ns] = true;
            if (_includeDependences != INCLUDE_NONE){
                includeDependences(ns);
            }
        }

        static function includeDependences(scope:ShaderContext):void
        {
            var code:ByteArray;
            var i:int;
            var ns:ShaderContext;
            var src1:uint;
            var src0:uint;
            var dest:uint;
            var id:int;
            var _local9:ShaderContext;
            var _local10:int;
            if (_includeDependences == INCLUDE_NONE){
                return;
            }
            if ((((_includeDependences == INCLUDE_TOPLEVEL)) && (!((scope.varType == ZSLFlags.FUNCTION))))){
                return;
            }
            code = scope.code;
            code.position = 0;
            _dependences[scope] = true;
            while (code.bytesAvailable > 0) {
                if (!(ns)){
                    ns = scope;
                }
                id = code.readUnsignedByte();
                switch (id){
                    case ZSLFlags.GET:
                        code.readUnsignedByte();
                        ns = scope;
                        break;
                    case ZSLFlags.CALL:
                        _local9 = (ns.globals[code.readUnsignedByte()] as ShaderContext);
                        includeDependences(_local9);
                        ns = scope;
                        break;
                    case ZSLFlags.PROP:
                        code.readUTF();
                        break;
                    case ZSLFlags.META:
                        code.readUTF();
                        code.readUTF();
                        break;
                    case ZSLFlags.PARENT:
                        ns = ns.parent;
                        break;
                    case ZSLFlags.PARENT_N:
                        _local10 = code.readUnsignedByte();
                        while (_local10--) {
                            ns = ns.parent;
                        }
                        break;
                    case ZSLFlags.GET_NS:
                        ns = (ns.globals[code.readUnsignedByte()] as ShaderContext);
                        includeDependences(ns);
                        break;
                    case ZSLFlags.AGAL:
                        code.readUnsignedByte();
                        code.readUnsignedByte();
                        break;
                    case ZSLFlags.IF:
                    case ZSLFlags.JUMP:
                        code.readShort();
                        break;
                    case ZSLFlags.DEBUG:
                        code.readUnsignedByte();
                        break;
                    case ZSLFlags.DEBUG_D:
                        code.readUnsignedShort();
                        code.readUnsignedShort();
                        break;
                    case ZSLFlags.RET:
                        break;
                }
            }
        }

        private static function validateWriteMask(t:ShaderToken, dest:uint):Boolean
        {
            var d:int;
            var m:int;
            var mask:int = ((dest >> 16) & 0xFF);
            var size:int = (((dest >> 24) & 3) + 1);
            var i:int;
            while (i < size) {
                d = (1 << ((mask >> (i * 2)) & 3));
                if ((m & d)){
                    error(t, (("Invalid write mask '" + ShaderCompiler.maskToStr(mask, size)) + "', components can not be repeteated."));
                }
                m = (m | d);
                i++;
            }
            return (true);
        }

        private static function registerToStr(register:uint, mask:int=-1, size:int=-1):String
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
            var type:String = ShaderCompiler.typeToStr(ShaderCompiler.getRegisterType(register));
            if (indirectReg){
                return ((((ShaderCompiler.names[index] + "[") + registerToStr(indirectReg)) + "]"));
            }
            return (ShaderCompiler.names[index]);
        }

        private static function isFloat(type:uint):int
        {
            return ((((((((type >= ZSLFlags.TEMPORAL)) && ((type <= ZSLFlags.MATRIX)))) || ((((type >= ZSLFlags.INPUT)) && ((type <= ZSLFlags.OUTPUT)))))) ? type : 0));
        }

        private static function registerStrType(register:uint):String
        {
            var size:int;
            if (register == 0){
                return ("");
            }
            var index:int = (register & 0xFFFF);
            var type:int = ShaderCompiler.getRegisterType(register);
            if (isFloat(type)){
                size = ShaderCompiler.getRegisterSize(register);
                return (("float" + (((size > 1)) ? size : "")));
            }
            return (ShaderCompiler.typeToStr(type));
        }

        private static function sourceStrType(source:uint):String
        {
            var size:int;
            var type:int = ((source >> 16) & 63);
            if (isFloat(type)){
                size = (((source >> 22) & 3) + 1);
                return (("float" + (((size > 1)) ? size : "")));
            }
            return (ShaderCompiler.typeToStr(type));
        }

        private static function argsToStr(registers:Vector.<uint>, length:int):String
        {
            var out:String = "";
            var i:int;
            while (i < length) {
                out = (out + (registerStrType(registers[i]) + ", "));
                i++;
            }
            return (out.substr(0, -2));
        }

        private static function expected(ch:String, msg:String=null):void
        {
            while ((((_position < _tokens.length)) && ((getToken().text == null)))) {
                _position++;
            }
            if (_position >= _tokens.length){
                _position = (_tokens.length - 1);
            }
            if (getToken().text != ch){
                error(getToken(), ((msg) || ((((("Expected '" + ch) + "' but found '") + getToken().text) + "'."))));
            }
        }

        private static function log(... _args):void
        {
            trace(String(_args).replace(new RegExp(",", "ig"), " "));
        }

        private static function verbose(position:int, name:String, ... _args):void
        {
            var space:String = "";
            var ns:ShaderContext = _namespace;
            while (ns.parent) {
                ns = ns.parent;
                space = (space + "    ");
            }
            var desc:String = ((position + " ") + name);
            while (desc.length < 20) {
                desc = (desc + " ");
            }
            if (_debug){
                trace(((space + desc) + String(_args).replace(new RegExp(",", "ig"), " ")));
            }
        }

        private static function error(t:ShaderToken, message:String):void
        {
			
            throw (new ShaderError(message, t.line, t.pos));
			
			return;
        }


    }
}

