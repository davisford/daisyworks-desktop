package daisyworks.event
{
	import daisyworks.model.Device;
	
	import flash.events.Event;
	
	import mx.rpc.Fault;
	
	public class BluetoothControlEvent extends Event
	{
		public static const CONNECT:String 			= "BluetoothControlEvent.CONNECT";
		public static const CONNECT_FAULT:String	= "BluetoothControlEvent.CONNECT_FAULT";
		public static const CONNECTED:String 		= "BluetoothControlEvent.CONNECTED";
		
		public static const DISCONNECT:String 		= "BluetoothControlEvent.DISCONNECT";
		public static const DISCONNECT_FAULT:String	= "BluetoothControlEvent.DISCONNECT_FAULT";
		public static const DISCONNECTED:String 	= "BluetoothControlEvent.DISCONNECTED";
		
		public var device:Device;
		public var fault:Fault;
		
		public function BluetoothControlEvent(type:String, device:Device=null, fault:Fault=null)
		{
			this.device = device;
			this.fault = fault;
			super(type, true, false);
		}
		
		override public function clone():Event {
			return new BluetoothControlEvent(type, device, fault);
		}
	}
	
}