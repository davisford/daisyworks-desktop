package daisyworks.controller
{
	
	import daisyworks.config.PlatformUtil;
	import daisyworks.event.UpdateEvent;
	import daisyworks.log.Logger;
	
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.Capabilities;
	
	import mx.collections.XMLListCollection;
	import mx.logging.ILogger;
	
	public class UpdateController
	{
		private static const LOG:ILogger = Logger.getLogger(UpdateController);
		
		private var urlLoader:URLLoader;
		
		[Dispatcher]
		public var dispatcher:IEventDispatcher;
		
		public function UpdateController()
		{
		}
		
		[PostConstruct]
		public function init():void {
			urlLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, loadComplete);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, loadError);
		}
		
		private function loadComplete(evt:Event):void {
			var xml:XML = XML(urlLoader.data);  
			
			var update:XML;
			
			// my version
			var me:String = PlatformUtil.getAppVersion();
			
			if(PlatformUtil.isWindows()) {
				if(me != xml.platform.windows.version) {
					dispatcher.dispatchEvent(new UpdateEvent(UpdateEvent.UPDATE_AVAILABLE, xml.platform.windows[0]));
				}
			} else if(PlatformUtil.isMacOS()) {
				if(me != xml.platform.mac.version) {
					dispatcher.dispatchEvent(new UpdateEvent(UpdateEvent.UPDATE_AVAILABLE, xml.platform.mac[0]));
				}
			} else if(PlatformUtil.isLinux32()) {
				if(me != xml.platform.linux.x86.version) {
					dispatcher.dispatchEvent(new UpdateEvent(UpdateEvent.UPDATE_AVAILABLE, xml.platform.linux.x86[0]));
				}
			} else if(PlatformUtil.isLinux64()) {
				if(me != xml.platform.linux.x64.version) {
					dispatcher.dispatchEvent(new UpdateEvent(UpdateEvent.UPDATE_AVAILABLE, xml.platform.linux.x64[0]));
				}
			} else {
				LOG.error("Unknown platform, can't auto-update: "+PlatformUtil.platform);
			}
		}
		
		private function loadError(evt:IOErrorEvent):void {
			LOG.error("Failed to contact update server "+evt.text);
		}
		
		[EventHandler(event="UpdateEvent.CHECK_FOR_UPDATE")]
		public function checkForUpdate():void {
			urlLoader.load(new URLRequest("http://dl.dropbox.com/u/4165049/daisyworks-desktop/version.xml"));
		}
				
	}
}