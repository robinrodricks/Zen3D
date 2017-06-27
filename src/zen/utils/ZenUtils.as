package zen.utils {
	import flash.display.*;
	import flash.display3D.*;
	import flash.display3D.textures.*;
	import flash.geom.*;
	import zen.materials.*;
	import zen.display.*;
	import zen.shaders.*;
	import zen.shaders.textures.*;
	import zen.utils.*;
	import flash.filesystem.*;
	import flash.utils.*;
	import zen.display.*;
	
	public class ZenUtils {
		
		// RENDERING UTILS
		
		private static var _initDone:Boolean = false;
		
		public static function init():void {
			
			if (!_initDone) {
				_initDone = true;
				
				ShaderCompiler.init();
				ShaderMaterial.init();
				ShaderParser.init();
				
				while (h < 8) {
					v = 0;
					while (v < 8) {
						nullBitmapData.fillRect(new Rectangle((h * 8), (v * 8), 8, 8), ((((((h % 2) + (v % 2)) % 2) == 0)) ? 0xFFFFFFFF : 4289769648));
						v++;
					}
					h++;
				}
			}
		}
		
		public static var global:Matrix3D = new Matrix3D();
		public static var invGlobal:Matrix3D = new Matrix3D();
		public static var view:Matrix3D = new Matrix3D();
		public static var cameraGlobal:Matrix3D = new Matrix3D();
		public static var viewProj:Matrix3D = new Matrix3D();
		public static var worldViewProj:Matrix3D = new Matrix3D();
		public static var worldView:Matrix3D = new Matrix3D();
		public static var proj:Matrix3D = new Matrix3D();
		public static var special0:Matrix3D = new Matrix3D();
		public static var special1:Matrix3D = new Matrix3D();
		public static var special2:Matrix3D = new Matrix3D();
		public static var temporal0:Matrix3D = new Matrix3D();
		public static var temporal1:Matrix3D = new Matrix3D();
		public static var bones:Vector.<Number> = new Vector.<Number>(((maxBonesPerSurface * 4) * 3));
		public static var ambient:Vector.<Number> = new Vector.<Number>(4, true);
		public static var random:Vector.<Number> = new Vector.<Number>(4, true);
		public static var time:Vector.<Number> = new Vector.<Number>(4, true);
		public static var sin_time:Vector.<Number> = new Vector.<Number>(4, true);
		public static var cos_time:Vector.<Number> = new Vector.<Number>(4, true);
		public static var mouse:Vector.<Number> = new Vector.<Number>(4, true);
		public static var cam:Vector.<Number> = new Vector.<Number>(4, true);
		public static var nearFar:Vector.<Number> = new Vector.<Number>(4, true);
		public static var screen:Vector.<Number> = new Vector.<Number>(4, true);
		public static var dirLight:Vector.<Number> = new Vector.<Number>(4);
		public static var dirColor:Vector.<Number> = new Vector.<Number>(4);
		public static var pointLight:Vector.<Number> = new Vector.<Number>();
		public static var pointColor:Vector.<Number> = new Vector.<Number>();
		
		// VARS
		public static var profile:String = "baseline";
		public static var scene:Zen3D;
		public static var camera:ZenCamera;
		public static var viewPort:Rectangle;
		public static var forceTextureInitialization:Boolean = true;
		public static var drawCalls:int;
		public static var trianglesDrawn:int;
		public static var objectsDrawn:int;
		private static var _maxBonesPerVertex:int = 2;
		public static var maxBonesPerSurface:int = 34;
		public static var nullBitmapData:BitmapData = new BitmapData(64, 64, true, 0xFFFFFFFF);
		private static var h:int = 0;
		private static var v:int;
		public static var maxTextureSize:int = 0x0800;
		public static var frameCount:int;
		public static var defaultSourceFactor:String = Context3DBlendFactor.ONE;//"one"
		public static var defaultDestFactor:String = Context3DBlendFactor.ZERO;//"zero"
		public static var defaultCullFace:String = Context3DTriangleFace.BACK;//"back"
		public static var usedSamples:int;
		public static var usedBuffers:int;
		public static var lastMaterial:ShaderMaterialBase;
		public static var invertCullFace:Boolean = false;
		public static var ignoreStates:Boolean = false;
		public static var context:Context3D;
		public static var samplers:Vector.<TextureBase> = new Vector.<TextureBase>(8, true);
		public static var program:Program3D;
		public static var cullFace:String;
		public static var sourceFactor:String;
		public static var destFactor:String;
		public static var depthWrite:Boolean;
		public static var depthCompare:String;
		
		public static function get maxBonesPerVertex():int {
			return (_maxBonesPerVertex);
		}
		
		public static function set maxBonesPerVertex(value:int):void {
			if ((((value < 1)) || ((value > 4)))) {
				
				throw new Error(("maxBonesPerVertex should be from 1 to 4 but was set to " + value));
				
				return;
			}
			_maxBonesPerVertex = value;
		}
		
		public static function setTextureAt(i:int, texture:TextureBase):void {
			if (samplers[i] != texture) {
				samplers[i] = texture;
				context.setTextureAt(i, texture);
			}
		}
		
		public static function setProgram(p:Program3D):void {
			if (program != p) {
				program = p;
				context.setProgram(p);
			}
		}
		
		public static function setCulling(triangleFace:String):void {
			if (cullFace != triangleFace) {
				cullFace = triangleFace;
				context.setCulling(triangleFace);
			}
		}
		
		public static function setDepthTest(depthMask:Boolean, passCompareMode:String):void {
			if (((!((depthWrite == depthMask))) || (!((passCompareMode == depthCompare))))) {
				depthWrite = depthMask;
				depthCompare = passCompareMode;
				context.setDepthTest(depthMask, passCompareMode);
			}
		}
		
		public static function setBlendFactors(source:String, destination:String):void {
			if (((!((sourceFactor == source))) || (!((destination == destFactor))))) {
				sourceFactor = source;
				destFactor = destination;
				context.setBlendFactors(source, destination);
			}
		}
		
		// FILE UTILS
		
		public static function LoadTextFile(filePath:String, maxBytes:int = 0):String {
			
			// ensure the file exists
			var file:File = new File(filePath);
			if (file.exists) {
				
				// connect to the file
				var stream:FileStream = new FileStream();
				stream.open(file, FileMode.READ);
				
				// read data as string
				if (maxBytes == 0) maxBytes = stream.bytesAvailable;
				var fileData:String = stream.readUTFBytes(maxBytes);
				stream.close();
				return fileData;
			}
			return null;
		}
		
		public static function LoadBinaryFile(filePath:String, maxBytes:int = 0):ByteArray {
			
			// ensure the file exists
			var file:File = new File(filePath);
			if (file.exists) {
				
				// connect to the file
				var stream:FileStream = new FileStream();
				stream.open(file, FileMode.READ);
				
				// read data as bytes
				var fileData:ByteArray = new ByteArray();
				if (maxBytes == 0) maxBytes = fileData.bytesAvailable;
				stream.readBytes(fileData, 0, maxBytes);
				stream.close();
				return fileData;
			}
			return null;
		}
		
		// STRING UTILS
		
		public static function Trim(string:String):String {
			
			// exit if blank
			if (string.length == 0) {
				return string;
			}
			
			// TRIM FROM BOTH SIDES
			var length:int = string.length;
			for (var startPos:int = 0; startPos < length; ++startPos) {
				var cc:int = string.charCodeAt(startPos);
				if (cc < 0x20) {
				} else {
					break;
				}
			}
			for (var endPos:int = string.length - 1; endPos >= startPos; --endPos) {
				var cc:int = string.charCodeAt(endPos);
				if (cc < 0x20) {
				} else {
					break;
				}
			}
			
			// MEM FIX: exit if no need to trim
			if (startPos == 0 && endPos == (length - 1)) {
				return string;
			}
			
			return string.substring(startPos, endPos + 1);
		}
		
		public static function SplitLines(text:String):Array {
			var lines:Array = text.split("\r\n").join("\n").split("\r").join("\n").split("\n");
			return lines;
		}
		
		public static function BeginsWith(text:String, prefix:String, caseSensitive:Boolean = true):Boolean {
			var l1:int = text.length;
			var l2:int = prefix.length;
			
			// check quickly if same/less length
			if (l1 < l2) {
				return false;
			}
			if (l1 == l2) {
				if (caseSensitive) {
					return text == prefix;
				}
				return text.toLowerCase() == prefix.toLowerCase();
			}
			
			// check using substring if main string longer
			if (caseSensitive) {
				//return text.substr(0, l2) == prefix;
				return text.lastIndexOf(prefix, 0) == 0;
			}
			return text.substr(0, l2).toLowerCase() == prefix.toLowerCase();
		}
		
		public static function AfterFirst(text:String, find:String, startAt:int = 0):String {
			if (text == null) {
				return '';
			}
			if (text.length == 0) {
				return text;
			}
			var idx:int = text.indexOf(find, startAt);
			if (idx == -1) {
				return '';
			}
			idx += find.length;
			return text.substr(idx);
		}
		
		public static function AfterLast(text:String, find:String, returnAll:Boolean = false):String {
			var idx:int = text.lastIndexOf(find);
			if (idx == -1) {
				return returnAll ? text : '';
			}
			idx += find.length;
			return text.substr(idx);
		}
		
		public static function ToInt(text:String):int {
			if (text == null || text == "") {
				return 0;
			}
			
			// if hex
			if (text.substr(0, 2) == "0x") {
				return int("0x" + text.substr(2).toUpperCase());
			}
			if (text.charAt(0) == "#") {
				return int("0x" + text.substr(1).toUpperCase());
			}
			
			// if decimal
			return parseInt(text);
		}
		
		public static function ToNumber(text:String):Number {
			
			// return 0 if null
			if (text == null || text == "") {
				return 0;
			}
			
			var num:Number = parseFloat(text);
			
			// return 0 if NaN
			if (num != num) {
				return 0;
			}
			
			return num;
		}
		
		public static function CalcTriNormal(point0:Vector3D, point1:Vector3D, point2:Vector3D, out:Vector3D = null, returnNullIf0Len:Boolean = false):Vector3D {
			
			if (out == null) {
				out = new Vector3D();
			}
			
			// calculate normal of a triangle
			var x:Number = (point1.y - point0.y) * (point2.z - point0.z) - (point1.z - point0.z) * (point2.y - point0.y);
			var y:Number = (point1.z - point0.z) * (point2.x - point0.x) - (point1.x - point0.x) * (point2.z - point0.z);
			var z:Number = (point1.x - point0.x) * (point2.y - point0.y) - (point1.y - point0.y) * (point2.x - point0.x);
			
			// convert to unit vector
			var nlen:Number;
			if ((nlen = Math.sqrt(x * x + y * y + z * z)) == 0) {
				if (returnNullIf0Len) {
					return null;
				}
				out.x = 0;
				out.y = 0;
				out.z = 0;
				return out;// throw new Error("Cannot calculate normal since triangle has an area of 0");
			}
			out.x = x / nlen;
			out.y = y / nlen;
			out.z = z / nlen;
			return out;
		}
		
		public static function SetExt(path:String, newExt:String = "txt"):String {
			
			var ext:int = path.lastIndexOf(".");
			if (ext > -1) {
				ext = path.length - ext;
			}
			path = path.substr(0, path.length - ext);
			
			return (path + "." + newExt);
		}
		
		public static function NewBitmap(width:int = 100, height:int = 100, transparent:Boolean = true, fill:uint = 0xFFFFFF, alpha:int = 0xFF):BitmapData {
			var fillColor:uint = uint(uint(uint(alpha) << 24) | fill);
			return new BitmapData(width, height, transparent, fillColor);
		}
		
		// COLOR UTILS
		
		public static function ColorToVector(color:int, out:Vector3D = null):Vector3D {
			if (out == null) {
				out = new Vector3D();
			}
			out.z = ((color & 0xFF) / 0xFF);
			out.y = (((color >> 8) & 0xFF) / 0xFF);
			out.x = (((color >> 16) & 0xFF) / 0xFF);
			return out;
		}
		
		public static function ColorFromVector(vector:Vector3D):int {
			return (int(vector.x * 0xFF) << 16) | (int(vector.y * 0xFF) << 8) | int(vector.z * 0xFF);
		}
		
		public static function ColorFromVector2(x:Number, y:Number, z:Number):int {
			return (int(x * 0xFF) << 16) | (int(y * 0xFF) << 8) | int(z * 0xFF);
		}
	
	}

}