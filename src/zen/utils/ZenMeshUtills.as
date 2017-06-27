package zen.utils {
	import flash.display.BitmapData;
	import flash.display.Shader;
	import flash.filters.ShaderFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.Dictionary;
	
	import zen.animation.ZenSkinModifier;
	import zen.shaders.textures.ShaderMaterialBase;
	import flash.geom.Matrix3D;
	import zen.display.*;
	import zen.display.*;
	import flash.utils.*;
	
	import zen.shaders.textures.*;
	import zen.animation.*;
	
	public class ZenMeshUtills {
		
		/**
		 * Merges a collection of objects into a static single one to reduce draw calls.
		 * The amount of draw calls / surfaces of the resulted mesh, depends directly on the amount of materials of the source mesh.
		 * Only surfaces with the same material can be marged to draw them together.
		 * If the surfaces reaches the limit of buffer sizes, they are also splited in different surfaces.
		 * @param	vector	A source vector containting all pivots you want to merge.
		 * @param	removeOiriginal	If the original objects should be removed from the scene once they are merged.
		 * @param	material	A material fitler used to only merge surfaces with a specific material.
		 * @param	includeChildren	if true, all pivot hierqarchy is included for each pivot in the collection of objects.
		 * @return	A new single mesh contating all the resulted surfaces. You need to add this mesh to the scene to be displayed.
		 */
		public static function mergeMeshes(vector:Vector.<ZenObject>, removeOiriginal:Boolean = true, material:ShaderMaterialBase = null, includeChildren:Boolean = false):ZenMesh {
			var p:ZenObject;
			var m:ZenMesh;
			var s:ZenFace;
			var i:int;
			var length:int;
			var surfaces:Dictionary;
			var mergeFailed:int;
			var sf:* = undefined;
			var surf:ZenFace;
			var valid:Boolean;
			var c:int;
			var before:int;
			var after:int;
			var v:Vector.<ZenObject>;
			var vector:Vector.<ZenObject> = vector;
			var removeOiriginal:Boolean = removeOiriginal;
			var material = material;
			var includeChildren:Boolean = includeChildren;
			var merged:Dictionary = new Dictionary();
			var mesh:ZenMesh = new ZenMesh("Merge");
			if (includeChildren) {
				vector = vector.concat();
				length = vector.length;
				i = 0;
				while (i < length) {
					p = vector[i];
					p.forEach(vector.push, ZenMesh);
					i = (i + 1);
				}
			}
			vector.sort(function(a:ZenObject, b:ZenObject):int {
				if (a.layer > b.layer) {
					return (1);
				}
				if (a.layer < b.layer) {
					return (-1);
				}
				return (0);
			});
			var mergeSurfaces:Vector.<ZenFace> = new Vector.<ZenFace>();
			var mergeMeshes:Vector.<ZenMesh> = new Vector.<ZenMesh>();
			i = 0;
			while (i < vector.length) {
				p = vector[i];
				m = (p as ZenMesh);
				if (((!(merged[p])) && (m))) {
					merged[p] = true;
					if (((!(m.visible)) || ((m.modifier is ZenSkinModifier)))) {
					} else {
						for each (s in m.surfaces) {
							if (((material) && (!((s.material == material))))) {
							} else {
								mergeSurfaces.push(s);
								mergeMeshes.push(m);
							}
						}
					}
				}
				i = (i + 1);
			}
			do {
				surfaces = new Dictionary();
				mergeFailed = 0;
				i = 0;
				while (i < mergeSurfaces.length) {
					s = mergeSurfaces[i];
					m = mergeMeshes[i];
					if (surfaces[s.material] == undefined) {
						surf = new ZenFace("merge");
						surf.sizePerVertex = s.sizePerVertex;
						surf.offset = s.offset.concat();
						surf.format = s.format.concat();
						surfaces[s.material] = surf;
						mesh.surfaces.push(surf);
					}
					surf = (surfaces[s.material] as ZenFace);
					valid = true;
					c = 0;
					while (c < 16) {
						if (surf.offset[c] != s.offset[c]) {
							valid = false;
							break;
						}
						c = (c + 1);
					}
					if (valid) {
						before = surf.indexVector.length;
						s.concat(surf);
						after = surf.indexVector.length;
						surf.transformBy(m.world, before, ((after - before) / 3));
						mergeSurfaces.splice(i, 1);
						mergeMeshes.splice(i, 1);
						i = (i - 1);
					} else {
						mergeFailed = (mergeFailed + 1);
					}
					i = (i + 1);
				}
				for (sf in surfaces) {
					surfaces[sf].material = sf;
				}
			} while (mergeFailed > 0);
			if (removeOiriginal) {
				v = vector.concat();
				i = 0;
				while (i < v.length) {
					if ((v[i] is ZenMesh)) {
						v[i].parent = null;
					}
					i = (i + 1);
				}
			}
			splitMesh(mesh);
			mesh.updateBoundings();
			return (mesh);
		}
		
		/**
		 * Split the surfaces of the mesh if they exceds the limit of the buffer size.
		 * @param	mesh	The mess to be splited.
		 */
		public static function splitMesh(mesh:ZenMesh):void {
			var c:ZenFace;
			var s:ZenFace;
			var sVtx:Vector.<Number>;
			var sIdx:Vector.<uint>;
			var e:int;
			var v0:int;
			var v1:int;
			var v2:int;
			var length:int;
			var index:int;
			var cLen:int;
			var cVtx:Vector.<Number>;
			var cIdx:Vector.<uint>;
			var maxIndex:int = 524287;
			var maxVertex:int = 65536;
			var i:int;
			while (i < mesh.surfaces.length) {
				s = mesh.surfaces[i];
				sVtx = s.vertexVector;
				sIdx = s.indexVector;
				if ((((sIdx.length >= maxIndex)) || (((sVtx.length / s.sizePerVertex) >= maxVertex)))) {
					length = sIdx.length;
					index = 0;
					c = new ZenFace(s.name);
					c.offset = s.offset.concat();
					c.format = s.format.concat();
					c.sizePerVertex = s.sizePerVertex;
					c.material = s.material;
					cLen = 0;
					cVtx = c.vertexVector;
					cIdx = c.indexVector;
					while (index < length) {
						if ((((cIdx.length >= (maxIndex - 3))) || (((cVtx.length / s.sizePerVertex) >= (maxVertex - s.sizePerVertex))))) {
							mesh.surfaces.push(c);
							c = new ZenFace(s.name);
							c.offset = s.offset.concat();
							c.format = s.format.concat();
							c.sizePerVertex = s.sizePerVertex;
							c.material = s.material;
							cLen = 0;
							cVtx = c.vertexVector;
							cIdx = c.indexVector;
						}
						v0 = (sIdx[index++] * s.sizePerVertex);
						v1 = (sIdx[index++] * s.sizePerVertex);
						v2 = (sIdx[index++] * s.sizePerVertex);
						e = 0;
						while (e < s.sizePerVertex) {
							var _local18 = cLen++;
							cVtx[_local18] = sVtx[(e + v0)];
							e++;
						}
						e = 0;
						while (e < s.sizePerVertex) {
							_local18 = cLen++;
							cVtx[_local18] = sVtx[(e + v1)];
							e++;
						}
						e = 0;
						while (e < s.sizePerVertex) {
							_local18 = cLen++;
							cVtx[_local18] = sVtx[(e + v2)];
							e++;
						}
					}
					s.dispose();
					mesh.surfaces.push(c);
					var _temp1 = i;
					i = (i - 1);
					mesh.surfaces.splice(_temp1, 1);
				}
				i++;
			}
			for each (c in mesh.surfaces) {
				c.numTriangles = (c.indexVector.length / 3);
			}
		}
		
		[Embed(source = "../utils/assets/utils/NormalMap.data", mimeType = "application/octet-stream")]
		private static var NormalMap:Class;
		private static var shader:Shader;
		private static var filter:ShaderFilter;
		
		public static function toNormalMap(bitmapData:BitmapData, x:Number = 1, y:Number = 1):BitmapData {
			shader = new Shader(new NormalMap());
			shader.data.x.value = [x];
			shader.data.y.value = [y];
			filter = new ShaderFilter(shader);
			bitmapData.applyFilter(bitmapData, bitmapData.rect, new Point(), filter);
			return (bitmapData);
		}
		
		public static function extractCubeMap(bitmapData:BitmapData):Array {
			var data:Array;
			var b:BitmapData;
			var images:Array = [];
			var m:Matrix = new Matrix();
			var bmp:BitmapData = bitmapData;
			var size:int = (((bmp.width > bmp.height)) ? (bmp.width / 4) : (bmp.width / 3));
			if (bmp.width > bmp.height) {
				data = [2, 1, 0, 0, 1, 0, 1, 0, 0, 1, 2, 0, 1, 1, 0, 3, 1, 0];
			} else {
				data = [2, 1, 0, 0, 1, 0, 1, 0, 0, 1, 2, 0, 1, 1, 0, 2, 4, Math.PI];
			}
			var i:int;
			while (i < 6) {
				if (bmp.width == bmp.height) {
					b = bmp;
				} else {
					b = new BitmapData(size, size, bmp.transparent, 0);
					m.identity();
					m.translate((-(size) * data[(i * 3)]), (-(size) * data[((i * 3) + 1)]));
					m.rotate(data[((i * 3) + 2)]);
					b.fillRect(b.rect, 0);
					b.draw(bmp, m);
				}
				images.push(b);
				i++;
			}
			return (images);
		}
	
	}

}