package zen.utils {
	
	public class LayerSort {
		
		public var layer:int;
		public var left:int;
		public var right:int;
		public var mode:int;
		public var active:Boolean;
		
		public function LayerSort(layer:int, left:int, right:int, mode:int) {
			this.layer = layer;
			this.left = left;
			this.right = right;
			this.mode = mode;
			this.active = false;
		}
	
	}

}