package zen.materials
{
    import flash.events.*;
	
    public interface ILibraryItem extends IEventDispatcher
    {

        function dispose():void;
        function get bytesTotal():uint;
        function get bytesLoaded():uint;
        function get loaded():Boolean;
        function get request();
        function load():void;
        function close():void;

    }
}

