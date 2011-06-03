package daisyworks.controller
{
	import daisyworks.event.AppStoreEvent;
	import daisyworks.log.Logger;
	
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	
	import mx.collections.XMLListCollection;
	import mx.logging.ILogger;

	public class AppStoreController
	{
		private static const LOG:ILogger = Logger.getLogger(AppStoreController);
		
		private var urlLoader:URLLoader;
		
		[Dispatcher]
		/**
		 * Injected via Swiz
		 * @default
		 */
		public var dispatcher:IEventDispatcher;
		
		public function AppStoreController()
		{
		}
		
		[PostConstruct]
		public function init():void {
			urlLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, loadComplete);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, loadError);
		}
		
		[EventHandler(event="AppStoreEvent.SEARCH", properties="search")]
		public function search(search:String):void {
			urlLoader.load(new URLRequest('assets/app-store-search-results.xml'));
		}
		
		private function loadComplete(evt:Event):void {
			var xml:XML = XML(urlLoader.data);
			dispatcher.dispatchEvent(new AppStoreEvent(AppStoreEvent.RESULTS, null, new XMLListCollection(xml.children())));
		}
		
		private function loadError(evt:IOErrorEvent):void {
			LOG.error("Failed to load data from app store " + evt.text);
		}
	}
}