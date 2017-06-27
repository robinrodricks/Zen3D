package zen.loaders {
	import flash.events.*;
	
	public interface IAsset extends IEventDispatcher {
		
		function dispose():void;
		function get bytesTotal():uint;
		function get bytesLoaded():uint;
		function get loaded():Boolean;
		function get request();
		function load():void;
		function close():void;
	
	}
}

