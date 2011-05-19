package daisyworks.event
{
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;

	public class SerialPortCmdEvent extends Event
	{	
		public static const CONNECT:String="SerialProfileEvent.CONNECT";
		public static const DISCONNECT:String="SerialProfileEvent.DISCONNECT";

		public var address:String;
		
		public function SerialPortCmdEvent(type:String, address:String)
		{
			this.address = address;
			super(type, true, false);
		}
		
		override public function clone():Event {
			return new SerialPortCmdEvent(type, address);
		}
	}
}