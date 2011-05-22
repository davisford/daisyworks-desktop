package daisyworks.event
{
	import daisyworks.model.Device;
	
	import flash.events.Event;
	
	import mx.rpc.Fault;
	
	public class BluetoothRenameEvent extends Event
	{
		public static const RENAME:String 	= "BluetoothRenameEvent.RENAME";

		public var name:String;
		public var device:Device;
		
		public function BluetoothRenameEvent(type:String, name:String, device:Device)
		{
			this.name = name;
			this.device = device;
			super(type, true, false);
		}
		
		override public function clone():Event {
			return new BluetoothRenameEvent(type, name, device);
		}
	}
	
}