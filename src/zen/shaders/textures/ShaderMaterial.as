package zen.shaders.textures {
	import zen.materials.*;
	import zen.enums.*;
	import zen.shaders.*;
	import zen.shaders.textures.*;
	
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import zen.ZenFace;
	import zen.shaders.textures.NullMaterial;
	import zen.shaders.core.*;
	import zen.Zen3D;
	import flash.events.Event;
	import zen.materials.*;
	import flash.geom.Point;
	import flash.system.Capabilities;
	import flash.events.TextEvent;
	import flash.display3D.Context3D;
	import flash.display3D.Context3DTriangleFace;
	import flash.display3D.Context3DProgramType;
	import zen.ZenObject;
	import zen.utils.*;
	import zen.display.*;
	import zen.shaders.textures.*;
	import zen.animation.*;
	import zen.utils.*;
	import zen.display.*;
	import flash.display3D.*;
	import flash.events.*;
	import flash.geom.*;
	import flash.system.*;
	import flash.utils.*;
	
	public class ShaderMaterial extends ShaderMaterialBase {
		
		public static var semantics:Array = [];
		public static var currentTextuesPath:String = "";
		private static var input:int = 0;
		
		private var _programs:Vector.<ShaderProgram>;
		private var _techniqueName:String;
		private var _techniqueNames:Array;
		private var _compiledTechniques:Array;
		private var _byteCode:ByteArray;
		private var _useWorldView:Boolean;
		private var _useInv:Boolean;
		private var _scope:ShaderContext2;
		public var params:Dictionary;
		private var _copmileAllTechniques:Boolean = false;
		public var source:String;
		
		public static function init():void {
			
			semantics["WORLD_VIEW_PROJ"] = ZenUtils.worldViewProj;
			semantics["WORLD_VIEW"] = ZenUtils.worldView;
			semantics["WORLD"] = ZenUtils.global;
			semantics["VIEW"] = ZenUtils.view;
			semantics["VIEW_PROJ"] = ZenUtils.viewProj;
			semantics["PROJ"] = ZenUtils.proj;
			semantics["IWORLD"] = ZenUtils.invGlobal;
			semantics["CAMERA"] = ZenUtils.cameraGlobal;
			semantics["TARGET_TEXTURE"] = new ShaderTexture();
			semantics["SHADOW_MAP"] = new ShaderTexture();
			semantics["TIME"] = ZenUtils.time;
			semantics["COS_TIME"] = ZenUtils.cos_time;
			semantics["SIN_TIME"] = ZenUtils.sin_time;
			semantics["MOUSE"] = ZenUtils.mouse;
			semantics["CAM_POS"] = ZenUtils.cam;
			semantics["NEAR_FAR"] = ZenUtils.nearFar;
			semantics["SCREEN"] = ZenUtils.screen;
			semantics["RANDOM"] = ZenUtils.random;
			semantics["AMBIENT"] = ZenUtils.ambient;
			semantics["BONES"] = ZenUtils.bones;
			semantics["DIR_LIGHT"] = ZenUtils.dirLight;
			semantics["DIR_COLOR"] = ZenUtils.dirColor;
			semantics["POINT_LIGHT"] = ZenUtils.pointLight;
			semantics["POINT_COLOR"] = ZenUtils.pointColor;
			semantics["POSITION"] = VertexType.POSITION;
			semantics["UV0"] = VertexType.UV0;
			semantics["UV1"] = VertexType.UV1;
			semantics["UV2"] = VertexType.UV2;
			semantics["UV3"] = VertexType.UV3;
			semantics["NORMAL"] = VertexType.NORMAL;
			semantics["TANGENT"] = VertexType.TANGENT;
			semantics["BITANGENT"] = VertexType.BITANGENT;
			semantics["PARTICLE"] = VertexType.PARTICLE;
			semantics["SKIN_WEIGHTS"] = VertexType.SKIN_WEIGHTS;
			semantics["SKIN_INDICES"] = VertexType.SKIN_INDICES;
			semantics["COLOR0"] = VertexType.COLOR0;
			semantics["COLOR1"] = VertexType.COLOR1;
			semantics["COLOR2"] = VertexType.COLOR2;
			semantics["TARGET_POSITION"] = VertexType.TARGET_POSITION;
			semantics["TARGET_NORMAL"] = VertexType.TARGET_NORMAL;
			while (input < 15) {
				semantics[("INPUT" + input)] = input;
				input++;
			}
		}
		
		public function ShaderMaterial(name:String = "", byteCode:ByteArray = null, techniqueName:String = null, compileAll:Boolean = false) {
			this._techniqueNames = [];
			super(name);
			this._copmileAllTechniques = compileAll;
			this.techniqueName = techniqueName;
			this.byteCode = byteCode;
			this.build();
		}
		
		override public function dispose():void {
			var prg:ShaderProgram;
			if (this._programs) {
				for each (prg in this._programs) {
					prg.dispose();
				}
			}
			this._programs = null;
			this._byteCode = null;
			this._scope = null;
			super.dispose();
		}
		
		public function set techniqueName(value:String):void {
			this._techniqueName = value;
		}
		
		public function get techniqueName():String {
			return (this._techniqueName);
		}
		
		public function setTechnique(name:String = null):void {
			this._techniqueName = name;
			if (!(name)) {
				this._programs = this._compiledTechniques[this._techniqueNames[0]];
			} else {
				if (this._compiledTechniques) {
					this.programs = this._compiledTechniques[name];
				}
			}
			ZenUtils.lastMaterial = null;
			if (!(this._programs)) {
				this._programs = NullMaterial.programs2;
			}
		}
		
		public function set byteCode(value:ByteArray):void {
			this._byteCode = value;
			if (((value) && ((value.length == 0)))) {
				return;
			}
			if (!(value)) {
				this.programs = null;
				this.params = null;
				this._scope = null;
				return;
			}
			this._scope = new ShaderContext2(name);
			this._scope.bind(value);
			this._techniqueNames = this._scope.getTechniqueNames();
			this.params = this._scope.params;
		}
		
		public function get byteCode():ByteArray {
			return (this._byteCode);
		}
		
		public function rebuild():void {
			this._programs = null;
			this.build();
		}
		
		public function build():void {
			var passes:int;
			var i:int;
			var name:String;
			var s:Zen3D;
			if (!(this._scope)) {
				return;
			}
			if (this._programs) {
				return;
			}
			if (this._copmileAllTechniques) {
				this._compiledTechniques = [];
				for each (name in this._techniqueNames) {
					this._programs = new Vector.<ShaderProgram>();
					passes = this._scope.getPasses(name);
					i = 0;
					while (i < passes) {
						this._scope.init(i);
						this._scope.call(name);
						this._programs.push(ShaderCompiler.build());
						i++;
					}
					this._compiledTechniques[name] = this._programs;
				}
				this.programs = this._compiledTechniques[this._techniqueNames[0]];
			} else {
				this._programs = new Vector.<ShaderProgram>();
				passes = this._scope.getPasses(this.techniqueName);
				i = 0;
				while (i < passes) {
					this._scope.init(i);
					this._scope.call(this.techniqueName);
					this._programs.push(ShaderCompiler.build());
					i++;
				}
				this.programs = this._programs;
			}
			if (scene) {
				s = scene;
				download();
				upload(s);
			}
			dispatchEvent(new Event(Event.CHANGE));
		}
		
		public function get programs():Vector.<ShaderProgram> {
			return (this._programs);
		}
		
		public function set programs(value:Vector.<ShaderProgram>):void {
			var prg:ShaderProgram;
			var input:ShaderInput;
			var param:ShaderVar;
			var matrix:ShaderMatrix;
			var i:int;
			this._programs = value;
			if (!(this._programs)) {
				return;
			}
			var p:int;
			while (p < this._programs.length) {
				prg = this._programs[p];
				for each (input in prg.inputs) {
					input.attribute = this.getSemantic(input.semantic);
				}
				for each (param in prg.params) {
					if (param.semantic) {
						param.value = this.getSemantic(param.semantic);
					}
				}
				for each (matrix in prg.matrix) {
					if (matrix.semantic) {
						matrix.value = this.getSemantic(matrix.semantic);
					}
				}
				i = 0;
				while (i < prg.samplers.length) {
					if (prg.samplers[i].semantic) {
						prg.samplers[i] = this.getSemantic(prg.samplers[i].semantic);
					}
					i++;
				}
				p++;
			}
		}
		
		override protected function context3DEvent(e:Event = null):void {
			var p:Vector.<ShaderProgram>;
			if (!(this._programs)) {
				this.build();
			}
			if (((!(this._programs)) || ((this._programs.length == 0)))) {
				this._programs = NullMaterial.programs2;
			}
			if (this._copmileAllTechniques) {
				for each (p in this._compiledTechniques) {
					this.uploadPrograms(p);
				}
				this._programs = this._compiledTechniques[this._techniqueNames[0]];
			} else {
				this.uploadPrograms(this._programs);
			}
		}
		
		private function uploadPrograms(programs:Vector.<ShaderProgram>):void {
			var prg:ShaderProgram;
			var p:int;
			var sampler:ShaderTexture;
			var libTexture:ZenTexture;
			var errText:String;
			var programs:Vector.<ShaderProgram> = programs;
			p = 0;
			while (p < programs.length) {
				prg = programs[p];
				for each (sampler in prg.samplers) {
					if (sampler.semantic) {
						sampler.value = this.getSemantic(sampler.semantic);
					}
					if (!(sampler.value)) {
						if (sampler.request) {
							libTexture = (scene.library.getItem(sampler.request) as ZenTexture);
							if (((libTexture) && ((libTexture.typeMode == sampler.type)))) {
								sampler.value = libTexture;
							} else {
								sampler.value = new ZenTexture((currentTextuesPath + sampler.request), sampler.optimizeForRenderToTexture, sampler.format, sampler.type);
							}
							scene.library.addItem(sampler.request, sampler.value);
						} else {
							if ((((sampler.width > 0)) && ((sampler.height > 0)))) {
								sampler.value = new ZenTexture(new Point(sampler.width, sampler.height), sampler.optimizeForRenderToTexture, sampler.format, sampler.type);
							} else {
								sampler.value = new ZenTexture(ZenUtils.nullBitmapData, sampler.optimizeForRenderToTexture, sampler.format, sampler.type);
							}
						}
					}
					sampler.value.filterMode = sampler.filter;
					sampler.value.mipMode = sampler.mip;
					sampler.value.wrapMode = sampler.wrap;
					sampler.value.typeMode = sampler.type;
					sampler.value.format = sampler.format;
					sampler.value.bias = sampler.bias;
					sampler.value.options = sampler.options;
					sampler.value.upload(scene);
				}
				p = (p + 1);
			}
			p = 0;
			while (p < programs.length) {
				try {
					prg = programs[p];
					if (prg.program) {
						prg.program.dispose();
					}
					prg.program = scene.context.createProgram();
					prg.program.upload(prg.vertexBytes, prg.fragmentBytes);
				} catch (e) {
					errText = "[Material " + name + "] : " + e;
					/*DebugOnly>*/
					errText = ((((ShaderCompiler.decompile(prg.vertexBytes, prg.fragmentBytes) + "\n[Material ") + name) + "] : ") + e);
					/*<DebugOnly*/
					trace(errText);
					programs[p] = NullMaterial.programs2[0];
					prg = programs[p];
					prg.program = scene.context.createProgram();
					prg.program.upload(prg.vertexBytes, prg.fragmentBytes);
					if (((Capabilities.isDebugger) && (scene.context.enableErrorChecking))) {
						
						throw(((name + ": ") + e));
						
						return;
					}
					dispatchEvent(new TextEvent("buildError", false, false, errText));
				}
				this.programs = programs;
				p = (p + 1);
			}
		}
		
		override public function clone():ShaderMaterialBase {
			var p:*;
			var c:ShaderMaterial = new ShaderMaterial(name);
			c.techniqueName = this.techniqueName;
			c.byteCode = this.byteCode;
			for (p in this.params) {
				if (!(this.params[p].value)) {
				} else {
					if ((((this.params[p] is ShaderTexture)) || ((this.params[p] is ShaderMatrix)))) {
						c.params[p].value = this.params[p].value;
					} else {
						c.params[p].value = this.params[p].value.concat();
					}
				}
			}
			return (c);
		}
		
		override public function validate(surf:ZenFace):Boolean {
			var prg:ShaderProgram;
			var i:int;
			var input:ShaderInput;
			var surface:ZenFace;
			var colors:ZenFace;
			var length:int;
			var vector:Vector.<Number>;
			var uvs:ZenFace;
			var e:int;
			var surf:ZenFace = surf;
			var replaceAttrib:Function = function(input:ShaderInput, i:int):void {
				surf.offset[input.attribute] = surf.offset[i];
				surf.format[input.attribute] = surf.format[i];
			}
			for each (prg in this.programs) {
				i = 0;
				while (i < prg.inputs.length) {
					input = prg.inputs[i];
					surface = ((surf.sources[input.attribute]) || (surf));
					if (surface.offset[input.attribute] == -1) {
						switch (input.attribute) {
						case VertexType.UV0: 
						case VertexType.UV1: 
						case VertexType.UV2: 
						case VertexType.UV3: 
							if (surf.offset[VertexType.UV3] != -1) {
								(replaceAttrib(input, VertexType.UV3));
							} else {
								if (surf.offset[VertexType.UV2] != -1) {
									(replaceAttrib(input, VertexType.UV2));
								} else {
									if (surf.offset[VertexType.UV1] != -1) {
										(replaceAttrib(input, VertexType.UV1));
									} else {
										if (surf.offset[VertexType.UV0] != -1) {
											(replaceAttrib(input, VertexType.UV0));
										} else {
											uvs = new ZenFace(("uvs : " + surface.name));
											uvs.addVertexData(input.attribute, 2, new Vector.<Number>(((surf.vertexVector.length / surf.sizePerVertex) * 2)));
											surf.sources[input.attribute] = uvs;
										}
									}
								}
							}
							break;
						case VertexType.TANGENT: 
						case VertexType.BITANGENT: 
							surf.buildTangentsAndBitangents();
							break;
						case VertexType.COLOR0: 
						case VertexType.COLOR1: 
						case VertexType.COLOR2: 
							colors = new ZenFace(("colors : " + surface.name));
							length = ((surf.vertexVector.length / surf.sizePerVertex) * 3);
							vector = new Vector.<Number>(length);
							e = 0;
							while (e < length) {
								vector[e] = 0;
								e = (e + 1);
							}
							colors.addVertexData(input.attribute, 3);
							colors.vertexVector = vector;
							surf.format[input.attribute] = input.format;
							surf.sources[input.attribute] = colors;
							break;
						}
						surface = ((surf.sources[input.attribute]) || (surf));
						if (surface.offset[input.attribute] == -1) {
							
							throw(((((("WARNING: Missing buffer: " + input.toString()) + " (") + input.attribute) + ") in material: ") + name));
							
							return false;
						}
					}
					i = (i + 1);
				}
			}
			return (true);
		}
		
		override public function draw(pivot:ZenObject, surf:ZenFace, firstIndex:int = 0, count:int = -1):void {
			var i:int;
			var len:int;
			var prg:ShaderProgram;
			var inputs:Vector.<ShaderInput>;
			var matrix:Vector.<ShaderMatrix>;
			var params:Vector.<ShaderVar>;
			var surface:ZenFace;
			var samplers:Vector.<ShaderTexture>;
			var t:ShaderInput;
			var s:ZenFace;
			var p:ShaderVar;
			var m:ShaderMatrix;
			if (!(this._programs)) {
				return;
			}
			if (!(scene)) {
				upload(pivot.scene);
			}
			if (!(surf.scene)) {
				surf.upload(scene);
			}
			var context:Context3D = scene.context;
			ZenUtils.context = context;
			if (this._useWorldView) {
				ZenUtils.worldView.copyFrom(ZenUtils.global);
				ZenUtils.worldView.append(ZenUtils.view);
			}
			if (this._useInv) {
				ZenUtils.invGlobal.copyFrom(pivot.invWorld);
			}
			var n:int;
			while (n < this._programs.length) {
				prg = this._programs[n];
				inputs = prg.inputs;
				matrix = prg.matrix;
				params = prg.params;
				surface = ((prg.surface) ? prg.surface.value : surf);
				samplers = prg.samplers;
				if (((prg.target) && (prg.target.value))) {
					if (!(prg.target.value.scene)) {
						prg.target.value.upload(scene);
					}
					context.setRenderToTexture(prg.target.value.texture);
					context.clear();
				}
				if (ZenUtils.lastMaterial != this) {
					i = 0;
					len = samplers.length;
					while (i < len) {
						if (!(samplers[i].value.scene)) {
							samplers[i].value.upload(scene);
						}
						if (!(samplers[i].value.loaded)) {
							ZenUtils.usedSamples = (((len > ZenUtils.usedSamples)) ? len : ZenUtils.usedSamples);
							ZenUtils.lastMaterial = null;
							return;
						}
						ZenUtils.setTextureAt(i, samplers[i].value.texture);
						i++;
					}
					while (i < ZenUtils.usedSamples) {
						var _temp1 = i;
						i = (i + 1);
						ZenUtils.setTextureAt(_temp1, null);
					}
					ZenUtils.usedSamples = len;
					if (!(prg.program)) {
						prg.program = context.createProgram();
						prg.program.upload(prg.vertexBytes, prg.fragmentBytes);
					}
					ZenUtils.setProgram(prg.program);
					if ((((ZenUtils.ignoreStates == false)) || ((n > 0)))) {
						if (prg.colorMask) {
							context.setColorMask(prg.colorMask[0], prg.colorMask[1], prg.colorMask[2], prg.colorMask[3]);
						}
						if (prg.scissor) {
							context.setScissorRectangle(prg.scissor);
						}
						if (!(ZenUtils.invertCullFace)) {
							ZenUtils.setCulling(prg.cullFace);
						} else {
							if (prg.cullFace == Context3DTriangleFace.BACK) {
								ZenUtils.setCulling(Context3DTriangleFace.FRONT);
							} else {
								if (prg.cullFace == Context3DTriangleFace.FRONT) {
									ZenUtils.setCulling(Context3DTriangleFace.BACK);
								} else {
									ZenUtils.setCulling(Context3DTriangleFace.NONE);
								}
							}
						}
						ZenUtils.setDepthTest(prg.depthWrite, prg.depthCompare);
						ZenUtils.setBlendFactors(prg.sourceFactor, prg.destFactor);
					}
					if (prg.colorMask) {
						context.setColorMask(prg.colorMask[0], prg.colorMask[1], prg.colorMask[2], prg.colorMask[3]);
					}
				}
				i = 0;
				len = inputs.length;
				while (i < len) {
					t = inputs[i];
					s = ((surface.sources[t.attribute]) || (surface));
					s = ((s.instanceOf) || (s));
					if (!(s.scene)) {
						s.upload(scene);
					}
					context.setVertexBufferAt(i, s.vertexBuffer, s.offset[t.attribute], s.format[t.attribute]);
					i++;
				}
				while (i < ZenUtils.usedBuffers) {
					var _temp2 = i;
					i = (i + 1);
					context.setVertexBufferAt(_temp2, null);
				}
				ZenUtils.usedBuffers = len;
				i = 0;
				len = params.length;
				while (i < len) {
					p = params[i];
					context.setProgramConstantsFromVector(prg.pTarget[i], prg.pOffset[i], p.value);
					i++;
				}
				context.setProgramConstantsFromVector(Context3DProgramType.VERTEX, 0, prg.vertexConstants);
				context.setProgramConstantsFromVector(Context3DProgramType.FRAGMENT, 0, prg.fragmentConstants);
				i = 0;
				len = matrix.length;
				while (i < len) {
					m = matrix[i];
					context.setProgramConstantsFromMatrix(prg.mTarget[i], prg.mOffset[i], m.value, true);
					i++;
				}
				if (count != -1) {
					ZenUtils.trianglesDrawn = (ZenUtils.trianglesDrawn + count);
				} else {
					ZenUtils.trianglesDrawn = (ZenUtils.trianglesDrawn + surface.numTriangles);
				}
				ZenUtils.drawCalls++;
				context.drawTriangles(surface.indexBuffer, firstIndex, count);
				if (prg.target) {
					scene.context.setRenderToBackBuffer();
				}
				if (prg.colorMask) {
					context.setColorMask(true, true, true, true);
				}
				ZenUtils.lastMaterial = null;
				n++;
			}
			if (n == 0) {
				ZenUtils.lastMaterial = this;
			}
		}
		
		public function getTechniqueNames():Array {
			return (this._techniqueNames);
		}
		
		private function getSemantic(semantic:String) {
			if (semantics[semantic] == undefined) {
				
				throw new Error((("Semantic '" + semantic) + "' is not defined.."));
				
				return;
			}
			if (semantics[semantic] == null) {
				
				throw new Error((("Semantic '" + semantic) + "' has null values."));
				
				return;
			}
			if (semantic == "WORLD_VIEW") {
				this._useWorldView = true;
			}
			if (semantic == "IWORLD") {
				this._useInv = true;
			}
			return (semantics[semantic]);
		}
	
	}
}

