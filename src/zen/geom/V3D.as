package zen.geom {
	import flash.geom.Vector3D;
	
	/** Primitive geometric calculations for 3D vectors and points */
	public class V3D {
		
		public static var UP:Vector3D = new Vector3D(0, 1, 0);
		public static var DOWN:Vector3D = new Vector3D(0, -1, 0);
		public static var RIGHT:Vector3D = new Vector3D(1, 0, 0);
		public static var LEFT:Vector3D = new Vector3D(-1, 0, 0);
		public static var FORWARD:Vector3D = new Vector3D(0, 0, 1);
		public static var BACK:Vector3D = new Vector3D(0, 0, -1);
		public static var ZERO:Vector3D = new Vector3D(0, 0, 0);
		public static var ONE:Vector3D = new Vector3D(1, 1, 1);
		
		public static function lengthSquared(a:Vector3D, b:Vector3D):Number {
			var dx:Number = (a.x - b.x);
			var dy:Number = (a.y - b.y);
			var dz:Number = (a.z - b.z);
			return ((((dx * dx) + (dy * dy)) + (dz * dz)));
		}
		
		public static function reset(a:Vector3D, value:Number = 0):Vector3D {
			a.x = value;
			a.y = value;
			a.z = value;
			return a;
		}
		
		public static function clear(a:Vector3D, value:Number = 0):Vector3D {
			a.x = value;
			a.y = value;
			a.z = value;
			return a;
		}
		
		/** returns the distance between 2 points */
		public static function length(a:Vector3D, b:Vector3D):Number {
			var dx:Number = (a.x - b.x);
			var dy:Number = (a.y - b.y);
			var dz:Number = (a.z - b.z);
			return (Math.sqrt((((dx * dx) + (dy * dy)) + (dz * dz))));
		}
		
		/** sets the length of the direction vector, preserving its angle */
		public static function setLength(a:Vector3D, length:Number):void {
			var l:Number = a.length;
			if (l > 0) {
				l = (l / length);
				a.x = (a.x / l);
				a.y = (a.y / l);
				a.z = (a.z / l);
			} else {
				a.x = (a.y = (a.z = 0));
			}
		}
		
		public static function sub(a:Vector3D, b:Vector3D, out:Vector3D = null):Vector3D {
			if (!out) {
				out = new Vector3D();
			}
			out.x = (a.x - b.x);
			out.y = (a.y - b.y);
			out.z = (a.z - b.z);
			return (out);
		}
		
		public static function add(a:Vector3D, b:Vector3D, out:Vector3D = null):Vector3D {
			if (!out) {
				out = new Vector3D();
			}
			out.x = (a.x + b.x);
			out.y = (a.y + b.y);
			out.z = (a.z + b.z);
			return (out);
		}
		
		public static function multiply(a:Vector3D, b:Vector3D, out:Vector3D = null):Vector3D {
			if (!out) {
				out = new Vector3D();
			}
			out.x = (a.x * b.x);
			out.y = (a.y * b.y);
			out.z = (a.z * b.z);
			return (out);
		}
		
		public static function multiplyNum(a:Vector3D, num:Number, out:Vector3D = null):Vector3D {
			if (!out) {
				out = new Vector3D();
			}
			out.x = (a.x * num);
			out.y = (a.y * num);
			out.z = (a.z * num);
			return (out);
		}
		
		public static function divide(a:Vector3D, b:Vector3D, out:Vector3D = null):Vector3D {
			if (!out) {
				out = new Vector3D();
			}
			out.x = (a.x / b.x);
			out.y = (a.y / b.y);
			out.z = (a.z / b.z);
			return (out);
		}
		
		public static function divideNum(a:Vector3D, num:Number, out:Vector3D = null):Vector3D {
			if (!out) {
				out = new Vector3D();
			}
			out.x = (a.x / num);
			out.y = (a.y / num);
			out.z = (a.z / num);
			return (out);
		}
		
		public static function setValue(write:Vector3D, x:Number = 0, y:Number = 0, z:Number = 0, w:Number = 0):void {
			write.x = x;
			write.y = y;
			write.z = z;
			write.w = w;
		}
		
		public static function setTo(write:Vector3D, read:Vector3D):void {
			
			if (write == read) {
				return;
			}
			
			write.x = read.x;
			write.y = read.y;
			write.z = read.z;
			write.w = read.w;
		}
		
		public static function negate(a:Vector3D, out:Vector3D = null):Vector3D {
			if (!out) {
				out = new Vector3D();
			}
			out.x = -(a.x);
			out.y = -(a.y);
			out.z = -(a.z);
			return (out);
		}
		
		public static function interpolate(a:Vector3D, b:Vector3D, value:Number, out:Vector3D = null):Vector3D {
			if (!out) {
				out = new Vector3D();
			}
			out.x = (a.x + ((b.x - a.x) * value));
			out.y = (a.y + ((b.y - a.y) * value));
			out.z = (a.z + ((b.z - a.z) * value));
			return (out);
		}
		
		public static function random(min:Number, max:Number, out:Vector3D = null):Vector3D {
			if (!out) {
				out = new Vector3D();
			}
			out.x = ((Math.random() * (max - min)) + min);
			out.y = ((Math.random() * (max - min)) + min);
			out.z = ((Math.random() * (max - min)) + min);
			return (out);
		}
		
		public static function mirror(vector:Vector3D, normal:Vector3D, out:Vector3D = null):Vector3D {
			if (!out) {
				out = new Vector3D();
			}
			var dot:Number = vector.dotProduct(normal);
			out.x = (vector.x - ((2 * normal.x) * dot));
			out.y = (vector.y - ((2 * normal.y) * dot));
			out.z = (vector.z - ((2 * normal.z) * dot));
			return (out);
		}
		
		public static function min(a:Vector3D, b:Vector3D, out:Vector3D = null):Vector3D {
			if (!out) {
				out = new Vector3D();
			}
			out.x = (((a.x < b.x)) ? a.x : b.x);
			out.y = (((a.y < b.y)) ? a.y : b.y);
			out.z = (((a.z < b.z)) ? a.z : b.z);
			return (out);
		}
		
		public static function max(a:Vector3D, b:Vector3D, out:Vector3D = null):Vector3D {
			if (!out) {
				out = new Vector3D();
			}
			out.x = (((a.x > b.x)) ? a.x : b.x);
			out.y = (((a.y > b.y)) ? a.y : b.y);
			out.z = (((a.z > b.z)) ? a.z : b.z);
			return (out);
		}
		
		public static function abs(a:Vector3D):void {
			if (a.x < 0) {
				a.x = -(a.x);
			}
			if (a.y < 0) {
				a.y = -(a.y);
			}
			if (a.z < 0) {
				a.z = -(a.z);
			}
		}
		
		public static function normalize(a:Vector3D, out:Vector3D = null):Vector3D {
			if (!out) {
				out = new Vector3D();
			}
			var len:Number = a.length;
			if (len == 0) {
				out.x = 0;
				out.y = 0;
				out.z = 0;
				return out;
			}
			out.x = (a.x / len);
			out.y = (a.y / len);
			out.z = (a.z / len);
			return out;
		}
		
		public static function cross(a:Vector3D, b:Vector3D, out:Vector3D = null):Vector3D {
			if (!out) {
				out = new Vector3D();
			}
			out.x = ((a.y * b.z) - (a.z * b.y));
			out.y = ((a.z * b.x) - (a.x * b.z));
			out.z = ((a.x * b.y) - (a.y * b.x));
			return (out);
		}
		
		public static function dot(a:Vector3D, w:Vector3D):Number {
			return (a.x * w.x + a.y * w.y + a.z * w.z);
		}
		
		public static function invert(a:Vector3D, out:Vector3D = null):Vector3D {
			if (!out) {
				out = new Vector3D();
			}
			out.x = -a.x;
			out.y = -a.y;
			out.z = -a.z;
			return out;
		}
		
		public static function pow(a:Vector3D, pow:Number, out:Vector3D = null):Vector3D {
			if (!out) {
				out = new Vector3D();
			}
			out.x = Math.pow(a.x, pow);
			out.y = Math.pow(a.y, pow);
			out.z = Math.pow(a.z, pow);
			return out;
		}
		
		public static function round(a:Vector3D, out:Vector3D = null):Vector3D {
			if (!out) {
				out = new Vector3D();
			}
			out.x = Math.round(a.x);
			out.y = Math.round(a.y);
			out.z = Math.round(a.z);
			return out;
		}
		
		public static function roundTo(a:Vector3D, decimals:int, out:Vector3D = null):Vector3D {
			if (!out) {
				out = new Vector3D();
			}
			
			// Returns a new point rounded to specified number of decimals
			var multiplier:Number = Math.pow(10, decimals);
			out.x = Math.round(a.x * multiplier) / multiplier;
			out.y = Math.round(a.y * multiplier) / multiplier;
			out.z = Math.round(a.z * multiplier) / multiplier;
			return out;
		}
		
		public static function modulo(a:Vector3D):Number {
			return Math.sqrt(a.x * a.x + a.y * a.y + a.z * a.z);
		}
		
		public static function moduloSq(a:Vector3D):Number {
			return a.x * a.x + a.y * a.y + a.z * a.z;
		}
		
		/** return the direction vector for the given std view. DO NOT MODIFY THE RESULT! */
		public static function standardView(view:int):Vector3D {
			return stdViewVector[view];
		}
		private static var stdViewVector:Array = [FORWARD, BACK, UP, DOWN, LEFT, RIGHT];
		
		/** return the point between `a` and `center` (if length is 0, center is returned) */
		public static function pointBetween(a:Vector3D, center:Vector3D, length:Number, out:Vector3D = null):Vector3D {
			return setLengthBetween(a, center, length, out);
		}
		
		/** return the point between `a` and `center` (if length is 0, center is returned) */
		public static function setLengthBetween(a:Vector3D, center:Vector3D, length:Number, out:Vector3D = null):Vector3D {
			if (!out) {
				out = new Vector3D();
			}
			var oldLen:Number = V3D.length(a, center);
			if (oldLen > 0) {
				out.x = center.x + (((a.x - center.x) / oldLen) * length);
				out.y = center.y + (((a.y - center.y) / oldLen) * length);
				out.z = center.z + (((a.z - center.z) / oldLen) * length);
			} else {
				out.x = center.x + length;
				out.y = center.y;
				out.z = center.z;
			}
			return out;
		}
	
	}
}

