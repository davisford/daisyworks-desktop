package daisyworks.event
{
	import daisyworks.model.Device;
	
	import flash.events.Event;
	
	public class BluetoothLocalEvent extends Event
	{
		public static const GET_LOCAL_DEVICE:String 	= "BluetoothLocalEvent.GET_LOCAL_DEVICE";
		public static const FOUND_LOCAL_DEVICE:String 	= "BluetoothLocalEvent.FOUND_LOCAL_DEVICE"; 
		
		public var device:Device;
		
		public function BluetoothLocalEvent(type:String, localDevice:Device=null)
		{
			this.device = localDevice;
			super(type, true, false);
		}
		
		override public function clone():Event {
			return new BluetoothLocalEvent(type, device);
		}
	}
}