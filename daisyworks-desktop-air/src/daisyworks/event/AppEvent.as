package daisyworks.event
{
	import flash.events.Event;
	
	import mx.collections.XMLListCollection;
	
	public class AppEvent extends Event
	{
		public static const LIST:String 				= "AppEvent.LIST";
		public static const LIST_RESULTS:String 		= "AppEvent.LIST_RESULTS";
		
		public static const REMOVE:String 				= "AppEvent.REMOVE";
		
		public static const DOWNLOAD:String 			= "AppEvent.DOWNLOAD";
		public static const DOWNLOAD_COMPLETE:String 	= "AppEvent.DOWNLOAD_COMPLETE";
		
		public static const DEPLOY:String				= "AppEvent.DEPLOY";
		
		public var app:XML;
		public var list:XMLListCollection;
		
		public function AppEvent(type:String, app:XML=null, list:XMLListCollection=null)
		{
			this.app = app;
			this.list = list;
			super(type, true, false);
		}
		
		override public function clone():Event {
			return new AppEvent(type, app, list);
		}
	}
}