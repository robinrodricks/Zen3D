package zen.filters.color {
	import zen.shaders.ShaderFilter;
	import flash.utils.ByteArray;
	
	import zen.shaders.*;
	import flash.utils.*;
	
	/** A material filter that tints the face by the given color */
	public class SelfColorFilter extends ShaderFilter {
		
		[Embed(source = "../../utils/assets/effects/SelfColorFilter.data", mimeType = "application/octet-stream")]
		private static var compiledShader:Class;
		private static var data:ByteArray;
		
		private var _color:Vector.<Number>;
		private var _level:Number;
		
		public function SelfColorFilter(color:int = 0, level:Number = 1) {
			if (data == null) {
				data = new compiledShader();
			}
			
			this._color = new Vector.<Number>(4);
			super(data, "");
			this._level = level;
			params.selfColor.value = this._color;
			this.color = color;
		}
		
		public function set color(value:uint):void {
			var a:Number = ((uint((value >> 24)) & 0xFF) / 0xFF);
			var r:Number = ((uint((value >> 16)) & 0xFF) / 0xFF);
			var g:Number = ((uint((value >> 8)) & 0xFF) / 0xFF);
			var b:Number = ((uint((value >> 0)) & 0xFF) / 0xFF);
			this._color[0] = r;
			this._color[1] = g;
			this._color[2] = b;
			this._color[3] = (1 * this._level);
		}
		
		public function get color():uint {
			return ((((((this._color[3] * 0xFF) << 24) ^ ((this._color[0] * 0xFF) << 16)) ^ ((this._color[1] * 0xFF) << 8)) ^ (this._color[2] * 0xFF)));
		}
		
		public function get level():Number {
			return (this._level);
		}
		
		public function set level(value:Number):void {
			this._level = value;
			this.color = this.color;
		}
	
	}
}

