package zen.shaders.core
{
	import zen.shaders.*;
	import zen.enums.*;
	
	/** ShaderInput defines the attributes to pass to the shader for each vertex. */
    public class ShaderInput extends ShaderBase 
    {

        public var attribute:int;
        public var format:String;

        public function ShaderInput()
        {
            this.varType = ZSLFlags.INPUT;
        }

        public function clone():ShaderInput
        {
            var i:ShaderInput = new ShaderInput();
            i.name = name;
            i.varType = varType;
            i.semantic = semantic;
            i.attribute = this.attribute;
            i.format = this.format;
            return (i);
        }


    }
}

