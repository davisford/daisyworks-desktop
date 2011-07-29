package daisyworks.event
{
	import daisyworks.model.App;
	
	import flash.events.Event;
	
	import mx.collections.XMLListCollection;
	
	public class AppEvent extends Event
	{
		public static const LIST:String 				= "AppEvent.LIST";
		public static const LIST_RESULTS:String 		= "AppEvent.LIST_RESULTS";
		
		public static const REMOVE:String 				= "AppEvent.REMOVE";
		public static const REMOVED:String				= "AppEvent.REMOVED";
		
		public static const DOWNLOAD:String 			= "AppEvent.DOWNLOAD";
		public static const DOWNLOAD_COMPLETE:String 	= "AppEvent.DOWNLOAD_COMPLETE";
		public static const DOWNLOAD_FAILED:String		= "AppEvent.DOWNLOAD_FAILED";
		
		public static const DEPLOY:String				= "AppEvent.DEPLOY";
		
		public var app:App;
		public var list:XMLListCollection;
		
		public function AppEvent(type:String, app:App=null, list:XMLListCollection=null)
		{
			trace("new event " +type);
			this.app = app;
			this.list = list;
			super(type, true, false);
		}
		
		override public function clone():Event {
			return new AppEvent(type, app, list);
		}
	}
}