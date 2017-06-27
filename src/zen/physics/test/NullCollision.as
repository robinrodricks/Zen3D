package zen.physics.test {
	import zen.geom.physics.*;
	import zen.physics.*;
	import zen.physics.colliders.*;
	import zen.physics.core.*;
	
	public class NullCollision implements ICollision {
		
		public function test(collider0:Collider, collider1:Collider, collisions:Vector.<Contact>, collisionCount:int):int {
			return (collisionCount);
		}
	
	}
}

