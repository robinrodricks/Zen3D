package zen.materials {
	import zen.materials.*;
	import zen.display.*;
	import zen.shaders.textures.*;
	import zen.shaders.*;
	import zen.shaders.core.*;
	import zen.filters.color.*;
	import zen.filters.maps.*;
	import zen.filters.transform.*;
	import zen.utils.*;
	import zen.shaders.*;
	import zen.display.*;
	import flash.display.*;
	import flash.display3D.*;
	import flash.events.*;
	import flash.utils.*;
	
	/** A complete material that can be applied to a ZenMesh. Contains multiple filters that configure the material's rendering. */
	public class ZenMaterial extends ShaderMaterial {
		
		public static const VERTEX_NORMAL:ShaderFilter = new TransformFilter();
		public static const VERTEX_SKIN:ShaderFilter = new SkinTransformFilter(ZenUtils.maxBonesPerVertex);
		
		[Embed(source = "../utils/assets/textures/ZenMaterial_shaders.data", mimeType = "application/octet-stream")]
		private static var shaders:Class;
		
		[Embed(source = "../utils/assets/textures/ZenMaterial_topLevel.data", mimeType = "application/octet-stream")]
		private static var topLevel:Class;
		
		private static var shader:ShaderContext2;
		public static var globalFilters:Array = [];
		
		public var libs:Array;
		private var _filters:Array;
		private var _postLightFilters:Array;
		private var _enableLights:Boolean;
		private var _transform:ShaderFilter;
		private var _changeState:Boolean;
		
		public function ZenMaterial(name:String = "", filters:Array = null, enableLights:Boolean = true, transform:ShaderFilter = null) {
			this.libs = [];
			super(name);
			this._enableLights = enableLights;
			this._transform = ((transform) || (VERTEX_NORMAL));
			this.filters = filters;
		}
		
		override public function dispose():void {
			this._filters = null;
			this._transform = null;
			super.dispose();
		}
		
		public function getFilterByClass(filterClass:Class) {
			if (!(this._filters)) {
				return (null);
			}
			var i:int;
			while (i < this._filters.length) {
				if ((this._filters[i] is filterClass)) {
					return (this._filters[i]);
				}
				i++;
			}
			return (null);
		}
		
		public function removeFilterByClass(filterClass:Class):Boolean {
			if (!(this._filters)) {
				return (false);
			}
			var i:int;
			while (i < this._filters.length) {
				if ((this._filters[i] is filterClass)) {
					this._filters.splice(i, 1);
					return (true);
				}
				i++;
			}
			return (false);
		}
		
		public function duplicate():ZenMaterial {
			var i:int;
			var m:ZenMaterial = (this.clone() as ZenMaterial);
			if (this.filters) {
				i = 0;
				while (i < this.filters.length) {
					m.filters[i] = this.filters[i].clone();
					i++;
				}
			}
			return (m);
		}
		
		override public function clone():ShaderMaterialBase {
			var i:int;
			var e:int;
			var pre:Array = [];
			if (this.filters) {
				i = 0;
				while (i < this.filters.length) {
					pre.push(this.filters[i]);
					i++;
				}
			}
			var post:Array = [];
			if (this.postLightFilters) {
				e = 0;
				while (e < this.postLightFilters.length) {
					post.push(this.postLightFilters[e]);
					e++;
				}
			}
			var m:ZenMaterial = new ZenMaterial(name, pre, this._enableLights, this._transform);
			m.postLightFilters = post;
			m.transparent = transparent;
			m.depthWrite = depthWrite;
			m.cullFace = cullFace;
			m.sourceFactor = sourceFactor;
			m.destFactor = destFactor;
			m.twoSided = twoSided;
			return (m);
		}
		
		override protected function context3DEvent(e:Event = null):void {
			if (!(programs)) {
				this.build();
			}
			super.context3DEvent(e);
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		override public function rebuild():void {
			this.filters = this.filters;
		}
		
		override public function build():void {
			var filter:ShaderFilter;
			var pass:int;
			var byteCode:ByteArray;
			var vtx:uint;
			var frg:uint;
			var index:int;
			var p:ShaderProgram;
			var scope:ShaderContext;
			if (!(scene)) {
				return;
			}
			var prgFilters:Array = ((this._filters) ? this._filters.concat() : []);
			var lightFilter:LightFilter = ((scene) ? scene.lights : ZenUtils.scene.lights);
			if (((globalFilters) && ((globalFilters.length > 0)))) {
				prgFilters = prgFilters.concat(globalFilters);
			}
			if (((this._enableLights) && (scene.lights))) {
				prgFilters.push(lightFilter);
			}
			if (this._postLightFilters) {
				prgFilters = prgFilters.concat(this._postLightFilters);
			}
			prgFilters.unshift(this._transform);
			if (!(shader)) {
				shader = new ShaderContext2("topLevel");
				shader.bind(new topLevel());
				shader.bind(new shaders());
				for each (byteCode in this.libs) {
					shader.bind(byteCode);
				}
			}
			var prg:Vector.<ShaderProgram> = new Vector.<ShaderProgram>();
			var passes:int = 1;
			for each (filter in prgFilters) {
				if (filter.passes > passes) {
					passes = filter.passes;
				}
			}
			this.flags = 0;
			pass = 0;
			while (pass < passes) {
				shader.init(pass);
				vtx = 0;
				frg = 0;
				index = 0;
				for each (filter in prgFilters) {
					if (!((((!((filter == this._transform))) && ((filter.passes <= pass)))) && ((pass > 0)))) {
						if (!(filter.enabled)) {
						} else {
							var _temp1 = index;
							index = (index + 1);
							filter.init(this, _temp1, pass);
							shader.process(filter);
							if (shader.outputVertex != vtx) {
								vtx = shader.outputVertex;
							}
							if (shader.outputFragment != frg) {
								if (((frg) && (filter.blendMode))) {
									scope = ((filter.getScope(filter.blendMode)) || (shader.getScope(("flare.blendMode." + filter.blendMode))));
									if (scope) {
										shader.outputFragment = scope.call("", [shader.outputFragment, frg]);
									}
								}
								frg = shader.outputFragment;
							}
						}
					}
				}
				if (!(frg)) {
					frg = shader.call("flare.undefined");
				}
				shader.call("flare.setVertex", [vtx]);
				shader.call("flare.setFragment", [frg]);
				p = shader.build();
				if (p) {
					prg.push(p);
				}
				pass++;
			}
			programs = prg;
			for each (filter in prgFilters) {
				filter.addEventListener("build", this.buildEvent, false, 0, true);
			}
			ZenUtils.lastMaterial = null;
		}
		
		override public function draw(pivot:ZenObject, surf:ZenFace, firstIndex:int = 0, count:int = -1):void {
			if (!(_scene)) {
				upload(pivot.scene);
			}
			var prg:Vector.<ShaderProgram> = programs;
			if (!(prg)) {
				return;
			}
			var p0:ShaderProgram = prg[0];
			p0.depthCompare = depthCompare;
			p0.depthWrite = depthWrite;
			p0.sourceFactor = sourceFactor;
			p0.destFactor = destFactor;
			p0.cullFace = cullFace;
			super.draw(pivot, surf, firstIndex, count);
		}
		
		public function get enableLights():Boolean {
			return (this._enableLights);
		}
		
		public function set enableLights(value:Boolean):void {
			if (value == this._enableLights) {
				return;
			}
			this._enableLights = value;
			this.filters = this._filters;
		}
		
		public function get filters():Array {
			return (this._filters);
		}
		
		public function set filters(value:Array):void {
			var filter:ShaderFilter;
			for each (filter in this._filters) {
				if (filter) {
					filter.removeEventListener("build", this.buildEvent);
				}
			}
			this._filters = ((value) || ([]));
			programs = null;
			if (scene) {
				this.context3DEvent(null);
			}
		}
		
		public function get postLightFilters():Array {
			return (this._postLightFilters);
		}
		
		public function set postLightFilters(value:Array):void {
			this._postLightFilters = value;
			programs = null;
			if (scene) {
				this.context3DEvent(null);
			}
		}
		
		private function buildEvent(e:Event):void {
			this.filters = this._filters;
		}
		
		public function get transform():ShaderFilter {
			return (this._transform);
		}
		
		public function set transform(value:ShaderFilter):void {
			this._transform = value;
			this.filters = this._filters;
		}
		
		public static function NewColorMaterial(color:int):ZenMaterial {
			
			/*var shp:Shape = new Shape();
			   shp.graphics.beginGradientFill( GradientType.LINEAR, [0x00FCFF, 0xB48AFF, 0xF72335, 0xFFD73A ], null, null, mtx );
			   shp.graphics.drawRect( 0, 0, 256, 10 );
			
			   var bmp:BitmapData = new BitmapData( 256, 2, false, 0 );
			   bmp.draw( shp );*/
			
			var _material:ZenMaterial = new ZenMaterial("temp");
			
			_material.filters.push(new ColorFilter(color, 1));
			//_material.filters.push( new LightFilter("sampled", 1, 1) );
			_material.filters.push(new SpecularFilter(200, 1));
			
			_material.twoSided = true;
			
			_material.build();
			
			return _material;
		}
	
	}
}

