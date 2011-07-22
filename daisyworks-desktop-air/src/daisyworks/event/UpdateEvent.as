package daisyworks.event
{
	import flash.events.Event;
	
	public class UpdateEvent extends Event
	{
		public static const CHECK_FOR_UPDATE:String="UpdateEvent.CHECK_FOR_UPDATE";
		public static const UPDATE_AVAILABLE:String="UpdateEvent.UPDATE_AVAILABLE";
		public static const DOWNLOAD_UPDATE:String="UpdateEvent.DOWNLOAD_UPDATE";
		
		public var xml:XML;
		
		public function UpdateEvent(type:String, xml:XML=null)
		{
			this.xml = xml;
			super(type, true, false);
		}
		
		override public function clone():Event {
			return new UpdateEvent(type, xml);
		}
	}
}