package daisyworks.controller
{
	import com.adobe.utils.StringUtil;
	
	import daisyworks.event.*;
	import daisyworks.log.Logger;
	import daisyworks.model.Device;
	import daisyworks.model.Preferences;
	
	import flash.events.IEventDispatcher;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
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
	
	import org.osmf.events.TimeEvent;

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
			controlRemoteObj.concurrency = "multiple";
			controlRemoteObj.showBusyCursor = true;
			
			operations = new Object();
			op = new Operation(null, "findDevices");
			op.addEventListener(ResultEvent.RESULT, findDevicesResult);
			op.addEventListener(FaultEvent.FAULT, findDevicesFault);
			operations["findDevices"] = op;
			
			op = new Operation(null, "findCachedDevices");
			op.addEventListener(ResultEvent.RESULT, findDevicesResult);
			op.addEventListener(FaultEvent.FAULT, findDevicesFault);
			operations["findCachedDevices"] = op;
			
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
			
			op = new Operation(null, "updateFirmware");
			op.addEventListener(ResultEvent.RESULT, updateFirmwareResult);
			op.addEventListener(FaultEvent.FAULT, updateFirmwareFault);
			operations["updateFirmware"] = op;
			
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
		
		[EventHandler(event="BluetoothDiscoveryEvent.DISCOVER_CACHED_DEVICES")]
		public function findCachedDevices():void {
			controlRemoteObj.findCachedDevices();
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
			var msg:String = String(event.message.body);
			/* I don't want to parse out the different types of FOTA messages on every incoming, so
			 * I made one FOTA_GENERAL event type, and let the FirmwareProgrammer parse out the text
			 * This is more efficient than trying to figure it out here and dispatching diff events
			 */
			if(msg.indexOf("FOTA") != -1) {
				dispatcher.dispatchEvent(new FirmwareEvent(FirmwareEvent.FOTA_GENERAL, null, msg, null));		
			} else {
				dispatcher.dispatchEvent(new BluetoothTxRxEvent(BluetoothTxRxEvent.RX, msg));
			}
			// TODO: comment this out
			LOG.info(msg);
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
		
		// _____________ RENAME ___________________ //
		[EventHandler(event="BluetoothRenameEvent.RENAME", properties="name, device")]
		public function rename(name:String, device:Device):void {
			// we have to disconnect for this to work b/c we have to reset the modem
			dispatcher.dispatchEvent(new BluetoothControlEvent(BluetoothControlEvent.DISCONNECTED));
			
			// shutdown the consumer, or else it'll get blasted with 'null' messages
			consumer.unsubscribe();
			
			controlRemoteObj.rename(device.address, name);
			
			var rescan:Timer = new Timer(5000, 1);
			rescan.addEventListener(TimerEvent.TIMER, function():void {
				controlRemoteObj.findDevices();
			});
			rescan.start();
		} 
		
		[EventHandler(event="FirmwareEvent.FOTA_START", properties="filePath")]
		public function updateFirmware(filePath:String):void {
			controlRemoteObj.updateFirmware(filePath);
		}
		
		public function updateFirmwareResult(evt:ResultEvent):void {
			LOG.info("Update firmware result");
		}
		
		/**
		 * You'll hit this if we can't connect to Java or an exception is thrown
		 */
		public function updateFirmwareFault(evt:FaultEvent):void {
			LOG.error("Update firmware fault: "+evt.fault.faultString);
			dispatcher.dispatchEvent(new FirmwareEvent(FirmwareEvent.FOTA_ERROR, null, null, evt.fault));
		}
		
	}
}