package zen.materials
{
    import flash.events.EventDispatcher;
    
    import flash.utils.Dictionary;
    import flash.events.Event;
    import flash.events.ProgressEvent;
    import flash.events.IOErrorEvent;
    import flash.display3D.*;
    import flash.events.*;
    import flash.utils.*;
    import zen.materials.*;
    

    [Event(name="updated", type="flash.events.Event")]
    [Event(name="complete", type="flash.events.Event")]
    [Event(name="progress", type="flash.events.ProgressEvent")]
    [Event(name="ioError", type="flash.events.IOErrorEvent")]
    public class Library3D extends EventDispatcher implements ILibraryItem 
    {

        private var _connections:int = 2;
        private var _connectionsCount:int = 0;
        private var _allowEventsAfterComplete:Boolean = true;
        private var _autoStart:Boolean = true;
        private var _loadInQueued:Vector.<ILibraryItem>;
        private var _loading:Vector.<ILibraryItem>;
        private var _bytesLoaded:uint;
        private var _bytesTotal:uint;
        private var _progress:Number = 0;
        private var _completed:Boolean;
        private var _loadCount:int;
        private var _loaded:Boolean;
        private var _items:Vector.<ILibraryItem>;
        private var _path:Dictionary;

        public function Library3D(connections:int=10, autoStart:Boolean=true, allowEventsAfterComplete:Boolean=true)
        {
            this._loadInQueued = new Vector.<ILibraryItem>();
            this._loading = new Vector.<ILibraryItem>();
            this._items = new Vector.<ILibraryItem>();
            this._path = new Dictionary();
            super();
            this._connections = connections;
            this._autoStart = autoStart;
            this._allowEventsAfterComplete = allowEventsAfterComplete;
        }

        public function get request()
        {
            return (null);
        }

        public function dispose():void
        {
            this._loadInQueued = null;
            this._loading = null;
            this._items = null;
            this._path = null;
        }

        public function reset():void
        {
            this.close();
            this._loading = new Vector.<ILibraryItem>();
            this._loadInQueued = new Vector.<ILibraryItem>();
            this._bytesLoaded = 0;
            this._bytesTotal = 0;
            this._progress = 0;
            this._completed = false;
            this._loadCount = 0;
            this._path = new Dictionary();
            this._items = new Vector.<ILibraryItem>();
        }

        public function addItem(key, item:ILibraryItem):ILibraryItem
        {
            this._path[key] = item;
            if (this._items.indexOf(item) == -1){
                this._items.push(item);
                dispatchEvent(new Event("updated"));
                return (item);
            }
            return (null);
        }

        public function removeItem(key):ILibraryItem
        {
            var index:int;
            var item:ILibraryItem = this._path[key];
            if (item){
                index = this._items.indexOf(item);
                if (index != -1){
                    this._items.splice(index, 1);
                }
                dispatchEvent(new Event("updated"));
                return (item);
            }
            return (null);
        }

        public function getItem(key):ILibraryItem
        {
            return (this._path[key]);
        }

        public function push(item:ILibraryItem):ILibraryItem
        {
            if (item.loaded){
                return (null);
            }
            if (this._loadInQueued.indexOf(item) == -1){
                this._loadInQueued.push(item);
                this._loading.push(item);
                this._loadCount++;
                item.addEventListener("complete", this.completeQueuedEvent, false, 0, true);
                item.addEventListener("progress", this.progressQueuedEvent, false, 0, true);
                item.addEventListener("ioError", this.completeQueuedEvent, false, 0, true);
                if (this._autoStart){
                    this.load();
                }
                return (item);
            }
            return (null);
        }

        public function load():void
        {
            if (((!(this._loading)) || ((this._loading.length == 0)))){
                this._progress = 0;
                this._bytesLoaded = 0;
                this._bytesTotal = 0;
            }
            if (this._loadInQueued.length == 0){
                this._loaded = true;
                this._progress = 1;
            }
            if ((((((this._connections > 0)) && ((this._connectionsCount >= this._connections)))) || ((this._loadInQueued.length == 0)))){
                return;
            }
            var item:ILibraryItem = this._loadInQueued.shift();
            item.load();
            this._connectionsCount++;
        }

        public function close():void
        {
            var i:ILibraryItem;
            for each (i in this._loadInQueued) {
                i.close();
            }
        }

        public function get loaded():Boolean
        {
            return (this._loaded);
        }

        private function progressQueuedEvent(e:ProgressEvent):void
        {
            var item:ILibraryItem;
            this._bytesTotal = 0;
            this._bytesLoaded = 0;
            this._progress = 0;
            for each (item in this._loading) {
                this._bytesLoaded = (this._bytesLoaded + item.bytesLoaded);
                this._bytesTotal = (this._bytesTotal + item.bytesTotal);
                if ((item is Library3D)){
                    this._progress = (this._progress + ((Library3D(item).progress / 100) / this._loading.length));
                } else {
                    if (item.bytesTotal > 0){
                        this._progress = (this._progress + ((item.bytesLoaded / item.bytesTotal) / this._loading.length));
                    }
                }
            }
            if ((((this._completed == false)) || (this._allowEventsAfterComplete))){
                dispatchEvent(e);
            }
        }

        private function completeQueuedEvent(e:Event=null):void
        {
            if (e){
                e.target.removeEventListener("complete", this.completeQueuedEvent);
                e.target.removeEventListener("progress", this.progressQueuedEvent);
                e.target.removeEventListener("ioError", this.completeQueuedEvent);
            }
            this._connectionsCount--;
            this._loadCount--;
            if (!(this._loadInQueued)){
                return;
            }
            if (this._loadInQueued.length > 0){
                this.load();
            } else {
                if (this._loadCount <= 0){
                    this._loading.splice(0, this._loading.length);
                    this._progress = 1;
                    this._loaded = true;
                    if ((((this._completed == false)) || (this._allowEventsAfterComplete))){
                        dispatchEvent(new Event("complete"));
                    }
                    if (!(this._allowEventsAfterComplete)){
                        this._completed = true;
                    }
                }
            }
            if ((e is IOErrorEvent)){
                dispatchEvent(e);
            }
        }

        public function get bytesTotal():uint
        {
            return (this._bytesTotal);
        }

        public function get bytesLoaded():uint
        {
            return (this._bytesLoaded);
        }

        public function get progress():Number
        {
            return ((this._progress * 100));
        }

        public function get items():Vector.<ILibraryItem>
        {
            return (this._items.concat());
        }

        public function get itemsToLoad():Vector.<ILibraryItem>
        {
            return (this._loadInQueued.concat());
        }

        public function get allowEventsAfterComplete():Boolean
        {
            return (this._allowEventsAfterComplete);
        }

        public function set allowEventsAfterComplete(value:Boolean):void
        {
            this._allowEventsAfterComplete = value;
        }


    }
}

