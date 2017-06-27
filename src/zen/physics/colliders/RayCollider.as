package zen.physics.colliders {
	import zen.enums.*;
	import flash.geom.Vector3D;
	import flash.geom.*;
	import zen.utils.*;
	
	public class RayCollider extends Collider {
		
		public var dir:Vector3D;
		public var distance:Number;
		
		public function RayCollider(dir:Vector3D = null, distance:Number = 1000) {
			this.shape = ColliderShape.RAY;
			this.distance = distance;
			this.dir = ((dir) || (new Vector3D()));
		}
		
		final override public function setMass(mass:Number):void {
			super.setMass(mass);
			invLocalInertia.rawData = new Vector.<Number>(16, true);
		}
		
		override public function update(timeStep:Number):void {
			var radius:Number;
			var mx:Number;
			var my:Number;
			var mz:Number;
			super.update(timeStep);
			if (pivot) {
				transform.copyColumnTo(2, this.dir);
				this.dir.normalize();
			}
			radius = (this.distance * 0.5);
			mx = (position.x + (this.dir.x * radius));
			my = (position.y + (this.dir.y * radius));
			mz = (position.z + (this.dir.z * radius));
			minX = (mx - radius);
			minY = (my - radius);
			minZ = (mz - radius);
			maxX = (mx + radius);
			maxY = (my + radius);
			maxZ = (mz + radius);
		}
		
		override public function clone():Collider {
			var collider:RayCollider = new RayCollider(this.dir, this.distance);
			collider.isStatic = isStatic;
			collider.isTrigger = isTrigger;
			collider.isRigidBody = isRigidBody;
			collider.setMass(mass);
			collider.enabled = enabled;
			collider.groups = groups;
			collider.collectContacts = collectContacts;
			collider.gravity = gravity;
			collider.neverSleep = neverSleep;
			collider.sleepingFactor = sleepingFactor;
			if (sleeping) {
				collider.sleep();
			}
			return (collider);
		}
	
	}
}

