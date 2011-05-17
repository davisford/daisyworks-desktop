package daisyworks.event
{
	import flash.events.Event;
	
	import mx.collections.ArrayCollection;

	public class BluetoothDiscoveryEvent extends Event
	{
		public static const DO_DISCOVERY:String="BluetoothDiscoveryEvent.DO_DISCOVERY";
		public static const DISCOVERY_COMPLETE:String="BluetoothDiscoveryEvent.DISCOVERY_COMPLETE";
		public static const GET_LOCAL_DEVICE:String="BluetoothDiscoveryEvent.GET_LOCAL_DEVICE";
		
		public var devices:ArrayCollection;
		
		public function BluetoothDiscoveryEvent(type:String, devices:ArrayCollection=null)
		{
			this.devices = devices;
			super(type, true, false);
		}
		
		override public function clone():Event {
			return new BluetoothDiscoveryEvent(type, devices);
		}
	}
}