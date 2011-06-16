package daisyworks.controller
{
	import com.adobe.utils.StringUtil;
	
	import daisyworks.event.AppDownloadEvent;
	import daisyworks.event.AppEvent;
	import daisyworks.log.Logger;
	import daisyworks.model.App;
	import daisyworks.model.Component;
	
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	
	import mx.collections.XMLListCollection;
	import mx.logging.ILogger;
	
	import org.swizframework.events.ChainEvent;
	import org.swizframework.utils.async.AsynchronousIOOperation;
	import org.swizframework.utils.async.IAsynchronousOperation;
	import org.swizframework.utils.chain.ChainType;
	import org.swizframework.utils.chain.EventChain;
	import org.swizframework.utils.chain.EventChainStep;
	import org.swizframework.utils.chain.FunctionChainStep;
	import org.swizframework.utils.services.URLRequestHelper;
	
	/**
	 * Handles all events / control related to app managment (e.g. download, install, list, etc.)
	 */
	public class AppController
	{
		private static const LOG:ILogger = Logger.getLogger(AppController);

		// reference to the XML file on disk: appStorage:/application.xml
		private var appMetadataFile:File = File.applicationStorageDirectory.resolvePath('applications.xml');
		
		// the directory where we install applications: appStorage:/applications/
		private var appDir:File = File.applicationStorageDirectory.resolvePath('applications');
				
		// in-memory XML of installed apps
		private var appXML:XML;
		
		[Dispatcher]
		public var dispatcher:IEventDispatcher;
		
		[Inject]public var urlRequestHelper:URLRequestHelper;
		
		public function AppController() {}
		
		[PostConstruct]
		public function init():void {			
			if(!appMetadataFile.exists) {
				appXML = bootstrapEmptyMetadata();
			} else {
				// load up app metadata
				appXML = readAppMetadata();
			}		
			dispatcher.dispatchEvent(new AppEvent(AppEvent.LIST_RESULTS, null, new XMLListCollection(appXML.children())));
		}
		
		/**
		 * Creates an empty app metadata XML if it doesn't exist
		 */
		private function bootstrapEmptyMetadata():XML {
			var outputString:String = "<?xml version='1.0' encoding='utf=8'?>"+File.lineEnding+"<apps></apps>";
			var fs:FileStream = new FileStream();
			try {
				fs.open(appMetadataFile, FileMode.WRITE);
				fs.writeUTFBytes(outputString);
			} finally {
				fs.close();
				return new XML(outputString);			
			}
		}
		
		/**
		 * Reads the app metadata file contents, returns as XML
		 */
		private function readAppMetadata():XML {
			var fs:FileStream = new FileStream();
			var xml:XML;
			try {
				fs.open(appMetadataFile, FileMode.READ);
				xml = XML(fs.readUTFBytes(fs.bytesAvailable));
			} finally {
				fs.close();
				return xml;
			}
		}
		
		/**
		 * Handles AppEvent.LIST event; loads the user's XML file that contains a list of 
		 * all installed applications.
		 */
		[EventHandler(event="AppEvent.LIST")]
		public function list():void {
			appXML = readAppMetadata();
			dispatcher.dispatchEvent(new AppEvent(AppEvent.LIST_RESULTS, null, new XMLListCollection(appXML.children())));
		}
		
		/**
		 * Handles AppEvent.DOWNLOAD event; downloads all software components, saves them to appStorage, and updates
		 * metadata regarding installed apps.
		 */
		[EventHandler(event="AppEvent.DOWNLOAD", properties="app")]
		public function downloadApp(app:App):void {			

			var chain:EventChain = new  EventChain(dispatcher, ChainType.SEQUENCE, true);
			chain.addEventListener(ChainEvent.CHAIN_COMPLETE, commandChainComplete);
			chain.addEventListener(ChainEvent.CHAIN_FAIL, commandChainFail);
			
			var firmwareFile:File;
			var swfFile:File;
			
			// download firmware file via urlrequest
			var firmware:Component = app.getFirmware();
			if(firmware) {
				firmwareFile = getFile('firmware', app.name);
				chain.addStep( new EventChainStep( new AppDownloadEvent(AppDownloadEvent.DOWNLOAD, app, firmware, firmwareFile), dispatcher ) );
			}
			
			// download swf file via urlrequest
			var swf:Component = app.getSwf();	
			if(swf) {
				swfFile = getFile('swf', app.name);
				chain.addStep( new EventChainStep( new AppDownloadEvent(AppDownloadEvent.DOWNLOAD, app, swf, swfFile), dispatcher ) );
			}
			
			if(chain.steps.length <= 0) {
				dispatcher.dispatchEvent(new AppEvent(AppEvent.DOWNLOAD_FAILED));
			} else {
				// start the chain
				chain.addStep( new FunctionChainStep( saveAppMetadata, [app, firmwareFile, swfFile] ));
				chain.start();		
			}	
		}
		
		/**
		 * Fired when the download chain has completed all of its steps
		 */
		private function commandChainComplete(evt:ChainEvent):void {
			dispatcher.dispatchEvent(new AppEvent(AppEvent.DOWNLOAD_COMPLETE));
		}
		
		/**
		 * Fired if any of the download chain steps fails
		 */
		private function commandChainFail(evt:ChainEvent):void {
			dispatcher.dispatchEvent(new AppEvent(AppEvent.DOWNLOAD_FAILED));
		}
		
		/**
		 * Handles the actual file download for us
		 */
		[EventHandler(event="AppDownloadEvent.DOWNLOAD", properties="app, component, file")]
		public function downloadSoftwareComponent(app:App, component:Component, file:File):IAsynchronousOperation {
			var request : URLRequest = new URLRequest( component.url );
			var loader : URLLoader = urlRequestHelper.executeURLRequest( request, downloadResult, downloadFailure, null, null, [app, component, file] );	
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			return new AsynchronousIOOperation(loader);
		}
		
		/**
		 * Result handler when file data is ready
		 */
		private function downloadResult(evt:Event, app:App, component:Component, file:File):void {
			var bytes:ByteArray = ByteArray(evt.target.data);
			var fs:FileStream = new FileStream();
			try {
				fs.open(file, FileMode.WRITE);
				fs.writeBytes(bytes);
			} finally {
				fs.close();
			}
		}
		
		/**
		 * Fault handler if file download failed
		 */
		private function downloadFailure(evt:Event, app:App, component:Component):void {
			LOG.error('download '+component.url+' failed because '+evt.toString());
		}
		
		/**
		 * Runs as the last step in the download chain; updates the master XML metadata with the install
		 * path of the firmware and/or swf 
		 */
		private function saveAppMetadata(app:App, firmwareFile:File=null, swfFile:File=null):void {
			if(firmwareFile) {
				app.getFirmware().path = firmwareFile.url;
			}
			if(swfFile) {
				app.getSwf().path = swfFile.url;
			}
			
			var xml:XML = app.toXml();
			
			LOG.info("Saving app metadata, appXML =>\n" + xml.toString());
			
			// if this app already exists, we will replace it in the app metadata XML
			var oldNode:XML = appXML.app.(@id == app.@id)[0];
			if(oldNode) {
				// replace
				appXML.replace(oldNode, xml);
			} else {
				// append
				appXML.appendChild(xml);
			}
			
			// write it out
			var fs:FileStream = new FileStream();
			try {
				fs.open(appMetadataFile, FileMode.WRITE);
				fs.writeUTFBytes(appXML);
			} finally {
				fs.close();
			}
			
			LOG.info("After writing it out, appXML =>\n" + appXML.toString());
		}
		
		/**
		 * Resolve the File / path where we save the firmware or swf
		 */
		private function getFile(type:String, appName:String):File {
			var outDir:File = appDir.resolvePath(cleanName(appName));
			if(type == 'firmware') {
				return outDir.resolvePath('firmware.hex');
			} else if(type == 'swf') {
				return outDir.resolvePath('ui.swf');
			} else {
				throw new Error('Unknown software component type '+type);
			}
		}
		
		/**
		 * Sanitize the name of the directory where we store the application; 
		 * Should remove illegal characters, spaces, etc.
		 */
		public static function cleanName(name:String):String {
			// trim whitespace
			name = StringUtil.trim(name);
			name = StringUtil.replace(name, ' ', '');
			// TODO check for illegal filename characters
			return name;
		}
		
	}
}