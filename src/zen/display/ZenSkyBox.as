package zen.display {
	import zen.display.*;
	import zen.enums.*;
	import zen.display.*;
	import zen.loaders.*;
	import zen.shaders.*;
	import zen.shaders.textures.*;
	import zen.utils.*;
	import zen.materials.*;
	import flash.display.*;
	import flash.display3D.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	
	[Event(name = "complete", type = "flash.events.Event")]
	[Event(name = "progress", type = "flash.events.ProgressEvent")]
	
	/** A 3D skybox that renders a six-sided cube to display a skybox texture on. */
	public class ZenSkyBox extends ZenMesh {
		
		public static const HORIZONTAL_CROSS:String = "horizontalCross";
		public static const VERTICAL_CROSS:String = "verticalCross";
		public static const FOLDER_JPG:String = "folderJPG";
		public static const FOLDER_PNG:String = "folderPNG";
		public static const BITMAP_DATA_ARRAY:String = "bitmapDataArray";
		
		[Embed(source = "../utils/assets/display/ZenSkyBox.data", mimeType = "application/octet-stream")]
		private static var data:Class;
		
		private var _textures:Vector.<ZenTexture>;
		private var _texture:ZenTexture;
		private var _library:AssetLoader;
		private var _format:String;
		private var _scaleRatio:Number;
		private var _material:ShaderMaterial;
		
		public function ZenSkyBox(request, format:String = "horizontalCross", sceneContext:Zen3D = null, scaleRatio:Number = 0.5) {
			var i:int;
			var folder:String;
			var ext:String;
			var images:Array;
			this._textures = new Vector.<ZenTexture>();
			super("skybox");
			this._scaleRatio = scaleRatio;
			this._format = format;
			this._material = new ShaderMaterial("skybox", new data());
			var surf:ZenFace = new ZenFace("skybox");
			surf.vertexVector = new Vector.<Number>();
			surf.indexVector = new Vector.<uint>();
			surf.addVertexData(VertexType.POSITION);
			surf.addVertexData(VertexType.UV0);
			surf.material = this._material;
			var size:Number = 500;
			surf.vertexVector.push(-(size), size, size, 0, 0);
			surf.vertexVector.push(size, size, size, 1, 0);
			surf.vertexVector.push(-(size), -(size), size, 0, 1);
			surf.vertexVector.push(size, -(size), size, 1, 1);
			surf.vertexVector.push(size, size, size, 0, 0);
			surf.vertexVector.push(size, size, -(size), 1, 0);
			surf.vertexVector.push(size, -(size), size, 0, 1);
			surf.vertexVector.push(size, -(size), -(size), 1, 1);
			surf.vertexVector.push(size, size, -(size), 0, 0);
			surf.vertexVector.push(-(size), size, -(size), 1, 0);
			surf.vertexVector.push(size, -(size), -(size), 0, 1);
			surf.vertexVector.push(-(size), -(size), -(size), 1, 1);
			surf.vertexVector.push(-(size), size, -(size), 0, 0);
			surf.vertexVector.push(-(size), size, size, 1, 0);
			surf.vertexVector.push(-(size), -(size), -(size), 0, 1);
			surf.vertexVector.push(-(size), -(size), size, 1, 1);
			surf.vertexVector.push(-(size), size, -(size), 0, 0);
			surf.vertexVector.push(size, size, -(size), 1, 0);
			surf.vertexVector.push(-(size), size, size, 0, 1);
			surf.vertexVector.push(size, size, size, 1, 1);
			surf.vertexVector.push(-(size), -(size), size, 0, 0);
			surf.vertexVector.push(size, -(size), size, 1, 0);
			surf.vertexVector.push(-(size), -(size), -(size), 0, 1);
			surf.vertexVector.push(size, -(size), -(size), 1, 1);
			i = 0;
			while (i < 24) {
				surf.indexVector.push(i, (i + 1), (i + 2), (i + 1), (i + 3), (i + 2));
				i = (i + 4);
			}
			i = 0;
			while (i < 6) {
				surf = surf.clone();
				surf.firstIndex = (i * 6);
				surf.numTriangles = 2;
				surfaces.push(surf);
				i++;
			}
			this._library = new AssetLoader();
			this._library.addEventListener("progress", dispatchEvent, false, 0, true);
			this._library.addEventListener("complete", this.completeTextureEvent, false, 0, true);
			if ((((format == HORIZONTAL_CROSS)) || ((format == VERTICAL_CROSS)))) {
				i = 0;
				while (i < 6) {
					this._textures[i] = new ZenTexture(ZenUtils.nullBitmapData);
					i++;
				}
				this._texture = new ZenTexture(request);
				if ((((request is String)) || ((request is ByteArray)))) {
					this._library.push(this._texture);
				}
			} else {
				if ((((format == FOLDER_JPG)) || ((format == FOLDER_PNG)))) {
					folder = (request as String);
					ext = (((format == FOLDER_JPG)) ? ".jpg" : ".png");
					images = ["front", "right", "back", "left", "top", "bottom"];
					if (((folder.length) && (!((folder.charAt((folder.length - 1)) == "/"))))) {
						folder = (folder + "/");
					}
					i = 0;
					while (i < 6) {
						this._textures[i] = (this._library.push(new ZenTexture(((folder + images[i]) + ext))) as ZenTexture);
						i++;
					}
				} else {
					if (format == BITMAP_DATA_ARRAY) {
						this._textures[0] = new ZenTexture(request[0]);
						this._textures[1] = new ZenTexture(request[2]);
						this._textures[2] = new ZenTexture(request[1]);
						this._textures[3] = new ZenTexture(request[3]);
						this._textures[4] = new ZenTexture(request[4]);
						this._textures[5] = new ZenTexture(request[5]);
					} else {
						
						throw new Error("Unknown format!");
						
						return;
					}
				}
			}
			if ((((request is String)) || ((request is ByteArray)))) {
				if (sceneContext) {
					sceneContext.library.push(this._library);
				} else {
					this._library.load();
				}
			} else {
				this.completeTextureEvent();
			}
			setLayer(32);
			castShadows = false;
			receiveShadows = false;
		}
		
		private function completeTextureEvent(e:Event = null):void {
			var i:int;
			var w:Number;
			var h:Number;
			var bmp:BitmapData;
			var point:Point = new Point();
			switch (this._format) {
			case HORIZONTAL_CROSS: 
			case VERTICAL_CROSS: 
				bmp = this._texture.bitmapData;
				w = (bmp.width / (((this._format == HORIZONTAL_CROSS)) ? 4 : 3));
				h = (bmp.height / (((this._format == HORIZONTAL_CROSS)) ? 3 : 4));
				i = 0;
				while (i < 6) {
					this._textures[i] = new ZenTexture(new BitmapData(w, h, false));
					i++;
				}
				if (this._format == HORIZONTAL_CROSS) {
					this._textures[0].bitmapData.copyPixels(bmp, new Rectangle(w, h, w, h), point);
					this._textures[1].bitmapData.copyPixels(bmp, new Rectangle((w * 2), h, w, h), point);
					this._textures[2].bitmapData.copyPixels(bmp, new Rectangle((w * 3), h, w, h), point);
					this._textures[3].bitmapData.copyPixels(bmp, new Rectangle(0, h, w, h), point);
					this._textures[4].bitmapData.copyPixels(bmp, new Rectangle(w, 0, w, h), point);
					this._textures[5].bitmapData.copyPixels(bmp, new Rectangle(w, (h * 2), w, h), point);
				} else {
					this._textures[0].bitmapData.copyPixels(bmp, new Rectangle(w, h, w, h), point);
					this._textures[1].bitmapData.copyPixels(bmp, new Rectangle((w * 2), h, w, h), point);
					this._textures[2].bitmapData.draw(bmp, new Matrix(-1, 0, 0, -1, (w * 2), bmp.height));
					this._textures[3].bitmapData.copyPixels(bmp, new Rectangle(0, h, w, h), point);
					this._textures[4].bitmapData.copyPixels(bmp, new Rectangle(w, 0, w, h), point);
					this._textures[5].bitmapData.copyPixels(bmp, new Rectangle(w, (h * 2), w, h), point);
				}
				break;
			}
			i = 0;
			while (i < 6) {
				this._textures[i].mipMode = TextureMipMapping.NONE;
				this._textures[i].wrapMode = TextureWrap.CLAMP;
				i++;
			}
			if (this._texture) {
				this._texture.dispose();
			}
		}
		
		override public function dispose():void {
			if (this._library) {
				this._library.dispose();
			}
			super.dispose();
		}
		
		override public function draw(includeChildren:Boolean = true, material:ShaderMaterialBase = null):void {
			if (!(visible)) {
				return;
			}
			if (!(scene)) {
				upload(ZenUtils.scene);
			}
			var pos:Vector3D = ZenUtils.camera.world.position;
			setPosition(pos.x, pos.y, pos.z);
			ZenUtils.global.copyFrom(world);
			ZenUtils.worldViewProj.copyFrom(world);
			ZenUtils.worldViewProj.append(ZenUtils.viewProj);
			ZenUtils.worldViewProj.appendScale(this._scaleRatio, this._scaleRatio, 1);
			ZenUtils.objectsDrawn++;
			var i:int;
			while (i < 6) {
				ZenUtils.lastMaterial = null;
				this._material.params.texture.value = this._textures[i];
				this._material.draw(this, surfaces[i], surfaces[i].firstIndex, surfaces[i].numTriangles);
				i++;
			}
		}
		
		public function get scaleRatio():Number {
			return (this._scaleRatio);
		}
		
		public function set scaleRatio(value:Number):void {
			this._scaleRatio = value;
		}
	
	}
}

