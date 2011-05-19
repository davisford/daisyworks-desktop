package daisyworks.controller
{
	import daisyworks.event.BluetoothDiscoveryEvent;
	import daisyworks.log.Logger;
	import daisyworks.model.Device;
	import daisyworks.model.Preferences;
	
	import flash.events.IEventDispatcher;
	
	import mx.collections.ArrayCollection;
	import mx.logging.ILogger;
	import mx.rpc.IResponder;
	import mx.rpc.events.FaultEvent;
	import mx.rpc.events.ResultEvent;
	import mx.rpc.remoting.RemoteObject;

	public class BluetoothController implements IResponder
	{
		private static const LOG:ILogger = Logger.getLogger(BluetoothController);
		
		private var remoteObj:RemoteObject;
		
		[Inject]
		public var prefs:Preferences;
		
		private static var port:Number;
		
		[Bindable]
		public var devices:ArrayCollection;
		
		[Bindable]
		public var localDevice:Device;
		
		[Dispatcher]
		public var dispatcher:IEventDispatcher;
		
		/**
		 * Constructor
		 */
		public function BluetoothController() {	}
		
		/**
		 * Initialization after swiz D.I.
		 */
		[PostConstruct]
		public function init():void {
			remoteObj = new RemoteObject();
			remoteObj.destination = "bluetoothService";
			remoteObj.addEventListener(ResultEvent.RESULT, result);
			remoteObj.addEventListener(FaultEvent.FAULT, fault);
			remoteObj.showBusyCursor = true;
			port = prefs.getValue("port", "8080");
			remoteObj.endpoint = "http://localhost:"+port+"/daisyworks/messagebroker/amf";
		}
		
		[EventHandler(event="daisyworks.event.BluetoothDiscoveryEvent.DO_DISCOVERY")]
		public function doDiscovery():void {
			remoteObj.discover();
		}
		
		[EventHandler(event="BluetoothDiscoveryEvent.GET_LOCAL_DEVICE")]
		public function getLocalDevice():void {
			remoteObj.getLocalDevice();
		}
		
		[EventHandler(event="SerialPortCmdEvent.CONNECT", properties="address")]
		public function connect(address:String):void {
			remoteObj.connect(address);
		}
		
		[EventHandler(event="SerialPortDataEvent.TX", properties="line")]
		public function send(line:String):void {
			remoteObj.send(line);
		}
		
		public function result(obj:Object):void {
			if(obj.result is ArrayCollection) {
				devices = obj.result as ArrayCollection;
				LOG.info("device count returned "+devices.length);
			} else if(obj.result is Device) {
				localDevice = obj.result as Device;	
				LOG.info("local name: "+localDevice.name);
			} else {
				LOG.info("other result");
			}
		}
		
		public function fault(obj:Object):void {
			LOG.error("bluetooth service failure: "+ obj.fault.faultDetail );
		}
		
	}
}