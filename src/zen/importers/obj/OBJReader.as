package zen.importers.obj {
    import zen.display.*;
	import flash.filesystem.File;
	import flash.filesystem.FileStream;
	import flash.geom.*;
	import zen.display.*;
	import zen.materials.*;
	import zen.effects.*;
	import zen.enums.VertexType;
	import zen.utils.ZenUtils;
	
	public class OBJReader {
		
		private static var blankVector:Vector3D = new Vector3D();
		private static var vertMapping:Array = [];
		private static var finalVertID:int;
		private static var curSurfaceName:String;
		private static var curSurfaceID:int;
		private static var calcNormals:Boolean;
		
		
		
		// OBJ
		
		public static function Load(objPath:String, material:ZenMaterial, recalcNormals:Boolean = false, scaleMesh:Number = 1, specular:Boolean = true, calcDupEdges:Boolean = false):ZenMesh {
			return Decode(ZenUtils.LoadTextFile(objPath), objPath, material, recalcNormals, scaleMesh, specular, calcDupEdges);
		}
		public static function Decode(objData:String, objPath:String, material:ZenMaterial, recalcNormals:Boolean = false, scaleMesh:Number = 1, specular:Boolean = true, calcDupEdges:Boolean = false):ZenMesh {
			
			
			
			// NEW MESH
			
			calcNormals = recalcNormals;
			
			var mesh:ZenMesh = new ZenMesh();
			
			var vals:Array;
			
			var vertCount:int = 0;
			var normalCount:int = 0;
			
			var verts:Array = [];
			var normals:Array = [];
			
			var indices:Array = [];
			var surfaces:Array = [];
			
			vertMapping.length = 0;
			
			var doneEdges:Array = [];
			var surfaceMapping:Object = {};
			
			var lines:Array = ZenUtils.SplitLines(objData);
			
			
			// load materials
			var materials:Object = objPath == null ? null : MTLReader.Load(ZenUtils.SetExt(objPath, "mtl"), specular);
			var curMat:ZenMaterial = null;
			
			
			// load all lines
			for each (var line:String in lines) {
				
				
				
				var isVert:Boolean = ZenUtils.BeginsWith(line, "v ");
				var isNormal:Boolean = ZenUtils.BeginsWith(line, "vn ");
				var isGroup:Boolean = ZenUtils.BeginsWith(line, "g ");
				var isFace:Boolean = ZenUtils.BeginsWith(line, "f ");
				var isMaterial:Boolean = ZenUtils.BeginsWith(line, "usemtl ");
				
				if (isGroup || (surface == null && isFace)) {
					
					
					
					// GROUP .. NEW SURFACE
					
					var surface:ZenFace = new ZenFace();
					mesh.surfaces.push(surface);
					
					surface.addVertexData( VertexType.POSITION, 3 );
					surface.addVertexData( VertexType.NORMAL, 3 );
					
					surface.edgeVector = new Vector.<uint>();
					
					
					// use MTL mat
					if (curMat) {
						surface.material = curMat;
					}else {
						
						// use given mat
						if (material) {
							surface.material = material;
						} else {
							
							// use random color if no mat given
							surface.material = ZenMaterial.NewColorMaterial(Math.random() * 0xFFFFFF);
						}
					}
					
					
					finalVertID = 0;
					
					curSurfaceName = isGroup ? ZenUtils.Trim(ZenUtils.AfterLast(ZenUtils.Trim(line), " ")) : null;
					curSurfaceID = mesh.surfaces.length - 1;
					
					surfaceMapping[curSurfaceName] = curSurfaceID;
					surfaces[curSurfaceID] = surface;
					vertMapping[curSurfaceID] = [];
					
					
				}
				
				if (isVert || isNormal) {
					
					
					
					// REGISTER VERT / NORMAL
					
					vals = line.split(" ");
					var point:Vector3D = new Vector3D();
					var c:int = 0;
					for (var v:int = 1, vl:int = vals.length; v < vl; v++) {
						var val:String = vals[v];
						if (val.length > 0) {
							c++;
							
							if (c == 1) {
								point.x = Number(val);
							}
							if (c == 2) {
								point.y = Number(val);
							}
							if (c == 3) {
								point.z = Number(val);
							}
						}
					}
					
					if (isVert) {
						if (scaleMesh != 1){
							point.scaleBy(scaleMesh);
						}
						vertCount++;
						verts[vertCount] = point;
					} else {
						normalCount++;
						normals[normalCount] = point;
					}
					
					
					
				}
				
				
				else if (isFace) {
					
					
					
					// REGISTER FACE
					
					vals = line.split(" ");
					indices.length = 0;
					
					var points:int = 0;// vals.length - 1;
					for (var v:int = 1, vl:int = vals.length; v < vl; v++) {
						var val:String = vals[v];
						if (val.length > 0) {
							indices.push(val.split("/"));
							points++;
						}
					}
					
					if (points == 3) {
						addFace(surface, indices[0], indices[1], indices[2], verts, normals);
					} else if (points == 4){
						addFace(surface, indices[0], indices[1], indices[2], verts, normals);
						addFace(surface, indices[2], indices[3], indices[0], verts, normals);
					}
					
				}
				
				
				else if (isMaterial) {
					
					
					// use loaded materials if MTL provided
					var mtlName:String = ZenUtils.AfterFirst(line, " ");
					if (materials && materials[mtlName] != null) {
						
						// set mat
						surface.material = curMat = materials[mtlName];
						
					}
					
				}
				
				
				else if (ZenUtils.BeginsWith(line, "e ")) {
					
					
					
					// REGISTER EDGE
					
					vals = line.split(" ");
					indices.length = 0;
					
					var points:int = 0;// vals.length - 1;
					for (var v:int = 1, vl:int = vals.length; v < vl; v++) {
						var val:String = vals[v];
						if (val.length > 0) {
							indices.push(val);
							points++;
						}
					}
					
					if (points == 2) {
						
						surface = surfaces[curSurfaceID];
						var curEdge:int = surface.edgeVector.length;
						
						
						
						// MARK DUPS FOR RENDERING LATER
						if (calcDupEdges){
							var ep1p:Vector3D = verts[int(indices[0])];
							var ep2p:Vector3D = verts[int(indices[1])];
							var dupSurface:int = -1;
							var dupEdge:int = -1;
							for (var e:int = 0, el:int = doneEdges.length; e < el; e+= 8) {
								
								// if dup found
								var match1:Boolean = (doneEdges[e] == ep1p.x && doneEdges[e+1] == ep1p.y && doneEdges[e+2] == ep1p.z && doneEdges[e+3] == ep2p.x && doneEdges[e+4] == ep2p.y && doneEdges[e+5] == ep2p.z);
								var match2:Boolean = (doneEdges[e] == ep2p.x && doneEdges[e+1] == ep2p.y && doneEdges[e+2] == ep2p.z && doneEdges[e+3] == ep1p.x && doneEdges[e+4] == ep1p.y && doneEdges[e+5] == ep1p.z);
								if (match1 || match2) {
									
									
									// link self to other
									dupSurface = doneEdges[e+6];
									dupEdge = doneEdges[e+7];
									
									// link other to self
									var otherSurface:ZenFace = mesh.surfaces[dupSurface];
									otherSurface.edgeVector[dupEdge + 2] = curSurfaceID;
									otherSurface.edgeVector[dupEdge + 3] = curEdge;
									
									
									break;
								}
							}
							if (dupSurface == -1){
								doneEdges.push(ep1p.x, ep1p.y, ep1p.z, ep2p.x, ep2p.y, ep2p.z, curSurfaceID, curEdge);
							}
						}
						
						
						
						
						var ep1:int = vertMapping[curSurfaceID][int(indices[0])];
						var ep2:int = vertMapping[curSurfaceID][int(indices[1])];
						surface.edgeVector.push(ep1, ep2, dupSurface, dupEdge, 0);
						
					}
					
				}
				
				else if (ZenUtils.BeginsWith(line, "eg ")) {
					
					curSurfaceName = ZenUtils.Trim(ZenUtils.AfterLast(ZenUtils.Trim(line), " "));
					curSurfaceID = surfaceMapping[curSurfaceName];
					
				}
				
				
			}
			
			return mesh;
		}
		
		private static var AF_Normal:Vector3D = new Vector3D();
		private static function addFace(surface:ZenFace, text1:Array, text2:Array, text3:Array, verts:Array, normals:Array):void {
			
			var v1:int = int(text1[0]);
			var v2:int = int(text2[0]);
			var v3:int = int(text3[0]);
			
			var n1:int = int(text1[2]);
			var n2:int = int(text2[2]);
			var n3:int = int(text3[2]);
			
			var vert1:Vector3D = verts[v1];
			var normal1:Vector3D = normals[n1];
			
			var vert2:Vector3D = verts[v2];
			var normal2:Vector3D = normals[n2];
			
			var vert3:Vector3D = verts[v3];
			var normal3:Vector3D = normals[n3];
			
			// calc normal if not given
			if (calcNormals || normal1 == null) {
				normal1 = normal2 = normal3 = ZenUtils.CalcTriNormal(vert1, vert2, vert3, AF_Normal, true);
				
				// exit since 0 len face
				if (normal1 == null) {
					return;
				}
				
			}
			
			// add 3 verts
			surface.vertexVector.push(vert1.x, vert1.y, vert1.z, normal1.x, normal1.y, normal1.z);
			surface.vertexVector.push(vert2.x, vert2.y, vert2.z, normal2.x, normal2.y, normal2.z);
			surface.vertexVector.push(vert3.x, vert3.y, vert3.z, normal3.x, normal3.y, normal3.z);
			
			// add face
			surface.indexVector.push(finalVertID, finalVertID + 1, finalVertID + 2);
			
			// save new vert indices
			vertMapping[curSurfaceID][v1] = finalVertID;
			vertMapping[curSurfaceID][v2] = finalVertID + 1;
			vertMapping[curSurfaceID][v3] = finalVertID + 2;
			
			finalVertID += 3;
			
		}
		
	}

}