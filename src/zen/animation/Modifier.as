package zen.animation {
	import zen.materials.*;
	import zen.ZenFace;
	import zen.ZenMesh;
	import zen.shaders.textures.ShaderMaterialBase;
	import zen.display.*;
	import zen.utils.*;
	import zen.shaders.textures.*;
	import flash.display3D.*;
	import flash.geom.*;
	import zen.display.*;
	
	public class Modifier {
		
		public function clone():Modifier {
			return (this);
		}
		
		public function draw(mesh:ZenMesh, material:ShaderMaterialBase = null):void {
			var surf:ZenFace;
			ZenUtils.global.copyFrom(mesh.world);
			ZenUtils.worldViewProj.copyFrom(ZenUtils.global);
			ZenUtils.worldViewProj.append(ZenUtils.viewProj);
			ZenUtils.objectsDrawn++;
			var l:int = mesh.surfaces.length;
			var i:int;
			while (i < l) {
				surf = mesh.surfaces[i];
				if (surf.visible) {
					((material) || (surf.material)).draw(mesh, surf, surf.firstIndex, surf.numTriangles);
				}
				i++;
			}
		}
	
	}
}

