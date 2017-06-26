package zen.intersects
{
	import zen.display.*;
    import zen.Poly3D;
    import flash.geom.Vector3D;
	import zen.geom.*;

    public class CollisionInfo 
    {

        public var mesh:ZenMesh;
        public var surface:ZenFace;
        public var poly:Poly3D;
        public var point:Vector3D;
        public var normal:Vector3D;
        public var u:Number;
        public var v:Number;

        public function CollisionInfo()
        {
            this.point = new Vector3D();
            this.normal = new Vector3D();
            super();
        }

		
        public function toString():String
        {
            return ("[object CollisionInfo]");
        }
		


    }
}

