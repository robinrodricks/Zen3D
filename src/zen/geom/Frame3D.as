package zen.geom
{
    import flash.geom.Matrix3D;
    
	/** A matrix that stores information about a certain object's transform (or frame) */
    public class Frame3D extends Matrix3D 
    {

        public var type:int = 0;
        public var callback:Function;

        public function Frame3D(vector:Vector.<Number>=null, type:int=0)
        {
            super(vector);
            this.type = type;
        }

        override public function clone():Matrix3D
        {
            var f:Frame3D = new Frame3D(rawData, this.type);
            f.callback = this.callback;
            return (f);
        }


    }
}

