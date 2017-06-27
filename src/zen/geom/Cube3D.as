package zen.geom {
	import flash.geom.Vector3D;
	
	/**
	 * An axis-aligned cube that storeds information of object bounds & dimensions.
	 */
	public class Cube3D {
		
		/// Radius of the object count from the center of the object (not from the object).
		public var radius:Number = 0;
		/// Minimum corner of the bounding box of the object.
		public var min:Vector3D;
		/// Maximum corner of the bounding box of the object.
		public var max:Vector3D;
		/// Lengths of the bounding box of the object. (Maximum corner minus minimum corner).
		public var length:Vector3D;
		/// Center of the object. The center does not correspond to (0,0,0) of the object, but it is the calculated center of all the vertices.
		public var center:Vector3D;
		
		/// Creates a new Cube3D object.
		public function Cube3D() {
			this.reset();
		}
		
		/**
		 * Creates a copy of a Cube3D object.
		 * @return	Returns a new Cube3D object.
		 */
		public function clone():Cube3D {
			var b:Cube3D = new Cube3D();
			b.radius = this.radius;
			b.min = this.min.clone();
			b.max = this.max.clone();
			b.length = this.length.clone();
			b.center = this.center.clone();
			return (b);
		}
		
		public function toString():String {
			return ("[object Boundings3D]");
		}
		
		/// Resets the object properties to its default values.
		public function reset():void {
			this.radius = 0;
			this.min = new Vector3D();
			this.max = new Vector3D();
			this.center = new Vector3D();
			this.length = new Vector3D();
		}
		
		/** returns an array of 8 of the corner points */
		public function cornerPoints():Array {
			return [new Vector3D(min.x, min.y, min.z), // Top Front Left
			new Vector3D(max.x, min.y, min.z), // Top Front Right
			new Vector3D(min.x, max.y, min.z), // Bottom Front Left
			new Vector3D(max.x, max.y, min.z), // Bottom Front Right
			new Vector3D(min.x, min.y, max.z), // Top Back Left
			new Vector3D(max.x, min.y, max.z), // Top Back Right
			new Vector3D(min.x, max.y, max.z), // Bottom Back Left
			new Vector3D(max.x, max.y, max.z), // Bottom Back Right
			];
		}
	
	}
}

