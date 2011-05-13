package daisyworks.event
{
	import flash.events.Event;
	
	public class DaisyWorksEvent extends Event
	{
		public static const JVM_START_FAILURE:String="DaisyWorksEvent.JVM_START_FAILURE";
		public static const HTTP_404:String ="DaisyWorksEvent.HTTP_404";
		
		public var message:String;
		
		public function DaisyWorksEvent(type:String, message:String)
		{
			this.message=message;
			super(type, true, false);
		}
		
		override public function clone():Event {
			return new DaisyWorksEvent(type, message);
		}
	}
}