package zen.display
{
    
	import zen.display.*;
    import flash.geom.Vector3D;
    import zen.utils.*;
	import zen.geom.*;
    import flash.geom.*;
    

    public class ZenSpline extends ZenObject 
    {

        public var splines:Vector.<Spline3D>;
        public var color:uint = 0xFFFFFF;
        private var _bounds:Cube3D;

        public function ZenSpline(name:String="")
        {
            this.splines = new Vector.<Spline3D>();
            super(name);
        }

		
        override public function toString():String
        {
            return ("[object ZenSpline]");
        }
		

        override public function clone():ZenObject
        {
            var c:ZenObject;
            var n:ZenSpline = new ZenSpline(name);
            n.copyFrom(this);
            n.color = this.color;
            n.splines = this.splines.concat();
            for each (c in children) {
                n.addChild(c.clone());
            }
            return (n);
        }

        public function getPoint(value:Number, global:Boolean=true, out:Vector3D=null):Vector3D
        {
            out = ((out) || (new Vector3D()));
            var index:int = (value * this.splines.length);
            var delta:Number = (1 / this.splines.length);
            var offset:Number = (value - (index * delta));
            this.splines[index].getPoint((offset / delta), out);
            if (global){
                localToGlobal(out, out);
            }
            return (out);
        }

        public function getTangent(value:Number, global:Boolean=true, out:Vector3D=null):Vector3D
        {
            out = ((out) || (new Vector3D()));
            var index:int = (value * this.splines.length);
            var delta:Number = (1 / this.splines.length);
            var offset:Number = (value - (index * delta));
            this.splines[index].getTangent((offset / delta), out);
            if (global){
                localToGlobalVector(out, out);
            }
            return (out);
        }

        public function updateBoundings():void
        {
            this._bounds = null;
            this._bounds = this.bounds;
        }

        public function get bounds():Cube3D
        {
            var s:Spline3D;
            var dx:Number;
            var dy:Number;
            var dz:Number;
            var temp:Number;
            var len:int;
            var i:int;
            if (this._bounds){
                return (this._bounds);
            }
            this._bounds = new Cube3D();
            this.bounds.min.setTo(10000000, 10000000, 10000000);
            this.bounds.max.setTo(-10000000, -10000000, -10000000);
            var v:Vector3D = new Vector3D();
            for each (s in this.splines) {
                len = s.knots.length;
                i = 0;
                while (i < 40) {
                    if (len < 2){
                        if (len == 1){
                            v.copyFrom(s.knots[0]);
                        } else {
                            v.setTo(0, 0, 0);
                        }
                        i = 40;
                    } else {
                        v = s.getPoint((i / 40), v);
                    }
                    if (v.x < this._bounds.min.x){
                        this._bounds.min.x = v.x;
                    }
                    if (v.y < this._bounds.min.y){
                        this._bounds.min.y = v.y;
                    }
                    if (v.z < this._bounds.min.z){
                        this._bounds.min.z = v.z;
                    }
                    if (v.x > this._bounds.max.x){
                        this._bounds.max.x = v.x;
                    }
                    if (v.y > this._bounds.max.y){
                        this._bounds.max.y = v.y;
                    }
                    if (v.z > this._bounds.max.z){
                        this._bounds.max.z = v.z;
                    }
                    i++;
                }
            }
            this._bounds.length.x = (this._bounds.max.x - this._bounds.min.x);
            this._bounds.length.y = (this._bounds.max.y - this._bounds.min.y);
            this._bounds.length.z = (this._bounds.max.z - this._bounds.min.z);
            this._bounds.center.x = ((this._bounds.length.x * 0.5) + this._bounds.min.x);
            this._bounds.center.y = ((this._bounds.length.y * 0.5) + this._bounds.min.y);
            this._bounds.center.z = ((this._bounds.length.z * 0.5) + this._bounds.min.z);
            for each (s in this.splines) {
                for each (v in s.knots) {
                    dx = (this._bounds.center.x - v.x);
                    dy = (this._bounds.center.y - v.y);
                    dz = (this._bounds.center.z - v.z);
                    temp = (((dx * dx) + (dy * dy)) + (dz * dz));
                    if (temp > this._bounds.radius){
                        this._bounds.radius = temp;
                    }
                }
            }
            this._bounds.radius = Math.sqrt(this._bounds.radius);
            return (this._bounds);
        }

        public function set bounds(value:Cube3D):void
        {
            this._bounds = value;
        }


    }
}

