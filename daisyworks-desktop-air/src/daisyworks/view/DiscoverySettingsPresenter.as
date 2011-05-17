package daisyworks.view
{
	import daisyworks.model.Device;
	
	import mx.collections.ArrayCollection;

	[Bindable]
	public class DiscoverySettingsPresenter
	{
		private var _devices:ArrayCollection;
		private var _localDevice:Device;
		
		public function DiscoverySettingsPresenter()
		{
		}

		[Inject(source="bluetoothController.devices", bind="true")]
		public function get devices():ArrayCollection
		{
			return _devices;
		}

		public function set devices(value:ArrayCollection):void
		{
			_devices = value;
		}

		[Inject(source="bluetoothController.localDevice", bind="true")]
		public function get localDevice():Device
		{
			return _localDevice;
		}

		public function set localDevice(value:Device):void
		{
			_localDevice = value;
		}


	}
}