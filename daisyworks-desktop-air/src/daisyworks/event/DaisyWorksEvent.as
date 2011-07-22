package daisyworks.event
{
	import flash.events.Event;
	
	import mx.rpc.Fault;
	
	public class DaisyWorksEvent extends Event
	{
		public static const JVM_START_FAILURE:String="DaisyWorksEvent.JVM_START_FAILURE";
		public static const HTTP_404:String ="DaisyWorksEvent.HTTP_404";
		
		public static const JVM_STARTED:String="DaisyWorksEvent.JVM_STARTED";
		
		public static const BLUETOOTH_FAILURE:String="DaisyWorksEvent.BLUETOOTH_FAILURE";
		
		public static const APP_STORE_FAILURE:String="DaisyWorksEvent.APP_STORE_FAILURE";
		
		public static const EXIT:String = "DaisyWorksEvent.EXIT";
		
		public var message:String;
		public var fault:Fault;
		
		public function DaisyWorksEvent(type:String, message:String=null, fault:Fault=null)
		{
			this.message=message;
			this.fault=fault;
			super(type, true, false);
		}
		
		override public function clone():Event {
			return new DaisyWorksEvent(type, message,fault);
		}
	}
}