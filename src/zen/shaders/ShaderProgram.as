package zen.shaders {
	
	import zen.shaders.core.*;
	import flash.display3D.Program3D;
	import flash.utils.ByteArray;
	import flash.geom.Rectangle;
	import flash.display3D.*;
	import flash.display3D.textures.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.utils.*;
	
	/** Compiled ZSL shader, contains the Stage3D class `Program3D`.
	 *
	 * Defines the structure and states to use for an specific pass of a ZSL material*/
	public class ShaderProgram {
		
		public var debug:String;
		public var name:String;
		public var samplers:Vector.<ShaderTexture>;
		public var inputs:Vector.<ShaderInput>;
		public var matrix:Vector.<ShaderMatrix>;
		public var params:Vector.<ShaderVar>;
		public var pTarget:Vector.<String>;
		public var mTarget:Vector.<String>;
		public var pOffset:Vector.<int>;
		public var mOffset:Vector.<int>;
		
		public var program:Program3D;
		public var vertexBytes:ByteArray;
		public var fragmentBytes:ByteArray;
		public var vertexConstants:Vector.<Number>;
		public var fragmentConstants:Vector.<Number>;
		
		public var cullFace:String = "back";
		public var sourceFactor:String = "one";
		public var destFactor:String = "zero";
		public var depthCompare:String = "lessEqual";
		public var depthWrite:Boolean = true;
		public var scissor:Rectangle;
		public var stencilEnabled:Boolean = false;
		public var stencilReferenceValue:int;
		public var stencilReadMask:int = 0xFF;
		public var stencilWriteMask:int = 0xFF;
		public var stencilTriangleFace:String = "frontAndBack";
		public var stencilCompareMode:String = "always";
		public var stencilOnPass:String = "keep";
		public var stencilOnBothPass:String = "keep";
		public var stencilOnDepthFail:String = "keep";
		public var colorMask:Vector.<Boolean>;
		public var surface:ShaderMesh;
		
		public var target:ShaderTexture;
		public var targetEnableDepthAndStencil:Boolean = false;
		public var targetAntiAlias:int = 0;
		public var targetSurfaceSelector:int = 0;
		
		public function ShaderProgram() {
			this.samplers = new Vector.<ShaderTexture>();
			this.inputs = new Vector.<ShaderInput>();
			this.matrix = new Vector.<ShaderMatrix>();
			this.params = new Vector.<ShaderVar>();
			this.pTarget = new Vector.<String>();
			this.mTarget = new Vector.<String>();
			this.pOffset = new Vector.<int>();
			this.mOffset = new Vector.<int>();
			this.vertexConstants = new Vector.<Number>();
			this.fragmentConstants = new Vector.<Number>();
			super();
		}
		
		public function dispose():void {
			var s:ShaderTexture;
			for each (s in this.samplers) {
				if (s.value) {
					s.value.download();
				}
			}
			this.samplers = null;
			this.inputs = null;
			this.matrix = null;
			this.params = null;
			this.surface = null;
			if (this.target) {
				this.target.value.dispose();
				this.target = null;
			}
		}
		
		public function clone():ShaderProgram {
			var s:ShaderTexture;
			var m:ShaderMatrix;
			var p:ShaderVar;
			var prg:ShaderProgram = new ShaderProgram();
			for each (s in this.samplers) {
				prg.samplers.push(s.clone());
			}
			for each (m in this.matrix) {
				prg.matrix.push(m.clone());
			}
			for each (p in this.params) {
				prg.params.push(p.clone());
			}
			prg.inputs = this.inputs;
			prg.pTarget = this.pTarget;
			prg.mTarget = this.mTarget;
			prg.pOffset = this.pOffset;
			prg.mOffset = this.mOffset;
			prg.vertexBytes = this.vertexBytes;
			prg.fragmentBytes = this.fragmentBytes;
			prg.vertexConstants = this.vertexConstants;
			prg.fragmentConstants = this.fragmentConstants;
			prg.cullFace = this.cullFace;
			prg.sourceFactor = this.sourceFactor;
			prg.destFactor = this.destFactor;
			prg.depthCompare = this.depthCompare;
			prg.depthWrite = this.depthWrite;
			prg.scissor = this.scissor;
			prg.stencilEnabled = this.stencilEnabled;
			prg.stencilReferenceValue = this.stencilReferenceValue;
			prg.stencilReadMask = this.stencilReadMask;
			prg.stencilWriteMask = this.stencilWriteMask;
			prg.stencilTriangleFace = this.stencilTriangleFace;
			prg.stencilCompareMode = this.stencilCompareMode;
			prg.stencilOnPass = this.stencilOnPass;
			prg.stencilOnBothPass = this.stencilOnBothPass;
			prg.stencilOnDepthFail = this.stencilOnDepthFail;
			prg.colorMask = this.colorMask;
			prg.surface = this.surface;
			prg.target = this.target;
			prg.targetEnableDepthAndStencil = this.targetEnableDepthAndStencil;
			prg.targetAntiAlias = this.targetAntiAlias;
			prg.targetSurfaceSelector = this.targetSurfaceSelector;
			return (prg);
		}
	
	/* public function getParamByName(name:String, index:int=0):ShaderVar
	   {
	   var l:int = this.params.length;
	   var s:int;
	   while (s < l) {
	   if ((((name == this.params[s].name)) && ((_temp1 < 0)))){
	   return (this.params[s]);
	   }
	   s++;
	   }
	   return (null);
	   }
	
	   public function getSamplerByName(name:String, index:int=0):ShaderTexture
	   {
	   var l:int = this.samplers.length;
	   var s:int;
	   while (s < l) {
	   if ((((name == this.samplers[s].name)) && ((_temp1 < 0)))){
	   return (this.samplers[s]);
	   }
	   s++;
	   }
	   return (null);
	   }*/
	
	}
}

