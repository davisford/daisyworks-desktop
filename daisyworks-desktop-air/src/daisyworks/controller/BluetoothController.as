package daisyworks.controller
{
	import daisyworks.event.*;
	import daisyworks.log.Logger;
	import daisyworks.model.Device;
	import daisyworks.model.Preferences;
	
	import flash.events.IEventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.logging.ILogger;
	import mx.messaging.ChannelSet;
	import mx.messaging.Consumer;
	import mx.messaging.channels.AMFChannel;
	import mx.messaging.events.ChannelEvent;
	import mx.messaging.events.ChannelFaultEvent;
	import mx.messaging.events.MessageEvent;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.remoting.Operation;
	import mx.rpc.remoting.RemoteObject;

	/**
	 * This controller handles all the interaction with the remote Java AMF/BlazeDS services
	 * which do all the Bluetooth stuff for us.  All interaction with this class is done
	 * purely via events.  See daisyworks/events/Bluetooth*Event.as
	 */
	public class BluetoothController
	{
		private static const LOG:ILogger = Logger.getLogger(BluetoothController);
		
		private var dataRemoteObj:RemoteObject;
		private var controlRemoteObj:RemoteObject;
		private var localDeviceRemoteObj:RemoteObject;
		
		private var consumer:Consumer;
		
		[Inject]
		public var prefs:Preferences;
		
		[Dispatcher]
		/**
		 * Injected via Swiz
		 * @default
		 */
		public var dispatcher:IEventDispatcher;
		
		public function BluetoothController()
		{
		}
		
		[PostConstruct]
		public function init():void {
			var endpoint:String = "http://localhost:" + prefs.getValue("port", "8080") + "/daisyworks/messagebroker/amf";
			var destination:String = "bluetoothService";
			
			// Remote Object for getting local adapter info
			localDeviceRemoteObj = new RemoteObject();
			localDeviceRemoteObj.destination = destination;
			localDeviceRemoteObj.endpoint = endpoint;
			localDeviceRemoteObj.concurrency = "multiple";
			localDeviceRemoteObj.showBusyCursor = false;
			
			var operations:Object = new Object();
			var op:Operation = new Operation(null, "getLocalDevice");
			op.addEventListener(ResultEvent.RESULT, getLocalDeviceResult);
			op.addEventListener(FaultEvent.FAULT, getLocalDeviceFault);
			operations["getLocalDevice"] = op;
			
			localDeviceRemoteObj.operations = operations;
						
			// Remote Object for control operations
			controlRemoteObj = new RemoteObject();
			controlRemoteObj.destination = destination;
			controlRemoteObj.endpoint = endpoint;
			controlRemoteObj.concurrency = "single";
			controlRemoteObj.showBusyCursor = true;
			
			operations = new Object();
			op = new Operation(null, "findDevices");
			op.addEventListener(ResultEvent.RESULT, findDevicesResult);
			op.addEventListener(FaultEvent.FAULT, findDevicesFault);
			operations["findDevices"] = op;
			
			op = new Operation(null, "findServices");
			op.addEventListener(ResultEvent.RESULT, findServicesResult);
			op.addEventListener(FaultEvent.FAULT, findServicesFault);
			operations["findServices"] = op;
			
			op = new Operation(null, "connectRFComm");
			op.addEventListener(ResultEvent.RESULT, connectResult);
			op.addEventListener(FaultEvent.FAULT, connectFault);
			operations["connectRFComm"] = op;
			
			op = new Operation(null, "disconnectRFComm");
			op.addEventListener(ResultEvent.RESULT, disconnectResult);
			op.addEventListener(FaultEvent.FAULT, disconnectFault);
			operations["disconnectRFComm"] = op;
			
			controlRemoteObj.operations = operations;
			
			// Remote Object for transmit operations
			dataRemoteObj = new RemoteObject();
			dataRemoteObj.destination = destination;
			dataRemoteObj.endpoint = endpoint;
			dataRemoteObj.concurrency = "multiple";
			dataRemoteObj.showBusyCursor = false;
			
			operations = new Object();
			op = new Operation(null, "send");
			op.addEventListener(ResultEvent.RESULT, sendResult);
			op.addEventListener(FaultEvent.FAULT, sendFault);
			operations["send"] = op;
			dataRemoteObj.operations = operations;
			
			// Consumer for receiving data	
			var channelSet:ChannelSet = new ChannelSet();
			var channel:AMFChannel = new AMFChannel("amfchannel", endpoint);
			channelSet.channels = [channel];
			
			consumer = new Consumer();
			consumer.channelSet = channelSet;
			consumer.destination="serialPort";
			
			consumer.addEventListener(ChannelEvent.CONNECT, channelConnected);
			consumer.addEventListener(ChannelEvent.DISCONNECT, channelDisconnected);
			consumer.addEventListener(MessageEvent.MESSAGE, messageReceived);
			consumer.addEventListener(ChannelFaultEvent.FAULT, channelFault);

		}
		
		// __________ GET LOCAL DEVICE ____________ //
		
		[EventHandler(event="BluetoothLocalEvent.GET_LOCAL_DEVICE")]
		public function getLocalDevice():void {
			localDeviceRemoteObj.getLocalDevice();
		}

		private function getLocalDeviceResult(evt:ResultEvent):void {
			dispatcher.dispatchEvent(new BluetoothLocalEvent(BluetoothLocalEvent.FOUND_LOCAL_DEVICE, evt.result as Device));
		}
		
		private function getLocalDeviceFault(evt:FaultEvent):void {
			dispatcher.dispatchEvent(new DaisyWorksEvent(DaisyWorksEvent.BLUETOOTH_FAILURE, "Failed to find local bluetooth adapter", evt.fault));
		}
				
		// ___________ FIND DEVICES ___________ //
		
		[EventHandler(event="BluetoothDiscoveryEvent.DISCOVER_DEVICES")]
		public function findDevices():void {
			controlRemoteObj.findDevices();
		}
		
		private function findDevicesResult(evt:ResultEvent):void {
			dispatcher.dispatchEvent(new BluetoothDiscoveryEvent(BluetoothDiscoveryEvent.FOUND_DEVICES, null, evt.result as ArrayCollection));
		}
		
		private function findDevicesFault(evt:FaultEvent):void {
			dispatcher.dispatchEvent(new BluetoothDiscoveryEvent(BluetoothDiscoveryEvent.DISCOVER_DEVICES_FAULT, null, null, evt.fault));
			dispatcher.dispatchEvent(new DaisyWorksEvent(DaisyWorksEvent.BLUETOOTH_FAILURE, "Failed to discover bluetooth devices", evt.fault));
		}
		
		// ___________ FIND SERVICES __________ //
		
		[EventHandler(event="BluetoothDiscoveryEvent.DISCOVER_SERVICES", properties="address")]
		public function findServices(address:String):void {
			controlRemoteObj.findServices(address);
		}
		
		private function findServicesResult(evt:ResultEvent):void {
			dispatcher.dispatchEvent(new BluetoothDiscoveryEvent(BluetoothDiscoveryEvent.FOUND_SERVICES));
		}
		
		private function findServicesFault(evt:FaultEvent):void {
			dispatcher.dispatchEvent(new BluetoothDiscoveryEvent(BluetoothDiscoveryEvent.DISCOVER_SERVICES_FAULT, null, null, evt.fault));
			dispatcher.dispatchEvent(new DaisyWorksEvent(DaisyWorksEvent.BLUETOOTH_FAILURE, "Failed to discover bluetooth services", evt.fault));
		}
		
		// ____________ CONNECT _______________ //
		
		private var connectingDevice:Device;
		
		[EventHandler(event="BluetoothControlEvent.CONNECT", properties="device")]
		public function connectDevice(device:Device):void {
			// save a copy so we can send it in the CONNECTED event
			connectingDevice = device;
			controlRemoteObj.connectRFComm(device.address);
		}
		
		private function connectResult(evt:ResultEvent):void {
			dispatcher.dispatchEvent(new BluetoothControlEvent(BluetoothControlEvent.CONNECTED, connectingDevice));
			connectingDevice = null;
			// start the receive channel
			consumer.subscribe();
		}
		
		private function connectFault(evt:FaultEvent):void {
			dispatcher.dispatchEvent(new BluetoothControlEvent(BluetoothControlEvent.CONNECT_FAULT, null, evt.fault));
			dispatcher.dispatchEvent(new DaisyWorksEvent(DaisyWorksEvent.BLUETOOTH_FAILURE, "Failed to connect to bluetooth device", evt.fault));
			connectingDevice = null;
		}
		
		// ____________ DISCONNECT ______________ //
		
		[EventHandler(event="BluetoothControlEvent.DISCONNECT", properties="device")]
		public function disconnectDevice(device:Device):void {
			controlRemoteObj.disconnectRFComm(device.address);
		}
		
		private function disconnectResult(evt:ResultEvent):void {
			dispatcher.dispatchEvent(new BluetoothControlEvent(BluetoothControlEvent.DISCONNECTED));
			// stop the receive channel
			consumer.unsubscribe();
		}
		
		private function disconnectFault(evt:FaultEvent):void {
			dispatcher.dispatchEvent(new BluetoothControlEvent(BluetoothControlEvent.DISCONNECT_FAULT, null, evt.fault));
		}
		
		// _____________ TRANSMIT ________________ //
		
		[EventHandler(event="BluetoothTxRxEvent.TX", properties="data")]
		public function transmit(data:String):void {
			dataRemoteObj.send(data);
		}
		
		private function sendResult(evt:ResultEvent):void {
			// no-op
		}
		
		private function sendFault(evt:FaultEvent):void {
			dispatcher.dispatchEvent(new BluetoothTxRxEvent(BluetoothTxRxEvent.TX_FAULT, null, evt.fault));
		}
		
		// _____________ RECEIVE _________________ //
		private function messageReceived(event:MessageEvent):void	{
			dispatcher.dispatchEvent(new BluetoothTxRxEvent(BluetoothTxRxEvent.RX, String(event.message.body)));
		}
		
		private function channelConnected(event:ChannelEvent):void {
			LOG.info("Consumer destination "+consumer.destination+" connected"); 
		}
		
		private function channelDisconnected(event:ChannelEvent):void {
			LOG.info("Consumer destination "+consumer.destination+" disconnectd");
		}
		
		private function channelFault(event:ChannelFaultEvent):void { 
			LOG.error("Consumer channel fault: "+event.faultString);
		}
		
	}
}