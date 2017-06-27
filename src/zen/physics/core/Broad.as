package zen.physics.core {
	
	import zen.geom.physics.*;
	import zen.physics.core.*;
	import zen.physics.*;
	import zen.physics.colliders.*;
	
	public class Broad implements IBroadPhase {
		
		private var _collisions:Vector.<ICollision>;
		private var _colliders:Vector.<Collider>;
		private var _count:int;
		private var _axis:int;
		
		public function Broad(collisions:Vector.<ICollision>) {
			this._collisions = collisions;
			this._colliders = new Vector.<Collider>();
		}
		
		public function addCollider(collider:Collider):Boolean {
			var _local2 = this._count++;
			this._colliders[_local2] = collider;
			return (true);
		}
		
		public function removeCollider(collider:Collider):Boolean {
			var index:int = this._colliders.indexOf(collider);
			if (index != -1) {
				this._count--;
				this._colliders.splice(index, 1);
				return (true);
			}
			return (false);
		}
		
		public function test(contacts:Vector.<Contact>):int {
			var s0:Collider;
			var j:int;
			var s1:Collider;
			var numContacts:int;
			var i:int;
			while (i < this._count) {
				s0 = this._colliders[i];
				j = (i + 1);
				while (j < this._count) {
					s1 = this._colliders[j];
					if (((s0.isStatic) && (s1.isStatic))) {
					} else {
						if (((s0.sleeping) && (s1.sleeping))) {
						} else {
							if (((((s0.parent) && (s1.parent))) && ((s0.parent == s1.parent)))) {
							} else {
								if ((s0.groups & s1.groups) == 0) {
								} else {
									if ((((((((((((s0.maxX < s1.minX)) || ((s0.minX > s1.maxX)))) || ((s0.maxY < s1.minY)))) || ((s0.minY > s1.maxY)))) || ((s0.maxZ < s1.minZ)))) || ((s0.minZ > s1.maxZ)))) {
									} else {
										if (s0.shape <= s1.shape) {
											numContacts = this._collisions[(s0.shape | s1.shape)].test(s0, s1, contacts, numContacts);
										} else {
											numContacts = this._collisions[(s0.shape | s1.shape)].test(s1, s0, contacts, numContacts);
										}
									}
								}
							}
						}
					}
					j++;
				}
				i++;
			}
			return (numContacts);
		}
		
		public function get axis():int {
			return (this._axis);
		}
		
		public function set axis(value:int):void {
			this._axis = value;
		}
	
	}
}

