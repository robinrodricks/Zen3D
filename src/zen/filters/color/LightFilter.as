package zen.filters.color {
	import zen.materials.*;
	import zen.enums.*;
	import zen.display.*;
	import flash.geom.*;
	import zen.shaders.*;
	import zen.shaders.textures.ShaderMaterial;
	import zen.shaders.core.*;
	import zen.utils.*;
	import zen.display.*;
	import flash.display.*;
	import flash.display3D.*;
	import flash.utils.*;
	
	/** A material filter that responds to scene lighting */
	public class LightFilter extends ShaderFilter {
		
		public static const LINEAR:String = "linear";
		public static const SAMPLED:String = "sampled";
		public static const PER_VERTEX:String = "perVertex";
		public static const PHONG:String = "phong";
		public static const NO_LIGHTS:String = "noLights";
		
		[Embed(source = "../../utils/assets/effects/LightFilter.data", mimeType = "application/octet-stream")]
		private static var compiledShader:Class;
		private static var data:ByteArray;
		
		[Embed(source = "../../utils/assets/effects/LightFilter_DiskFilter.data", mimeType = "application/octet-stream")]
		private static var DiskFilter:Class;
		public static var lightSamples:int = 128;
		public static var lightSamplesRate:int = 4;
		
		public var defaultLight:ZenLight;
		public var ambientColor:Vector3D;
		public var list:Vector.<ZenLight>;
		private var _temp:Vector3D;
		private var _intensity:Number = 1;
		private var _saturation:Number = 5;
		private var _maxPointLights:int = 0;
		private var _maxDirectionalLights:int = 1;
		private var _dirLight:Vector.<Number>;
		private var _dirColor:Vector.<Number>;
		private var _pointLight:Vector.<Number>;
		private var _pointColor:Vector.<Number>;
		private var _pDirLight:ShaderVar;
		private var _pDirColor:ShaderVar;
		private var _pPointLight:ShaderVar;
		private var _pPointColor:ShaderVar;
		private var _texturePoint:Point;
		private var _textureRect:Rectangle;
		private var _texture:ZenTexture;
		private var _textureOffset:ShaderVar;
		private var _diskFilter:ShaderMaterial;
		private var _filterMapTexture:ZenTexture;
		private var _shadowMapTexture:ZenTexture;
		public var enableShadowsFiltering:Boolean = true;
		public var shadowsFiltering:Number = 10;
		public var projectors:Vector.<ZenShadowLight>;
		public var enableRenderShadows:Boolean = true;
		public var scene:Zen3D;
		
		public function LightFilter(techniqueName:String = "sampled", maxPointLights:int = 0, maxDirectionalLights:int = 1, useDefaultLights:Boolean = false) {
			if (data == null) {
				data = new compiledShader();
			}
			
			this.defaultLight = new ZenLight("Default Light", LightType.DIRECTIONAL);
			this.ambientColor = new Vector3D(0.23, 0.23, 0.23, 1);
			this.list = new Vector.<ZenLight>();
			this._temp = new Vector3D();
			this._dirLight = ZenUtils.dirLight;
			this._dirColor = ZenUtils.dirColor;
			this._pointLight = ZenUtils.pointLight;
			this._pointColor = ZenUtils.pointColor;
			this._texturePoint = new Point();
			this._textureRect = new Rectangle(0, 0, lightSamples, (lightSamplesRate * 8));
			this._textureOffset = new ShaderVar(new Vector.<Number>(8), 2);
			super(data, null, techniqueName);
			if (!(useDefaultLights)) {
				this._dirLight = new Vector.<Number>(4);
				this._dirColor = new Vector.<Number>(4);
				this._pointLight = new Vector.<Number>();
				this._pointColor = new Vector.<Number>();
			}
			this._maxPointLights = maxPointLights;
			this._maxDirectionalLights = maxDirectionalLights;
			this._texture = new ZenTexture(new BitmapData(this._textureRect.width, this._textureRect.height, true, 0));
			this._texture.mipMode = TextureMipMapping.NONE;
			this._texture.filterMode = TextureFilter.NEAREST;
			this._texture.wrapMode = TextureWrap.CLAMP;
			this._pDirLight = new ShaderVar(this._dirLight, this._maxDirectionalLights);
			this._pDirColor = new ShaderVar(this._dirColor, this._maxDirectionalLights);
			this._pPointLight = new ShaderVar(this._pointLight, this._maxPointLights);
			this._pPointColor = new ShaderVar(this._pointColor, this._maxPointLights);
			this._pPointLight.name = "pointLight";
			this._pPointColor.name = "pointColor";
			this._pDirLight.name = "dirLight";
			this._pDirColor.name = "dirColor";
			this.defaultLight.infinite = true;
			this.defaultLight.color.setTo(0.75, 0.75, 0.75);
			params.ambient.value = new Vector.<Number>(4);
			params.samples.value = this._texture;
			params.gamma.value = Vector.<Number>([1, 1, 1, 1]);
			params.enableFog.value = Vector.<Number>([0, 0, 0, 0]);
			params.fogRange.value = Vector.<Number>([0, 1000, 0, 0]);
			params.fogColor.value = Vector.<Number>([0.1, 0.2, 0.3, 1]);
			var i:int;
			while (i < 8) {
				this._textureOffset.value[i] = ((i / 8) + 0.1);
				i++;
			}
		}
		
		public function setGamma(r:Number = 2.2, g:Number = 2.2, b:Number = 2.2):void {
			var prev:Number = params.gamma.value[0];
			params.gamma.value = Vector.<Number>([(1 / r), (1 / g), (1 / b), 1]);
			if ((((((prev == 1)) && (!((r == 1))))) || (((!((prev == 1))) && ((r == 1)))))) {
				build();
			}
		}
		
		public function setFogProperties(enabled:Boolean = true, near:Number = 0, far:Number = 1000, r:Number = 0.1, g:Number = 0.2, b:Number = 0.3, a:Number = 1):void {
			var prev:Boolean = (((params.enableFog.value[0] == 1)) ? true : false);
			params.enableFog.value = Vector.<Number>([((enabled) ? 1 : 0)]);
			params.fogRange.value = ((params.fogRange.value) || (new Vector.<Number>(4, true)));
			params.fogRange.value[0] = near;
			params.fogRange.value[1] = (far - near);
			params.fogColor.value = ((params.fogColor.value) || (new Vector.<Number>(4, true)));
			params.fogColor.value[0] = r;
			params.fogColor.value[1] = g;
			params.fogColor.value[2] = b;
			params.fogColor.value[3] = a;
			if (prev != enabled) {
				build();
			}
		}
		
		public function dispose():void {
			if (this._shadowMapTexture) {
				this._shadowMapTexture.dispose();
			}
			this.projectors = null;
			this._texture.dispose();
		}
		
		override public function process(scope:ShaderContext2):void {
			var i:int;
			var dirLight:uint;
			var dirColor:uint;
			var pointLight:uint;
			var pointColor:uint;
			var offsets:uint;
			if (techniqueName == NO_LIGHTS) {
				return;
			}
			if (this._maxDirectionalLights) {
				dirLight = scope.createRegisterFromParam(this._pDirLight);
				dirColor = scope.createRegisterFromParam(this._pDirColor);
			}
			if (this._maxPointLights) {
				pointLight = scope.createRegisterFromParam(this._pPointLight);
				pointColor = scope.createRegisterFromParam(this._pPointColor);
			}
			i = 0;
			while (i < this._maxDirectionalLights) {
				scope.call((techniqueName + ".directional"), [scope.getRegister(dirLight, "xyz", i), scope.getRegister(dirColor, "xyz", i)]);
				i++;
			}
			if (techniqueName == SAMPLED) {
				offsets = scope.createRegisterFromParam(this._textureOffset);
				i = 0;
				while (i < this._maxPointLights) {
					scope.call((techniqueName + ".point"), [scope.getRegister(pointLight, "xyzw", i), scope.getRegister(offsets, "xyzw".charAt((i % 4)), (i / 4))]);
					i++;
				}
			} else {
				i = 0;
				while (i < this._maxPointLights) {
					scope.call((techniqueName + ".point"), [scope.getRegister(pointLight, "xyzw", i), scope.getRegister(pointColor, "xyzw", i)]);
					i++;
				}
			}
			if (!(scope.outputFragment)) {
				scope.outputFragment = scope.call("flare.undefined");
			}
			scope.outputFragment = scope.call((techniqueName + ".blend"), [scope.outputFragment]);
		}
		
		public function set cubeMap(value:ZenTexture):void {
			if (!(params.cube.value)) {
				params.cube.value = value;
				if (value) {
					build();
				}
			} else {
				params.cube.value = value;
				if (!(value)) {
					build();
				}
			}
		}
		
		public function get cubeMap():ZenTexture {
			return (params.cube.value);
		}
		
		public function get filterMapTexture():ZenTexture {
			return (this._filterMapTexture);
		}
		
		public function set filterMapTexture(value:ZenTexture):void {
			this._filterMapTexture = value;
		}
		
		public function get shadowMapTexture():ZenTexture {
			return (this._shadowMapTexture);
		}
		
		public function set shadowMapTexture(value:ZenTexture):void {
			if (((((value) && (((value.request is Point) == false)))) && (((value.request is Rectangle) == false)))) {
				
				throw("Shadow map value should be a dynamic texture.");
				
				return;
			}
			params.enableShadowMap.value = Vector.<Number>([((value) ? 1 : 0)]);
			ShaderMaterial.semantics["SHADOW_MAP"].value = value;
			if (value != this._shadowMapTexture) {
				if (this._shadowMapTexture) {
					this._shadowMapTexture.dispose();
					this._shadowMapTexture = null;
				}
				if (this._filterMapTexture) {
					this._filterMapTexture.dispose();
					this._filterMapTexture = null;
				}
				if (this._diskFilter) {
					this._diskFilter.dispose();
					this._diskFilter = null;
				}
				this._shadowMapTexture = value;
				if (this._shadowMapTexture) {
					this._shadowMapTexture.upload(this.scene);
				}
				build();
			}
		}
		
		public function get maxPointLights():int {
			return (this._maxPointLights);
		}
		
		public function set maxPointLights(value:int):void {
			if (value != this._maxPointLights) {
				this._maxPointLights = value;
				this._pPointLight = new ShaderVar(this._pointLight, this._maxPointLights);
				this._pPointColor = new ShaderVar(this._pointColor, this._maxPointLights);
				this._pPointLight.name = "pointLight";
				this._pPointColor.name = "pointColor";
				build();
			}
		}
		
		public function get maxDirectionalLights():int {
			return (this._maxDirectionalLights);
		}
		
		public function set maxDirectionalLights(value:int):void {
			if (value != this._maxDirectionalLights) {
				this._maxDirectionalLights = value;
				this._pDirLight = new ShaderVar(this._dirLight, this._maxDirectionalLights);
				this._pDirColor = new ShaderVar(this._dirColor, this._maxDirectionalLights);
				this._pDirLight.name = "dirLight";
				this._pDirColor.name = "dirColor";
				build();
			}
		}
		
		public function get texture():ZenTexture {
			return (this._texture);
		}
		
		private function setPointLight(l:ZenLight, index:int):void {
			index = (index * 4);
			if (l) {
				l.world.copyColumnTo(3, this._temp);
				this._pointLight[(index + 0)] = this._temp.x;
				this._pointLight[(index + 1)] = this._temp.y;
				this._pointLight[(index + 2)] = this._temp.z;
				this._pointLight[(index + 3)] = (l.radius * l.radius);
				this._pointColor[(index + 0)] = (l.color.x * l.multiplier);
				this._pointColor[(index + 1)] = (l.color.y * l.multiplier);
				this._pointColor[(index + 2)] = (l.color.z * l.multiplier);
				this._pointColor[(index + 3)] = ((l.infinite) ? 1 : 0);
			} else {
				this._pointColor[(index + 0)] = 0;
				this._pointColor[(index + 1)] = 0;
				this._pointColor[(index + 2)] = 0;
				this._pointColor[(index + 3)] = 0;
			}
		}
		
		private function setDirLight(l:ZenLight, index:int):void {
			index = (index * 4);
			if (l) {
				l.world.copyColumnTo(2, this._temp);
				this._temp.normalize();
				this._dirLight[(index + 0)] = -(this._temp.x);
				this._dirLight[(index + 1)] = -(this._temp.y);
				this._dirLight[(index + 2)] = -(this._temp.z);
				this._dirLight[(index + 3)] = 0;
				this._dirColor[(index + 0)] = (l.color.x * l.multiplier);
				this._dirColor[(index + 1)] = (l.color.y * l.multiplier);
				this._dirColor[(index + 2)] = (l.color.z * l.multiplier);
				this._dirColor[(index + 3)] = 0;
			} else {
				this._dirColor[(index + 0)] = 0;
				this._dirColor[(index + 1)] = 0;
				this._dirColor[(index + 2)] = 0;
				this._dirColor[(index + 3)] = 0;
			}
		}
		
		private function sortLightsFunction(a:ZenLight, b:ZenLight):int {
			if (a.priority > b.priority) {
				return (1);
			}
			if (a.priority < b.priority) {
				return (-1);
			}
			return (0);
		}
		
		private function sort(data:Vector.<ZenLight>):void {
			var i:int;
			var j:int;
			var e:int;
			var priority:int;
			var pivot:ZenLight;
			var left:int;
			var right:int = (data.length - 1);
			i = (left + 1);
			right++;
			while (i < right) {
				pivot = data[i];
				j = (i - 1);
				e = i;
				priority = pivot.priority;
				while ((((j >= left)) && ((data[j].priority > priority)))) {
					var _local9 = e--;
					data[_local9] = data[j--];
				}
				data[e] = pivot;
				i++;
			}
		}
		
		public function update():void {
			var light:ZenLight;
			var point:int;
			var directional:int;
			for each (light in this.list) {
				if (light.visible) {
					light.draw(false);
				}
			}
			this.sort(this.list);
			params.ambient.value[0] = this.ambientColor.x;
			params.ambient.value[1] = this.ambientColor.y;
			params.ambient.value[2] = this.ambientColor.z;
			params.ambient.value[3] = 1;
			ZenUtils.ambient[0] = this.ambientColor.x;
			ZenUtils.ambient[1] = this.ambientColor.y;
			ZenUtils.ambient[2] = this.ambientColor.z;
			ZenUtils.ambient[3] = 1;
			if ((((techniqueName == SAMPLED)) && (this._maxPointLights))) {
				this._texture.upload(this.scene);
				this._texture.bitmapData.lock();
				this._texture.bitmapData.fillRect(this._textureRect, 0);
				this._texturePoint.y = 0;
			}
			if (((this.defaultLight) && (this.defaultLight.visible))) {
				this.defaultLight.world = ZenUtils.camera.world;
				if (this._maxDirectionalLights) {
					this.setDirLight(this.defaultLight, directional++);
				} else {
					if (this._maxPointLights) {
						this.setPointLight(this.defaultLight, point++);
					}
				}
			}
			for each (light in this.list) {
				if (light.visible == false) {
				} else {
					if (light.type == LightType.DIRECTIONAL) {
						if (directional >= this._maxDirectionalLights) {
							//unresolved jump
						}
						this.setDirLight(light, directional++);
					} else {
						if (light.type == LightType.POINT) {
							if (point >= this._maxPointLights) {
							} else {
								if (techniqueName == SAMPLED) {
									this._texturePoint.y = (point * lightSamplesRate);
									this._texture.bitmapData.copyPixels(light.sample, this._textureRect, this._texturePoint);
								}
								this.setPointLight(light, point++);
							}
						}
					}
				}
			}
			while (point < this._maxPointLights) {
				this.setPointLight(null, point++);
			}
			while (directional < this._maxDirectionalLights) {
				this.setDirLight(null, directional++);
			}
			if ((((techniqueName == SAMPLED)) && (this._maxPointLights))) {
				if (!(this._texture.scene)) {
					this._texture.upload(this.scene);
				}
				this._texture.bitmapData.unlock();
				this._texture.uploadTexture();
			}
		}
		
		public function renderShadows():Boolean {
			var pvCount:int;
			var i:int;
			var sizeX:Number;
			var sizeY:Number;
			var debug:Boolean;
			if (((!(this.projectors)) || (!(this.projectors.length)))) {
				if (this._shadowMapTexture) {
					this.shadowMapTexture = null;
				}
				return (false);
			}
			if (!(this.enableRenderShadows)) {
				return (false);
			}
			i = 0;
			while (i < this.projectors.length) {
				if (this.projectors[i].visible) {
					pvCount++;
				}
				i++;
			}
			if (pvCount == 0) {
				return (false);
			}
			i = 0;
			while (i < this.projectors.length) {
				this.projectors[i].renderDepthMap();
				if (this.projectors[i].debug) {
					debug = true;
				}
				i++;
			}
			if (!(this._shadowMapTexture)) {
				this.shadowMapTexture = new ZenTexture(new Rectangle(0, 0, 0x0800, 0x0400));
			}
			if (this.enableShadowsFiltering) {
				if (!(this._filterMapTexture)) {
					this._filterMapTexture = new ZenTexture(this._shadowMapTexture.request, true);
				}
				if (!(this._diskFilter)) {
					this._diskFilter = new ShaderMaterial("diskFilter", new DiskFilter());
					this._diskFilter.params.texture.value = this._filterMapTexture;
					this._diskFilter.upload(this.scene);
				}
				if (!(this._filterMapTexture.scene)) {
					this._filterMapTexture.upload(this.scene);
				}
				this.scene.context.setRenderToTexture(this._filterMapTexture.texture, true);
			} else {
				if (this._filterMapTexture) {
					this._filterMapTexture.dispose();
					this._filterMapTexture = null;
				}
				if (this._diskFilter) {
					this._diskFilter.dispose();
					this._diskFilter = null;
				}
				if (!(this._shadowMapTexture.scene)) {
					this._shadowMapTexture.upload(this.scene);
				}
				this.scene.context.setRenderToTexture(this._shadowMapTexture.texture, true);
			}
			this.scene.context.clear(1, 1, 1, 1);
			if (pvCount > 1) {
				this.scene.context.setColorMask(false, false, false, true);
				(this.projectors[0] as ZenShadowLight).renderShadowMap();
				this.scene.context.setColorMask(true, true, true, false);
				i = 0;
				while (i < this.projectors.length) {
					(this.projectors[i] as ZenShadowLight).renderShadowMap(Context3DBlendFactor.DESTINATION_COLOR, Context3DBlendFactor.SOURCE_COLOR);
					i++;
				}
			} else {
				this.scene.context.setColorMask(true, true, true, true);
				if (!(debug)) {
					i = 0;
					while (i < this.projectors.length) {
						(this.projectors[i] as ZenShadowLight).renderShadowMap(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
						i++;
					}
				} else {
					(this.projectors[0] as ZenShadowLight).renderShadowMap(Context3DBlendFactor.ONE, Context3DBlendFactor.ZERO);
				}
			}
			if (this.enableShadowsFiltering) {
				if (!(this._shadowMapTexture.scene)) {
					this._shadowMapTexture.upload(this.scene);
				}
				sizeX = (((this._shadowMapTexture.request is Point)) ? this._shadowMapTexture.request.x : this._shadowMapTexture.request.width);
				sizeY = (((this._shadowMapTexture.request is Point)) ? this._shadowMapTexture.request.y : this._shadowMapTexture.request.height);
				this._diskFilter.params.texel.value[0] = (this.shadowsFiltering / sizeX);
				this._diskFilter.params.texel.value[1] = (this.shadowsFiltering / sizeY);
				this.scene.context.setRenderToTexture(this._shadowMapTexture.texture, true);
				this.scene.context.clear(1, 1, 1, 1);
				this.scene.drawQuadTexture(null, 0, 0, 1, 1, this._diskFilter);
			}
			this.scene.context.setColorMask(true, true, true, true);
			return (true);
		}
	
	}
}

