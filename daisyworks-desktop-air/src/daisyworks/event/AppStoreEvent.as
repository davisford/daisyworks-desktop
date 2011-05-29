package daisyworks.event
{
	import flash.events.Event;
	
	import mx.collections.XMLListCollection;
	
	public class AppStoreEvent extends Event
	{
		public static const SEARCH:String = "AppStoreEvent.SEARCH";
		public static const RESULTS:String = "AppStoreEvent.RESULTS";
		
		public var search:String;
		public var results:XMLListCollection;
		
		public function AppStoreEvent(type:String, search:String=null, results:XMLListCollection=null)
		{
			this.search = search;
			this.results = results;
			super(type, true, false);
		}
		
		override public function clone():Event {
			return new AppStoreEvent(type, search, results);
		}
	}
}