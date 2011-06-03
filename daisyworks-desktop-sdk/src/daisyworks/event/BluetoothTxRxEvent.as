package daisyworks.event
{
	import flash.events.Event;
	
	import mx.rpc.Fault;
	
	public class BluetoothTxRxEvent extends Event
	{
		public static const TX:String = "BluetoothTxRxEvent.TX";
		public static const RX:String = "BluetoothTxRxEvent.RX";
		
		public static const TX_FAULT:String = "BluetoothTxRxEvent.TX_FAULT";
		public static const RX_FAULT:String = "BluetoothTxRxEvent.RX_FAULT";
		
		public var data:String;
		public var fault:Fault;
		
		public function BluetoothTxRxEvent(type:String, data:String, fault:Fault=null)
		{
			this.data = data;
			this.fault = fault;
			super(type, true, false);
		}
		
		override public function clone():Event {
			return new BluetoothTxRxEvent(type, data, fault);
		}
	}
}