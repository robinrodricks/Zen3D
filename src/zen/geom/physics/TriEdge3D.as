package zen.geom.physics {
	import flash.geom.Vector3D;
	
	/** Stores information about triangle edges during physics collision detection. */
	public class TriEdge3D extends Vector3D {
		
		public var v0:LinkedVector3D;
		public var v1:LinkedVector3D;
		public var next:TriEdge3D;
		public var valid:Boolean = true;
		public var tri:Tri3D;
		
		public function TriEdge3D(v0:LinkedVector3D, v1:LinkedVector3D) {
			this.v0 = v0;
			this.v1 = v1;
			this.x = (v1.x - v0.x);
			this.y = (v1.y - v0.y);
			this.z = (v1.z - v0.z);
			this.normalize();
		}
	
	}
}

