package zen.debug
{
    import zen.materials.*;
	import zen.enums.*;
    import zen.shaders.textures.*;
    import zen.display.*;
    import zen.display.*;

    public class DebugLight extends ZenObject implements IDrawable 
    {

        private var _lPoint:ZenCanvas;
        private var _lPointInfinite:ZenCanvas;
        private var _lDir:ZenCanvas;
        private var _light:ZenLight;
        private var _type:int = -1;
        private var _infinite:Boolean;
        private var color:int;
        private var alpha:Number;

        public function DebugLight(light:ZenLight, color:int=0xFFCB00, alpha:Number=1)
        {
            this._lPoint = new ZenCanvas();
            this._lPointInfinite = new ZenCanvas();
            this._lDir = new ZenCanvas();
            super(("debug_" + ((light) ? light.name : "light")));
            this.alpha = alpha;
            this.color = color;
            this.light = light;
            this.drawDir();
            this.drawPointInfinite();
            this.drawRadius();
        }

        private function drawDir():void
        {
            this._lDir.lineStyle(1, this.color, this.alpha);
            var s:Number = 20;
            var s2:Number = 8;
            var d:Number = 20;
            var d2:Number = 30;
            this._lDir.moveTo(-(s), -(s), 0);
            this._lDir.lineTo(-(s), s, 0);
            this._lDir.lineTo(s, s, 0);
            this._lDir.lineTo(s, -(s), 0);
            this._lDir.lineTo(-(s), -(s), 0);
            this._lDir.moveTo(0, 0, 0);
            this._lDir.lineTo(0, 0, d);
            this._lDir.moveTo(-(s2), 0, d);
            this._lDir.lineTo(s2, 0, d);
            this._lDir.lineTo(0, 0, d2);
            this._lDir.lineTo(-(s2), 0, d);
        }

        private function drawPointInfinite():void
        {
            var x:Number;
            var y:Number;
            var z:Number;
            var u:Number = 0;
            var v:Number = 0;
            var s:Number = ((Math.PI * 2) / 6);
            var s0:Number = (30 * 0.7);
            var s1:Number = 30;
            this._lPointInfinite.lineStyle(1, this.color, this.alpha);
            v = s;
            while (v <= ((Math.PI * 2) + s)) {
                u = s;
                while (u <= ((Math.PI * 2) + s)) {
                    y = -(Math.cos(v));
                    x = (Math.cos((u * 1)) * Math.sin(v));
                    z = (-(Math.sin((u * 1))) * Math.sin(v));
                    this._lPointInfinite.moveTo((x * s0), (y * s0), (z * s0));
                    this._lPointInfinite.lineTo((x * s1), (y * s1), (z * s1));
                    u = (u + s);
                }
                v = (v + s);
            }
        }

        private function drawRadius(steps:int=24):void
        {
            var x:Number;
            var y:Number;
            var z:Number;
            var n:Number = 0;
            var s:Number = ((Math.PI * 2) / steps);
            var scale:Number = 1;
            this._lPoint.lineStyle(1, this.color, this.alpha);
            this._lPoint.moveTo((Math.cos(0) * scale), 0, (Math.sin(0) * scale));
            n = s;
            while (n <= ((Math.PI * 2) + s)) {
                this._lPoint.lineTo((Math.cos(n) * scale), 0, (Math.sin(n) * scale));
                n = (n + s);
            }
            this._lPoint.moveTo(0, (Math.cos(0) * scale), (Math.sin(0) * scale));
            n = s;
            while (n <= ((Math.PI * 2) + s)) {
                this._lPoint.lineTo(0, (Math.cos(n) * scale), (Math.sin(n) * scale));
                n = (n + s);
            }
            this._lPoint.moveTo((Math.cos(0) * scale), (Math.sin(0) * scale), 0);
            n = s;
            while (n <= ((Math.PI * 2) + s)) {
                this._lPoint.lineTo((Math.cos(n) * scale), (Math.sin(n) * scale), 0);
                n = (n + s);
            }
        }

        public function get light():ZenLight
        {
            return (this._light);
        }

        public function set light(value:ZenLight):void
        {
            this._light = value;
        }

        override public function draw(includeChildren:Boolean=true, material:ShaderMaterialBase=null):void
        {
            super.draw(includeChildren, material);
            if (!(this._light)){
                return;
            }
            if (this._light.type == LightType.DIRECTIONAL){
                this._lDir.transform = world;
                this._lDir.dirty = true;
                this._lDir.draw(false);
            } else {
                if (this._light.infinite){
                    this._lPointInfinite.transform = world;
                    this._lPointInfinite.dirty = true;
                    this._lPointInfinite.draw(false);
                } else {
                    this._lPoint.transform = world;
                    this._lPoint.dirty = true;
                    this._lPoint.setScale(this._light.radius, this._light.radius, this._light.radius);
                    this._lPoint.draw(false);
                }
            }
        }


    }
}

