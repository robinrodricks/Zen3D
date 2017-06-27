package zen.display {
	import zen.materials.*;
	import zen.enums.*;
	import zen.display.*;
	import flash.utils.*;
	import zen.shaders.textures.*;
	import zen.shaders.*;
	import zen.utils.*;
	import zen.utils.*;
	import flash.display3D.*;
	import flash.events.*;
	import flash.geom.*;
	
	/** A 3D canvas that supports moveTo/lineTo API similar to the Graphics class.
	 * All elements are internally rendered with 3D lines as curves are not supported by the GPU. */
	public class ZenCanvas extends ZenMesh {
		
		[Embed(source = "../utils/assets/display/ZenCanvas.data", mimeType = "application/octet-stream")]
		private static var compiledShader:Class;
		
		private static var data:ByteArray;
		
		private static var materials:Dictionary = new Dictionary(true);
		
		private var _thickness:Number = 1;
		private var _color:uint = 0xFFFFFF;
		private var _alpha:Number = 1;
		private var _lx:Number = 0;
		private var _ly:Number = 0;
		private var _lz:Number = 0;
		private var _r:Number = 1;
		private var _g:Number = 1;
		private var _b:Number = 1;
		private var _surf:ZenFace;
		private var _uploaded:Boolean = false;
		private var _lastSize:uint;
		private var _material:ShaderMaterial;
		private var _colors:Vector.<Vector.<Number>>;
		
		public function ZenCanvas(name:String = "lines") {
			if (data == null) {
				data = new compiledShader();
			}
			
			this._colors = new Vector.<Vector.<Number>>();
			super(name);
		}
		
		override public function clone():ZenObject {
			var c:ZenObject;
			var l:ZenCanvas = new ZenCanvas(name);
			l.copyFrom(this);
			l.useHandCursor = useHandCursor;
			l.surfaces = surfaces;
			l.bounds = bounds;
			l._colors = this._colors;
			l._material = this._material;
			for each (c in children) {
				if (!(c.lock)) {
					l.addChild(c.clone());
				}
			}
			return (l);
		}
		
		override public function dispose():void {
			super.dispose();
			this.download();
			materials = null;
		}
		
		override public function download(includeChildren:Boolean = true):void {
			super.download(includeChildren);
			this._uploaded = false;
		}
		
		override public function upload(scene:Zen3D, includeChildren:Boolean = true):void {
			super.upload(scene, includeChildren);
			if (scene.context) {
				this.contextEvent();
			}
			scene.addEventListener(Event.CONTEXT3D_CREATE, this.contextEvent);
		}
		
		private function contextEvent(e:Event = null):void {
			var s:ZenFace;
			if (!(materials)) {
				materials = new Dictionary(true);
			}
			this._material = this.material;
			materials[scene] = this._material;
			for each (s in surfaces) {
				s.upload(scene);
			}
			this._uploaded = true;
		}
		
		public function clear():void {
			var s:ZenFace;
			for each (s in surfaces) {
				s.download();
			}
			surfaces = new Vector.<ZenFace>();
			this._surf = null;
			this._uploaded = false;
			this._lx = 0;
			this._ly = 0;
			this._lz = 0;
		}
		
		public function lineStyle(thickness:Number = 1, color:uint = 0xFFFFFF, alpha:Number = 1):void {
			this._alpha = alpha;
			this._color = color;
			this._thickness = thickness;
			this._r = (((color >> 16) & 0xFF) / 0xFF);
			this._g = (((color >> 8) & 0xFF) / 0xFF);
			this._b = ((color & 0xFF) / 0xFF);
			this._surf = null;
		}
		
		public function moveTo(x:Number, y:Number, z:Number):void {
			this._lx = x;
			this._ly = y;
			this._lz = z;
		}
		
		public function lineTo(x:Number, y:Number, z:Number):void {
			var index:uint = ((this._surf) ? (this._surf.vertexVector.length / this._surf.sizePerVertex) : 0);
			if (((!(this._surf)) || ((index >= (65536 - 6))))) {
				this._surf = new ZenFace((name + "_surface"));
				this._surf.addVertexData(0, 3);
				this._surf.addVertexData(1, 3);
				this._surf.addVertexData(2, 1);
				this._surf.vertexVector = new Vector.<Number>();
				this._surf.indexVector = new Vector.<uint>();
				this._colors[surfaces.length] = Vector.<Number>([this._r, this._g, this._b, this._alpha]);
				surfaces.push(this._surf);
				index = 0;
			}
			this._surf.vertexVector.push(this._lx, this._ly, this._lz, x, y, z, this._thickness, x, y, z, this._lx, this._ly, this._lz, -(this._thickness), this._lx, this._ly, this._lz, x, y, z, -(this._thickness), x, y, z, this._lx, this._ly, this._lz, this._thickness);
			this._surf.indexVector.push((index + 2), (index + 1), index, (index + 1), (index + 2), (index + 3));
			this._lx = x;
			this._ly = y;
			this._lz = z;
			this._uploaded = false;
		}
		
		public function setColor(r:Number, g:Number, b:Number, a:Number = 1):void {
			var i:int;
			while (i < surfaces.length) {
				this._colors[i] = Vector.<Number>([r, g, b, a]);
				i++;
			}
		}
		
		override public function draw(includeChildren:Boolean = true, material:ShaderMaterialBase = null):void {
			var context:Context3D;
			var i:int;
			var surf:ZenFace;
			var child:ZenObject;
			if (!(scene)) {
				this.upload(ZenUtils.scene);
			}
			if ((_eventFlags & ObjectFlags.ENTER_DRAW_FLAG)) {
				dispatchEvent(_enterDrawEvent);
			}
			if (inView) {
				context = _scene.context;
				if (!(this._uploaded)) {
					for each (surf in surfaces) {
						surf.download();
					}
					this._uploaded = true;
				}
				ZenUtils.global.copyFrom(world);
				ZenUtils.worldViewProj.copyFrom(_world);
				ZenUtils.worldViewProj.append(ZenUtils.viewProj);
				ZenUtils.objectsDrawn++;
				if (((!(this._material)) || (!(this._material.scene)))) {
					this.upload(scene);
				}
				if (ZenUtils.camera.fovMode == CameraFovMode.HORIZONTAL) {
					this._material.params.size.value[0] = (ZenUtils.camera.zoom / ZenUtils.viewPort.width);
				} else {
					this._material.params.size.value[0] = (ZenUtils.camera.zoom / ZenUtils.viewPort.height);
				}
				i = 0;
				while (i < surfaces.length) {
					this._material.params.color.value = this._colors[i];
					this._material.draw(this, surfaces[i]);
					i++;
				}
			}
			if (includeChildren) {
				for each (child in children) {
					child.draw(includeChildren);
				}
			}
			if ((_eventFlags & ObjectFlags.EXIT_DRAW_FLAG)) {
				dispatchEvent(_exitDrawEvent);
			}
		}
		
		public function get material():ShaderMaterial {
			this._material = ((this._material) || (new ShaderMaterial("material_lines", data, "lines")));
			return (this._material);
		}
	
	}
}

