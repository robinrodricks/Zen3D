package zen.filters.maps {
	import zen.enums.*;
	import zen.display.*;
	import zen.materials.*;
	import zen.shaders.*;
	import zen.shaders.textures.*;
	import zen.shaders.core.*;
	import flash.display.*;
	import flash.events.*;
	import flash.utils.*;
	
	/** A material filter that displays a bitmap as the texture */
	public class TextureMapFilter extends ShaderFilter {
		
		[Embed(source = "../../utils/assets/effects/TextureMapFilter.data", mimeType = "application/octet-stream")]
		private static var compiledShader:Class;
		
		private static var data:ByteArray;
		
		public function TextureMapFilter(texture:ZenTexture = null, channel:int = 0, blendMode:String = "multiply", alpha:Number = 1) {
			if (data == null) {
				data = new compiledShader();
			}
			
			super(data, blendMode, "main");
			params.alpha.value = new Vector.<Number>();
			params.channel.value = new Vector.<Number>();
			this.channel = channel;
			this.alpha = alpha;
			this.texture = texture;
		}
		
		override public function init(material:ShaderMaterialBase, index:int, pass:int):void {
			if (((params.mask.value) && ((params.mask.value[0] > 0)))) {
				material.flags = (material.flags | MaterialFlags.MASK);
			}
		}
		
		public function get alpha():Number {
			return (params.alpha.value[0]);
		}
		
		public function set alpha(value:Number):void {
			params.alpha.value[0] = value;
		}
		
		private function setParamValue(param:ShaderVar, index:int, value:Number, def:Array):void {
			if (!(param.value)) {
				param.value = Vector.<Number>(def);
			}
			param.value[index] = value;
		}
		
		public function get offsetX():Number {
			return (params.offset.value[0]);
		}
		
		public function set offsetX(value:Number):void {
			this.setParamValue(params.offset, 0, value, [0, 0, 0, 0]);
		}
		
		public function get offsetY():Number {
			return (params.offset.value[1]);
		}
		
		public function set offsetY(value:Number):void {
			this.setParamValue(params.offset, 1, value, [0, 0, 0, 0]);
		}
		
		public function get repeatX():Number {
			return (params.repeat.value[0]);
		}
		
		public function set repeatX(value:Number):void {
			this.setParamValue(params.repeat, 0, value, [1, 1, 1, 1]);
		}
		
		public function get repeatY():Number {
			return (params.repeat.value[1]);
		}
		
		public function set repeatY(value:Number):void {
			this.setParamValue(params.repeat, 1, value, [1, 1, 1, 1]);
		}
		
		public function get texture():ZenTexture {
			return (params.texture.value);
		}
		
		public function set texture(value:ZenTexture):void {
			params.texture.value = value;
		}
		
		public function get channel():int {
			return (params.channel.value[0]);
		}
		
		public function set channel(value:int):void {
			this.setParamValue(params.channel, 0, value, [0, 0, 0, 0]);
		}
	
	}
}

