package zen.geom {
	import flash.geom.Vector3D;
	
	/** Holds information about a single 3D particle */
	public class Particle3D {
		
		public var position:Vector3D;
		public var velocity:Vector3D;
		public var spin:Number = 0;
		public var scale:Number = 1;
		
		public function Particle3D() {
			this.position = new Vector3D();
			this.velocity = new Vector3D();
			super();
		}
	
	}
}

