package zen.geom {
	import zen.display.*;
	import zen.Poly3D;
	import flash.geom.Vector3D;
	import zen.geom.*;
	
	/** A single 3D intersection between two objects */
	public class Intersection3D {
		
		public var mesh:ZenMesh;
		public var surface:ZenFace;
		public var poly:Poly3D;
		public var point:Vector3D;
		public var normal:Vector3D;
		public var u:Number;
		public var v:Number;
		
		public function Intersection3D() {
			this.point = new Vector3D();
			this.normal = new Vector3D();
			super();
		}
		
		public function toString():String {
			return ("[object Intersection3D]");
		}
	
	}
}

