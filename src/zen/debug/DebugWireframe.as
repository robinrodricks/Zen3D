package zen.debug
{
	import zen.enums.*;
    import zen.display.*;
    import zen.animation.*;
    import zen.utils.*;
	import zen.geom.*;
    import zen.display.*;

    public class DebugWireframe extends ZenCanvas 
    {

        private var _mesh:ZenMesh;
        private var _color:uint;
        private var _alpha:Number;
        private var _lastSkinFrame:Number;
        private var _hasSkin:Boolean;

        public function DebugWireframe(mesh:ZenMesh=null, color:uint=0xFFFFFF, alpha:Number=1)
        {
            super(("debug_" + mesh.name));
            this._alpha = alpha;
            this._mesh = mesh;
            this._color = color;
            this.config();
        }

        public function config():void
        {
            var i:int;
            var surf:ZenFace;
            var start:int;
            var len:int;
            var p:Poly3D;
            var pos:int;
            var vertex:Vector.<Number>;
            var index:Vector.<uint>;
            var length:int;
            var size:int;
            var v0:int;
            var v1:int;
            var v2:int;
            download();
            clear();
            lineStyle(1, this._color, this._alpha);
            bounds = this._mesh.bounds;
            if ((this._mesh.modifier is ZenSkinModifier)){
                this._hasSkin = true;
                this._lastSkinFrame = this._mesh.currentFrame;
                for each (surf in this._mesh.surfaces) {
                    start = (surf.firstIndex / 3);
                    len = surf.numTriangles;
                    if (len == -1){
                        len = (surf.indexVector.length / 3);
                    }
                    len = (len + start);
                    i = start;
                    while (i < len) {
                        p = surf.polys[i];
                        super.moveTo(p.v0.x, p.v0.y, p.v0.z);
                        super.lineTo(p.v1.x, p.v1.y, p.v1.z);
                        super.lineTo(p.v2.x, p.v2.y, p.v2.z);
                        super.lineTo(p.v0.x, p.v0.y, p.v0.z);
                        i++;
                    }
                }
            } else {
                for each (surf in this._mesh.surfaces) {
                    pos = surf.offset[VertexType.POSITION];
                    if (pos < 0){
                        return;
                    }
                    vertex = surf.vertexVector;
                    index = surf.indexVector;
                    length = index.length;
                    size = surf.sizePerVertex;
                    i = 0;
                    while (i < length) {
                        v0 = (index[i++] * size);
                        v1 = (index[i++] * size);
                        v2 = (index[i++] * size);
                        moveTo(vertex[v0], vertex[(v0 + 1)], vertex[(v0 + 2)]);
                        lineTo(vertex[v1], vertex[(v1 + 1)], vertex[(v1 + 2)]);
                        lineTo(vertex[v2], vertex[(v2 + 1)], vertex[(v2 + 2)]);
                        lineTo(vertex[v0], vertex[(v0 + 1)], vertex[(v0 + 2)]);
                    }
                }
            }
        }

        public function get color():uint
        {
            return (this._color);
        }

        public function get mesh():ZenMesh
        {
            return (this._mesh);
        }


    }
}

