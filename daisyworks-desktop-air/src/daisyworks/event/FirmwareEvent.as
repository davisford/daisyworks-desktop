package daisyworks.event
{
	import flash.events.Event;
	
	import mx.rpc.Fault;
	
	public class FirmwareEvent extends Event
	{
		public static const FOTA_START:String = "FirmwareEvent.FOTA_START";
		public static const FOTA_ERROR:String = "FirmwareEvent.FOTA_ERROR";
		public static const FOTA_GENERAL:String = "FirmwareEvent.FOTA_GENERAL";
		
		// these are the STK500 Event Type names
		public static const SYNC_STARTED:String = "SYNC_STARTED";
		public static const SYNC_DONE:String = "SYNC_DONE";
		public static const PARAMETERS_SET_START:String = "PARAMETERS_SET_START";
		public static const PARAMETERS_SET_DONE:String = "PARAMETERS_SET_DONE";
		public static const FIRMWARE_SEND_UPDATE:String = "FIRMWARE_SEND_UPDATE";
		public static const FIRMWARE_SEND_DONE:String = "FIRMWARE_SEND_DONE";
		public static const COMPLETE:String = "COMPLETE";
		
		public var filePath:String;
		public var fault:Fault;
		public var message:String;
		
		public function FirmwareEvent(type:String, filePath:String=null, msg:String=null, fault:Fault=null)
		{
			this.filePath = filePath;
			this.message = msg;
			this.fault = fault;
			super(type, true, false);
		}
		
		override public function clone():Event {
			return new FirmwareEvent(type, filePath, message, fault);
		}
	}
}