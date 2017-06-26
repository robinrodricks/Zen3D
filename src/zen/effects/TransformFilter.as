package zen.effects
{
	import zen.shaders.core.ShaderContext2;
    import zen.shaders.ShaderFilter;
    import flash.display.BlendMode;

    public class TransformFilter extends ShaderFilter 
    {

        public function TransformFilter()
        {
            super(null, BlendMode.MULTIPLY, "flare.transforms.transform");
        }

        override public function process(scope:ShaderContext2):void
        {
            scope.outputVertex = scope.call(techniqueName);
        }


    }
}

