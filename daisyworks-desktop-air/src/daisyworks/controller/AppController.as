package daisyworks.controller
{
	import com.adobe.utils.StringUtil;
	
	import daisyworks.event.AppEvent;
	import daisyworks.event.AppStoreEvent;
	import daisyworks.log.Logger;
	
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.utils.ByteArray;
	import flash.utils.IDataOutput;
	
	import mx.collections.XMLListCollection;
	import mx.logging.ILogger;
	
	import nochump.util.zip.ZipEntry;
	import nochump.util.zip.ZipFile;
	
	public class AppController
	{
		private static const LOG:ILogger = Logger.getLogger(AppController);
		
		private var urlLoader:URLLoader;
		
		// reference to the XML file on disk
		private var appMetadataFile:File = File.applicationStorageDirectory.resolvePath('applications.xml');
		
		private var appDir:File = File.applicationStorageDirectory.resolvePath('applications');
		
		// empty starter XML when file does not exist
		private static const emptyXML:XML = <apps></apps>;
		
		// in-memory XML of installed apps
		private var appXML:XML;
		
		[Dispatcher]
		public var dispatcher:IEventDispatcher;
		
		public function AppController() {}
		
		[PostConstruct]
		public function init():void {
			urlLoader = new URLLoader();
			urlLoader.addEventListener(Event.COMPLETE, loadComplete);
			urlLoader.addEventListener(IOErrorEvent.IO_ERROR, loadError);
			if(!appMetadataFile.exists) {
				// write the file out if it doesn't exist
				var fs:FileStream = new FileStream();
				try {
					fs.open(appMetadataFile, FileMode.WRITE);
					fs.writeObject(emptyXML.toString());
				}
				finally {
					fs.close();
				}
			}
		}
		
		/**
		 * Handles AppEvent.LIST event; loads the user's XML file that contains a list of 
		 * all installed applications.
		 */
		[EventHandler(event="AppEvent.LIST")]
		public function list():void {
			urlLoader.load(new URLRequest(appMetadataFile.url));
		}
		
		private function loadComplete(evt:Event):void {
			var xml:XML = XML(urlLoader.data);
			dispatcher.dispatchEvent(new AppEvent(AppEvent.LIST_RESULTS, null, new XMLListCollection(xml.children())));
		}
		
		private function loadError(evt:IOErrorEvent):void {
			LOG.error("Failed to load the installed app XML file " + evt.text);
		}
		
		/**
		 * Handles AppEvent.DOWNLOAD event; downloads the zip file, saves it to /:appStorage, 
		 * and then unzips the contents
		 */
		[EventHandler(event="AppEvent.DOWNLOAD", properties="app")]
		public function download(app:XML):void {
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.BINARY;
			loader.addEventListener(IOErrorEvent.IO_ERROR, downloadError);
			
			// do this in-line so we can ref the app
			loader.addEventListener(Event.COMPLETE, function(evt:Event):void {
				var loader:URLLoader = URLLoader(evt.target);
				var bytes:ByteArray = ByteArray(evt.target.data);
				
				var appName:String = cleanName(app.name);
				// path should be appStorage:/applications/{app.name}/{app.name.zip} 
				var zipName:String = appName + File.separator + appName+'.zip';
				
				// write out the zip file
				var fs:FileStream = new FileStream();
				try {
					fs.open(appDir.resolvePath(zipName), FileMode.WRITE);
					fs.writeBytes(bytes);
				} finally { fs.close(); }
				
				// uncompress it
				try {
					// open the file for reading
					fs = new FileStream();
					fs.open(appDir.resolvePath(zipName), FileMode.READ);
					// create a new ZipFile from the stream
					var zipFile:ZipFile = new ZipFile(fs);
					
					// path should be appStorage:/applications/{app.name}/  ?
					var outDir:File = appDir.resolvePath(appName);
					
					// iterate through entries, and write them out
					for(var i:uint=0; i<zipFile.entries.length; i++)
					{
						var zipEntry:ZipEntry = zipFile.entries[i] as ZipEntry;
						if(!zipEntry.isDirectory())
						{
							var file:File = outDir.resolvePath(zipEntry.name);
							var stream:FileStream = new FileStream();
							stream.open(file, FileMode.WRITE);
							stream.writeBytes(zipFile.getInput(zipEntry));
							stream.close();
						}
					}
				} finally {
					fs.close();
					// delete the zip file, we don't need it anymore
					appDir.resolvePath(zipName).deleteFile();
				}
			});
			
			// load the zip file from the URL
			loader.load(new URLRequest(app.url));
		}
				
		private function downloadError(evt:IOErrorEvent):void {
			LOG.error("Failed to download the app " + evt.text);
		}
		
		private function cleanName(name:String):String {
			// trim whitespace
			name = StringUtil.trim(name);
			name = StringUtil.replace(name, ' ', '');
			// TODO check for illegal filename characters
			return name;
		}
		
	}
}