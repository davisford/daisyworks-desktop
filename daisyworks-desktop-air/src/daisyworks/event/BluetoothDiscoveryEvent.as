package daisyworks.event
{
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;
	import mx.rpc.Fault;
	
	public class BluetoothDiscoveryEvent extends Event
	{
		public static const DISCOVER_DEVICES:String 		= "BluetoothDiscoveryEvent.DISCOVER_DEVICES";
		public static const DISCOVER_CACHED_DEVICES:String  = "BluetoothDiscoveryEvent.DISCOVER_CACHED_DEVICES";
		public static const DISCOVER_DEVICES_FAULT:String	= "BluetoothDiscoveryEvent.DISCOVER_DEVICES_FAULT";
		public static const FOUND_DEVICES:String			= "BluetoothDiscoveryEvent.FOUND_DEVICES";
		
		public static const DISCOVER_SERVICES:String		= "BluetoothDiscoveryEvent.DISCOVER_SERVICES";
		public static const DISCOVER_SERVICES_FAULT:String	= "BluetoothDiscoveryEvent.DISCOVER_SERVICES_FAULT";
		public static const FOUND_SERVICES:String			= "BluetoothDiscoveryEvent.FOUND_SERVICES";
		
		public var devices:ArrayCollection;
		public var address:String;
		
		public var fault:Fault;
		
		public function BluetoothDiscoveryEvent(type:String, address:String=null, devices:ArrayCollection=null, fault:Fault=null)
		{
			this.devices = devices;
			this.address = address;
			this.fault = fault;
			super(type, true, false);
		}
		
		override public function clone():Event {
			return new BluetoothDiscoveryEvent(type, address, devices, fault);
		}
	}
}