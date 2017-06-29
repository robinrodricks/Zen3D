package zen.animation {
	
	import zen.display.*;
	import zen.display.*;
	import zen.shaders.textures.ShaderMaterialBase;
	
	/** Animates a single 3D vertex of a mesh using linear interpolation. */
	public class ZenVertexModifier extends Modifier {
		
		public var frames:Vector.<Vector.<Number>>;
		public var normals:Vector.<Vector.<Number>>;
		public var frameSkip:int = 1;
		public var index:Vector.<uint>;
		public var morphEnabled:Boolean = false;
		public var morphValue:Number = 0;
		public var updateAllInstances:Boolean = false;
		private var mesh:ZenMesh;
		private var surf:ZenFace;
		private var morphFrame:Vector.<Number>;
		private var currentFrame:Number;
		private var nextFrame:Number;
		private var lastValue:Number;
		private var lastFrame:Number;
		private var morphFromFrame:int;
		private var _morphToFrame:int = 0;
		
		public function ZenVertexModifier() {
			this.frames = new Vector.<Vector.<Number>>();
			super();
		}
		
		public function toString():String {
			return ("[object VertexAnimationModifier]");
		}
		
		override public function clone():Modifier {
			var v:ZenVertexModifier = new ZenVertexModifier();
			v.frames = this.frames;
			v.frameSkip = this.frameSkip;
			v.normals = this.normals;
			v.index = this.index;
			v.updateAllInstances = this.updateAllInstances;
			return (v);
		}
		
		override public function draw(mesh:ZenMesh, material:ShaderMaterialBase = null):void {
			if (!(mesh.scene.context)) {
				return;
			}
			this.currentFrame = mesh.currentFrame;
			this.mesh = mesh;
			this.surf = mesh.surfaces[0];
			var baseFrame:int = (this.currentFrame / this.frameSkip);
			var value:Number = ((this.currentFrame / this.frameSkip) - baseFrame);
			if (!(this.morphEnabled)) {
				if ((baseFrame + 1) < this.frames.length) {
					var _temp1 = baseFrame;
					baseFrame = (baseFrame + 1);
					this.interpolate(_temp1, baseFrame, value);
				} else {
					this.interpolate(baseFrame, 0, value);
				}
			} else {
				if (this._morphToFrame < 0) {
					this._morphToFrame = 0;
				} else {
					if (this._morphToFrame >= mesh.frames.length) {
						this._morphToFrame = (this.frames.length - 1);
					}
				}
				this.interpolate(0, (this._morphToFrame / this.frameSkip), this.morphValue);
				mesh.gotoAndStop((this.morphFromFrame + ((this._morphToFrame - this.morphFromFrame) * this.morphValue)));
			}
		}
		
		private function startMorph():void {
			var src:int;
			var dst:int;
			if (!(this.mesh)) {
				return;
			}
			this.morphEnabled = true;
			this.morphValue = 0;
			this.morphFromFrame = this.mesh.currentFrame;
			if (!(this.morphFrame)) {
				this.morphFrame = new Vector.<Number>(this.frames[0].length, true);
			}
			var i:int;
			var l:int = this.index.length;
			var size:int = this.surf.sizePerVertex;
			var vector:Vector.<Number> = this.surf.vertexVector;
			i = 0;
			while (i < l) {
				src = int((this.surf.indexVector[i] * size));
				dst = int((this.index[i] * 3));
				var _local7 = dst++;
				this.morphFrame[_local7] = vector[src++];
				var _local8 = dst++;
				this.morphFrame[_local8] = vector[src++];
				this.morphFrame[dst] = vector[src];
				i++;
			}
		}
		
		private function interpolate(from:int, to:int, value:Number):void {
			var size:int;
			var length:int;
			var frameIndex:int;
			var dstIndex:int;
			var dst:Vector.<Number> = this.surf.vertexVector;
			var frame:Vector.<Number> = ((this.morphEnabled) ? this.morphFrame : this.frames[from]);
			var toFrame:Vector.<Number> = this.frames[to];
			var i:int;
			if (((((!((this.currentFrame == this.lastFrame))) || (!((value == this.lastValue))))) || (this.updateAllInstances))) {
				size = this.surf.sizePerVertex;
				length = this.surf.indexVector.length;
				while (i < length) {
					frameIndex = int((this.index[i] * 3));
					dstIndex = int((this.surf.indexVector[i] * size));
					var _local12 = dstIndex++;
					dst[_local12] = (frame[frameIndex] + ((toFrame[frameIndex] - frame[frameIndex]) * value));
					frameIndex++;
					var _local13 = dstIndex++;
					dst[_local13] = (frame[frameIndex] + ((toFrame[frameIndex] - frame[frameIndex]) * value));
					frameIndex++;
					dst[dstIndex] = (frame[frameIndex] + ((toFrame[frameIndex] - frame[frameIndex]) * value));
					i++;
				}
				this.surf.vertexBuffer.uploadFromVector(dst, 0, this.index.length);
			}
			this.lastValue = value;
			this.lastFrame = this.mesh.currentFrame;
		}
		
		public function get morphToFrame():int {
			return (this._morphToFrame);
		}
		
		public function set morphToFrame(value:int):void {
			this._morphToFrame = value;
			this.startMorph();
		}
	
	}
}

