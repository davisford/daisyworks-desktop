package daisyworks.event
{
	import daisyworks.model.Device;
	
	import flash.events.Event;
	
	public class BluetoothEvent extends Event
	{
		public static const CONNECTED:String="BluetoothEvent.CONNECTED";
		public static const DISCONNECTED:String ="BluetoothEvent.DISCONNECTED";
		
		public static const DISCONNECT:String="BluetoothEvent.DISCONNECT";
		
		public static const LOCAL_DEVICE:String="BluetoothEvent.LOCAL_DEVICE";
		
		public var device:Device;
		
		public function BluetoothEvent(type:String, device:Device=null)
		{
			this.device=device;
			super(type, true, false);
		}
		
		override public function clone():Event {
			return new BluetoothEvent(type, device);
		}
	}
}