package zen.display {
	import zen.display.*;
	import zen.display.*;
	import zen.materials.*;
	import zen.enums.*;
	import flash.geom.*;
	import flash.display.*;
	import zen.filters.color.*;
	import zen.utils.*;
	import zen.geom.*;
	import zen.shaders.textures.*;
	
	/** A 3D directional or point light that supports various lighting configurations.
	   Only objects whose materials have a LightFilter will respond to lighting. */
	public class ZenLight extends ZenObject {
		
		private static const _position:Vector3D = new Vector3D();
		
		public var type:int;
		public var color:Vector3D;
		public var radius:Number = 0;
		public var attenuation:Number = 100;
		public var infinite:Boolean = true;
		public var multiplier:Number = 1;
		public var sample:BitmapData;
		
		public function ZenLight(name:String = "", type:int = 1) {
			this.sample = new BitmapData(LightFilter.lightSamples, LightFilter.lightSamplesRate, false, 0);
			this.color = new Vector3D(1, 1, 1);
			this.type = type;
			this.setParams(0xFFFFFF, 100, 1, 1, true);
			super(name);
		}
		
		override public function dispose():void {
			// if already disposed
			if (sample == null) {
				return;
			}
			
			super.dispose();
			this.sample.dispose();
			this.sample = null;
		}
		
		override public function clone():ZenObject {
			var c:ZenObject;
			var l:ZenLight = new ZenLight(name, this.type);
			l.copyFrom(this);
			l.setParams(((((this.color.x * 0xFF) << 16) ^ ((this.color.y * 0xFF) << 8)) ^ (this.color.z * 0xFF)), this.radius, this.attenuation, this.multiplier, this.infinite);
			for each (c in children) {
				if (!(c.lock)) {
					l.addChild(c.clone());
				}
			}
			return (l);
		}
		
		override public function get inView():Boolean {
			var min:Number = -1000000;
			var max:Number = 1000000;
			if (((this.infinite) || ((this.type == LightType.DIRECTIONAL)))) {
				priority = min;
				return (true);
			}
			priority = max;
			world.copyColumnTo(3, _position);
			M3D.transformVector(ZenUtils.view, _position, _position);
			var zoom:Number = ((1 / ZenUtils.camera.zoom) / _position.z);
			var ratio:Number = ZenUtils.camera.aspectRatio;
			if (_position.length > this.radius) {
				if (((_position.x + this.radius) * zoom) < -1) {
					return (false);
				}
				if (((_position.x - this.radius) * zoom) > 1) {
					return (false);
				}
				if ((((_position.y + this.radius) * zoom) * ratio) < -1) {
					return (false);
				}
				if ((((_position.y - this.radius) * zoom) * ratio) > 1) {
					return (false);
				}
				if ((_position.z - this.radius) > ZenUtils.camera.far) {
					return (false);
				}
				if ((_position.z + this.radius) < ZenUtils.camera.near) {
					return (false);
				}
			}
			priority = ((_position.z / ZenUtils.camera.far) * 100000);
			return (true);
		}
		
		override public function draw(includeChildren:Boolean = true, material:ShaderMaterialBase = null):void {
			var child:ZenObject;
			if ((_eventFlags & ObjectFlags.ENTER_DRAW_FLAG)) {
				dispatchEvent(_enterDrawEvent);
			}
			if (includeChildren) {
				for each (child in children) {
					child.draw(true, material);
				}
			}
			if (this.inView) {
			}
			if ((_eventFlags & ObjectFlags.EXIT_DRAW_FLAG)) {
				dispatchEvent(_exitDrawEvent);
			}
		}
		
		public function setParams(color:int = 0xFFFFFF, radius:Number = 0, attenuation:Number = 1, multiplier:Number = 1, infinite:Boolean = false):void {
			if (this.type == LightType.DIRECTIONAL) {
				infinite = true;
			}
			this.radius = radius;
			this.attenuation = attenuation;
			this.color.x = ((color & 0xFF0000) >> 16);
			this.color.y = ((color & 0xFF00) >> 8);
			this.color.z = (color & 0xFF);
			this.color.scaleBy((1 / 0xFF));
			this.infinite = infinite;
			this.multiplier = multiplier;
			var colors:Array = [color, color, color, 0];
			var ratios:Array = [];
			var r:Number = (radius * radius);
			ratios.push(0, 0);
			if (infinite) {
				ratios.push(0xFF, 0xFF);
			} else {
				ratios.push(((((((1 - attenuation) * (1 - attenuation)) * radius) * radius) / r) * 253));
				ratios.push((((radius * radius) / r) * 253));
				if (ratios[2] >= ratios[3]) {
					ratios[2] = (ratios[3] - 1);
				}
			}
			this.setColors(this.sample, colors, null, ratios);
			var m:Number = (multiplier / 5);
			this.sample.colorTransform(this.sample.rect, new ColorTransform(m, m, m));
		}
		
		private function setColors(bmp:BitmapData, colors:Array, alphas:Array = null, ratios:Array = null):void {
			var shape:Shape = new Shape();
			var matrix:Matrix = new Matrix();
			matrix.createGradientBox(bmp.width, bmp.height);
			shape.graphics.beginGradientFill(GradientType.LINEAR, colors, alphas, ratios, matrix, SpreadMethod.PAD, InterpolationMethod.RGB);
			shape.graphics.drawRect(0, 0, bmp.width, bmp.height);
			bmp.draw(shape);
		}
		
		public function setColor(colorInt:int):void {
			ZenUtils.ColorToVector(colorInt, color);
		}
	
	}
}

