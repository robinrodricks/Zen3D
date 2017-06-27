package zen.physics.colliders {
	import zen.enums.*;
	
	public class SphereCollider extends Collider {
		
		public var radius:Number;
		
		public function SphereCollider(radius:Number) {
			this.shape = ColliderShape.SPHERE;
			this.radius = radius;
			this.setMass(1);
		}
		
		final override public function setMass(mass:Number):void {
			var i:Number;
			super.setMass(mass);
			if (this.mass > 0) {
				i = ((((2 / 5) * this.mass) * this.radius) * this.radius);
				invLocalInertia.copyRawDataFrom(Vector.<Number>([i, 0, 0, 0, 0, i, 0, 0, 0, 0, i, 0, 0, 0, 0, 1]));
				invLocalInertia.invert();
			} else {
				invLocalInertia.rawData = new Vector.<Number>(16, true);
			}
		}
		
		final override public function update(timeStep:Number):void {
			super.update(timeStep);
			minX = (position.x - this.radius);
			minY = (position.y - this.radius);
			minZ = (position.z - this.radius);
			maxX = (position.x + this.radius);
			maxY = (position.y + this.radius);
			maxZ = (position.z + this.radius);
		}
		
		override public function clone():Collider {
			var collider:SphereCollider = new SphereCollider(this.radius);
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

