package zen.geom.physics {
	import zen.geom.*;
	import flash.geom.*;
	
	/** A node in a bounding volume hierarchy, used during physics collision calculations. */
	public class PhysicsNode3D {
		
		private static const _min:Vector3D = new Vector3D();
		private static const _max:Vector3D = new Vector3D();
		private static const _average:Vector3D = new Vector3D();
		
		/** The maximun number of depth nodes allowed. */
		public static var maxDepth:int = 8;
		
		public var minX:Number;
		public var minY:Number;
		public var minZ:Number;
		public var maxX:Number;
		public var maxY:Number;
		public var maxZ:Number;
		/** The parent BVH tree node. */
		public var parent:PhysicsNode3D;
		/** The triangle list contained in this node. */
		public var tris:Vector.<Tri3D>;
		/** The first leaf of this BVH node. */
		public var node0:PhysicsNode3D;
		/** The second leaf of this BVH node. */
		public var node1:PhysicsNode3D;
		private var depth:Number;
		
		public function PhysicsNode3D(parent:PhysicsNode3D = null) {
			this.parent = parent;
			if (parent) {
				this.minX = parent.minX;
				this.minY = parent.minY;
				this.minZ = parent.minZ;
				this.maxX = parent.maxX;
				this.maxY = parent.maxY;
				this.maxZ = parent.maxZ;
			}
		}
		
		/** Recalculates the local space bounds for all the tree nodes. */
		public function trim():void {
			if (this.tris) {
				this.balance();
			} else {
				if (this.node0) {
					this.node0.trim();
				}
				if (this.node1) {
					this.node1.trim();
				}
			}
		}
		
		/** Rebalances the spatial structure for efficiency in future computations. */
		private function balance():void {
			var t:Tri3D;
			var v0:LinkedVector3D;
			var v1:LinkedVector3D;
			var v2:LinkedVector3D;
			_min.setTo(1000000, 1000000, 1000000);
			_max.setTo(-1000000, -1000000, -1000000);
			_average.setTo(0, 0, 0);
			var length:int = this.tris.length;
			var i:int;
			while (i < length) {
				t = this.tris[i];
				v0 = t.v0;
				v1 = t.v1;
				v2 = t.v2;
				if (v0.x < _min.x) {
					_min.x = v0.x;
				}
				if (v0.y < _min.y) {
					_min.y = v0.y;
				}
				if (v0.z < _min.z) {
					_min.z = v0.z;
				}
				if (v1.x < _min.x) {
					_min.x = v1.x;
				}
				if (v1.y < _min.y) {
					_min.y = v1.y;
				}
				if (v1.z < _min.z) {
					_min.z = v1.z;
				}
				if (v2.x < _min.x) {
					_min.x = v2.x;
				}
				if (v2.y < _min.y) {
					_min.y = v2.y;
				}
				if (v2.z < _min.z) {
					_min.z = v2.z;
				}
				if (v0.x > _max.x) {
					_max.x = v0.x;
				}
				if (v0.y > _max.y) {
					_max.y = v0.y;
				}
				if (v0.z > _max.z) {
					_max.z = v0.z;
				}
				if (v1.x > _max.x) {
					_max.x = v1.x;
				}
				if (v1.y > _max.y) {
					_max.y = v1.y;
				}
				if (v1.z > _max.z) {
					_max.z = v1.z;
				}
				if (v2.x > _max.x) {
					_max.x = v2.x;
				}
				if (v2.y > _max.y) {
					_max.y = v2.y;
				}
				if (v2.z > _max.z) {
					_max.z = v2.z;
				}
				_average.x = (_average.x + ((v0.x + v1.x) + v2.x));
				_average.y = (_average.y + ((v0.y + v1.y) + v2.y));
				_average.z = (_average.z + ((v0.z + v1.z) + v2.z));
				i++;
			}
			this.minX = (((_min.x > this.minX)) ? _min.x : this.minX);
			this.minY = (((_min.y > this.minY)) ? _min.y : this.minY);
			this.minZ = (((_min.z > this.minZ)) ? _min.z : this.minZ);
			this.maxX = (((_max.x < this.maxX)) ? _max.x : this.maxX);
			this.maxY = (((_max.y < this.maxY)) ? _max.y : this.maxY);
			this.maxZ = (((_max.z < this.maxZ)) ? _max.z : this.maxZ);
			_average.scaleBy((1 / (length * 3)));
		}
		
		/** Builds this node and slits into new nodes recursively if necessary. */
		public function build(depth:int = 0):void {
			var i:int;
			var t:Tri3D;
			var axis:int;
			var center:Number;
			var min:Number;
			var max:Number;
			var l0:uint;
			var l1:uint;
			var v0:LinkedVector3D;
			var v1:LinkedVector3D;
			var v2:LinkedVector3D;
			var length:int = this.tris.length;
			this.balance();
			var nx:Number = (this.maxX - this.minX);
			var ny:Number = (this.maxY - this.minY);
			var nz:Number = (this.maxZ - this.minZ);
			nx = (_average.x - this.minX);
			ny = (_average.y - this.minY);
			nz = (_average.z - this.minZ);
			var maxAxis:Number = (((nx > ny)) ? (((nx > nz)) ? nx : nz) : (((ny > nz)) ? ny : nz));
			if (maxAxis == nx) {
				center = _average.x;
				axis = 0;
			}
			if (maxAxis == ny) {
				center = _average.y;
				axis = 1;
			} else {
				if (maxAxis == nz) {
					center = _average.z;
					axis = 2;
				}
			}
			this.node0 = new PhysicsNode3D(this);
			this.node1 = new PhysicsNode3D(this);
			this.node0.tris = new Vector.<Tri3D>();
			this.node1.tris = new Vector.<Tri3D>();
			i = 0;
			while (i < length) {
				t = this.tris[i];
				v0 = t.v0;
				v1 = t.v1;
				v2 = t.v2;
				if (axis == 0) {
					min = (((v0.x < v1.x)) ? (((v0.x < v2.x)) ? v0.x : v2.x) : (((v1.x < v2.x)) ? v1.x : v2.x));
					max = (((v0.x > v1.x)) ? (((v0.x > v2.x)) ? v0.x : v2.x) : (((v1.x > v2.x)) ? v1.x : v2.x));
				} else {
					if (axis == 1) {
						min = (((v0.y < v1.y)) ? (((v0.y < v2.y)) ? v0.y : v2.y) : (((v1.y < v2.y)) ? v1.y : v2.y));
						max = (((v0.y > v1.y)) ? (((v0.y > v2.y)) ? v0.y : v2.y) : (((v1.y > v2.y)) ? v1.y : v2.y));
					} else {
						min = (((v0.z < v1.z)) ? (((v0.z < v2.z)) ? v0.z : v2.z) : (((v1.z < v2.z)) ? v1.z : v2.z));
						max = (((v0.z > v1.z)) ? (((v0.z > v2.z)) ? v0.z : v2.z) : (((v1.z > v2.z)) ? v1.z : v2.z));
					}
				}
				if (max < center) {
					var _local18 = l0++;
					this.node0.tris[_local18] = t;
				} else {
					if (min > center) {
						_local18 = l1++;
						this.node1.tris[_local18] = t;
					} else {
						_local18 = l0++;
						this.node0.tris[_local18] = t;
						var _local19 = l1++;
						this.node1.tris[_local19] = t;
					}
				}
				i++;
			}
			if (axis == 0) {
				this.node0.maxX = center;
				this.node1.minX = center;
			} else {
				if (axis == 1) {
					this.node0.maxY = center;
					this.node1.minY = center;
				} else {
					this.node0.maxZ = center;
					this.node1.minZ = center;
				}
			}
			if (l0 == 0) {
				this.node0 = null;
			}
			if (l1 == 0) {
				this.node1 = null;
			}
			if ((((l0 == length)) && ((l1 == length)))) {
				this.node0 = null;
				this.node1 = null;
			}
			if (depth < maxDepth) {
				if (((((this.node0) && ((l0 > 10)))) && (!((l0 == length))))) {
					this.node0.build((depth + 1));
				}
				if (((((this.node1) && ((l1 > 10)))) && (!((l1 == length))))) {
					this.node1.build((depth + 1));
				}
			}
			if (((this.node0) || (this.node1))) {
				this.tris = null;
			}
		}
		
		/** Sorts the nodes by depth */
		private function sort(out:Vector.<PhysicsNode3D>, count:int):void {
			var i:int;
			var j:int;
			var e:int;
			var min:Number;
			var bvh:PhysicsNode3D;
			i = 1;
			while (i < count) {
				bvh = out[i];
				j = (i - 1);
				e = i;
				min = bvh.depth;
				while ((((j >= 0)) && ((out[j].depth > min)))) {
					var _local8 = e--;
					out[_local8] = out[j--];
				}
				out[e] = bvh;
				i++;
			}
		}
		
		/** Test a ray againts the BVH. */
		public function intersectRay(from:Vector3D, direction:Vector3D, out:Vector.<PhysicsNode3D>, count:int = 0, sort:Boolean = true):int {
			var tmin:Number;
			var tmax:Number;
			var tymin:Number;
			var tymax:Number;
			var tzmin:Number;
			var tzmax:Number;
			if (count >= 0x0400) {
				return (count);
			}
			var t0:Number = 0;
			var t1:Number = Number.MAX_VALUE;
			if (direction.x >= 0) {
				tmin = ((this.minX - from.x) / direction.x);
				tmax = ((this.maxX - from.x) / direction.x);
			} else {
				tmin = ((this.maxX - from.x) / direction.x);
				tmax = ((this.minX - from.x) / direction.x);
			}
			if (direction.y >= 0) {
				tymin = ((this.minY - from.y) / direction.y);
				tymax = ((this.maxY - from.y) / direction.y);
			} else {
				tymin = ((this.maxY - from.y) / direction.y);
				tymax = ((this.minY - from.y) / direction.y);
			}
			if ((((tmin > tymax)) || ((tymin > tmax)))) {
				return (count);
			}
			if (tymin > tmin) {
				tmin = tymin;
			}
			if (tymax < tmax) {
				tmax = tymax;
			}
			if (direction.z >= 0) {
				tzmin = ((this.minZ - from.z) / direction.z);
				tzmax = ((this.maxZ - from.z) / direction.z);
			} else {
				tzmin = ((this.maxZ - from.z) / direction.z);
				tzmax = ((this.minZ - from.z) / direction.z);
			}
			if ((((tmin > tzmax)) || ((tzmin > tmax)))) {
				return (count);
			}
			if (tzmin > tmin) {
				tmin = tzmin;
			}
			if (tzmax < tmax) {
				tmax = tzmax;
			}
			if ((((tmin < t1)) && ((tmax > t0)))) {
				if (this.tris) {
					this.depth = tmin;
					var _local14 = count++;
					out[_local14] = this;
				} else {
					if (this.node0) {
						count = this.node0.intersectRay(from, direction, out, count, sort);
					}
					if (this.node1) {
						count = this.node1.intersectRay(from, direction, out, count, sort);
					}
				}
			}
			if (sort) {
				this.sort(out, count);
				sort = false;
			}
			return (count);
		}
		
		/** Test a sphere volume against the BVH tree. */
		public function intersectSphere(from:Vector3D, radius:Number, out:Vector.<PhysicsNode3D>, count:int = 0):int {
			if (count >= 0x0400) {
				return (count);
			}
			if ((from.x + radius) < this.minX) {
				return (count);
			}
			if ((from.x - radius) > this.maxX) {
				return (count);
			}
			if ((from.y + radius) < this.minY) {
				return (count);
			}
			if ((from.y - radius) > this.maxY) {
				return (count);
			}
			if ((from.z + radius) < this.minZ) {
				return (count);
			}
			if ((from.z - radius) > this.maxZ) {
				return (count);
			}
			if (this.tris) {
				var _local5 = count++;
				out[_local5] = this;
			} else {
				if (this.node0) {
					count = this.node0.intersectSphere(from, radius, out, count);
				}
				if (this.node1) {
					count = this.node1.intersectSphere(from, radius, out, count);
				}
			}
			return (count);
		}
	
	}
}

