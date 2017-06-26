package zen.animation
{
    public class Label3D 
    {

        public var name:String;
        public var from:int;
        public var to:int;
        public var frameSpeed:Number = 1;

        public function Label3D(name:String, from:int, to:int, frameSpeed:Number=1)
        {
            this.name = name;
            this.from = from;
            this.to = to;
            this.frameSpeed = frameSpeed;
        }

        public function get length():int
        {
            return (((this.to - this.from) + 1));
        }

		
        public function toString():String
        {
            return ((((((("[object Label3D " + this.name) + " from:") + this.from) + ", to:") + this.to) + "]"));
        }
		


    }
}

