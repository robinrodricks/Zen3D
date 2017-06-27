package zen.utils {
	import zen.display.*;
	import zen.materials.*;
	import zen.enums.*;
	import zen.display.*;
	import zen.shaders.textures.*;
	import zen.utils.*;
	import flash.geom.*;
	
	/** A 2D quad shape (not 3D quad), used as a holder to render other 3D content (such as the Zen3D) */
	public class ZenSceneCanvas extends ZenMesh {
		
		private var _x:Number;
		private var _y:Number;
		private var _width:Number;
		private var _height:Number;
		private var _surf:ZenFace;
		public var fullScreenMode:Boolean = true;
		
		public function ZenSceneCanvas(name:String = "quad", x:Number = 0, y:Number = 0, width:Number = 100, height:Number = 100, fullScreenMode:Boolean = false, material:ShaderMaterialBase = null, vertices:int = 4) {
			super(name);
			this._surf = new ZenFace();
			this._surf.addVertexData(VertexType.POSITION);
			this._surf.addVertexData(VertexType.UV0);
			this._surf.vertexVector = new Vector.<Number>();
			this._surf.indexVector = new Vector.<uint>();
			
			if (vertices == 4) {
				this._surf.vertexVector.push(-1, 1, 0, 0, 0); /// TL vertex
				this._surf.vertexVector.push(1, 1, 0, 1, 0); /// TR vertex
				this._surf.vertexVector.push(-1, -1, 0, 0, 1); /// BL vertex
				this._surf.vertexVector.push(1, -1, 0, 1, 1); /// BR vertex
				this._surf.indexVector.push(0, 1, 2, /// tri 1
				3, 2, 1  /// tri 2
				);
			} else if (vertices == 6) {
				this._surf.vertexVector.push(-1, 1, 0, 0, 0); /// V0
				this._surf.vertexVector.push(0, 1, 0, 0.5, 0); /// V1
				this._surf.vertexVector.push(1, 1, 0, 1, 0); /// V2
				this._surf.vertexVector.push(1, -1, 0, 1, 1); /// V3
				this._surf.vertexVector.push(0, -1, 0, 0.5, 1); /// V4
				this._surf.vertexVector.push(-1, -1, 0, 0, 1); /// V5
				this._surf.indexVector.push(0, 1, 5, /// tri 1
				5, 1, 4, /// tri 2
				1, 2, 4, /// tri 3
				4, 2, 3  /// tri 4
				);
			}
			
			this._surf.material = ((material) || (new NullMaterial()));
			surfaces.push(this._surf);
			this.setTo(x, y, width, height, fullScreenMode);
		}
		
		public function set material(value:ShaderMaterialBase):void {
			this._surf.material = value;
		}
		
		public function get material():ShaderMaterialBase {
			return (this._surf.material);
		}
		
		public function setTo(x:Number, y:Number, width:Number, height:Number, fullScreenMode:Boolean = false):void {
			this._x = x;
			this._y = y;
			this._width = width;
			this._height = height;
			this.fullScreenMode = fullScreenMode;
		}
		
		override public function draw(includeChildren:Boolean = true, material:ShaderMaterialBase = null):void {
			var x:Number;
			var y:Number;
			var w:Number;
			var h:Number;
			if (!(scene)) {
				upload(ZenUtils.scene);
			}
			if (!(visible)) {
				return;
			}
			var v:Rectangle = scene.viewPort;
			x = (this._x / v.width);
			y = (this._y / v.height);
			w = (this._width / v.width);
			h = (this._height / v.height);
			if (this.fullScreenMode) {
				w = ((1 - x) - w);
				h = ((1 - y) - h);
			}
			transform.identity();
			transform.appendScale(((w) || (1E-5)), ((h) || (1E-5)), 1);
			transform.appendTranslation(((-1 + w) + (x * 2)), ((1 - h) - (y * 2)), 0);
			ZenUtils.worldViewProj.copyFrom(transform);
			ShaderMaterialBase(((material) || (this._surf.material))).draw(this, this._surf);
		}
	
	}
}

