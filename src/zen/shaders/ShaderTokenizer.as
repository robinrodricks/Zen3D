package zen.shaders {
	
	import zen.shaders.core.*;
	import zen.shaders.objects.*;
	import zen.enums.*;
	import zen.shaders.ShaderError;
	import zen.shaders.*;
	
	public class ShaderTokenizer {
		
		private static const _preprocesor:Array = ["#debug", "#dependences", "#semantic", "#define", "#if", "#else", "#elseif", "#for", "#debug", "#include", "#exclude", "#topLevel"];
		private static const _reserved:Array = ["trace", "agal", "null", "this", "parent", "return", "input", "interpolated", "param", "const", "namespace", "technique", "pass", "for", "if", "else", "use", "output"];
		private static const _keywords:Array = ["float4x4", "float3x3", "float4x3", "float4", "float3", "float2", "float", "sampler2D", "sampler3D", "surface", "string", "void"];
		private static const _operators:Array = ["++", "--", "+=", "-=", "*=", "/=", "<<", ">>", "&&", "||", "<=", ">=", "==", "!=", ">", "<", "&", "|", "^", "~", "!", "$", "+", "-", "*", "/", ".", "?", ",", ":", "=", ";", "(", ")", "{", "}", "[", "]"];
		
		private static var _char:int;
		private static var _source:String;
		private static var _tokens:Vector.<ShaderToken>;
		private static var _definitions:Array = [];
		private static var _lineAt:int = 0;
		
		public static function parse(source:String):Vector.<ShaderToken> {
			var c:String;
			var t:ShaderToken;
			var s:String;
			_tokens = new Vector.<ShaderToken>();
			_source = source.replace(new RegExp("\\r", "g"), "");
			_source = (_source + "\n");
			_lineAt = 0;
			_char = 0;
			while (_char < _source.length) {
				c = _source.charAt(_char);
				t = null;
				t = isComment(_char);
				if (t == null) {
					t = isTokenArray(_char, _preprocesor, TokenType.PREPROCESOR);
					if (!t) {
						t = isTokenArray(_char, _reserved, TokenType.RESERVED);
						if (!t) {
							t = isTokenArray(_char, _keywords, TokenType.KEYWORD);
							if (!t) {
								t = isString(_char);
								if (!t) {
									t = isWord(_char);
									if (!t) {
										t = isTokenArray(_char, _operators, TokenType.OPERATOR);
										if (!t) {
											if (isNewLine(c)) {
												_lineAt++;
											} else {
												if (c != "\t") {
													if (c != String.fromCharCode(32)) {
														error(_char, (("Unexpected character '" + c) + "'."));
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
				if (t) {
					if (t.type != TokenType.COMMENT) {
						_tokens.push(t);
					}
					if (t.type == TokenType.STRING) {
						_char = (_char + 2);
					}
					_char = (_char + t.text.length);
				} else {
					_char++;
				}
			}
			_tokens.push(new ShaderToken("End of File", TokenType.OPERATOR, getLinesAt(_char), getPositionAt(_char)));
			var r:Vector.<ShaderToken> = _tokens;
			_tokens = null;
			_source = null;
			return (r);
		}
		
		private static function isTokenArray(start:int, array:Array, type:String):ShaderToken {
			var s:String;
			var t:ShaderToken;
			for each (s in array) {
				t = isToken(start, s, type);
				if (t) {
					return (t);
				}
			}
			return (null);
		}
		
		private static function isToken(start:int, text:String, type:String):ShaderToken {
			if (_source.substr(start, text.length) == text) {
				if (((!((type == TokenType.OPERATOR))) && (isDigitOrLetter(_source.charAt((_char + text.length)))))) {
					return (null);
				}
				return (new ShaderToken(text, type, getLinesAt(start), getPositionAt(start)));
			}
			return (null);
		}
		
		private static function isWord(start:int):ShaderToken {
			var value:Number;
			var ch:String = _source.charAt(start);
			if (((!(isDigitOrLetter(ch))) && (!((ch == "."))))) {
				return (null);
			}
			var t:String = "";
			var pos:int = start;
			while (((((isDigitOrLetter(ch)) || ((ch == ".")))) || ((ch.toLowerCase() == "x")))) {
				t = (t + ch);
				ch = _source.charAt(++start);
			}
			if (t.length > 0) {
				if (((isDigit(t.charAt(0))) || ((t.charAt(0) == ".")))) {
					value = Number(t);
					if (isNaN(value)) {
						if (t.charAt(0) == ".") {
							return (new ShaderToken(".", TokenType.OPERATOR, getLinesAt(pos), getPositionAt(pos)));
						}
						error((start - t.length), "Invalid number value.");
					}
					return (new ShaderToken(t, TokenType.NUMBER, getLinesAt(pos), getPositionAt(pos)));
				}
				if (t.indexOf(".") != -1) {
					t = t.substr(0, t.indexOf("."));
				}
				return (new ShaderToken(t, TokenType.WORD, getLinesAt(pos), getPositionAt(pos)));
			}
			return (null);
		}
		
		private static function isComment(start:int):ShaderToken {
			var i:int;
			var ch:String = _source.substr(start, 2);
			var t:String = "";
			if (ch == "//") {
				start++;
				while (!(isNewLine(ch))) {
					ch = _source.charAt(++start);
					t = (t + ch);
				}
				return (new ShaderToken((t + ch), TokenType.COMMENT, getLinesAt(start), getPositionAt(start)));
			}
			if (ch == "/*") {
				i = _source.indexOf("*/", start);
				if (i == -1) {
					i = (_source.length - 2);
				}
				_lineAt = (_lineAt + _source.substr(start, (i - start)).match(new RegExp("\\n", "g")).length);
				return (new ShaderToken(_source.substring(start, (i + 2)), TokenType.COMMENT, getLinesAt(start), getPositionAt(start)));
			}
			return (null);
		}
		
		private static function isString(start:int):ShaderToken {
			var i:int;
			if (_source.charAt(start) == '"') {
				i = _source.indexOf('"', (start + 1));
				if (i == -1) {
					error(start, "A string literal must be terminated.");
				}
				return (new ShaderToken(_source.substring((start + 1), i), TokenType.STRING, getLinesAt(start), getPositionAt(start)));
			}
			return (null);
		}
		
		private static function isDigit(ch:String):Boolean {
			return ((((ch >= "0")) && ((ch <= "9"))));
		}
		
		private static function isLetter(ch:String):Boolean {
			return ((((((((ch >= "A")) && ((ch <= "Z")))) || ((((ch >= "a")) && ((ch <= "z")))))) || ((ch == "_"))));
		}
		
		private static function isNewLine(ch:String):Boolean {
			return ((((ch == "\r")) || ((ch == "\n"))));
		}
		
		private static function isDigitOrLetter(ch:String):Boolean {
			return (((isDigit(ch)) || (isLetter(ch))));
		}
		
		private static function getLinesAt(start:int):int {
			return ((_lineAt + 1));
		}
		
		private static function getPositionAt(start:int):int {
			return ((start - _source.lastIndexOf("\n", start)));
		}
		
		private static function error(char:int, message:String):void {
			
			throw(new ShaderError(message, getLinesAt(char), getPositionAt(char)));
			
			return;
		}
	
	}
}

