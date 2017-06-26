package zen.display
{
	import zen.materials.*;
	import zen.display.*;
	import zen.display.*;
	import zen.shaders.textures.*;
	import zen.utils.*;
	import flash.display.*;
	import flash.display3D.*;
	import flash.geom.*;
	
	public class ZenReflector
	{
		private var _camera:ZenCamera;
		private var _camProj:Matrix3D;
		private var _camPlane:Vector3D;
		private var _planeVec:Vector3D;
		private var _matrix:Matrix3D;
		private var _vector:Vector3D;
		private var _raw:Vector.<Number>;
		private var _out:Vector3D;
		private var _inv:Matrix3D;
		
		public var accuracy:Number;
		
		public function ZenReflector()
		{
			_camera = new ZenCamera();
			_matrix = new Matrix3D();
			_vector = new Vector3D();
			_planeVec = new Vector3D();
			_camProj = new Matrix3D();
			_raw = new Vector.<Number>( 16, true );
			_out = new Vector3D();
			_inv = new Matrix3D();
		}
		
		public function update( worldMatrix:Matrix3D ):void
		{
			_matrix.copyFrom( worldMatrix );
			_matrix.invert();
			_matrix.copyRowTo( 1, _vector );
			_planeVec.x = -_vector.x;
			_planeVec.y = -_vector.y;
			_planeVec.z = -_vector.z;
			_planeVec.w = -_vector.w + 0.1;
		}
		
		public function setupCamera( camera:ZenCamera ):void
		{
			updateCamera( camera );
			ZenUtils.view.copyFrom( _camera.view );
			ZenUtils.viewProj.copyFrom( ZenUtils.view );
			ZenUtils.viewProj.append( _camProj );
		}
		
		private function updateCamera( camera:ZenCamera ):void
		{
			reflection( _planeVec, _matrix );
			_matrix.prepend( camera.world );
			_camera.transform = _matrix;
			_camera.updateTransforms( true );
			_camPlane = transformPlane( _planeVec, _matrix );
			_camera.fieldOfView = camera.fieldOfView;
			_camera.viewPort = camera.viewPort;
			updateProj();
		}
		
		private function updateProj():void
		{
			_camProj.copyFrom( _camera.projection );
			
			var x:Number = _camPlane.x;
			var y:Number = _camPlane.y;
			var z:Number = _camPlane.z;
			var w:Number = -_camPlane.w;
			var cornerX:Number = x >= 0 ? 1 : -1;
			var cornerY:Number = y >= 0 ? 1 : -1;
			
			_out.x = cornerX;
			_out.y = cornerY;
			_out.z = 1;
			_out.w = 1;
			
			var newMatrix:Matrix3D = _matrix.clone();
			newMatrix.invert();
			
			var projCorner:Vector3D = newMatrix.transformVector( _out );
			_camProj.copyRowTo( 3, _out );
			
			var sumCorner:Number = ( projCorner.x * _out.x + projCorner.y * _out.y + projCorner.z * _out.z + projCorner.w * _out.w ) / ( x * projCorner.x + y * projCorner.y + z * projCorner.z + w * projCorner.w );
			sumCorner *= accuracy;
			sumCorner = sumCorner > 0 ? -sumCorner : sumCorner;
			
			_out.x = x * sumCorner;
			_out.y = y * sumCorner;
			_out.z = z * sumCorner;
			_out.w = w * sumCorner;
			
			_camProj.copyRowFrom( 2, _out );
		}
		
		private function transformPlane( vec:Vector3D, transform:Matrix3D ):Vector3D
		{
			var x:Number = vec.x;
			var y:Number = vec.y;
			var z:Number = vec.z;
			var w:Number = vec.w;
			
			transform.copyRawDataTo( _raw );
			_out.x = x * _raw[ 0 ] + y * _raw[ 1 ] + z * _raw[ 2 ] + w * _raw[ 3 ]; 
			_out.y = x * _raw[ 4 ] + y * _raw[ 5 ] + z * _raw[ 6 ] + w * _raw[ 7 ];
			_out.z = x * _raw[ 8 ] + y * _raw[ 9 ] + z * _raw[ 10 ] + w * _raw[ 11 ];
			_out.w = -( x * _raw[ 12 ] + y * _raw[ 13 ] + z * _raw[ 14 ] + w * _raw[ 15 ] );
			_out.normalize();
			
			return _out;
		}
		
		public function isBehind( camera:ZenCamera ):Boolean
		{
			const worldPos:Vector3D = camera.world.position;
			
			return worldPos.x * _planeVec.x + worldPos.y * _planeVec.y + worldPos.z * _planeVec.z + _planeVec.w >= 0;
		}
		
		private function reflection( reflectVec:Vector3D, out:Matrix3D = null ):Matrix3D
		{
			out ||= new Matrix3D();
			var right:Number = reflectVec.x;
			var up:Number = reflectVec.y;
			var dir:Number = reflectVec.z;
			var pos:Number = reflectVec.w;
			var refR:Number = -2 * up * right;
			var refD:Number = -2 * right * dir;
			var refU:Number = -2 * dir * up;
			
			_raw[ 0 ] = 1 - ( 2 * right * right );
			_raw[ 5 ] = 1 - ( 2 * up * up );
			_raw[ 10 ] = 1 - ( 2 * dir * dir );
			
			_raw[ 1 ] = _raw[ 4 ] = refR;
			_raw[ 2 ] = _raw[ 8 ] = refD;
			_raw[ 6 ] = _raw[ 9 ] = refU;
			
			_raw[ 12 ] = -2 * right * pos;
			_raw[ 13 ] = ( -2 * up ) * pos;
			_raw[ 14 ] = -2 * dir * pos;
			
			_raw[ 3 ] = _raw[ 7 ] = _raw[ 15 ] = 0;
			_raw[ 15 ] = 1;
			
			out.copyRawDataFrom( _raw );
			
			return ( out );
		}
	}
}