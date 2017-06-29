package zen.display {
	import zen.enums.*;
	import flash.geom.*;
	import flash.events.*;
	import zen.geom.*;
	import zen.geom.intersects.*;
	import zen.intersects.*;
	import zen.physics.*;
	import zen.input.*;
	import zen.display.*;
	import zen.display.*;
	import zen.utils.*;
	import zen.materials.*;
	import zen.loaders.*;
	import zen.shaders.textures.*;
	import zen.filters.color.*;
	import zen.filters.maps.*;
	import zen.filters.transform.*;
	import zen.shaders.*;
	import zen.utils.*;
	import flash.display.*;
	import flash.display3D.*;
	import flash.display3D.textures.*;
	import flash.system.*;
	import flash.ui.*;
	import flash.utils.*;
	
	/**
	 * Fired whenever loading results in fatal errors.
	 * @eventType	flash.events.IOErrorEvent.IO_ERROR
	 */
	[Event(name = "ioError", type = "flash.events.IOErrorEvent")]
	
	/**
	 * Fired whenever the scene elements make progress during loading.
	 * @eventType	flash.events.Event
	 */
	[Event(name = "progress", type = "flash.events.ProgressEvent")]
	
	/**
	 * Fired after all the scene elements have finished loading.
	 * @eventType	flash.events.Event
	 */
	[Event(name = "complete", type = "flash.events.Event")]
	
	/**
	 * Fired after rendering completes, but before calling present().
	 * @eventType	flash.events.Event
	 */
	[Event(name = "overlay", type = "flash.events.Event")]
	
	/**
	 * Fired after rendering the scene.
	 * @eventType	flash.events.Event
	 */
	[Event(name = "postRender", type = "flash.events.Event")]
	
	/**
	 * Fired before rendering the scene.
	 * @eventType	flash.events.Event
	 */
	[Event(name = "render", type = "flash.events.Event")]
	
	/**
	 * Fired whenever the program must be updated.
	 * @eventType	flash.events.Event
	 */
	[Event(name = "update", type = "flash.events.Event")]
	
	/**
	 * A 3D scene and viewport, that contains all the 3D objects to be displayed.
	 *
	 * Similar to the Stage in 2D graphics.
	 */
	public class Zen3D extends ZenObject {
		
		public var autoDispose:Boolean = false;
		/// Color to use to clear the back buffer.
		public var clearColor:Vector3D;
		/// Allow to detect mouse events with non visible objects such as references or simplified geometry.
		public var ignoreInvisibleUnderMouse:Boolean = true;
		/// AssetLoader instance that manages all scene resources.
		public var library:AssetLoader;
		/// A reference to a LightFilter that manage all scene lights.
		public var lights:LightFilter;
		public var materials:Vector.<ShaderMaterialBase>;
		/// Main reference to the physics manager.
		public var physics:ZenPhysics;
		/**
		 * When is set to true, the scene will maintain a constant
		 * update framerate (based on scene.frameRate property), but render frames could be skipped to
		 * keep the framerate constant (recommended for games).
		 * Otherwise, then update and render will be synchronized with the enterFrame event (better sittuated for simple visualizations).
		 * By default is true.
		 */
		public var skipFrames:Boolean = false;
		public var surfaces:Vector.<ZenFace>;
		public var targetFilters:Vector.<ShaderMaterialBase>;
		public var textures:Vector.<ZenTexture>;
		
		public var renderToQuadVertices:int = 4;
		private var _renderToQuad:Boolean = false;
		private var renderTex:ZenTexture;
		public var renderBitmap:BitmapData;
		private var _renderToBitmap:Boolean = false;
		
		// CALLBACKS
		public var onCanZoom:Function;
		public var onStartDrag:Function;
		public var onStopDrag:Function;
		
		// STATUS
		public var dragging:Boolean;
		
		// CONFIG
		public var interactiveZoom:Boolean = true;
		public var interactiveRotate:Boolean = true;
		public var autoRotate:Boolean;
		public var autoRotateSpeed:Number = 1;
		public var rotateSmoothing:Number = 1;
		public var rotateSpeed:Number = 0.5;
		
		private var _out:Vector3D;
		public var _drag:Boolean;
		public var _dragActive:Boolean;
		private var _spinX:Number = 0;
		private var _spinY:Number = 0;
		private var _spinZ:Number = 0;
		private var dragSGX:Number = 0;
		private var dragSGY:Number = 0;
		
		public static const UPDATE_EVENT:String = "update";
		public static const RENDER_EVENT:String = "render";
		public static const PAUSED_EVENT:String = "paused";
		public static const POSTUPDATE_EVENT:String = "postUpdate";
		public static const POSTRENDER_EVENT:String = "postRender";
		public static const OVERLAY_EVENT:String = "overlay";
		public static const COMPLETE_EVENT:String = "complete";
		public static const PROGRESS_EVENT:String = "progress";
		
		private static var _temp:Vector3D = new Vector3D();
		private static var _stages3d:int;
		
		private var _antialias:int = 2;
		private var _autoResize:Boolean = false;
		private var _camera:ZenCamera;
		private var _clipped:Boolean = false;
		private var _container:DisplayObjectContainer;
		private var _context:Context3D;
		private var _currTime:Number;
		private var _dispatchRenderEvent:Boolean = false;
		private var _down:ZenMesh;
		private var _enableUpdateAndRender:Boolean = true;
		private var _fist;
		private var _frameCount:int;
		private var _frameRate:Number;
		private var _info:Intersection3D;
		private var _input:Boolean;
		private var _interactive:MouseIntersect;
		private var _last:Intersection3D;
		private var _lastCursor:String;
		private var _layers:Vector.<LayerSort>;
		private var _lights:Vector.<ZenLight>;
		private var _mouseEnabled:Boolean = true;
		private var _overlayEvent:Event;
		private var _paused:Boolean;
		private var _pausedEvent:Event;
		private var _postUpdateEvent:Event;
		private var _prEvent:Event;
		private var _profile:String;
		private var _quadMaterial:QuadMaterial;
		private var _renderCount:int;
		private var _renderEvent:Event;
		private var _renderIndex:int;
		private var _renderLength:int;
		private var _renderList:Vector.<ZenObject>;
		private var _rendersPerSecond:int;
		private var _renderTime:int;
		private var _secondTargetTexture:ZenTexture;
		private var _stage:Stage;
		private var _stage3D:Stage3D;
		private var _stageIndex:int;
		private var _startTime:Number;
		private var _targetMaterial:ShaderMaterialBase;
		private var _targetQuad:ZenSceneCanvas;
		private var _targetTexture:ZenTexture;
		private var _tick:Number;
		private var _time:Number;
		private var _timer:int;
		private var _updateCount:int;
		private var _updated:Boolean;
		private var _updateEvent:Event;
		private var _updateIndex:int;
		private var _updateLength:int;
		private var _updateList:Vector.<ZenObject>;
		private var _updatesPerSecond:int;
		private var _updateStaticIndex:Dictionary;
		private var _updateTime:int;
		private var _viewPort:Rectangle;
		
		/**
		 * Create a new Zen3D instance and initialize the static classes.
		 * 
		 * @param	container	Sprite to hold the scene viewport. It must not be rotated or scaled.
		 */
		public function Zen3D(container:DisplayObjectContainer) {
			init();
			
			this._out = new Vector3D();
			this._prEvent = new Event(POSTRENDER_EVENT, false, true);
			this._pausedEvent = new Event(PAUSED_EVENT, false, true);
			this._updateEvent = new Event(UPDATE_EVENT, false, true);
			this._postUpdateEvent = new Event(POSTUPDATE_EVENT, false, true);
			this._renderEvent = new Event(RENDER_EVENT, false, true);
			this._overlayEvent = new Event(OVERLAY_EVENT, false, true);
			this._interactive = new MouseIntersect();
			this.physics = new ZenPhysics();
			this.clearColor = new Vector3D(0.25, 0.25, 0.25, 1);
			this.materials = new Vector.<ShaderMaterialBase>();
			this.surfaces = new Vector.<ZenFace>();
			this.textures = new Vector.<ZenTexture>();
			this._quadMaterial = new QuadMaterial();
			this.targetFilters = new Vector.<ShaderMaterialBase>();
			this._last = new Intersection3D();
			this._updateStaticIndex = new Dictionary(true);
			this._updateList = new Vector.<ZenObject>();
			this._renderList = new Vector.<ZenObject>();
			this._lights = new Vector.<ZenLight>();
			super("Scene");
			this.library = new AssetLoader();
			this.library.addEventListener("progress", dispatchEvent, false, 0, true);
			this.library.addEventListener("complete", dispatchEvent, false, 0, true);
			this.library.addEventListener("ioError", dispatchEvent, false, 0, true);
			this.profile = ZenUtils.profile;
			this._camera = new ZenCamera("Default_Scene_Camera");
			this._camera.parent = this;
			ZenUtils.scene = this;
			ZenUtils.camera = this.camera;
			this.lights = new LightFilter(LightFilter.SAMPLED, 0, 1, true);
			this.lights.scene = this;
			this.frameRate = 45;
			this._container = container;
			if (this._container.stage) {
				this.addedToStageEvent();
			} else {
				this._container.addEventListener(Event.ADDED_TO_STAGE, this.addedToStageEvent, false, 0, true);
			}
		}
		
		public static function init():void {
			ZenUtils.init();
		}
		
		override public function dispose():void {
			this.freeMemory();
			super.dispose();
			if (ZenUtils.scene == this) {
				ZenUtils.scene = null;
			}
			if (ZenUtils.camera == this.camera) {
				ZenUtils.camera = null;
			}
			if (this.library) {
				this.library.dispose();
				this.library = null;
			}
			if (this.lights) {
				this.lights.dispose();
				this.lights = null;
			}
			this.camera = null;
			if (this._container.stage) {
				this.autoResize = false;
				this._container.stage.removeEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownEvent);
				this._container.stage.removeEventListener(MouseEvent.MOUSE_UP, this.mouseUpEvent);
				this._container.stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.mouseMoveEvent);
				this._container.stage.removeEventListener(MouseEvent.MOUSE_WHEEL, this.mouseWheelEvent);
			}
			/*try {
			   if (this._showMenu){
			   this._container.contextMenu = null;
			   }
			   } catch(e) {
			   }*/
			this._container.removeEventListener(Event.ENTER_FRAME, this.enterFrameEvent);
			this._container = null;
			this._stage3D.removeEventListener(Event.CONTEXT3D_CREATE, this.stageContextEvent);
			this._stage3D = null;
			if (this._context) {
				this._context.dispose();
				this._context = null;
			}
			this._info = null;
			this._last = null;
			this._down = null;
			this._updateStaticIndex = null;
			this._renderList = null;
			this._updateList = null;
			this._lights = null;
			this._layers = null;
			this._interactive.dispose();
			this._interactive = null;
			this._prEvent = null;
			this._pausedEvent = null;
			this._container = null;
			this._viewPort = null;
			this._fist = null;
			_stages3d = (_stages3d - (1 << this._stageIndex));
			Mouse.cursor = ((this._lastCursor) || (MouseCursor.AUTO));
			this._lastCursor = null;
		}
		
		private function addedToStageEvent(e:Event = null):void {
			var e = e;
			this._container.removeEventListener(Event.ADDED_TO_STAGE, this.addedToStageEvent);
			this._stage = this._container.stage;
			if (_stages3d == 0) {
				this._input = true;
			}
			if (this._input) {
				ZenInput.initialize(this._stage);
			}
			this._stage.addEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownEvent, false, 0, true);
			this._stage.addEventListener(MouseEvent.MOUSE_UP, this.mouseUpEvent, false, 0, true);
			this._stage.addEventListener(MouseEvent.MOUSE_MOVE, this.mouseMoveEvent, false, 0, true);
			this._stage.addEventListener(MouseEvent.MOUSE_WHEEL, this.mouseWheelEvent, false, 0, true);
			this._container.addEventListener(Event.REMOVED_FROM_STAGE, this.removedFromStageEvent, false, 0, true);
			this._stageIndex = -1;
			if ((_stages3d & 1) == 0) {
				this._stageIndex = 0;
			} else {
				if ((_stages3d & 2) == 0) {
					this._stageIndex = 1;
				} else {
					if ((_stages3d & 4) == 0) {
						this._stageIndex = 2;
					} else {
						if ((_stages3d & 8) == 0) {
							this._stageIndex = 3;
						}
					}
				}
			}
			if (this._stageIndex >= 0) {
				_stages3d = (_stages3d | (1 << this._stageIndex));
			} else {
				
				throw new Error("No more Stage3D's availables.");
				
				return;
			}
			this._stage3D = this._stage.stage3Ds[this._stageIndex];
			this._stage3D.addEventListener(Event.CONTEXT3D_CREATE, this.stageContextEvent, false, 0, true);
			try {
				this._stage3D.requestContext3D.call(this, Context3DRenderMode.AUTO, this.profile);
			} catch (e) {
				trace("Unsuported profile", profile);
				_stage3D.requestContext3D(Context3DRenderMode.AUTO);
			}
			this.autoResize = this._autoResize;
		}
		
		private function removedFromStageEvent(e:Event):void {
			removeEventListener(Event.REMOVED_FROM_STAGE, this.removedFromStageEvent);
			this._stage.removeEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownEvent);
			this._stage.removeEventListener(MouseEvent.MOUSE_UP, this.mouseUpEvent);
			this._stage.removeEventListener(MouseEvent.MOUSE_MOVE, this.mouseMoveEvent);
			this._stage.removeEventListener(MouseEvent.MOUSE_WHEEL, this.mouseWheelEvent);
			this._stage.removeEventListener(Event.RESIZE, this.resizeStageEvent);
			this._stage = null;
			if (this.autoDispose) {
				this.dispose();
			}
		}
		
		private function stageContextEvent(e:Event):void {
			this._context = this._stage3D.context3D;
			if (this._context.driverInfo.indexOf("Software") != -1) {
				trace("WARNING: you are running in software mode!");
			}
			if (!(this._viewPort)) {
				this.setViewport(0, 0, this._stage.stageWidth, this._stage.stageHeight, this._antialias);
			} else {
				this._stage3D.x = this._viewPort.x;
				this._stage3D.y = this._viewPort.y;
				this._context.configureBackBuffer(this._viewPort.width, this._viewPort.height, this._antialias, true);
			}
			if (this._enableUpdateAndRender) {
				this._container.addEventListener(Event.ENTER_FRAME, this.enterFrameEvent);
			}
			dispatchEvent(e);
		}
		
		private function onUpdate():void {
			if (ZenInput.eventPhase > EventPhase.AT_TARGET) {
				return;
			}
			
			// on mouse RELEASE
			if (interactiveRotate) {
				if (ZenInput.mouseUp) {
					this._drag = false;
					_dragActive = false;
					
					// inform parent
					if (_dragActive) {
						if (onStopDrag) {
							onStopDrag();
						}
					}
				}
			}
			
			// if mouse PRESSED
			dragging = this._drag;
			if (interactiveRotate) {
				if (this._drag) {
					
					// calc mouse movement
					if (!_dragActive) {
						var dragDX:Number = (stage.mouseX - dragSGX);
						var dragDY:Number = (stage.mouseY - dragSGY);
						var diff:Number = dragDX + dragDY;
						
						// only inform parent after certain pixels
						if (diff > 3) {
							_dragActive = true;
							
							// inform parent
							if (onStartDrag) {
								onStartDrag();
							}
						}
					}
					
					// if space
					if (ZenInput.keyDown(KeyCodes.Spacebar)) {
						
						// MOVE
						camera.translateX(((-(ZenInput.mouseXSpeed) * camera.getPosition().length) / 300));
						camera.translateY(((ZenInput.mouseYSpeed * camera.getPosition().length) / 300));
						
					} else {
						
						// ORBIT
						this._spinX = (this._spinX + ((ZenInput.mouseXSpeed * this.rotateSmoothing) * this.rotateSpeed));
						this._spinY = (this._spinY + ((ZenInput.mouseYSpeed * this.rotateSmoothing) * this.rotateSpeed));
					}
				}
			}
			
			// ZOOM
			if (interactiveZoom) {
				if (ZenInput.delta != 0 && viewPort.contains(ZenInput.mouseX, ZenInput.mouseY) && (onCanZoom == null || onCanZoom() == true)) {
					this._spinZ = ((((camera.getPosition(false, this._out).length + 0.1) * this.rotateSpeed) * ZenInput.delta) / 20);
				}
			}
			
			calcCamera();
			
			// if mouse PRESS
			if (interactiveRotate) {
				if ((ZenInput.mouseHit && (viewPort.contains(ZenInput.mouseX, ZenInput.mouseY)))) {
					
					// save that mouse pressed
					this._drag = true;
					_dragActive = false;
					
					// record initial conditions
					dragSGX = stage.mouseX;
					dragSGY = stage.mouseY;
				}
			}
		
		}
		
		private function calcCamera():void {
			
			camera.translateZ(this._spinZ);
			camera.rotateY(this._spinX, false, V3D.ZERO);
			camera.rotateX(this._spinY, true, V3D.ZERO);
			this._spinX = (this._spinX * (1 - this.rotateSmoothing));
			this._spinY = (this._spinY * (1 - this.rotateSmoothing));
			this._spinZ = (this._spinZ * (1 - this.rotateSmoothing));
		
		}
		
		public function get stage():Stage {
			return _stage;
		}
		
		public function set backgroundColor(value:int):void {
			ZenUtils.ColorToVector(value, clearColor);
		}
		
		public function get backgroundColor():int {
			return ZenUtils.ColorFromVector(clearColor);
		}
		
		/**
		 * Sets the dimensions of the canvas rendering area.
		 * @param	x	left maring of rendering area in pixels.
		 * @param	y	Top maring of rendering area in pixels.
		 * @param	width	Width of rendering area in pixels.
		 * @param	height	Height of rendering area in pixels.
		 * @param	antialias	an int selecting anti-aliasing quality. 0 is no anti-aliasing. Correlates to the number of sub-samples; a value of 2 is generally the minimum, although some systems with anti-alias with a value of one. More anti-aliasing is more depanding on the GPU and may impact performance.
		 */
		public function setViewport(x:Number = 0, y:Number = 0, width:Number = 640, height:Number = 480, antialias:int = 0):void {
			var antialias:int = antialias;
			if (width < 50) {
				width = 50;
			}
			if (height < 50) {
				height = 50;
			}
			if (((this._context) && (!((this._context.driverInfo.indexOf("Software") == -1))))) {
				if (width > 0x0800) {
					width = 0x0800;
				}
				if (height > 0x0800) {
					height = 0x0800;
				}
			}
			if (((((((((((this._viewPort) && ((this._viewPort.x == x)))) && ((this._viewPort.y == y)))) && ((this._viewPort.width == width)))) && ((this._viewPort.height == height)))) && ((this._antialias == antialias)))) {
				return;
			}
			if (!(this._viewPort)) {
				this._viewPort = new Rectangle();
			}
			this._viewPort.x = x;
			this._viewPort.y = y;
			this._viewPort.width = width;
			this._viewPort.height = height;
			if (this._camera) {
				this._camera.updateProjectionMatrix();
			}
			if (((this._stage3D) && (this._stage3D.context3D))) {
				try {
					this._stage3D.x = this._viewPort.x;
					this._stage3D.y = this._viewPort.y;
					this._context.configureBackBuffer(this._viewPort.width, this._viewPort.height, this._antialias, true);
				} catch (err) {
					trace(err);
				}
			}
		}
		
		/// Sets or returns the camera to be used for rendering.
		public function get camera():ZenCamera {
			return (this._camera);
		}
		
		public function set camera(value:ZenCamera):void {
			this._camera = value;
			
			if (_camera) {
				_camera.activeScene = this;
			}
		
		}
		
		public function drawQuadTexture(texture:ZenTexture, x:Number, y:Number, width:Number, height:Number, material:ShaderMaterialBase = null, sourceFactor:String = "sourceAlpha", destFactor:String = "oneMinusSourceAlpha"):void {
			if (!(material)) {
				this._quadMaterial.texture = texture;
				this._quadMaterial.programs[0].sourceFactor = sourceFactor;
				this._quadMaterial.programs[0].destFactor = destFactor;
			}
			this._targetQuad = ((this._targetQuad) || (new ZenSceneCanvas("screen_quad", 0, 0, 0, 0, false)));
			this._targetQuad.setTo(x, y, width, height);
			this._targetQuad.draw(false, ((material) || (this._quadMaterial)));
		}
		
		/// Updates global constants for each frame.
		public function setupConstants():void {
			var timer:int = getTimer();
			ZenUtils.time[0] = (timer / 1000);
			ZenUtils.time[1] = (timer / 2000);
			ZenUtils.time[2] = (timer / 4000);
			ZenUtils.time[3] = (timer / 16000);
			ZenUtils.cos_time[0] = Math.cos(ZenUtils.time[0]);
			ZenUtils.cos_time[1] = Math.cos(ZenUtils.time[1]);
			ZenUtils.cos_time[2] = Math.cos(ZenUtils.time[2]);
			ZenUtils.cos_time[3] = Math.cos(ZenUtils.time[3]);
			ZenUtils.sin_time[0] = Math.sin(ZenUtils.time[0]);
			ZenUtils.sin_time[1] = Math.sin(ZenUtils.time[1]);
			ZenUtils.sin_time[2] = Math.sin(ZenUtils.time[2]);
			ZenUtils.sin_time[3] = Math.sin(ZenUtils.time[3]);
			ZenUtils.mouse[0] = ZenInput.mouseX;
			ZenUtils.mouse[1] = ZenInput.mouseY;
			ZenUtils.mouse[2] = (ZenInput.mouseX / this._viewPort.width);
			ZenUtils.mouse[3] = (ZenInput.mouseY / this._viewPort.height);
			ZenUtils.screen[0] = this._viewPort.width;
			ZenUtils.screen[1] = this._viewPort.height;
			ZenUtils.screen[2] = (1 / this._viewPort.width);
			ZenUtils.screen[3] = (1 / this._viewPort.height);
			ZenUtils.random[0] = Math.random();
			ZenUtils.random[1] = Math.random();
			ZenUtils.random[2] = Math.random();
			ZenUtils.random[3] = Math.random();
			ZenUtils.lastMaterial = null;
			ZenUtils.program = null;
			ZenUtils.depthWrite = true;
			ZenUtils.depthCompare = null;
		}
		
		/**
		 * This method prepares the scene to be rendered.
		 * The render method call to this before render. You should only use this function if you want to
		 * draw manually specific objects.
		 * @param	camera
		 */
		public function setupFrame(camera:ZenCamera = null):void {
			var l:LayerSort;
			ZenUtils.camera = ((camera) || (this._camera));
			ZenUtils.camera.updateProjectionMatrix();
			ZenUtils.cameraGlobal.copyFrom(ZenUtils.camera.world);
			ZenUtils.viewProj.copyFrom(ZenUtils.camera.viewProjection);
			ZenUtils.proj.copyFrom(ZenUtils.camera.projection);
			ZenUtils.view.copyFrom(ZenUtils.camera.view);
			ZenUtils.viewPort = ((ZenUtils.camera.viewPort) || (this._viewPort));
			ZenUtils.lastMaterial = null;
			ZenUtils.context = this._stage3D.context3D;
			ZenUtils.scene = this;
			ZenUtils.camera.getPosition(false, _temp);
			ZenUtils.cam[0] = _temp.x;
			ZenUtils.cam[1] = _temp.y;
			ZenUtils.cam[2] = _temp.z;
			ZenUtils.nearFar[0] = ZenUtils.camera.near;
			ZenUtils.nearFar[1] = ZenUtils.camera.far;
			ZenUtils.nearFar[2] = (ZenUtils.camera.far - ZenUtils.camera.near);
			if (((ZenUtils.camera.viewPort) && (ZenUtils.camera.clipRectangle))) {
				this._context.setScissorRectangle(ZenUtils.camera.viewPort);
				this._clipped = true;
			} else {
				if (this._clipped) {
					this._context.setScissorRectangle(null);
					this._clipped = false;
				}
			}
			for each (l in this._layers) {
				if (!!(l.active)) {
					if (l.mode == StageSortMode.BACK_TO_FRONT) {
						this.sortByPriorityAsc(this._renderList, l.left, l.right);
					} else {
						if (l.mode == StageSortMode.FRONT_TO_BACK) {
							this.sortByPriorityDesc(this._renderList, l.left, l.right);
						}
					}
				}
			}
			if (this.lights) {
				this.lights.update();
			}
		}
		
		override public function draw(includeChildren:Boolean = true, material:ShaderMaterialBase = null):void {
			
			throw new Error("The ZenStage can not be drawn, please use render method instead.");
		
		}
		
		/// Forces to update the scene and animations and will dispatch the scene 'update' event.
		override public function update():void {
			if (this._input) {
				ZenInput.update();
			}
			var t:int = getTimer();
			var doUpdate:Boolean = true;
			if (hasEventListener(UPDATE_EVENT)) {
				doUpdate = dispatchEvent(this._updateEvent);
				onUpdate();
			}
			if (!(doUpdate)) {
				return;
			}
			this._updateLength = this._updateList.length;
			this._updateIndex = 0;
			while (this._updateIndex < this._updateLength) {
				this._updateList[this._updateIndex].update();
				this._updateIndex++;
			}
			if (((this._updateList) && (hasEventListener(POSTUPDATE_EVENT)))) {
				dispatchEvent(this._postUpdateEvent);
			}
			this._updateTime = (getTimer() - t);
		}
		
		private function enterFrameEvent(e:Event):void {
			renderScene();
			
			// if not dragging
			if (!this._drag) {
				
				if (autoRotate) {
					
					this._spinX = autoRotateSpeed;
					this._spinY = 0;
					
					calcCamera();
				}
				
			}
		
		}
		
		public function renderScene():void {
			var length:int;
			var textureA:TextureBase;
			var textureB:TextureBase;
			var f:int;
			if (!(this._stage)) {
				return;
			}
			this._currTime = getTimer();
			if (this.skipFrames) {
				while (this._time < this._currTime) {
					this._updateCount++;
					if (!(this._paused)) {
						this.update();
					} else {
						if (this._input) {
							ZenInput.update();
						}
						dispatchEvent(this._pausedEvent);
					}
					this._time = (this._time + this._tick);
					this._updated = true;
					if (!(this._context)) {
						return;
					}
				}
				if ((this._currTime - this._timer) > 1000) {
					this._timer = (this._timer + 1000);
					this._updatesPerSecond = this._updateCount;
					this._rendersPerSecond = this._renderCount;
					this._renderCount = 0;
					this._updateCount = 0;
				}
			} else {
				if (!(this._paused)) {
					this.update();
				} else {
					if (this._input) {
						ZenInput.update();
					}
					dispatchEvent(this._pausedEvent);
				}
				this._updated = true;
			}
			ZenUtils.frameCount = this._frameCount++;
			ZenUtils.trianglesDrawn = 0;
			ZenUtils.drawCalls = 0;
			ZenUtils.objectsDrawn = 0;
			ZenUtils.camera = this.camera;
			ZenUtils.camera.updateProjectionMatrix();
			ZenUtils.cameraGlobal.copyFrom(ZenUtils.camera.world);
			ZenUtils.viewProj.copyFrom(ZenUtils.camera.viewProjection);
			ZenUtils.proj.copyFrom(ZenUtils.camera.projection);
			ZenUtils.view.copyFrom(ZenUtils.camera.view);
			ZenUtils.context = this._stage3D.context3D;
			ZenUtils.scene = this;
			if (((this._stage3D.context3D) && (this._updated))) {
				this._updated = false;
				if (!(this._paused)) {
					this._renderCount++;
					this._renderTime = getTimer();
					this._context.clear(this.clearColor.x, this.clearColor.y, this.clearColor.z, this.clearColor.w);
					ZenUtils.setDepthTest(true, Context3DCompareMode.LESS_EQUAL);
					this._dispatchRenderEvent = true;
					
					// RENDER TO SCREEN
					if (((this.lights) && (this.lights.renderShadows()))) {
						if (!(this.targetTexture)) {
							this._context.setRenderToBackBuffer();
						}
					}
					
					// RENDER ALL OBJS TO SCREEN
					this.render(this._camera, false, this.targetTexture);
					
					if (hasEventListener(POSTRENDER_EVENT)) {
						this.dispatchEvent(this._prEvent);
					}
					
					// RENDER TO TEXTURE ALSO
					if (this.targetTexture) {
						this._targetQuad = ((this._targetQuad) || (new ZenSceneCanvas("screen_quad", 0, 0, 0, 0, false)));
						this._targetQuad.setTo(0, 0, this._viewPort.width, this._viewPort.height);
						length = this.targetFilters.length;
						if ((((length > 1)) && (!(this._secondTargetTexture)))) {
							this._secondTargetTexture = new ZenTexture((this._targetTexture.request as Point), true);
							this._secondTargetTexture.mipMode = this._targetTexture.mipMode;
							this._secondTargetTexture.filterMode = this._targetTexture.filterMode;
							this._secondTargetTexture.wrapMode = this._targetTexture.wrapMode;
							this._secondTargetTexture.bias = this._targetTexture.bias;
							this._secondTargetTexture.upload(this);
						}
						textureA = this._targetTexture.texture;
						textureB = ((this._secondTargetTexture) ? this._secondTargetTexture.texture : null);
						f = 0;
						while (f < length) {
							if ((f % 2) == 0) {
								this._targetTexture.texture = textureA;
								if (f == (length - 1)) {
									this._context.setRenderToBackBuffer();
								} else {
									this._context.setRenderToTexture(textureB);
								}
								this._context.clear(this.clearColor.x, this.clearColor.y, this.clearColor.z, this.clearColor.w);
							} else {
								this._targetTexture.texture = textureB;
								if (f == (length - 1)) {
									this._context.setRenderToBackBuffer();
								} else {
									this._context.setRenderToTexture(textureA);
								}
								this._context.clear(this.clearColor.x, this.clearColor.y, this.clearColor.z, this.clearColor.w);
							}
							this._targetQuad.draw(false, this.targetFilters[f]);
							f++;
						}
						if (length == 0) {
							if (!(this._targetMaterial)) {
								this._targetMaterial = new QuadMaterial(this._targetTexture);
							}
							this._context.setRenderToBackBuffer();
							this._targetQuad.draw(false, this._targetMaterial);
						}
						this._targetTexture.texture = textureA;
						this.endFrame();
					}
					
					// END RENDER
					if (hasEventListener(OVERLAY_EVENT)) {
						dispatchEvent(this._overlayEvent);
					}
					
					if (_renderToBitmap) {
						_context.drawToBitmapData(renderBitmap);
					} else {
						this._context.present();
					}
					
					this._renderTime = (getTimer() - this._renderTime);
					
				} else {
					if (hasEventListener(RENDER_EVENT)) {
						dispatchEvent(this._renderEvent);
					}
				}
			}
		}
		
		/**
		 * Renders the current scene frame. This method is called by the scene automatically but can force the rendering if necessary or if the scene is paused.
		 * This method also will dispatch the scene 'render' event but not the 'postRender' event.
		 */
		public function render(camera:ZenCamera = null, clearDepth:Boolean = false, target:ZenTexture = null):void {
			if (((((!(this._stage3D)) || (!(this._stage3D.context3D)))) || (!(this._renderList)))) {
				return;
			}
			if (target) {
				if (!(target.scene)) {
					target.upload(this);
				}
				this._context.setRenderToTexture(target.texture, true, this._antialias);
				this._context.clear(this.clearColor.x, this.clearColor.y, this.clearColor.z, this.clearColor.w);
			} else {
				if (clearDepth) {
					this._context.clear(0, 0, 0, 0, 1, 0, Context3DClearMask.DEPTH);
				}
			}
			var doRender:Boolean = true;
			if (this.lights) {
				this.lights.list = this._lights;
			}
			this.setupFrame(camera);
			this.setupConstants();
			if (((!(this._paused)) && (this._dispatchRenderEvent))) {
				this._dispatchRenderEvent = false;
				if (hasEventListener(RENDER_EVENT)) {
					doRender = dispatchEvent(this._renderEvent);
				}
			}
			if (!(this._renderList)) {
				return;
			}
			if (doRender) {
				this._renderLength = this._renderList.length;
				this._renderIndex = 0;
				while (this._renderIndex < this._renderLength) {
					this._renderList[this._renderIndex].draw(false);
					this._renderIndex++;
				}
			}
			if (target) {
				this._context.setRenderToBackBuffer();
			}
			this.endFrame();
		}
		
		public function endFrame():void {
			var i:int;
			i = 0;
			while (i < ZenUtils.usedSamples) {
				ZenUtils.setTextureAt(i, null);
				i++;
			}
			i = 0;
			while (i < ZenUtils.usedBuffers) {
				this._context.setVertexBufferAt(i, null);
				i++;
			}
			ZenUtils.setDepthTest(false, Context3DCompareMode.ALWAYS);
		}
		
		/**
		 * Loads a texture from an external file.
		 * @param	request	File path.
		 * @return	The loaded texture. The texture will become available after the “complete” event of the scene.
		 */
		public function addTextureFromFile(request, optimizeForRenderToTexture:Boolean = false, format:int = 0, type:int = 0):ZenTexture {
			var texture:ZenTexture = new ZenTexture(request, optimizeForRenderToTexture, format, type);
			this.library.addItem(request, texture);
			this.library.push(texture);
			return (texture);
		}
		
		private function completeResourceEvent(e:Event):void {
			if (this._camera.name != "Default_Scene_Camera") {
				return;
			}
			if ((((((e.target == this._fist)) && (e.target.hasOwnProperty("activeCamera")))) && (e.target.activeCamera))) {
				this.camera = e.target.activeCamera;
				this._fist = true;
				this._camera.dirty = true;
			}
		}
		
		/**
		 * Gets the global loading process of the scene.
		 * The returned value is a percent value between 0 and 100.
		 */
		public function get loadProgress():Number {
			return (this.library.progress);
		}
		
		override public function get parent():ZenObject {
			return (null);
		}
		
		override public function set parent(value:ZenObject):void {
		}
		
		/// Exits pause mode.
		public function resume():void {
			if (((this._stage3D) && (this._stage3D.context3D))) {
				this._context.clear(this.clearColor.x, this.clearColor.y, this.clearColor.z, this.clearColor.w);
				this.render();
				this._context.present();
			}
			this.frameRate = this._frameRate;
			this._frameCount = 0;
			this._paused = false;
		}
		
		/// Pauses the “update” event and starts shooting the “paused” event.
		public function pause():void {
			this._paused = true;
		}
		
		/// Returns 'true' if the scene is paused.
		public function get paused():Boolean {
			return (this._paused);
		}
		
		/// An int selecting anti-aliasing quality. 0 is no anti-aliasing. Correlates to the number of sub-samples; a value of 2 is generally the minimum, although some systems with anti-alias with a value of one. More anti-aliasing is more depanding on the GPU and may impact performance.
		public function get antialias():int {
			return (this._antialias);
		}
		
		public function set antialias(value:int):void {
			this._antialias = value;
			if (((((this._viewPort) && (this._stage3D))) && (this._context))) {
				this._context.configureBackBuffer(this._viewPort.width, this._viewPort.height, this._antialias);
			}
		}
		
		/// Gets the viewport area associated to the Stage3D.
		public function get viewPort():Rectangle {
			return (this._viewPort);
		}
		
		/// Returns the time taken to update the scene in milliseconds.
		public function get updateTime():int {
			return (this._updateTime);
		}
		
		/**
		 * Returns time taken to render the scene, including lights, object occlusion, drawing, etc.., in milliseconds.
		 * The returned time, does not include the present call.
		 */
		public function get renderTime():int {
			return (this._renderTime);
		}
		
		/// Returns the rendering frame rate for statistical purposes.
		public function get rendersPerSecond():int {
			return (this._rendersPerSecond);
		}
		
		/// Returns the update frame rate for statistical purposes.
		public function get updatesPerSecond():int {
			return (this._updatesPerSecond);
		}
		
		/// Gets and sets the frame rate of the 3d scene only for the "update" event. The frame rate is defined as frames per second.
		public function get frameRate():Number {
			return (this._frameRate);
		}
		
		public function set frameRate(value:Number):void {
			this._frameRate = value;
			this._startTime = getTimer();
			this._time = this._startTime;
			this._tick = (1000 / this._frameRate);
		}
		
		private function mouseDownEvent(e:MouseEvent):void {
			if (this._interactive) {
				if (((!(this._mouseEnabled)) || ((ZenInput.eventPhase > EventPhase.AT_TARGET)))) {
					return;
				}
				this._info = null;
				this._last.mesh = null;
				this._last.surface = null;
				this._down = null;
				this.updateMouseEvents();
				if (this._interactive.data.length) {
					this._down = this._interactive.data[0].mesh;
				}
				if (this._info) {
					this._info.mesh.dispatchEvent(new MouseEvent3D(MouseEvent3D.MOUSE_DOWN, this._info));
				}
			}
		}
		
		private function mouseUpEvent(e:MouseEvent):void {
			if (this._interactive) {
				if (((!(this._mouseEnabled)) || ((ZenInput.eventPhase > EventPhase.AT_TARGET)))) {
					return;
				}
				if (this._interactive.data.length) {
					this._interactive.data[0].mesh.dispatchEvent(new MouseEvent3D(MouseEvent3D.MOUSE_UP, this._info));
					if (((this._down) && ((this._down == this._interactive.data[0].mesh)))) {
						this._interactive.data[0].mesh.dispatchEvent(new MouseEvent3D(MouseEvent3D.CLICK, this._info));
					}
				}
				this._down = null;
				this.updateMouseEvents();
			}
		}
		
		private function mouseMoveEvent(e:MouseEvent):void {
			if (this._interactive) {
				if (((((!(this._mouseEnabled)) || ((ZenInput.eventPhase > EventPhase.AT_TARGET)))) || ((this._interactive.collisionCount == 0)))) {
					return;
				}
				if (this._info) {
					this._last.mesh = this._info.mesh;
					this._last.surface = this._info.surface;
					this._last.normal = this._info.normal;
					this._last.point = this._info.point;
					this._last.poly = this._info.poly;
				} else {
					this._last.mesh = null;
				}
				this.updateMouseEvents();
			}
		}
		
		/// This method forces to update mouse events for all 3D objects in the scene.
		public function updateMouseEvents():void {
			if (((((this._viewPort) && (this._viewPort.contains(ZenInput.mouseX, ZenInput.mouseY)))) && (this._interactive.test(ZenInput.mouseX, ZenInput.mouseY, true, this.ignoreInvisibleUnderMouse)))) {
				this._info = this._interactive.data[0];
				this._info.mesh.dispatchEvent(new MouseEvent3D(MouseEvent3D.MOUSE_MOVE, this._info));
				if (((this._last.mesh) && (!((this._last.mesh == this._info.mesh))))) {
					this._last.mesh.dispatchEvent(new MouseEvent3D(MouseEvent3D.MOUSE_OUT, this._last));
				}
				if (this._last.mesh != this._info.mesh) {
					this._info.mesh.dispatchEvent(new MouseEvent3D(MouseEvent3D.MOUSE_OVER, this._info));
				}
			} else {
				this._info = null;
				if (this._last.mesh) {
					this._last.mesh.dispatchEvent(new MouseEvent3D(MouseEvent3D.MOUSE_OUT, this._last));
				}
			}
			if (((this._info) && (this._info.mesh.useHandCursor))) {
				if (!(this._lastCursor)) {
					this._lastCursor = Mouse.cursor;
				}
				Mouse.cursor = MouseCursor.BUTTON;
			} else {
				if (this._lastCursor) {
					Mouse.cursor = this._lastCursor;
					this._lastCursor = null;
				}
			}
		}
		
		private function mouseWheelEvent(e:MouseEvent):void {
			if (((!(this._mouseEnabled)) || ((ZenInput.eventPhase > EventPhase.AT_TARGET)))) {
				return;
			}
			if (this._interactive.data.length) {
				this._interactive.data[0].mesh.dispatchEvent(new MouseEvent3D(MouseEvent3D.MOUSE_WHEEL, this._info));
			}
		}
		
		/// Enables or disable all mouse scene events.
		public function get mouseEnabled():Boolean {
			return (this._mouseEnabled);
		}
		
		public function set mouseEnabled(value:Boolean):void {
			this._mouseEnabled = value;
			if (this._mouseEnabled == false) {
				this._last.mesh = null;
				this._info = null;
				this._down = null;
			}
		}
		
		override public function get scene():Zen3D {
			return (this);
		}
		
		/**
		 * Enables or disable the automatic update, render and postRender events of the scene.
		 * Seting this property to false will allow you to manage your own update and render loop, calling to those methods manually.
		 */
		public function get enableUpdateAndRender():Boolean {
			return (this._enableUpdateAndRender);
		}
		
		public function set enableUpdateAndRender(value:Boolean):void {
			this._enableUpdateAndRender = value;
			if (((value) && (this._context))) {
				this._container.addEventListener(Event.ENTER_FRAME, this.enterFrameEvent, false, 0, true);
			} else {
				this._container.removeEventListener(Event.ENTER_FRAME, this.enterFrameEvent);
			}
			if (value) {
				this.frameRate = this._frameRate;
				this._frameCount = 0;
			}
		}
		
		/// Gets the associated Stage3D index.
		public function get stageIndex():int {
			return (this._stageIndex);
		}
		
		/** Returns the 2D screen coordinates of the given 3D point.
		   0,0 represents the top-left point of the 3D world.
		   The 2D point is relative to the current viewPort size.
		
		 * @param	out	If a vector is specified, this vector will be filled with the returned values.
		 * @return	The vector with the coordinates.
		 */
		override public function getPointScreenCoords(point:Vector3D, out:Vector3D = null, cam:ZenCamera = null):Vector3D {
			if (!(out)) {
				out = new Vector3D();
			}
			if (!cam) {
				cam = this.camera;
			}
			var t:Vector3D = cam.viewProjection.transformVector(point);
			var w2:Number = (_viewPort.width * 0.5);
			var h2:Number = (_viewPort.height * 0.5);
			out.x = ((((t.x / t.w) * w2) + w2));
			out.y = ((((-(t.y) / t.w) * h2) + h2));
			out.z = t.z;
			out.w = t.w;
			return (out);
		}
		
		/** returns true if the given 3D point (in world coordinates) is visible within the 2D viewport (also checks if within nearplane) */
		public function isPointOnScreen(point:Vector3D, cam:ZenCamera = null):Boolean {
			if (!cam) {
				cam = this.camera;
			}
			var t:Vector3D = cam.viewProjection.transformVector(point);
			var w2:Number = (_viewPort.width * 0.5);
			var h2:Number = (_viewPort.height * 0.5);
			var x:Number = (((t.x / t.w) * w2) + w2);
			var y:Number = (((-(t.y) / t.w) * h2) + h2);
			return t.z > 0 && x > 0 && y > 0 && x < _viewPort.width && y < _viewPort.height;
		}
		
		public function getVectorScreenCoords(point:Vector3D, out:Vector3D = null):Vector3D {
			if (!(out)) {
				out = new Vector3D();
			}
			this.camera.globalToLocalVector(point, out);
			return out;
		}
		
		public function isObjFullyInView(obj:ZenObject):Boolean {
			return camera.isObjFullyInView(obj);
		}
		
		public function isObjInView(obj:ZenObject):Boolean {
			return camera.isObjInView(obj);
		}
		
		override public function hide():void {
			visible = false;
			this._stage3D.visible = false;
		}
		
		override public function show():void {
			visible = true;
			this._stage3D.visible = true;
		}
		
		/**
		 * This property forces to the scene to take the stage dimensions when the stage is resized if is setted to true.
		 * Also changes the stage.align to topLeft and sets the stage.scaleMode to noScale.
		 */
		public function get autoResize():Boolean {
			return (this._autoResize);
		}
		
		public function set autoResize(value:Boolean):void {
			this._autoResize = value;
			if (this._stage) {
				if (value) {
					this._stage.align = "tl";
					this._stage.scaleMode = "noScale";
					this._stage.addEventListener(Event.RESIZE, this.resizeStageEvent, false, 0, true);
				} else {
					this._stage.removeEventListener(Event.RESIZE, this.resizeStageEvent);
				}
			}
		}
		
		private function resizeStageEvent(e:Event):void {
			if (this._stage) {
				this.setViewport(0, 0, this._stage.stageWidth, this._stage.stageHeight);
			}
		}
		
		private function sortByPriorityDesc(data:Vector.<ZenObject>, left:int, right:int):void {
			var i:int;
			var j:int;
			var e:int;
			var priority:int;
			var pivot:ZenObject;
			var temp:ZenObject;
			if ((right - left) < 20) {
				i = (left + 1);
				right++;
				while (i < right) {
					pivot = data[i];
					j = (i - 1);
					e = i;
					priority = pivot.priority;
					while ((((j >= left)) && ((data[j].priority > priority)))) {
						var _local10 = e--;
						data[_local10] = data[j--];
					}
					data[e] = pivot;
					i++;
				}
			} else {
				i = left;
				j = right;
				pivot = data[((left + right) >>> 1)];
				priority = pivot.priority;
				while (i <= j) {
					while (data[j].priority > priority) {
						j--;
					}
					while (data[i].priority < priority) {
						i++;
					}
					if (i <= j) {
						temp = data[i];
						data[i] = data[j];
						i++;
						data[j] = temp;
						j--;
					}
				}
				if (left < j) {
					this.sortByPriorityDesc(data, left, j);
				}
				if (i < right) {
					this.sortByPriorityDesc(data, i, right);
				}
			}
		}
		
		private function sortByPriorityAsc(data:Vector.<ZenObject>, left:int, right:int):void {
			var i:int;
			var j:int;
			var e:int;
			var priority:int;
			var pivot:ZenObject;
			var temp:ZenObject;
			if ((right - left) < 20) {
				i = (left + 1);
				right++;
				while (i < right) {
					pivot = data[i];
					j = (i - 1);
					e = i;
					priority = pivot.priority;
					while ((((j >= left)) && ((data[j].priority < priority)))) {
						var _local10 = e--;
						data[_local10] = data[j--];
					}
					data[e] = pivot;
					i++;
				}
			} else {
				i = left;
				j = right;
				pivot = data[((left + right) >>> 1)];
				priority = pivot.priority;
				while (i <= j) {
					while (data[j].priority < priority) {
						j--;
					}
					while (data[i].priority > priority) {
						i++;
					}
					if (i <= j) {
						temp = data[i];
						data[i] = data[j];
						i++;
						data[j] = temp;
						j--;
					}
				}
				if (left < j) {
					this.sortByPriorityAsc(data, left, j);
				}
				if (i < right) {
					this.sortByPriorityAsc(data, i, right);
				}
			}
		}
		
		/// Gets access to the render list.
		public function get renderList():Vector.<ZenObject> {
			return (this._renderList);
		}
		
		/// Gets access to the update list.
		public function get updateList():Vector.<ZenObject> {
			return (this._updateList);
		}
		
		public function removeFromScene(pivot:ZenObject, update:Boolean, render:Boolean, interactive:Boolean, collider:Boolean = false):void {
			var i:int;
			var l:LayerSort;
			if (((update) && (this._updateList.length))) {
				i = this._updateStaticIndex[pivot];
				if (this._updateList[i] == pivot) {
					this._updateList[i] = this._updateList[(this._updateList.length - 1)];
					this._updateStaticIndex[this._updateList[i]] = i;
					this._updateList.length--;
					this._updateLength--;
					this._updateIndex--;
					if (this._updateIndex < 0) {
						this._updateIndex = 0;
					}
					delete this._updateStaticIndex[pivot];
				}
			}
			if (render) {
				i = this._renderList.indexOf(pivot);
				if (i != -1) {
					this._renderList.splice(i, 1);
					this._renderLength--;
					this._renderIndex--;
					if (this._renderIndex < 0) {
						this._renderIndex = 0;
					}
					for each (l in this._layers) {
						if (!!(l.active)) {
							if (pivot.layer <= l.layer) {
								l.right--;
							}
							if (pivot.layer < l.layer) {
								l.left--;
							}
							if ((l.right - l.left) < 0) {
								l.active = false;
							}
						}
					}
				}
			}
			if (interactive) {
				this._interactive.removeCollisionWith(pivot, false);
			}
			if (collider) {
				this.physics.removeCollider(pivot.collider);
			}
			if ((pivot is ZenLight)) {
				i = this._lights.indexOf((pivot as ZenLight));
				if (i >= 0) {
					this._lights.splice(i, 1);
				}
			}
		}
		
		public function insertIntoScene(pivot:ZenObject, update:Boolean, render:Boolean, interactive:Boolean, collider:Boolean = false):void {
			var middle:int;
			var left:int;
			var right:int;
			var value:int;
			var l:LayerSort;
			if (pivot.lock) {
				return;
			}
			if (update) {
				if (this._updateStaticIndex[pivot] == null) {
					this._updateStaticIndex[pivot] = this._updateList.length;
					this._updateList[this._updateList.length] = pivot;
				}
			}
			if (render) {
				left = 0;
				right = this._renderList.length;
				value = pivot.layer;
				while (left < right) {
					middle = ((left + right) >>> 1);
					if (this._renderList[middle].layer == value) break;
					if ((value > this._renderList[middle].layer)) {
						left = ++middle;
					} else {
						right = middle;
					}
				}
				this._renderList.splice(middle, 0, pivot);
				for each (l in this._layers) {
					if (((!(l.active)) && ((pivot.layer == l.layer)))) {
						l.active = true;
						l.left = middle;
						l.right = middle;
					} else {
						if (l.active) {
							if (pivot.layer <= l.layer) {
								l.right++;
							}
							if (pivot.layer < l.layer) {
								l.left++;
							}
						}
					}
				}
			}
			if (interactive) {
				this._interactive.addCollisionWith(pivot, false);
				this.updateMouseEvents();
			}
			if (collider) {
				this.physics.addCollider(pivot.collider);
			}
			if ((((pivot is ZenLight)) && ((this._lights.indexOf((pivot as ZenLight)) == -1)))) {
				this._lights.push((pivot as ZenLight));
			}
		}
		
		/**
		 * Draws the objects in the specified layer.
		 * @param	layer	The layer to draw.
		 * @param	material	An optional material to use in the draw operations.
		 */
		public function drawLayer(layer:int, material:ShaderMaterialBase = null):void {
			var list:Vector.<ZenObject>;
			var left:int;
			var right:int;
			var p:ZenObject;
			var v:Boolean;
			var l:LayerSort = this.getLayer(layer);
			if (((l) && (l.active))) {
				list = this._renderList;
				left = l.left;
				right = l.right;
				while (left <= right) {
					p = list[left++];
					v = p.visible;
					p.visible = true;
					p.draw(false, material);
					p.visible = v;
				}
			}
		}
		
		/**
		 * Hides the objects in the specified layer.
		 * @param	layer	The layer to hide.
		 */
		public function hideLayer(layer:int):void {
			var list:Vector.<ZenObject>;
			var left:int;
			var right:int;
			var l:LayerSort = this.getLayer(layer);
			if (((l) && (l.active))) {
				list = this._renderList;
				left = l.left;
				right = l.right;
				while (left <= right) {
					list[left++].visible = false;
				}
			}
		}
		
		/**
		 * Shows the object in the specified layer.
		 * @param	layer	The layer to show.
		 */
		public function showLayer(layer:int):void {
			var list:Vector.<ZenObject>;
			var left:int;
			var right:int;
			var l:LayerSort = this.getLayer(layer);
			if (((l) && (l.active))) {
				list = this._renderList;
				left = l.left;
				right = l.right;
				while (left <= right) {
					list[left++].visible = true;
				}
			}
		}
		
		private function getLayer(layer:int):LayerSort {
			var l:LayerSort;
			var middle:int;
			var left:int;
			var right:int;
			var temp:int;
			if (!(this._layers)) {
				this._layers = new Vector.<LayerSort>();
			}
			var i:int = (this._layers.length - 1);
			while (i > 0) {
				if (this._layers[i].layer == layer) {
					return (this._layers[i]);
				}
				i--;
			}
			l = new LayerSort(layer, 0, 0, StageSortMode.NONE);
			this._layers.push(l);
			var length:int = this._renderList.length;
			left = 0;
			right = length;
			while (left < right) {
				middle = ((left + right) >> 1);
				temp = this._renderList[middle].layer;
				if (layer > temp) {
					left = ++middle;
				} else {
					if (layer < temp) {
						right = --middle;
					} else {
						break;
					}
				}
			}
			if ((((middle == length)) || (!((this._renderList[middle].layer == layer))))) {
				return (l);
			}
			if (right == length) {
				right--;
			}
			while (this._renderList[right].layer != layer) {
				right--;
			}
			while (this._renderList[left].layer != layer) {
				left++;
			}
			l.left = left;
			l.right = right;
			l.active = true;
			return (l);
		}
		
		/**
		 * Specifies a layer to be sorted per object on each frame. This is very useful to draw correctly alpha objects that needs to be sorted.
		 * This property is property is used in conjunction with ZenObject sortMode property.
		 * @param	layer	Index of the layer to be sorted.
		 * @param	mode	The sort mode should be one of the constants SORT_FRONT_TO_BACK, SORT_BACK_TO_FRONT or SORT_NONE.
		 */
		public function setLayerSortMode(layer:int, mode:int = 2):void {
			var l:LayerSort = this.getLayer(layer);
			l.mode = mode;
		}
		
		public function get profile():String {
			return (this._profile);
		}
		
		public function set profile(value:String):void {
			this._profile = value;
		}
		
		public function get targetTexture():ZenTexture {
			return (this._targetTexture);
		}
		
		public function set targetTexture(value:ZenTexture):void {
			var point:Point;
			var rect:Rectangle;
			if (value == this._targetTexture) {
				return;
			}
			this._targetTexture = value;
			ShaderMaterial.semantics["TARGET_TEXTURE"].value = value;
			if (value) {
				value.mipMode = TextureMipMapping.NONE;
				point = (value.request as Point);
				rect = (value.request as Rectangle);
				
				if (((!(point)) && (!(rect)))) {
					
					throw new Error("Target texture should be a dynamic texture, ie. created via Point or Rectangle.");
					
					return;
				}
				if (!(value.optimizeForRenderToTexture)) {
					
					throw new Error("Target texture should have the optimizeForRenderToTexture parameter set to true.");
					
					return;
				}
				
			} else {
				if (this._secondTargetTexture) {
					this._secondTargetTexture.dispose();
					this._secondTargetTexture = null;
				}
			}
		}
		
		/// Returns the current Stage3D context.
		public function get context():Context3D {
			return (((this._stage3D) ? this._stage3D.context3D : null));
		}
		
		/**
		 * Forces to free all unused memory.
		 * This method calls to download method of all previously uploaded resources (textures, materials and surfaces), and then uploads again all the objects linked to the scene in order to render the next frame.
		 * Use this method when you want to clean the GPU memory of objects that are not currently in use.
		 * When you upload multiple files, textures, materials into the GPU, those resources will remain active until you release them.
		 */
		public function freeMemory():void {
			while (this.scene.textures.length) {
				this.scene.textures[0].download();
			}
			while (this.scene.materials.length) {
				this.scene.materials[0].download();
			}
			while (this.scene.surfaces.length) {
				this.scene.surfaces[0].download();
			}
			this.scene.textures.length = 0;
			this.scene.materials.length = 0;
			this.scene.surfaces.length = 0;
			this.scene.upload(this);
		}
		
		public function registerClass(... _args):void {
		}
		
		public function get renderToQuad():Boolean {
			return _renderToQuad;
		}
		
		public function set renderToQuad(value:Boolean):void {
			if (_renderToQuad != value) {
				_renderToQuad = value;
				
				if (_renderToQuad) {
					//hide();
					renderTex = new ZenTexture(new Rectangle(0, 0, 1024, 1024), true);
					targetTexture = renderTex;
					
					var temp:ZenSceneCanvas = renderQuad; /// ensure its created now
					
				} else {
					/*renderMat.dispose();
					   renderQuad.remove();
					   renderBitmap.dispose();
					   renderTex.download();
					   //show();*/
				}
				
			}
		}
		
		public function get renderQuad():ZenSceneCanvas {
			this._targetQuad = ((this._targetQuad) || (new ZenSceneCanvas("screen_quad", 0, 0, 0, 0, false, null, renderToQuadVertices)));
			return _targetQuad;
		}
		
		/** You have to add your own Bitmap object to view the BitmapData! (scene.renderBitmap), Also stage size must be fixed before setting this! */
		public function get renderToBitmap():Boolean {
			return _renderToBitmap;
		}
		
		public function set renderToBitmap(value:Boolean):void {
			if (_renderToBitmap != value) {
				_renderToBitmap = value;
				
				if (_renderToBitmap && (_autoResize || _viewPort == null || _viewPort.width == 0)) {
					
					throw new Error("Stage size must be fixed using setViewport() before enabling renderToBitmap!");
					
					return;
				}
				
				if (_renderToBitmap) {
					renderBitmap = ZenUtils.NewBitmap(_viewPort.width, _viewPort.height, true, 0, 0);
					clearColor.setTo(0, 0, 0);
					clearColor.w = 0;
				} else {
					renderBitmap.dispose();
					renderBitmap = null;
				}
				
			}
		}
	
	}
}