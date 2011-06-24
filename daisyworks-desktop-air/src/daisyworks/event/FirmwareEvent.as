package daisyworks.event
{
	import flash.events.Event;
	
	import mx.rpc.Fault;
	
	public class FirmwareEvent extends Event
	{
		public static const FOTA_START:String = "FirmwareEvent.FOTA_START";
		public static const FOTA_COMPLETE:String = "FirmwareEvent.FOTA_COMPLETE";
		public static const FOTA_ERROR:String = "FirmwareEvent.FOTA_ERROR";
		public static const FOTA_PROGRESS:String = "FirmwareEvent.FOTA_PROGRESS";
		
		public var filePath:String;
		public var fault:Fault;
		
		public function FirmwareEvent(type:String, filePath:String=null, fault:Fault=null)
		{
			this.filePath = filePath;
			this.fault = fault;
			super(type, true, false);
		}
		
		override public function clone():Event {
			return new FirmwareEvent(type, filePath, fault);
		}
	}
}