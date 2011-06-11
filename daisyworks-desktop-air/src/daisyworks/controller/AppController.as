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

		// reference to the XML file on disk: appStorage:/application.xml
		private var appMetadataFile:File = File.applicationStorageDirectory.resolvePath('applications.xml');
		
		// the directory where we install applications: appStorage:/applications/
		private var appDir:File = File.applicationStorageDirectory.resolvePath('applications');
				
		// in-memory XML of installed apps
		private var appXML:XML;
		
		[Dispatcher]
		public var dispatcher:IEventDispatcher;
		
		public function AppController() {}
		
		[PostConstruct]
		public function init():void {
			
			if(!appMetadataFile.exists) {
				var outputString:String = '<?xml version="1.0" encoding="utf-8"?>\n';
				outputString += '<apps></apps>';
				outputString = outputString.replace(/\n/g, File.lineEnding);
				// write the file out if it doesn't exist
				var fs:FileStream = new FileStream();
				try {
					fs.open(appMetadataFile, FileMode.WRITE);
					fs.writeUTFBytes(outputString);
				}
				finally {
					fs.close();
				}
			}
			appXML = new XML(outputString);
		}
		
		/**
		 * Handles AppEvent.LIST event; loads the user's XML file that contains a list of 
		 * all installed applications.
		 */
		[EventHandler(event="AppEvent.LIST")]
		public function list():void {
			var fs:FileStream = new FileStream();
			try {
				fs.open(appMetadataFile, FileMode.READ);
				appXML = XML(fs.readUTFBytes(fs.bytesAvailable));
				dispatcher.dispatchEvent(new AppEvent(AppEvent.LIST_RESULTS, null, new XMLListCollection(appXML.children())));	
			} finally {
				fs.close();
			}
		}
		
		public function downloadApp(app:XML):void {
			
			for each(var item:XML in app.software.children()) {
				if(item.@type == 'firmware') {
					// download firmware
				} else if(item.@type == 'swf') {
					// download swf
				}
			}
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
					
					var installXML:XML = 
						<install path=''>
							<ui></ui>
							<firmware></firmware>
							<manifest></manifest>
						</install>;
					
					// iterate through entries, and write them out
					for(var i:uint=0; i<zipFile.entries.length; i++)
					{
						var zipEntry:ZipEntry = zipFile.entries[i] as ZipEntry;
						if(!zipEntry.isDirectory())
						{
							var file:File = outDir.resolvePath(zipEntry.name);
							var stream:FileStream = new FileStream();
							if(StringUtil.endsWith(file.name.toLowerCase(), ".swf")) { 
								installXML.ui = file.url; 
							} else if(StringUtil.endsWith(file.name.toLowerCase(), ".hex")) {
								installXML.firmware = file.url;
							} else if(StringUtil.endsWith(file.name.toLowerCase(), ".xml")) {
								installXML.manifest = file.url;
							}
							// write the file
							stream.open(file, FileMode.WRITE);
							stream.writeBytes(zipFile.getInput(zipEntry));
							stream.close();
						}
					}
					installXML.@path = appDir.resolvePath(appName).url;
					// tell the world that the app is installed
					addAppAndSave(app, installXML);
					
					dispatcher.dispatchEvent(new AppEvent(AppEvent.DOWNLOAD_COMPLETE));
					dispatcher.dispatchEvent(new AppEvent(AppEvent.LIST_RESULTS, null, new XMLListCollection(appXML.children()) ) );
					
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
		
		public static function cleanName(name:String):String {
			// trim whitespace
			name = StringUtil.trim(name);
			name = StringUtil.replace(name, ' ', '');
			// TODO check for illegal filename characters
			return name;
		}
		
		private function addAppAndSave(app:XML, installXML:XML):void {
			app.appendChild(installXML);
			appXML.appendChild(app);
			var fs:FileStream = new FileStream();
			try {
				fs.open(appMetadataFile, FileMode.WRITE);
				fs.writeUTFBytes(appXML);
			}
			finally {
				fs.close();
			}
		}
		
		private function removeAppAndSave(app:XML, installPath:String):void {
			// TODO
		}
		
	}
}