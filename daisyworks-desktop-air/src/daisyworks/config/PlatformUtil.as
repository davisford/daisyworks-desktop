package daisyworks.config
{
	import com.adobe.utils.DateUtil;
	
	import flash.desktop.NativeApplication;
	import flash.system.Capabilities;
	
	import flashx.textLayout.conversion.TextConverter;
	import flashx.textLayout.elements.TextFlow;

	public class PlatformUtil
	{
		private static var WINDOWS:String = "Windows";
		private static var MAC:String = "Macintosh";
		private static var LINUX:String = "Linux";
		
		private static var os:String = Capabilities.manufacturer.replace("Adobe ","");
		
		public function PlatformUtil()
		{
		}
		
		public static function getAppVersion():String {
			var appXml:XML = NativeApplication.nativeApplication.applicationDescriptor;
			var ns:Namespace = appXml.namespace();
			var appVersion:String = appXml.ns::versionNumber[0];
			return appVersion;
		}
		
		public static function get platform():String { return os; }
		
		public static function isWindows():Boolean {
			return WINDOWS == os;
		}
		
		public static function isMacOS():Boolean {
			return MAC == os;
		}
		
		public static function isLinux32():Boolean {
			return LINUX == os && !Capabilities.supports64BitProcesses;
		}
		
		public static function isLinux64():Boolean {
			return LINUX == os && Capabilities.supports64BitProcesses;
		}
		
		public static function getTextFlow(node:XML, propertyName:String):TextFlow {
			try {  
				if(node != null) {
					var text:String = node[propertyName].toString();
					return TextConverter.importToFlow(text, TextConverter.TEXT_FIELD_HTML_FORMAT)
				} else {
					return null;
				}
			} catch(e:Error) {
				// don't crash the UI if this has an error, just display nothing
				trace(e.message);
			}
			return null;
		}
		
		public static function getDate(node:XML):Date {
			try { 
				return DateUtil.parseW3CDTF(node);
			} catch(e:Error) {
				return new Date();
			}
			return null;
		}
	}
}