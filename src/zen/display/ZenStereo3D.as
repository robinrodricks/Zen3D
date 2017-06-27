package zen.display {
	import flash.display.*;
	import flash.geom.*;
	import zen.display.*;
	import zen.display.*;
	import flash.display.*;
	import flash.display3D.*;
	import flash.events.*;
	import flash.geom.*;
	import zen.materials.*;
	
	/** An extension to the Zen3D class that renders two views of the same scene for stereo rendering.
	 */
	public class ZenStereo3D extends Zen3D {
		private var _transform:Matrix3D = new Matrix3D();
		private var _depthReference:Vector3D = new Vector3D();
		
		// The distance between the eyes.
		public var eyeDistance:Number = 5;
		
		// The distance of the reference point. This is the point where the eyes intersect.
		public var depthDistance:Number = 1000;
		
		public function ZenStereo3D(container:Sprite) {
			super(container);
		}
		
		override public function render(camera:ZenCamera = null, clearDepth:Boolean = false, target:ZenTexture = null):void {
			if (!camera) camera = scene.camera;
			
			// store the source camera position and rotation.
			_transform.copyFrom(camera.world);
			
			// the cameras should not be parallel, so we create a point of reference
			// where the cameras will look. that's the point where the two cameras intersect each other.
			// taking the depth distance, transforms from local camera to global point.
			_depthReference.setTo(0, 0, depthDistance);
			
			camera.localToGlobal(_depthReference, _depthReference);
			
			// translates the camera and orientates the first camera.
			camera.translateX(-eyeDistance);
			camera.lookAt(_depthReference.x, _depthReference.y, _depthReference.z, camera.getUp(false));
			
			// the first render.
			super.context.clear();
			super.context.setColorMask(true, false, false, false);
			super.render(camera);
			
			// transform the second camera.
			camera.world.copyFrom(_transform);
			camera.translateX(eyeDistance);
			camera.lookAt(_depthReference.x, _depthReference.y, _depthReference.z, camera.getUp(false));
			
			//the second render.
			super.context.setColorMask(false, true, true, false);
			super.render(camera, true);
			
			// restore the original camera transform.
			camera.world.copyFrom(_transform);
		}
	}
}