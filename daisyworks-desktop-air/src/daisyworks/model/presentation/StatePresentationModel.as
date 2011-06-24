package daisyworks.model.presentation
{
	public class StatePresentationModel
	{
		private var _connected:Boolean=false;
		
		public function StatePresentationModel()
		{
		}
		
		[Bindable]
		public function get connected():Boolean { return _connected; }
		
		public function set connected(val:Boolean):void { _connected=val; }
		
		[EventHandler(event="BluetoothControlEvent.CONNECTED")]
		public function onConnected():void {
			connected = true;
		}
		
		[EventHandler(event="BluetoothControlEvent.DISCONNECTED")]
		public function onDisconnected():void {
			connected = false;
		}
	}
}