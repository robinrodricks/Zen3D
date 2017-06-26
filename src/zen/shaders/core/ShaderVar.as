package zen.shaders.core
{
	import zen.shaders.*;
	import zen.enums.*;
    

	/** ShaderVar defines a float register to be used as a parameter.
	 * The length of the value vector of the parameter always be modulo of 4. */
    public class ShaderVar extends ShaderBase 
    {

        public var value:Vector.<Number>;
        public var length:int;
        public var format:String;
        public var min:Number = 0;
        public var max:Number = 0;
        public var order:int = 0;
        public var ui:String;

        public function ShaderVar(value:Vector.<Number>=null, length:int=1)
        {
            this.varType = ZSLFlags.PARAM;
            this.value = value;
            this.length = length;
        }

        public function clone():ShaderVar
        {
            var p:ShaderVar = new ShaderVar();
            if (semantic != ""){
                p.value = this.value;
            } else {
                if (this.value){
                    p.value = this.value.concat();
                }
            }
            p.length = this.length;
            p.format = this.format;
            p.min = this.min;
            p.max = this.max;
            p.name = name;
            p.varType = varType;
            p.semantic = semantic;
            p.order = this.order;
            p.ui = this.ui;
            return (p);
        }


    }
}

