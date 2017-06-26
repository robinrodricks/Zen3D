package zen.intersects
{
    import flash.geom.Vector3D;
    import flash.geom.Matrix3D;
	import zen.input.ZenUtils;
    
    import flash.geom.Rectangle;
    import flash.geom.*;
    import zen.display.*;
    import zen.utils.*;
    import flash.utils.*;
	import zen.display.*;
	import zen.display.*;
    

    public class MouseCollision 
    {

        private static var _pos:Vector3D = new Vector3D();
        private static var _dir:Vector3D = new Vector3D();
        private static var _inv:Matrix3D = new Matrix3D();
        private static var _raw:Vector.<Number> = new Vector.<Number>(16, true);

        public var data:Vector.<CollisionInfo>;
        private var _ray:RayCollision;
        private var _cam:ZenCamera;

        public function MouseCollision(camera:ZenCamera=null)
        {
            this.data = new Vector.<CollisionInfo>();
            super();
            this._cam = camera;
            this._ray = new RayCollision();
        }

        public function dispose():void
        {
            this.data = null;
            this._cam = null;
            this._ray.dispose();
            this._ray = null;
        }

        public function test(x:Number, y:Number, getAllPolysUnderPoint:Boolean=false, ignoreInvisible:Boolean=true, ignoreBackFace:Boolean=true):Boolean
        {
            if (!(this.getCameraDir(x, y))){
                return (false);
            }
            this._ray.ignoreMouseDissabled = true;
            this._ray.test(_pos, _dir, getAllPolysUnderPoint, ignoreInvisible, ignoreBackFace);
            this.data = this._ray.data;
            return (this._ray.collided);
        }

        private function getCameraDir(x:Number, y:Number):Boolean
        {
            var camera:ZenCamera = ((this._cam) ? this._cam : ZenUtils.camera);
            var viewport:Rectangle = ZenUtils.scene.viewPort;
            if (((!(camera)) || (!(viewport)))){
                return (false);
            }
            camera.getPointDir(x, y, _dir, _pos);
            return (true);
        }

        public function addCollisionWith(pivot:ZenObject, includeChildren:Boolean=true):void
        {
            this._ray.addCollisionWith(pivot, includeChildren);
        }

        public function removeCollisionWith(pivot:ZenObject, includeChildren:Boolean=true):void
        {
            this._ray.removeCollisionWith(pivot, includeChildren);
        }

        public function get camera():ZenCamera
        {
            return (this._cam);
        }

        public function set camera(value:ZenCamera):void
        {
            this._cam = value;
        }

        public function get collisionTime():int
        {
            return (this._ray.collisionTime);
        }

        public function get collisionCount():int
        {
            return (this._ray.collisionCount);
        }

        public function get collided():Boolean
        {
            return (this._ray.collided);
        }

        public function get ray():RayCollision
        {
            return (this._ray);
        }


    }
}

