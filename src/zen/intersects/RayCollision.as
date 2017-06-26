package zen.intersects
{
    import flash.geom.Vector3D;
    import flash.geom.Matrix3D;
    
    import flash.utils.Dictionary;
    import flash.utils.getTimer;

	import zen.display.*;
    import flash.events.Event;
    import flash.geom.*;
    import zen.display.*;
    import zen.utils.*;
    import zen.geom.*;
	import zen.display.*;
	import zen.display.*;
    import flash.events.*;
    import flash.utils.*;
    

    public class RayCollision 
    {

        private static var _collisionDistance:Number;
        private static var _collisionSurface:ZenFace;
        private static var _collisionMesh:ZenMesh;
        private static var _collisionPoly:Poly3D;
        private static var _polyIntersectionNormal:Vector3D = new Vector3D();
        private static var _polyIntersectionPoint:Vector3D = new Vector3D();
        private static var _global:Matrix3D = new Matrix3D();
        private static var _inv:Matrix3D = new Matrix3D();
        private static var _pos:Vector3D = new Vector3D();
        private static var _dir:Vector3D = new Vector3D();
        private static var _q:Vector3D = new Vector3D();
        private static var _f:Vector3D = new Vector3D();
        private static var _d:Vector3D = new Vector3D();
        private static var _pIPoint:Vector3D = new Vector3D();
        private static var _dist0:Number;

        public var data:Vector.<CollisionInfo>;
        private var _collided:Boolean;
        private var _collisionTime:int;
        private var _pull:Vector.<CollisionInfo>;
        private var _list:Vector.<ZenMesh>;
        private var _meshList:Dictionary;
        var ignoreMouseDissabled:Boolean = false;

        public function RayCollision()
        {
            this.data = new Vector.<CollisionInfo>();
            this._pull = new Vector.<CollisionInfo>();
            this._list = new Vector.<ZenMesh>();
            this._meshList = new Dictionary(true);
            super();
        }

        public function dispose():void
        {
            _collisionSurface = null;
            _collisionMesh = null;
            _collisionPoly = null;
            this._pull = null;
            this._list = null;
            this._meshList = null;
        }

        public function test(from:Vector3D, direction:Vector3D, getAllPolysUnderPoint:Boolean=false, ignoreInvisible:Boolean=true, ignoreBackFace:Boolean=true):Boolean
        {
            var t:int = getTimer();
            while (this.data.length) {
                this._pull.push(this.data.pop());
            }
            this.update(from, direction, getAllPolysUnderPoint, ignoreInvisible, ignoreBackFace);
            if (((!(getAllPolysUnderPoint)) && (this._collided))){
                this.data.push(this.addInfo(_collisionMesh, _collisionSurface, _collisionPoly, _polyIntersectionPoint, _polyIntersectionNormal));
            }
            this._collisionTime = (getTimer() - t);
            return (this._collided);
        }

        private function update(pos:Vector3D, dir:Vector3D, array:Boolean=false, ignoreInvisible:Boolean=false, backFace:Boolean=false):void
        {
            var mesh:ZenMesh;
            var p:Poly3D;
            var surf:ZenFace;
            var center:Vector3D;
            var radius:Number;
            var _B:Number;
            var _C:Number;
            var polys:Vector.<Poly3D>;
            var start:int;
            var length:int;
            var pn:int;
            this._collided = false;
            _collisionDistance = Number.MAX_VALUE;
            var collisionGlobalDistance:Number = Number.MAX_VALUE;
            var globalDistance:Number = Number.MAX_VALUE;
            var intersectionPoint:Vector3D = new Vector3D();
            for each (mesh in this._list) {
                if (((ignoreInvisible) && (!(mesh.visible)))){
                } else {
                    if (((this.ignoreMouseDissabled) && (!(mesh.mouseEnabled)))){
                    } else {
                        _global.copyFrom(mesh.world);
                        M3D.invert(_global, _inv);
                        M3D.transformVector(_inv, pos, _f);
                        M3D.deltaTransformVector(_inv, dir, _d);
                        _d.normalize();
                        if (mesh.bounds){
                            center = mesh.bounds.center;
                            radius = mesh.bounds.radius;
                            _q.x = (_f.x - center.x);
                            _q.y = (_f.y - center.y);
                            _q.z = (_f.z - center.z);
                            _B = _q.dotProduct(_d);
                            _C = (_q.dotProduct(_q) - (radius * radius));
                            if (((_B * _B) - _C) < 0){
                                //unresolved jump
                            }
                        }
                        for each (surf in mesh.surfaces) {
                            if (!(surf.polys)){
                                surf.buildPolys();
                            }
                            polys = surf.polys;
                            if ((((((backFace == true)) && (surf.material))) && ((surf.material.twoSided == true)))){
                                backFace = false;
                            }
                            start = (surf.firstIndex / 3);
                            length = surf.numTriangles;
                            if (length == -1){
                                length = surf.polys.length;
                            }
                            length = (length + start);
                            pn = start;
                            while (pn < length) {
                                p = polys[pn];
                                if (((backFace) && ((((((p.normal.x * _f.x) + (p.normal.y * _f.y)) + (p.normal.z * _f.z)) + p.plane) < 0)))){
                                } else {
                                    _dist0 = (-(((((p.normal.x * _f.x) + (p.normal.y * _f.y)) + (p.normal.z * _f.z)) + p.plane)) / (((p.normal.x * _d.x) + (p.normal.y * _d.y)) + (p.normal.z * _d.z)));
                                    if (_dist0 > 0){
                                        _pIPoint.x = (_f.x + (_d.x * _dist0));
                                        _pIPoint.y = (_f.y + (_d.y * _dist0));
                                        _pIPoint.z = (_f.z + (_d.z * _dist0));
                                        if (p.isPoint(_pIPoint.x, _pIPoint.y, _pIPoint.z)){
                                            M3D.transformVector(_global, _pIPoint, intersectionPoint);
                                            globalDistance = Vector3D.distance(pos, intersectionPoint);
                                            _collisionDistance = _dist0;
                                            this._collided = true;
                                            if ((((globalDistance < collisionGlobalDistance)) || (array))){
                                                _collisionPoly = p;
                                                _collisionSurface = surf;
                                                _collisionMesh = mesh;
                                                M3D.deltaTransformVector(_global, p.normal, _polyIntersectionNormal);
                                                _polyIntersectionPoint.copyFrom(intersectionPoint);
                                                if (array){
                                                    if (globalDistance < collisionGlobalDistance){
                                                        collisionGlobalDistance = globalDistance;
                                                        this.data.unshift(this.addInfo(mesh, surf, p, _polyIntersectionPoint, _polyIntersectionNormal));
                                                    } else {
                                                        this.data.push(this.addInfo(mesh, surf, p, _polyIntersectionPoint, _polyIntersectionNormal));
                                                    }
                                                } else {
                                                    collisionGlobalDistance = globalDistance;
                                                }
                                            }
                                        }
                                    }
                                }
                                pn++;
                            }
                        }
                    }
                }
            }
        }

        private function addInfo(mesh:ZenMesh, surface:ZenFace, poly:Poly3D, point:Vector3D, normal:Vector3D):CollisionInfo
        {
            var i:CollisionInfo = ((this._pull.length) ? this._pull.pop() : new CollisionInfo());
            i.mesh = mesh;
            i.surface = surface;
            i.poly = poly;
            i.point.copyFrom(point);
            i.normal.copyFrom(normal);
            i.u = poly.getPointU();
            i.v = poly.getPointV();
            return (i);
        }

        public function addCollisionWith(pivot:ZenObject, includeChildren:Boolean=true):void
        {
            var mesh:ZenMesh;
            var c:ZenObject;
            if (this._meshList[pivot] == undefined){
                mesh = (pivot as ZenMesh);
                if (mesh){
                    mesh.addEventListener(ZenObject.UNLOAD_EVENT, this.unloadEvent, false, 0, true);
                    mesh.addEventListener(ZenObject.REMOVED_FROM_SCENE_EVENT, this.unloadEvent, false, 0, true);
                    this._meshList[mesh] = (this._list.push(mesh) - 1);
                }
            }
            if (includeChildren){
                for each (c in pivot.children) {
                    this.addCollisionWith(c, includeChildren);
                }
            }
        }

        private function unloadEvent(e:Event):void
        {
            while (this.data.length) {
                this._pull.push(this.data.pop());
            }
            this.removeCollisionWith((e.target as ZenObject), false);
        }

        public function removeCollisionWith(pivot:ZenObject, includeChildren:Boolean=true):void
        {
            var mesh:ZenMesh;
            var index:uint;
            var c:ZenObject;
            if (this._meshList[pivot] >= 0){
                if ((pivot is ZenMesh)){
                    mesh = (pivot as ZenMesh);
                    index = this._list.indexOf(mesh);
                    delete this._meshList[mesh];
                    this._list.splice(index, 1);
                }
            }
            if (includeChildren){
                for each (c in pivot.children) {
                    this.removeCollisionWith(c, includeChildren);
                }
            }
        }

        public function get collisionTime():int
        {
            return (this._collisionTime);
        }

        public function get collisionCount():int
        {
            return (this._list.length);
        }

        public function get collided():Boolean
        {
            return (this._collided);
        }


    }
}

