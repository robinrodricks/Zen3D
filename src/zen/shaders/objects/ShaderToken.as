package zen.shaders.objects
{
	import zen.shaders.*;
	import zen.shaders.core.*;
	
    public class ShaderToken 
    {

        public var text:String;
        public var type:String;
        public var data:String;
        public var line:int;
        public var pos:int;

        public function ShaderToken(text:String, type:String, line:int=0, pos:int=0)
        {
            this.text = text;
            this.type = type;
            this.line = line;
            this.pos = pos;
        }

		
        public function toString():String
        {
            return ((((((("Token line: " + this.line) + "   type:   [") + this.type) + "] \t") + " text: ") + this.text));
        }
		


    }
}

