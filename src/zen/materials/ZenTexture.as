package zen.materials {
	import zen.materials.*;
	import zen.enums.*;
	import zen.display.*;
	import flash.display.*;
	import flash.geom.*;
	import zen.loaders.*;
	import zen.utils.*;
	import zen.utils.*;
	import flash.display3D.*;
	import flash.display3D.textures.*;
	import flash.events.*;
	import flash.net.*;
	import flash.system.*;
	import flash.utils.*;
	
	/** A single texture bitmap used for texture mapping and for various masks/maps */
	public class ZenTexture extends EventDispatcher implements IAsset {
		
		public var bitmapData:BitmapData;
		public var texture:TextureBase;
		private var _data;
		private var _request;
		private var _loader:Loader;
		private var _urlLoader:URLLoader;
		private var _bytesTotal:uint;
		private var _bytesLoaded:uint;
		private var _levels:BitmapData;
		private var _mips:BitmapData;
		private var _transparent:Boolean;
		private var _optimizeForRenderToTexture:Boolean;
		private var _loaded:Boolean = false;
		private var _isATF:Boolean;
		private var _width:int;
		private var _height:int;
		private var _url:String;
		public var scene:Zen3D;
		public var filterMode:int = 1;
		public var wrapMode:int = 1;
		public var mipMode:int = 2;
		public var typeMode:int = 0;
		public var bias:int = 0;
		public var options:int = 0;
		public var format:int;
		public var name:String = "";
		public var uploadTexture:Function;
		
		/** Create a 2D/Cube texture from any given data
		 *
		 * `request` can be following types:
		 *
		 * - `string` - URL to be loaded, only JPG/PNG files supported.
		 * - `DisplayObject` - captured into a BitmapData for the texture.
		 * - `BitmapData` - Bitmap texture.
		 * - `Bitmap` - Bitmap display object.
		 * - `ByteArray` - ATF texture in ByteArray format.
		 * - `Point` - texture width/height set to point x/y.
		 * - `Rectangle` - texture width/height set to rect width/height.
		 * - `TextureBase` - texture is copied from given texture.
		 * - `Array` - first Bitmap / BitmapData in array is used.
		 *
		 * `format` is the specific format of the bitmap/ATF texture, necessary only for ATF textures:
		 *
		 * - TextureFormat.RGBA
		 * - TextureFormat.COMPRESSED
		 * - TextureFormat.COMPRESSED_ALPHA
		 *
		 * `type` is 2D / Cube texture.
		 *
		 * - TextureType.FLAT
		 * - TextureType.CUBE
		 *
		 * */
		public function ZenTexture(request = null, optimizeForRenderToTexture:Boolean = false, format:int = 0, type:int = 0) {
			var d:DisplayObject;
			var r:Rectangle;
			var m:Matrix;
			var i:int;
			super();
			
			// capture MC into bitmap
			if ((request is DisplayObject)) {
				d = (request as DisplayObject);
				r = d.getBounds(d);
				m = new Matrix(1, 0, 0, 1, -(r.x), -(r.y));
				request = new BitmapData(((r.width) || (1)), ((r.height) || (1)), true, 0);
				request.draw(d, m);
			}
			
			this._url = (request as String);
			this._request = ((request) || (ZenUtils.nullBitmapData));
			this._optimizeForRenderToTexture = optimizeForRenderToTexture;
			this.typeMode = type;
			this.format = format;
			this.uploadTexture = this.uploadWithMipmaps;
			
			if ((((format == TextureFormat.COMPRESSED)) || ((format == TextureFormat.COMPRESSED_ALPHA)))) {
				this._isATF = true;
			}
			
			if (type == TextureType.FLAT) {
				
				// 2D BITMAP TEXTURE
				
				if ((this._request is ByteArray)) {
					if (this._isATF) {
						this._data = this._request;
						this.loaded = true;
					}
				} else {
					if ((((this._request is Point)) || ((this._request is Rectangle)))) {
						this._optimizeForRenderToTexture = true;
						if ((this._request is Point)) {
							this._width = this._request.x;
							this._height = this._request.y;
						} else {
							this._width = this._request.width;
							this._height = this._request.height;
						}
						this.loaded = true;
						if ((this._request is Rectangle)) {
							this.mipMode = TextureMipMapping.NONE;
							this.wrapMode = TextureWrap.CLAMP;
						}
					} else {
						if ((((this._request is BitmapData)) || ((this._request is Bitmap)))) {
							this.bitmapData = (((this._request as BitmapData)) || (this._request.bitmapData));
							this.loaded = true;
							this._transparent = this.bitmapData.transparent;
						} else {
							if ((this._request is TextureBase)) {
								this.texture = this._request;
								this.loaded = true;
							} else {
								if ((this._request is String)) {
									this.name = this._request;
								} else {
									
									throw new Error("Unknown texture object.");
									
									return;
								}
							}
						}
					}
				}
			} else {
				
				// CUBE TEXTURE
				
				if ((this._request is ByteArray)) {
					if (this._isATF) {
						this._data = this._request;
						this.loaded = true;
					}
				} else {
					if ((this._request is Array)) {
						this._data = [];
						i = 0;
						while (i < 6) {
							this._data[i] = (((this._request[i] is BitmapData)) ? this._request[i] : this._request[i].bitmapData);
							i++;
						}
						this.loaded = true;
					} else {
						if ((((this._request is Point)) || ((this._request is Rectangle)))) {
							this._optimizeForRenderToTexture = true;
							this.loaded = true;
							if ((this._request is Rectangle)) {
								this.mipMode = TextureMipMapping.NONE;
								this.wrapMode = TextureWrap.CLAMP;
							}
						} else {
							if ((((this._request is Bitmap)) || ((this._request is BitmapData)))) {
								this.bitmapData = ((this._request) || (this._request.bitmapData));
								this.loaded = true;
							} else {
								if ((this._request is TextureBase)) {
									this.texture = this._request;
									this.loaded = true;
								} else {
									if ((this._request is String)) {
										this.name = this._request;
									} else {
										
										throw new Error("Unknown texture object.");
										
										return;
									}
								}
							}
						}
					}
				}
			}
		}
		
		/** Stops loading the texture from URL.
		   Unloads the texture from the GPU. Disposes texture data.
		   Disposes all internal texture data. */
		public function dispose():void {
			this.download();
			if (this._loader) {
				this._loader.unloadAndStop(false);
				this._loader = null;
			}
			if (this._urlLoader) {
				this._urlLoader = null;
			}
			if (this.bitmapData) {
				if (this.bitmapData != ZenUtils.nullBitmapData) {
					this.bitmapData.dispose();
				}
				this.bitmapData = null;
			}
			if (this._levels) {
				this._levels.dispose();
				this._levels = null;
			}
			if (this._mips) {
				this._mips.dispose();
				this._mips = null;
			}
			this._request = null;
		}
		
		/** Load the texture into the GPU. Texture must be loaded first. */
		public function upload(scene:Zen3D):void {
			if (this.scene) {
				return;
			}
			this.scene = scene;
			if (this.scene.textures.indexOf(this) == -1) {
				this.scene.textures.push(this);
			}
			if (((((!(this._loaded)) && (!(this._loader)))) && (!(this._urlLoader)))) {
				this.load();
			}
			if (this.scene.context) {
				this.contextEvent();
			}
			this.scene.addEventListener(Event.CONTEXT3D_CREATE, this.contextEvent);
		}
		
		public function get stringFormat():String {
			switch (this.format) {
			case TextureFormat.RGBA: 
				return (Context3DTextureFormat.BGRA);
			case TextureFormat.COMPRESSED: 
				return (Context3DTextureFormat.COMPRESSED);
			case TextureFormat.COMPRESSED_ALPHA: 
				return (Context3DTextureFormat.COMPRESSED_ALPHA);
			case TextureFormat.BGR_PACKED: 
				return ("bgrPacked565");
			case TextureFormat.BGRA_PACKED: 
				return ("bgraPacked4444");
			default: 
				return (Context3DTextureFormat.BGRA);
			}
		}
		
		private function parseATF():void {
		}
		
		private function uploadATF(parseOnly:Boolean = false):void {
			var frmt:String;
			var bytes:ByteArray = (this._data as ByteArray);
			if ((((bytes.length < 3)) || (!((String.fromCharCode(bytes[0], bytes[1], bytes[2]) == "ATF"))))) {
				
				throw((("Invalid ATF texture " + this.name) + "."));
				
				return;
			}
			if (bytes[6] == 0xFF) {
				bytes.position = 12;
			} else {
				bytes.position = 6;
			}
			var flag:int = bytes.readUnsignedByte();
			var isCube:int = (flag >> 7);
			switch ((flag & 127)) {
			case 0: 
			case 1: 
				frmt = Context3DTextureFormat.BGRA;
				this.format = TextureFormat.RGBA;
				break;
			case 2: 
			case 3: 
				frmt = Context3DTextureFormat.COMPRESSED;
				this.format = TextureFormat.COMPRESSED;
				break;
			case 4: 
			case 5: 
				frmt = "compressedAlpha";
				this.format = TextureFormat.COMPRESSED_ALPHA;
				break;
			}
			if (isCube == 0) {
				this.typeMode = TextureType.FLAT;
			} else {
				this.typeMode = TextureType.CUBE;
			}
			if (!(parseOnly)) {
				this._width = (1 << bytes.readUnsignedByte());
				this._height = (1 << bytes.readUnsignedByte());
				if (this.typeMode == TextureType.FLAT) {
					this.texture = this.scene.context.createTexture(this._width, this._height, frmt, this._optimizeForRenderToTexture);
					Texture(this.texture).uploadCompressedTextureFromByteArray(bytes, 0);
				} else {
					this.texture = this.scene.context.createCubeTexture(this._width, frmt, this._optimizeForRenderToTexture);
					CubeTexture(this.texture).uploadCompressedTextureFromByteArray(bytes, 0);
				}
			}
		}
		
		private function contextEvent(e:Event = null):void {
			var i:int;
			var e = e;
			if (this._loaded) {
				this.texture = null;
				if (((((this._isATF) || ((this.format == TextureFormat.COMPRESSED)))) || ((this.format == TextureFormat.COMPRESSED_ALPHA)))) {
					this.uploadATF();
				} else {
					if (this.typeMode == TextureType.FLAT) {
						if ((((this._request is Point)) || ((this._request is Rectangle)))) {
							if (((((((this._request is Rectangle) == false)) && (this.isPowerOfTwo(this._request.x)))) && (this.isPowerOfTwo(this._request.y)))) {
								this.texture = this.scene.context.createTexture(this._request.x, this._request.y, this.stringFormat, this.optimizeForRenderToTexture);
							} else {
								
								// ReferenceError: Error #1069: Property createRectangleTexture not found on flash.display3D.Context3D
								/* if ((this._request is Point)){
								   this.texture = this.scene.context.createRectangleTexture(this._request.x, this._request.y, this.stringFormat, this.optimizeForRenderToTexture);
								   } else {
								
								   try {
								   this.texture = this.scene.context.createRectangleTexture(this._request.width, this._request.height, this.stringFormat, this.optimizeForRenderToTexture);
								   } catch(err) {
								   trace(err);*/
								
								texture = scene.context.createTexture(_request.width, _request.height, stringFormat, optimizeForRenderToTexture);
								
								/*}
								   }*/
								
							}
							if (ZenUtils.forceTextureInitialization) {
								this.scene.context.setRenderToTexture(this.texture);
								this.scene.context.clear();
								this.scene.context.setRenderToBackBuffer();
							}
						} else {
							if ((this._request is TextureBase)) {
								this.texture = this._request;
							} else {
								this.uploadTexture();
							}
						}
					} else {
						if (this.typeMode == TextureType.CUBE) {
							if ((this._request is Point)) {
								this.texture = this.scene.context.createCubeTexture(this._request.x, this.stringFormat, this.optimizeForRenderToTexture);
							} else {
								if ((this._request is TextureBase)) {
									this.texture = this._request;
								} else {
									if (!(this._data)) {
										this._data = ZenMeshUtills.extractCubeMap(((((this.bitmapData) || ((this._request as BitmapData)))) || (this._request.bitmapData)));
									}
									i = 0;
									while (i < 6) {
										this.uploadTexture(this._data[i], i);
										i = (i + 1);
									}
								}
							}
						}
					}
				}
			}
		}
		
		/** Unloads the texture from the GPU. Disposes texture data. */
		public function download():void {
			if (this.texture) {
				this.texture.dispose();
				this.texture = null;
			}
			if (this.scene) {
				this.scene.removeEventListener(Event.CONTEXT3D_CREATE, this.contextEvent);
				this.scene.textures.splice(this.scene.textures.indexOf(this), 1);
				this.scene = null;
			}
		}
		
		public function get bytesTotal():uint {
			return (this._bytesTotal);
		}
		
		public function get bytesLoaded():uint {
			return (this._bytesLoaded);
		}
		
		public function get request() {
			return (this._request);
		}
		
		public function set request(value):void {
			this._request = value;
		}
		
		public function get loaded():Boolean {
			return (this._loaded);
		}
		
		public function set loaded(value:Boolean):void {
			this._loaded = value;
		}
		
		public function get optimizeForRenderToTexture():Boolean {
			return (this._optimizeForRenderToTexture);
		}
		
		public function get url():String {
			return (((this._url) || (this.name)));
		}
		
		public function get width():int {
			if (this.bitmapData) {
				return (this.bitmapData.width);
			}
			return (this._width);
		}
		
		public function get height():int {
			if (this.bitmapData) {
				return (this.bitmapData.height);
			}
			return (this._height);
		}
		
		/** Begin loading a texture from URL. Only needed when texture is specified as URL.
		   Not needed when texture data is given directly in BitmapData / ByteArray format. */
		public function load():void {
			if (((((this._loader) || (this._urlLoader))) || (this.loaded))) {
				return;
			}
			var context:LoaderContext = new LoaderContext();
			context.imageDecodingPolicy = ImageDecodingPolicy.ON_LOAD;
			if (this.format == TextureFormat.RGBA) {
				this._loader = new Loader();
				this._loader.contentLoaderInfo.addEventListener("complete", this.completeEvent, false, 0, true);
				this._loader.contentLoaderInfo.addEventListener("progress", this.progressEvent, false, 0, true);
				this._loader.contentLoaderInfo.addEventListener("ioError", this.ioErrorEvent, false, 0, true);
				if ((this._request is String)) {
					this._loader.load(new URLRequest(this._request), context);
				} else {
					if ((this._request is ByteArray)) {
						this._loader.loadBytes((this._request as ByteArray), context);
					}
				}
			} else {
				if ((((this.format == TextureFormat.COMPRESSED)) || ((this.format == TextureFormat.COMPRESSED_ALPHA)))) {
					this._urlLoader = new URLLoader();
					this._urlLoader.dataFormat = URLLoaderDataFormat.BINARY;
					this._urlLoader.addEventListener("complete", this.completeEvent, false, 0, true);
					this._urlLoader.addEventListener("progress", this.progressEvent, false, 0, true);
					this._urlLoader.addEventListener("ioError", this.ioErrorEvent, false, 0, true);
					this._urlLoader.load(new URLRequest(this._request));
				}
			}
		}
		
		/** Stop loading the texture from URL. Only needed for online textures.
		   Does not clear stored texture data. */
		public function close():void {
			if (((this._loader) && ((this.loaded == false)))) {
				this._loader.close();
			}
			if (((this._urlLoader) && ((this.loaded == false)))) {
				this._urlLoader.close();
			}
		}
		
		private function ioErrorEvent(e:IOErrorEvent):void {
			this.bitmapData = ZenUtils.nullBitmapData;
			if (this.typeMode == TextureType.CUBE) {
				this._data = ZenMeshUtills.extractCubeMap(this.bitmapData);
			}
			this.loaded = true;
			this._transparent = false;
			if (((this.scene) && (this.scene.context))) {
				this.contextEvent();
			}
			trace(e);
			dispatchEvent(e);
		}
		
		private function progressEvent(e:ProgressEvent):void {
			this._bytesLoaded = e.bytesLoaded;
			this._bytesTotal = e.bytesTotal;
			dispatchEvent(e);
		}
		
		private function completeEvent(e:Event):void {
			if (this._urlLoader) {
				if (((this._isATF) && ((this._request is String)))) {
					this._data = this._urlLoader.data;
				}
			} else {
				if (this._loader) {
					this.bitmapData = Bitmap(this._loader.content).bitmapData;
					if (this.typeMode == TextureType.CUBE) {
						this._data = ZenMeshUtills.extractCubeMap(this.bitmapData);
					}
					this._transparent = this.bitmapData.transparent;
					this._loader.unloadAndStop();
					this._loader = null;
				}
			}
			this.loaded = true;
			if (this._isATF) {
				this.uploadATF(true);
			}
			if (((this.scene) && (this.scene.context))) {
				this.contextEvent();
			}
			dispatchEvent(e);
		}
		
		private function uploadWithMipmaps(source:BitmapData = null, side:int = 0):void {
			var swapped:Boolean;
			var oldMips:BitmapData;
			var oldMip:BitmapData;
			if (!(this.scene)) {
				
				throw new Error("The texture is not linked to any scene, you may need to call to ZenTexture.upload method before.");
				
				return
			}
			var bitmapData:BitmapData = ((source) || (this.bitmapData));
			var max:Number = ZenUtils.maxTextureSize;
			var width:int = (((bitmapData.width < max)) ? bitmapData.width : max);
			var height:int = (((bitmapData.height < max)) ? bitmapData.height : max);
			var w:int = 1;
			while ((w << 1) <= width) {
				w = (w << 1);
			}
			var h:int = 1;
			while ((h << 1) <= height) {
				h = (h << 1);
			}
			if (!(this.texture)) {
				if (this.typeMode == TextureType.FLAT) {
					this.texture = this.scene.context.createTexture(w, h, this.stringFormat, this._optimizeForRenderToTexture);
				} else {
					if (this.typeMode == TextureType.CUBE) {
						this.texture = this.scene.context.createCubeTexture(w, this.stringFormat, this._optimizeForRenderToTexture);
					}
				}
			}
			var inv:Matrix = new Matrix();
			var transform:Matrix = new Matrix((w / bitmapData.width), 0, 0, (h / bitmapData.height));
			var rect:Rectangle = bitmapData.rect;
			var mipRect:Rectangle = new Rectangle();
			var level:int;
			if (this.mipMode == TextureMipMapping.NONE) {
				if (((!((w == width))) || (!((h == height))))) {
					if (!(this._levels)) {
						this._levels = new BitmapData(w, h, this._transparent, 0);
					} else {
						if (this._transparent) {
							this._levels.fillRect(this._levels.rect, 0);
						}
					}
					this._levels.draw(bitmapData, transform, null, null, null, true);
				}
				if (this.typeMode == TextureType.FLAT) {
					Texture(this.texture).uploadFromBitmapData(((this._levels) || (bitmapData)), 0);
				} else {
					if (this.typeMode == TextureType.CUBE) {
						CubeTexture(this.texture).uploadFromBitmapData(((this._levels) || (bitmapData)), side, 0);
					}
				}
			} else {
				this._mips = ((this._optimizeForRenderToTexture) ? bitmapData : bitmapData.clone());
				swapped = false;
				while ((((w >= 1)) || ((h >= 1)))) {
					if ((((w == width)) && ((h == height)))) {
						if (this.typeMode == TextureType.FLAT) {
							Texture(this.texture).uploadFromBitmapData(bitmapData, level);
						} else {
							if (this.typeMode == TextureType.CUBE) {
								CubeTexture(this.texture).uploadFromBitmapData(bitmapData, side, level);
							}
						}
					} else {
						mipRect.width = w;
						mipRect.height = h;
						if (!(this._levels)) {
							this._levels = new BitmapData(((w) || (1)), ((h) || (1)), this._transparent, 0);
						} else {
							if (this._transparent) {
								this._levels.fillRect(mipRect, 0);
							}
						}
						this._levels.draw(this._mips, transform, null, null, mipRect, true);
						if (this.typeMode == TextureType.FLAT) {
							Texture(this.texture).uploadFromBitmapData(this._levels, level);
						} else {
							if (this.typeMode == TextureType.CUBE) {
								CubeTexture(this.texture).uploadFromBitmapData(this._levels, side, level);
							}
						}
					}
					if (this._levels) {
						oldMips = this._mips;
						this._mips = this._levels;
						this._levels = oldMips;
						swapped = !(swapped);
					}
					transform.a = 0.5;
					transform.d = 0.5;
					w = (w >> 1);
					h = (h >> 1);
					level++;
				}
				if (swapped) {
					oldMip = this._mips;
					this._mips = this._levels;
					this._levels = oldMip;
				}
			}
			if (((!(this._optimizeForRenderToTexture)) && (this._levels))) {
				this._levels.dispose();
				this._levels = null;
				if (this.mipMode != TextureMipMapping.NONE) {
					this._mips.dispose();
					this._mips = null;
				}
			}
		}
		
		private function isPowerOfTwo(x:int):Boolean {
			return (((x & (x - 1)) == 0));
		}
		
		override public function toString():String {
			return ((("[object ZenTexture name:" + this.name) + "]"));
		}
	
	}
}

