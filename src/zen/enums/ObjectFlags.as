package zen.enums {
	
	public class ObjectFlags {
		
        public static const ENTER_FRAME_FLAG:int = 1;
        public static const EXIT_FRAME_FLAG:int = 2; // (1 << 1);
        public static const ENTER_DRAW_FLAG:int = 4; // (1 << 2);
        public static const EXIT_DRAW_FLAG:int = 8; // (1 << 3);
        public static const UPDATE_TRANSFORM_FLAG:int = 16; // (1 << 4);
        public static const ANIMATION_COMPLETE_FLAG:int = 32; // (1 << 5);
		
	}
	
}