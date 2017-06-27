package zen.loaders.obj {
	import flash.filesystem.File;
	import zen.filters.color.*;
	import zen.filters.maps.*;
	import zen.filters.transform.*;
	import zen.materials.*;
	import zen.utils.*;
	import zen.display.*;
	
	public class MTLReader {
		
		// MTL
		
		public static function Load(mtlPath:String, specular:Boolean):Object {
			
			var materials:Object = {};
			
			if (!(new File(mtlPath).exists)) {
				return null;
			}
			
			var mats:Array = [];
			var lines:Array = ZenUtils.SplitLines(ZenUtils.LoadTextFile(mtlPath));
			var mat:ZenMaterial;
			
			// load all lines
			for each (var line:String in lines) {
				
				var arg:String = ZenUtils.Trim(ZenUtils.AfterFirst(line, " "));
				var args:Array = arg.split(" ");
				
				if (ZenUtils.BeginsWith(line, "newmtl ")) {
					
					mat = new ZenMaterial(arg);
					mat.info = {};
					
					materials[arg] = mat;
					mats.push(mat);
					
						// AmbientColor
				} else if (ZenUtils.BeginsWith(line, "Ka ")) {
					mat.info.AmbientColor = parseMtlColor(args);
					
						// DiffuseColor
				} else if (ZenUtils.BeginsWith(line, "Kd ")) {
					mat.info.DiffuseColor = parseMtlColor(args);
					
						// SpecularColor
				} else if (ZenUtils.BeginsWith(line, "Ks ")) {
					mat.info.SpecularColor = parseMtlColor(args);
					
						// SpecularCoefficient
				} else if (ZenUtils.BeginsWith(line, "Ns ")) {
					mat.info.SpecularCoefficient = parseMtlFloat(args);
					
						// Transparency
				} else if (ZenUtils.BeginsWith(line, "d ") || ZenUtils.BeginsWith(line, "Tr ")) {
					mat.info.Transparency = parseMtlFloat(args);
					
						// IlluminationModel
				} else if (ZenUtils.BeginsWith(line, "illum ")) {
					mat.info.IlluminationModel = parseMtlInt(args);
					
						// AmbientTextureMap
				} else if (ZenUtils.BeginsWith(line, "map_Ka ")) {
					mat.info.AmbientTextureMap = arg;
					
						// DiffuseTextureMap
				} else if (ZenUtils.BeginsWith(line, "map_Kd ")) {
					mat.info.DiffuseTextureMap = arg;
					
						// SpecularTextureMap
				} else if (ZenUtils.BeginsWith(line, "map_Ks ")) {
					mat.info.SpecularTextureMap = arg;
					
						// SpecularHighlightTextureMap
				} else if (ZenUtils.BeginsWith(line, "map_Ns ")) {
					mat.info.SpecularHighlightTextureMap = arg;
					
						// AlphaTextureMap
				} else if (ZenUtils.BeginsWith(line, "map_d ")) {
					mat.info.AlphaTextureMap = arg;
					
						// BumpMap
				} else if (ZenUtils.BeginsWith(line, "map_bump ") || ZenUtils.BeginsWith(line, "bump ")) {
					mat.info.BumpMap = arg;
					
						// DisplacementMap
				} else if (ZenUtils.BeginsWith(line, "disp ")) {
					mat.info.DisplacementMap = arg;
					
						// StencilDecalMap
				} else if (ZenUtils.BeginsWith(line, "decal ")) {
					mat.info.StencilDecalMap = arg;
					
				}
				
			}
			
			// BUILD ALL MATERIALS
			for each (var mat:ZenMaterial in mats) {
				
				// if has mat
				/*if (mat.info.DisplacementMap != null) {
				   mat.filters.push( new TextureMapFilter(?) );
				
				   // else use color
				   }else {*/
				if (mat.info.DiffuseColor != null) {
					if (mat.info.Transparency != null) {
						mat.filters.push(new TextureMapFilter(new ZenTexture(ZenUtils.NewBitmap(1, 1, true, uint(mat.info.DiffuseColor))), 0, "multiply", Number(mat.info.Transparency)));
					} else {
						mat.filters.push(new ColorFilter(mat.info.DiffuseColor, 1));
					}
				}
				/*}*/
				
				if (specular) {
					mat.filters.push(new SpecularFilter(200, 1));
				}
				mat.twoSided = true;
				mat.build();
				
			}
			
			return materials;
		}
		
		private static function parseMtlColor(args:Array):int {
			return ZenUtils.ColorFromVector2(ZenUtils.ToNumber(args[0]), ZenUtils.ToNumber(args[1]), ZenUtils.ToNumber(args[2]));
		}
		
		private static function parseMtlFloat(args:Array):Number {
			return ZenUtils.ToNumber(args[0]);
		}
		
		private static function parseMtlInt(args:Array):int {
			return ZenUtils.ToInt(args[0]);
		}
	
	}

}