package zen.filters.transform {
	import zen.shaders.core.ShaderContext2;
	import zen.shaders.ShaderFilter;
	import zen.shaders.textures.ShaderMaterialBase;
	
	/** A material filter that responds to skin transform */
	public class SkinTransformFilter extends ShaderFilter {
		
		private var _bones:int;
		
		public function SkinTransformFilter(bones:int = 1) {
			this._bones = bones;
			super(null, null, ("flare.transforms.skin" + bones));
		}
		
		override public function init(material:ShaderMaterialBase, index:int, pass:int):void {
			super.init(material, index, pass);
			if (this._bones == 1) {
				material.flags = 1;
			}
			if (this._bones == 2) {
				material.flags = 2;
			}
			if (this._bones == 3) {
				material.flags = 4;
			}
			if (this._bones == 4) {
				material.flags = 8;
			}
		}
		
		override public function process(scope:ShaderContext2):void {
			scope.outputVertex = scope.call(techniqueName);
		}
	
	}
}

