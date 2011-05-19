package daisyworks.event
{
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;

	public class SerialPortDataEvent extends Event
	{
		public static const TX:String="SerialProfileEvent.TX";
		public static const RX:String="SerialProfileEvent.RX";

		public var line:String;
		
		public function SerialPortDataEvent(type:String, line:String)
		{
			this.line = line;
			super(type, true, false);
		}
		
		override public function clone():Event {
			return new SerialPortDataEvent(type, line);
		}
	}
}