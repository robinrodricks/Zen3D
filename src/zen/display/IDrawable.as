package zen.display {
	import zen.shaders.textures.ShaderMaterialBase;
	
	public interface IDrawable {
		
		function draw(_arg1:Boolean = true, _arg2:ShaderMaterialBase = null):void;
		function get inView():Boolean;
	
	}
}

