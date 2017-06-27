package zen.display {
	import zen.display.*;
	import zen.enums.*;
	import flash.geom.*;
	import zen.display.*;
	import zen.materials.*;
	import zen.shaders.textures.*;
	import zen.geom.*;
	
	/** A static class that provides methods to create various types of 3D primitives */
	public class ZenPrimitives {
		
		public static function Arrow(name:String = "arrow", length:Number = 50, size:Number = 5, color:int = 0xFFCB00, alpha:Number = 1):ZenCanvas {
			var obj:ZenCanvas = new ZenCanvas(name);
			
			obj.clear();
			obj.lineStyle(1, color, alpha);
			var s2:Number = size;
			var d:Number = length;
			var d2:Number = (length + size);
			if (d > 0) {
				obj.moveTo(0, 0, 0);
				obj.lineTo(0, 0, d);
			}
			obj.moveTo(-(s2), 0, d);
			obj.lineTo(s2, 0, d);
			obj.lineTo(0, 0, d2);
			obj.lineTo(-(s2), 0, d);
			
			return obj;
		}
		
		public static function Box(name:String = "", width:Number = 10, height:Number = 10, depth:Number = 10, segments:int = 1, material:ShaderMaterialBase = null):ZenMesh {
			var obj:ZenMesh = new ZenMesh(name);
			
			var surf:ZenFace;
			var max:Number;
			
			if (!(material)) {
				material = new ZenMaterial((name + "_material"));
			}
			var count:Number = 0;
			while (count < 6) {
				var objSurf:ZenFace = new ZenFace(((name + "_surface") + count));
				obj.surfaces[count] = objSurf;
				objSurf.addVertexData(VertexType.POSITION);
				objSurf.addVertexData(VertexType.NORMAL);
				objSurf.addVertexData(VertexType.UV0);
				objSurf.vertexVector = new Vector.<Number>();
				objSurf.indexVector = new Vector.<uint>();
				objSurf.material = material;
				count++;
			}
			createBoxPlane(obj.surfaces[0], width, height, (depth * 0.5), segments, material, "+xy");
			createBoxPlane(obj.surfaces[1], width, height, (depth * 0.5), segments, material, "-xy");
			createBoxPlane(obj.surfaces[2], depth, height, (width * 0.5), segments, material, "+yz");
			createBoxPlane(obj.surfaces[3], depth, height, (width * 0.5), segments, material, "-yz");
			createBoxPlane(obj.surfaces[4], width, depth, (height * 0.5), segments, material, "+xz");
			createBoxPlane(obj.surfaces[5], width, depth, (height * 0.5), segments, material, "-xz");
			obj.surfaces[0].material = material;
			for each (surf in obj.surfaces) {
				surf.updateBoundings();
			}
			max = (Math.max(width, height, depth) * 0.5);
			obj.bounds = new Cube3D();
			obj.bounds.max.setTo((width * 0.5), (height * 0.5), (depth * 0.5));
			obj.bounds.min.setTo((-(width) * 0.5), (-(height) * 0.5), (-(depth) * 0.5));
			obj.bounds.length = obj.bounds.max.subtract(obj.bounds.min);
			obj.bounds.radius = Vector3D.distance(obj.bounds.center, obj.bounds.max);
			
			return obj;
		}
		
		private static function createBoxPlane(surface:ZenFace, width:Number, height:Number, depth:Number, segments:int, material:ShaderMaterialBase, axis:String):void {
			var u:Number;
			var v:Number;
			var x:Number;
			var y:Number;
			var matrix:Matrix3D = new Matrix3D();
			if (axis == "+xy") {
				M3D.setOrientation(matrix, new Vector3D(0, 0, -1));
			} else {
				if (axis == "-xy") {
					M3D.setOrientation(matrix, new Vector3D(0, 0, 1));
				} else {
					if (axis == "+xz") {
						M3D.setOrientation(matrix, new Vector3D(0, 1, 0));
					} else {
						if (axis == "-xz") {
							M3D.setOrientation(matrix, new Vector3D(0, -1, 0));
						} else {
							if (axis == "+yz") {
								M3D.setOrientation(matrix, new Vector3D(1, 0, 0));
							} else {
								if (axis == "-yz") {
									M3D.setOrientation(matrix, new Vector3D(-1, 0, 0));
								}
							}
						}
					}
				}
			}
			M3D.setScale(matrix, width, height, 1);
			M3D.translateZ(matrix, depth);
			var raw:Vector.<Number> = matrix.rawData;
			var normal:Vector3D = M3D.getDir(matrix);
			v = 0;
			while (v <= segments) {
				u = 0;
				while (u <= segments) {
					x = ((u / segments) - 0.5);
					y = ((v / segments) - 0.5);
					surface.vertexVector.push((((x * raw[0]) + (y * raw[4])) + raw[12]), (((x * raw[1]) + (y * raw[5])) + raw[13]), (((x * raw[2]) + (y * raw[6])) + raw[14]), normal.x, normal.y, normal.z, (1 - (u / segments)), (1 - (v / segments)));
					u++;
				}
				v++;
			}
			v = 0;
			while (v < segments) {
				u = 0;
				while (u < segments) {
					surface.indexVector[0] = ((u + 1) + (v * (segments + 1)));
					surface.indexVector[1] = ((u + 1) + ((v + 1) * (segments + 1)));
					surface.indexVector[2] = (u + ((v + 1) * (segments + 1)));
					surface.indexVector[3] = (u + (v * (segments + 1)));
					surface.indexVector[4] = ((u + 1) + (v * (segments + 1)));
					surface.indexVector[5] = (u + ((v + 1) * (segments + 1)));
					u++;
				}
				v++;
			}
		}
		
		public static function Capsule(name:String = "", radius:Number = 3, height:Number = 10, segments:int = 12, material:ShaderMaterialBase = null):ZenMesh {
			var obj:ZenMesh = new ZenMesh(name);
			
			var surface:ZenFace;
			var i:int;
			var u:Number;
			var v:Number;
			var x:Number;
			var y:Number;
			var z:Number;
			var offset:Number;
			
			if (!(material)) {
				material = new ZenMaterial((name + "_material"));
			}
			var objSurf:ZenFace = new ZenFace((name + "_surface"));
			obj.surfaces[0] = objSurf;
			objSurf.addVertexData(VertexType.POSITION);
			objSurf.addVertexData(VertexType.NORMAL);
			objSurf.addVertexData(VertexType.UV0);
			objSurf.vertexVector = new Vector.<Number>();
			objSurf.indexVector = new Vector.<uint>();
			objSurf.material = material;
			surface = objSurf;
			var normal:Vector3D = new Vector3D();
			var sx:int = segments;
			var sy:int = (segments + 1);
			var h:Number = (height - (radius * 2));
			i = 0;
			v = 0;
			while (v <= sy) {
				y = (-(Math.cos(((v / sy) * Math.PI))) * radius);
				offset = (((v > (sy / 2))) ? (h / 2) : (-(h) / 2));
				u = 0;
				while (u <= sx) {
					x = ((Math.cos((((u / sx) * Math.PI) * 2)) * radius) * Math.sin(((v / sy) * Math.PI)));
					z = ((-(Math.sin((((u / sx) * Math.PI) * 2))) * radius) * Math.sin(((v / sy) * Math.PI)));
					normal.x = x;
					normal.y = y;
					normal.z = z;
					normal.normalize();
					surface.vertexVector.push(x, (y + offset), z, normal.x, normal.y, normal.z, (1 - (u / segments)), (1 - (v / segments)));
					i++;
					u++;
				}
				v++;
			}
			i = 0;
			v = 0;
			while (v < sy) {
				u = 0;
				while (u < sx) {
					var _local19 = i++;
					surface.indexVector[_local19] = (u + (v * (sx + 1)));
					var _local20 = i++;
					surface.indexVector[_local20] = ((u + 1) + (v * (sx + 1)));
					var _local21 = i++;
					surface.indexVector[_local21] = (u + ((v + 1) * (sx + 1)));
					var _local22 = i++;
					surface.indexVector[_local22] = ((u + 1) + (v * (sx + 1)));
					var _local23 = i++;
					surface.indexVector[_local23] = ((u + 1) + ((v + 1) * (sx + 1)));
					var _local24 = i++;
					surface.indexVector[_local24] = (u + ((v + 1) * (sx + 1)));
					u++;
				}
				v++;
			}
			surface.material = material;
			obj.bounds = new Cube3D();
			var halfH:Number = (height * 0.5);
			obj.bounds.max.setTo(radius, halfH, radius);
			obj.bounds.min.setTo(-(radius), -(halfH), -(radius));
			obj.bounds.length = obj.bounds.max.subtract(obj.bounds.min);
			obj.bounds.radius = Vector3D.distance(obj.bounds.center, obj.bounds.max);
			surface.bounds = obj.bounds;
			
			return obj;
		}
		
		public static function Cone(name:String = "cone", radius1:Number = 5, radius2:Number = 0, height:Number = 10, segments:int = 12, material:ShaderMaterialBase = null):ZenMesh {
			var obj:ZenMesh = new ZenMesh(name);
			
			var i:int;
			var d:int;
			var v:Number;
			var x:Number;
			var y:Number;
			var z:Number;
			var r1:int;
			var r2:int;
			var surf:ZenFace;
			var max:Number;
			
			if (!(material)) {
				material = new ZenMaterial((name + "_material"));
			}
			var objSurf:ZenFace = new ZenFace();
			obj.surfaces[0] = objSurf;
			objSurf.addVertexData(VertexType.POSITION);
			objSurf.addVertexData(VertexType.NORMAL);
			objSurf.addVertexData(VertexType.UV0);
			objSurf.vertexVector = new Vector.<Number>();
			objSurf.indexVector = new Vector.<uint>();
			var surface:ZenFace = objSurf;
			var normal:Vector3D = new Vector3D();
			var sy:int = segments;
			v = 0;
			while (v <= sy) {
				y = 0;
				x = Math.cos((((v / sy) * Math.PI) * 2));
				z = -(Math.sin((((v / sy) * Math.PI) * 2)));
				normal.x = x;
				normal.y = ((radius1 - radius2) / height);
				normal.z = z;
				normal.normalize();
				surface.vertexVector.push((x * radius1), 0, (z * radius1), normal.x, normal.y, normal.z, (v / segments), 1);
				surface.vertexVector.push((x * radius2), height, (z * radius2), normal.x, normal.y, normal.z, (v / segments), 0);
				i++;
				v++;
			}
			if (radius1 > 0) {
				r1 = (surface.vertexVector.length / surface.sizePerVertex);
				v = 0;
				while (v <= sy) {
					x = (Math.cos((((v / sy) * Math.PI) * 2)) * radius1);
					z = (-(Math.sin((((v / sy) * Math.PI) * 2))) * radius1);
					surface.vertexVector.push(x, 0, z, 0, -1, 0, ((x / radius1) * 0.5), ((z / radius1) * 0.5));
					v++;
				}
			}
			if (radius2 > 0) {
				r2 = (surface.vertexVector.length / surface.sizePerVertex);
				v = 0;
				while (v <= sy) {
					x = (Math.cos((((v / sy) * Math.PI) * 2)) * radius2);
					z = (-(Math.sin((((v / sy) * Math.PI) * 2))) * radius2);
					surface.vertexVector.push(x, height, z, 0, 1, 0, ((x / radius2) * 0.5), ((z / radius2) * 0.5));
					v++;
				}
			}
			i = 0;
			v = 0;
			while (v < sy) {
				var _local20 = i++;
				surface.indexVector[_local20] = ((v * 2) + 2);
				var _local21 = i++;
				surface.indexVector[_local21] = ((v * 2) + 1);
				var _local22 = i++;
				surface.indexVector[_local22] = (v * 2);
				var _local23 = i++;
				surface.indexVector[_local23] = ((v * 2) + 2);
				var _local24 = i++;
				surface.indexVector[_local24] = ((v * 2) + 3);
				var _local25 = i++;
				surface.indexVector[_local25] = ((v * 2) + 1);
				v++;
			}
			if (radius1 > 0) {
				v = 1;
				while (v < (sy - 1)) {
					_local20 = i++;
					surface.indexVector[_local20] = ((r1 + v) + 1);
					_local21 = i++;
					surface.indexVector[_local21] = (r1 + v);
					_local22 = i++;
					surface.indexVector[_local22] = r1;
					v++;
				}
			}
			if (radius2 > 0) {
				v = 1;
				while (v < (sy - 1)) {
					_local20 = i++;
					surface.indexVector[_local20] = r2;
					_local21 = i++;
					surface.indexVector[_local21] = (r2 + v);
					_local22 = i++;
					surface.indexVector[_local22] = ((r2 + v) + 1);
					v++;
				}
			}
			surface.material = material;
			for each (surf in obj.surfaces) {
				surf.updateBoundings();
			}
			max = Math.max(radius1, radius2);
			obj.bounds = new Cube3D();
			obj.bounds.center.y = (height * 0.5);
			obj.bounds.max.setTo(max, height, max);
			obj.bounds.min.setTo(-(max), 0, -(max));
			obj.bounds.length = obj.bounds.max.subtract(obj.bounds.min);
			obj.bounds.radius = Vector3D.distance(obj.bounds.center, obj.bounds.max);
			
			return obj;
		}
		
		public static function Cross(name:String = "cross", size:Number = 10, color:uint = 0xFFFFFF, alpha:Number = 1):ZenCanvas {
			var obj:ZenCanvas = new ZenCanvas(name);
			
			var s:Number = (size * 0.5);
			obj.clear();
			obj.lineStyle(1, color, alpha);
			obj.moveTo(s, 0, 0);
			obj.lineTo(-(s), 0, 0);
			obj.moveTo(0, s, 0);
			obj.lineTo(0, -(s), 0);
			obj.moveTo(0, 0, s);
			obj.lineTo(0, 0, -(s));
			
			return obj;
		}
		
		public static function Cube(name:String = "", width:Number = 10, height:Number = 10, depth:Number = 10, segments:int = 1, material:ShaderMaterialBase = null):ZenMesh {
			var obj:ZenMesh = new ZenMesh(name);
			
			if (!(material)) {
				material = new ZenMaterial((name + "_material"));
			}
			var objSurf:ZenFace = new ZenFace(name);
			obj.surfaces[0] = objSurf;
			objSurf.addVertexData(VertexType.POSITION);
			objSurf.addVertexData(VertexType.NORMAL);
			objSurf.addVertexData(VertexType.UV0);
			objSurf.vertexVector = new Vector.<Number>();
			objSurf.indexVector = new Vector.<uint>();
			createCubePlane(obj, width, height, (depth * 0.5), segments, material, "+xy");
			createCubePlane(obj, width, height, (depth * 0.5), segments, material, "-xy");
			createCubePlane(obj, depth, height, (width * 0.5), segments, material, "+yz");
			createCubePlane(obj, depth, height, (width * 0.5), segments, material, "-yz");
			createCubePlane(obj, width, depth, (height * 0.5), segments, material, "+xz");
			createCubePlane(obj, width, depth, (height * 0.5), segments, material, "-xz");
			objSurf.material = material;
			var max:Number = (Math.max(width, height, depth) * 0.5);
			obj.bounds = new Cube3D();
			obj.bounds.max.setTo((width * 0.5), (height * 0.5), (depth * 0.5));
			obj.bounds.min.setTo((-(width) * 0.5), (-(height) * 0.5), (-(depth) * 0.5));
			obj.bounds.length = obj.bounds.max.subtract(obj.bounds.min);
			obj.bounds.radius = Vector3D.distance(obj.bounds.center, obj.bounds.max);
			
			return obj;
		}
		
		private static function createCubePlane(obj:ZenMesh, width:Number, height:Number, depth:Number, segments:int, material:ShaderMaterialBase, axis:String):void {
			var i:int;
			var e:int;
			var u:Number;
			var v:Number;
			var x:Number;
			var y:Number;
			var surface:ZenFace = obj.surfaces[0];
			var matrix:Matrix3D = new Matrix3D();
			if (axis == "+xy") {
				M3D.setOrientation(matrix, new Vector3D(0, 0, -1));
			} else {
				if (axis == "-xy") {
					M3D.setOrientation(matrix, new Vector3D(0, 0, 1));
				} else {
					if (axis == "+xz") {
						M3D.setOrientation(matrix, new Vector3D(0, 1, 0));
					} else {
						if (axis == "-xz") {
							M3D.setOrientation(matrix, new Vector3D(0, -1, 0));
						} else {
							if (axis == "+yz") {
								M3D.setOrientation(matrix, new Vector3D(1, 0, 0));
							} else {
								if (axis == "-yz") {
									M3D.setOrientation(matrix, new Vector3D(-1, 0, 0));
								}
							}
						}
					}
				}
			}
			M3D.setScale(matrix, width, height, 1);
			M3D.translateZ(matrix, depth);
			var raw:Vector.<Number> = matrix.rawData;
			var normal:Vector3D = M3D.getDir(matrix);
			i = (surface.vertexVector.length / surface.sizePerVertex);
			e = i;
			v = 0;
			while (v <= segments) {
				u = 0;
				while (u <= segments) {
					x = ((u / segments) - 0.5);
					y = ((v / segments) - 0.5);
					surface.vertexVector.push((((x * raw[0]) + (y * raw[4])) + raw[12]), (((x * raw[1]) + (y * raw[5])) + raw[13]), (((x * raw[2]) + (y * raw[6])) + raw[14]), normal.x, normal.y, normal.z, (1 - (u / segments)), (1 - (v / segments)));
					i++;
					u++;
				}
				v++;
			}
			i = surface.indexVector.length;
			v = 0;
			while (v < segments) {
				u = 0;
				while (u < segments) {
					var _local17 = i++;
					surface.indexVector[_local17] = (((u + 1) + (v * (segments + 1))) + e);
					var _local18 = i++;
					surface.indexVector[_local18] = (((u + 1) + ((v + 1) * (segments + 1))) + e);
					var _local19 = i++;
					surface.indexVector[_local19] = ((u + ((v + 1) * (segments + 1))) + e);
					var _local20 = i++;
					surface.indexVector[_local20] = ((u + (v * (segments + 1))) + e);
					var _local21 = i++;
					surface.indexVector[_local21] = (((u + 1) + (v * (segments + 1))) + e);
					var _local22 = i++;
					surface.indexVector[_local22] = ((u + ((v + 1) * (segments + 1))) + e);
					u++;
				}
				v++;
			}
		}
		
		public static function Cylinder(name:String = "cylinder", radius:Number = 5, height:Number = 10, segments:int = 12, material:ShaderMaterialBase = null):ZenMesh {
			return Cone(name, radius, radius, height, segments, material);
		}
		
		public static function Dome(name:String = "dome", radius:Number = 5, color:uint = 0xFFFFFF, alpha:Number = 1, steps:int = 24):ZenCanvas {
			var obj:ZenCanvas = new ZenCanvas(name);
			
			var x:Number;
			var y:Number;
			var z:Number;
			var n:Number = 0;
			var s:Number = ((Math.PI * 2) / steps);
			var scale:Number = radius;
			obj.clear();
			obj.lineStyle(1, color, alpha);
			obj.moveTo((Math.cos(0) * scale), 0, (Math.sin(0) * scale));
			n = s;
			while (n <= ((Math.PI * 2) + s)) {
				obj.lineTo((Math.cos(n) * scale), 0, (Math.sin(n) * scale));
				n = (n + s);
			}
			obj.moveTo(0, (Math.sin(0) * scale), (Math.cos(0) * scale));
			n = s;
			while (n <= (Math.PI + s)) {
				obj.lineTo(0, (Math.sin(n) * scale), (Math.cos(n) * scale));
				n = (n + s);
			}
			obj.moveTo((Math.cos(0) * scale), (Math.sin(0) * scale), 0);
			n = s;
			while (n <= (Math.PI + s)) {
				obj.lineTo((Math.cos(n) * scale), (Math.sin(n) * scale), 0);
				n = (n + s);
			}
			
			return obj;
		}
		
		public static function Dot(name:String = "point", radius:Number = 5, color:uint = 0xFFFFFF):ZenCanvas {
			return Radius(name, radius, color, 4);
		}
		
		public static function Dummy(name:String = "dummy", size:Number = 10, thickness:Number = 1, color:uint = 0xFFFFFF, alpha:Number = 1):ZenCanvas {
			var obj:ZenCanvas = new ZenCanvas(name);
			
			var s:Number = (size * 0.5);
			obj.clear();
			obj.lineStyle(thickness, color, alpha);
			obj.moveTo(-(s), -(s), -(s));
			obj.lineTo(s, -(s), -(s));
			obj.lineTo(s, s, -(s));
			obj.lineTo(-(s), s, -(s));
			obj.lineTo(-(s), -(s), -(s));
			obj.moveTo(-(s), -(s), s);
			obj.lineTo(s, -(s), s);
			obj.lineTo(s, s, s);
			obj.lineTo(-(s), s, s);
			obj.lineTo(-(s), -(s), s);
			obj.moveTo(-(s), -(s), -(s));
			obj.lineTo(-(s), -(s), s);
			obj.moveTo(s, -(s), -(s));
			obj.lineTo(s, -(s), s);
			obj.moveTo(-(s), s, -(s));
			obj.lineTo(-(s), s, s);
			obj.moveTo(s, s, -(s));
			obj.lineTo(s, s, s);
			obj.bounds = new Cube3D();
			obj.bounds.min.setTo(-(s), -(s), -(s));
			obj.bounds.max.setTo(s, s, s);
			obj.bounds.length = obj.bounds.max.subtract(obj.bounds.min);
			obj.bounds.radius = obj.bounds.max.length;
			
			return obj;
		}
		
		public static function HPlane(name:String = "", size:int = 10, color:int = 0xFFCB00, alpha:Number = 1):ZenCanvas {
			var obj:ZenCanvas = new ZenCanvas(name);
			
			obj.lineStyle(1, color, alpha);
			var s:Number = (size * 0.5);
			var s2:Number = (size * 0.4);
			var d:Number = (size * 0.5);
			var d2:Number = (size * 0.75);
			obj.moveTo(-(s), -(s), 0);
			obj.lineTo(-(s), s, 0);
			obj.lineTo(s, s, 0);
			obj.lineTo(s, -(s), 0);
			obj.lineTo(-(s), -(s), 0);
			obj.moveTo(0, 0, 0);
			obj.lineTo(0, 0, d);
			obj.moveTo(-(s2), 0, d);
			obj.lineTo(s2, 0, d);
			obj.lineTo(0, 0, d2);
			obj.lineTo(-(s2), 0, d);
			
			return obj;
		}
		
		public static function Pie(name:String = "", from:Number = 1, to:Number = 10, radius:Number = 20, height:Number = 5, material:ShaderMaterialBase = null):ZenMesh {
			var obj:ZenMesh = new ZenMesh(name);
			
			if (!material) {
				material = new ZenMaterial(name + "_material");
			}
			
			var segments:int = 24;
			var steps:int = 12;
			
			var indices:Vector.<uint> = new Vector.<uint>;
			var positions:Vector.<Number> = new Vector.<Number>;
			var uvs:Vector.<Number> = new Vector.<Number>;
			var normals:Vector.<Number> = new Vector.<Number>;
			var vertex:Vector.<Number> = new Vector.<Number>;
			var normal:Vector.<Number> = new Vector.<Number>;
			var matrix:Matrix3D = new Matrix3D;
			var i:int, j:int;
			
			from = from * 360 / 100;
			to = to * 360 / 100;
			
			vertex.push(0, height, 0);
			vertex.push(radius, height, 0);
			vertex.push(radius, height, 0);
			vertex.push(radius, 0, 0);
			vertex.push(radius, 0, 0);
			vertex.push(0, 0, 0);
			normal.push(0, 1, 0);
			normal.push(0, 1, 0);
			normal.push(1, 0, 0);
			normal.push(1, 0, 0);
			normal.push(0, -1, 0);
			normal.push(0, -1, 0);
			
			var length:int = vertex.length / 3;
			
			// project vertex positions and normals.
			var out:Vector.<Number> = new Vector.<Number>;
			matrix.identity();
			matrix.appendRotation(from, Vector3D.Y_AXIS);
			for (i = 0; i < segments + 1; i++) {
				matrix.transformVectors(vertex, out);
				positions = positions.concat(out);
				matrix.transformVectors(normal, out);
				normals = normals.concat(out);
				matrix.appendRotation((to - from) / segments, Vector3D.Y_AXIS);
			}
			
			// uvs.
			for (i = 0; i < segments + 1; i++)
				for (j = 0; j < length; j++)
					uvs.push(i / segments, j / (length - 1));
			
			// build indices.
			for (i = 0; i < segments; i++) {
				for (j = 0; j < length - 1; j++) {
					var id0:uint = ((i + 1) * length) + j;
					var id1:uint = (i * length) + j;
					var id2:uint = ((i + 1) * length) + j + 1;
					var id3:uint = (i * length) + j + 1;
					indices.push(id1, id2, id0);
					indices.push(id2, id1, id3);
				}
			}
			
			var len:int = positions.length / 3;
			
			out = new Vector.<Number>;
			uvs = uvs.concat(Vector.<Number>([0, 0, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 0, 1]));
			vertex = Vector.<Number>([0, height, 0, radius, height, 0, radius, 0, 0, 0, 0, 0]);
			
			normal = Vector.<Number>([0, 0, 1, 0, 0, 1, 0, 0, 1, 0, 0, 1]);
			matrix.identity();
			matrix.appendRotation(from, Vector3D.Y_AXIS);
			matrix.transformVectors(vertex, out);
			positions = positions.concat(out);
			matrix.transformVectors(normal, out);
			normals = normals.concat(out);
			indices.push(len + 2, len + 1, len);
			indices.push(len + 3, len + 2, len);
			
			normal = Vector.<Number>([0, 0, -1, 0, 0, -1, 0, 0, -1, 0, 0, -1]);
			matrix.appendRotation(to - from, Vector3D.Y_AXIS);
			matrix.transformVectors(vertex, out);
			positions = positions.concat(out);
			matrix.transformVectors(normal, out);
			normals = normals.concat(out);
			indices.push(len + 4, len + 5, len + 6);
			indices.push(len + 4, len + 6, len + 7);
			
			var surf:ZenFace = new ZenFace("pieChart");
			surf.vertexVector = positions;
			surf.indexVector = indices;
			surf.addVertexData(VertexType.POSITION);
			surf.addVertexData(VertexType.UV0, 2, uvs);
			surf.addVertexData(VertexType.NORMAL, 3, normals);
			surf.material = material;
			obj.surfaces.push(surf);
			
			return obj;
		}
		
		public static function Plane(name:String = "", width:Number = 10, height:Number = 10, segments:int = 1, material:ShaderMaterialBase = null, axis:String = "+xy"):ZenMesh {
			var obj:ZenMesh = new ZenMesh(name);
			
			var i:int;
			var u:Number;
			var v:Number;
			var x:Number;
			var y:Number;
			var surf:ZenFace;
			var max:Number;
			var hwidth:Number;
			var hheight:Number;
			
			if (!(material)) {
				material = new ZenMaterial((name + "_material"));
			}
			var objSurf:ZenFace = new ZenFace();
			obj.surfaces[0] = objSurf;
			objSurf.addVertexData(VertexType.POSITION);
			objSurf.addVertexData(VertexType.NORMAL);
			objSurf.addVertexData(VertexType.UV0);
			objSurf.vertexVector = new Vector.<Number>();
			objSurf.indexVector = new Vector.<uint>();
			var matrix:Matrix3D = new Matrix3D();
			if (axis == "+xy") {
				M3D.setOrientation(matrix, new Vector3D(0, 0, -1));
			} else {
				if (axis == "-xy") {
					M3D.setOrientation(matrix, new Vector3D(0, 0, 1));
				} else {
					if (axis == "+xz") {
						M3D.setOrientation(matrix, new Vector3D(0, 1, 0));
					} else {
						if (axis == "-xz") {
							M3D.setOrientation(matrix, new Vector3D(0, -1, 0));
						} else {
							if (axis == "+yz") {
								M3D.setOrientation(matrix, new Vector3D(1, 0, 0));
							} else {
								if (axis == "-yz") {
									M3D.setOrientation(matrix, new Vector3D(-1, 0, 0));
								} else {
									M3D.setOrientation(matrix, new Vector3D(0, 0, -1));
								}
							}
						}
					}
				}
			}
			M3D.setScale(matrix, width, height, 1);
			var raw:Vector.<Number> = matrix.rawData;
			var normal:Vector3D = M3D.getDir(matrix);
			var surface:ZenFace = objSurf;
			i = 0;
			v = 0;
			while (v <= segments) {
				u = 0;
				while (u <= segments) {
					x = ((u / segments) - 0.5);
					y = ((v / segments) - 0.5);
					surface.vertexVector.push((((x * raw[0]) + (y * raw[4])) + raw[12]), (((x * raw[1]) + (y * raw[5])) + raw[13]), (((x * raw[2]) + (y * raw[6])) + raw[14]), normal.x, normal.y, normal.z, (1 - (u / segments)), (1 - (v / segments)));
					i++;
					u++;
				}
				v++;
			}
			i = 0;
			v = 0;
			while (v < segments) {
				u = 0;
				while (u < segments) {
					var _local20 = i++;
					surface.indexVector[_local20] = ((u + 1) + (v * (segments + 1)));
					var _local21 = i++;
					surface.indexVector[_local21] = ((u + 1) + ((v + 1) * (segments + 1)));
					var _local22 = i++;
					surface.indexVector[_local22] = (u + ((v + 1) * (segments + 1)));
					var _local23 = i++;
					surface.indexVector[_local23] = (u + (v * (segments + 1)));
					var _local24 = i++;
					surface.indexVector[_local24] = ((u + 1) + (v * (segments + 1)));
					var _local25 = i++;
					surface.indexVector[_local25] = (u + ((v + 1) * (segments + 1)));
					u++;
				}
				v++;
			}
			surface.material = material;
			for each (surf in obj.surfaces) {
				surf.updateBoundings();
			}
			max = (Math.max(width, height) * 0.5);
			hwidth = (width * 0.5);
			hheight = (height * 0.5);
			obj.bounds = new Cube3D();
			obj.bounds.max.setTo(hwidth, hheight, 0);
			if (axis.indexOf("xy") != -1) {
				obj.bounds.min.setTo(-(hwidth), -(hheight), 0);
			} else {
				if (axis.indexOf("xz") != -1) {
					obj.bounds.max.setTo(hwidth, 0, hheight);
					obj.bounds.min.setTo(-(hwidth), 0, -(hheight));
				} else {
					if (axis.indexOf("yz") != -1) {
						obj.bounds.max.setTo(0, hwidth, hheight);
						obj.bounds.min.setTo(0, -(hwidth), -(hheight));
					}
				}
			}
			obj.bounds.length = obj.bounds.max.subtract(obj.bounds.min);
			obj.bounds.radius = Vector3D.distance(obj.bounds.center, obj.bounds.max);
			
			return obj;
		}
		
		public static function Radius(name:String = "radius", radius:Number = 5, color:uint = 0xFFFFFF, alpha:Number = 1, steps:int = 24):ZenCanvas {
			var obj:ZenCanvas = new ZenCanvas(name);
			
			var x:Number;
			var y:Number;
			var z:Number;
			var n:Number = 0;
			var s:Number = ((Math.PI * 2) / steps);
			var scale:Number = radius;
			obj.clear();
			obj.lineStyle(1, color, alpha);
			obj.moveTo((Math.cos(0) * scale), 0, (Math.sin(0) * scale));
			n = s;
			while (n <= ((Math.PI * 2) + s)) {
				obj.lineTo((Math.cos(n) * scale), 0, (Math.sin(n) * scale));
				n = (n + s);
			}
			obj.moveTo(0, (Math.cos(0) * scale), (Math.sin(0) * scale));
			n = s;
			while (n <= ((Math.PI * 2) + s)) {
				obj.lineTo(0, (Math.cos(n) * scale), (Math.sin(n) * scale));
				n = (n + s);
			}
			obj.moveTo((Math.cos(0) * scale), (Math.sin(0) * scale), 0);
			n = s;
			while (n <= ((Math.PI * 2) + s)) {
				obj.lineTo((Math.cos(n) * scale), (Math.sin(n) * scale), 0);
				n = (n + s);
			}
			
			return obj;
		}
		
		public static function Sphere(name:String = "sphere", radius:Number = 5, segments:int = 24, material:ShaderMaterialBase = null):ZenMesh {
			var obj:ZenMesh = new ZenMesh(name);
			
			var i:int;
			var u:Number;
			var v:Number;
			var x:Number;
			var y:Number;
			var z:Number;
			var surf:ZenFace;
			
			if (!(material)) {
				material = new ZenMaterial((name + "_material"));
			}
			var objSurf:ZenFace = new ZenFace((name + "_surface"));
			obj.surfaces[0] = objSurf;
			objSurf.addVertexData(VertexType.POSITION);
			objSurf.addVertexData(VertexType.NORMAL);
			objSurf.addVertexData(VertexType.UV0);
			objSurf.vertexVector = new Vector.<Number>();
			objSurf.indexVector = new Vector.<uint>();
			var surface:ZenFace = objSurf;
			var normal:Vector3D = new Vector3D();
			var sx:int = segments;
			var sy:int = (segments + 1);
			i = 0;
			v = 0;
			while (v <= sy) {
				u = 0;
				while (u <= sx) {
					y = (-(Math.cos(((v / sy) * Math.PI))) * radius);
					x = ((Math.cos((((u / sx) * Math.PI) * 2)) * radius) * Math.sin(((v / sy) * Math.PI)));
					z = ((-(Math.sin((((u / sx) * Math.PI) * 2))) * radius) * Math.sin(((v / sy) * Math.PI)));
					normal.x = x;
					normal.y = y;
					normal.z = z;
					normal.normalize();
					surface.vertexVector.push(x, y, z, normal.x, normal.y, normal.z, (1 - (u / segments)), (1 - (v / segments)));
					i++;
					u++;
				}
				v++;
			}
			i = 0;
			v = 0;
			while (v < sy) {
				u = 0;
				while (u < sx) {
					var _local16 = i++;
					surface.indexVector[_local16] = (u + (v * (sx + 1)));
					var _local17 = i++;
					surface.indexVector[_local17] = ((u + 1) + (v * (sx + 1)));
					var _local18 = i++;
					surface.indexVector[_local18] = (u + ((v + 1) * (sx + 1)));
					var _local19 = i++;
					surface.indexVector[_local19] = ((u + 1) + (v * (sx + 1)));
					var _local20 = i++;
					surface.indexVector[_local20] = ((u + 1) + ((v + 1) * (sx + 1)));
					var _local21 = i++;
					surface.indexVector[_local21] = (u + ((v + 1) * (sx + 1)));
					u++;
				}
				v++;
			}
			
			//vertexCount = ((sx + 1) * (sy + 1));
			
			surface.material = material;
			for each (surf in obj.surfaces) {
				surf.updateBoundings();
			}
			obj.bounds = new Cube3D();
			obj.bounds.max.setTo(radius, radius, radius);
			obj.bounds.min.setTo(-(radius), -(radius), -(radius));
			obj.bounds.length = obj.bounds.max.subtract(obj.bounds.min);
			obj.bounds.radius = radius;
			
			return obj;
		}
		
		public static function Spring(name:String = "spring", radius:Number = 5, length:Number = 5, count:Number = 5, color:uint = 0xFFFFFF, alpha:Number = 1, steps:int = 24):ZenCanvas {
			var obj:ZenCanvas = new ZenCanvas(name);
			
			var x:Number;
			var y:Number;
			var z:Number;
			var n:Number = 0;
			var s:Number = ((Math.PI * 2) / steps);
			var l:Number = ((Math.PI * 2) * count);
			obj.clear();
			obj.lineStyle(1, color, alpha);
			obj.moveTo((Math.cos(0) * radius), 0, (Math.sin(0) * radius));
			n = s;
			while (n <= (l + s)) {
				obj.lineTo((Math.cos(n) * radius), ((n / l) * length), (Math.sin(n) * radius));
				n = (n + s);
			}
			
			return obj;
		}
	
	}

}