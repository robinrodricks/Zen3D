package zen.shaders.textures
{
    import zen.shaders.textures.ShaderMaterial;
    import flash.utils.ByteArray;
    import zen.materials.*;
    import zen.display.*;
    import zen.shaders.*;
    import flash.utils.*;

    public class QuadMaterial extends ShaderMaterial 
    {

		[Embed(source = "../../utils/assets/textures/QuadMaterial.data", mimeType = "application/octet-stream")]
        private static var compiledShader:Class;
		
        private static var data:ByteArray;

        private var _texture:Texture3D;

        public function QuadMaterial(texture:Texture3D=null)
        {
			if (data == null) {
				data = new compiledShader();
			}
			
            super("quad");
            this.byteCode = data;
            this.texture = texture;
            this.rebuild();
        }

        public function get texture():Texture3D
        {
            return (this._texture);
        }

        public function set texture(value:Texture3D):void
        {
            this._texture = value;
            this.params.texture.value = this._texture;
        }


    }
}

