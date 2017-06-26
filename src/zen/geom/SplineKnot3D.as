package zen.geom
{
    import flash.geom.Vector3D;

	/** A knot on a spline */
    public class SplineKnot3D extends Vector3D 
    {

        public var inVec:Vector3D;
        public var outVec:Vector3D;

        public function SplineKnot3D()
        {
            this.inVec = new Vector3D();
            this.outVec = new Vector3D();
            super();
        }

		
        override public function toString():String
        {
            return ("[object Knot3D]");
        }
		

        override public function clone():Vector3D
        {
            var n:SplineKnot3D = new SplineKnot3D();
            n.x = x;
            n.y = y;
            n.z = z;
            n.w = w;
            n.inVec = this.inVec.clone();
            n.outVec = this.outVec.clone();
            return (n);
        }


    }
}

